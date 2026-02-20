import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portone_flutter_v2/portone_flutter_v2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:wish_drop/core/theme.dart';
import 'package:wish_drop/features/wish/data/project_model.dart';
import 'package:wish_drop/features/donation/data/donation_repository.dart';
import 'package:wish_drop/features/donation/presentation/pages/donation_success_page.dart';

// ✅ 분리된 서비스와 페이지 임포트 (경로 확인해주세요!)
import '../../services/payment_service.dart';
import 'payment_webview_page.dart';

class DonationInputPage extends StatefulWidget {
  final ProjectModel project;
  const DonationInputPage({super.key, required this.project});

  @override
  State<DonationInputPage> createState() => _DonationInputPageState();
}

class _DonationInputPageState extends State<DonationInputPage> {
  int _selectedAmount = 10000;
  bool _isUpdating = false; // 로딩 상태

  final TextEditingController _amountController = TextEditingController(
    text: "10,000",
  );
  final TextEditingController _msgController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // 3가지 금액 프리셋
  final List<int> _presetAmounts = [10000, 30000, 50000];
  final currencyFormat = NumberFormat("#,###");

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onTextChanged);
    _amountController.dispose();
    _msgController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // 금액 입력 시 자동 포맷팅 (10000 -> 10,000)
  void _onTextChanged() {
    String text = _amountController.text.replaceAll(',', '');
    if (text.isEmpty) {
      setState(() => _selectedAmount = 0);
      return;
    }
    int? val = int.tryParse(text);
    if (val != null && val != _selectedAmount) {
      setState(() => _selectedAmount = val);
    }
  }

  // 프리셋 버튼(1만, 3만, 5만) 클릭 시
  void _selectPreset(int amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = currencyFormat.format(amount);
      _focusNode.unfocus();
    });
  }

  // 🚀 [핵심] 결제 버튼 클릭 로직 (서비스 분리 적용됨)
  void _onDonatePressed() async {
    // 1. 중복 클릭 방지 (이미 처리 중이면 함수 종료)
    if (_isUpdating) {
      print("🚫 [중복 방지] 이미 처리 중입니다.");
      return;
    }
    if (_selectedAmount <= 0) return;

    // 2. 로딩 시작 (버튼 비활성화)
    setState(() => _isUpdating = true);

    try {
      // 3. 결제 요청 객체 생성
      final paymentRequest = PaymentService.createKakaoRequest(
        orderName: widget.project.title,
        amount: _selectedAmount,
        projectId: widget.project.id.toString(),
        message: _msgController.text,
      );

      if (paymentRequest == null) {
        throw Exception("환경 설정(.env) 오류");
      }

      // 4. 결제창 이동 (결과를 기다림)
      final dynamic result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PaymentWebViewPage(paymentRequest: paymentRequest),
        ),
      );

      // 화면이 닫혔거나(mounted false), 결과가 없으면 종료
      if (!mounted) return;

      // 5. 결제 결과 확인
      // result가 null이거나 code가 null이 아니면 실패로 간주
      if (result is PaymentResponse && result.code == null) {
        print("💰 결제 성공! DB 업데이트 시작");

        // DB 업데이트 (새로운 플로우: insertDonation + updateCurrentAmount)
        final donationRepo = DonationRepository();
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          throw Exception("로그인이 필요합니다.");
        }

        // payment_id는 PaymentService에서 생성한 uniqueId 사용
        final paymentId = paymentRequest.paymentId;
        final projectId = widget.project.id; // 이미 int 타입

        // 1. 후원 기록 INSERT (payment_id 포함)
        await donationRepo.insertDonation(
          projectId: projectId,
          userId: user.id,
          amount: _selectedAmount,
          message: _msgController.text,
          isAnonymous: false, // UI에서 익명 옵션이 없으면 false
          paymentId: paymentId,
        );

        // 2. 프로젝트 current_amount 증가 (트리거가 자동으로 종료 체크)
        await donationRepo.updateCurrentAmount(
          projectId: projectId,
          addedAmount: _selectedAmount,
        );

        print("🚀 DB 업데이트 완료. 성공 페이지로 이동합니다.");

        if (!mounted) return;

        // 다음 프레임에서 이동 (async 직후 context가 안정되도록)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DonationSuccessPage()),
            (r) => false,
          );
        });
      } else {
        // 결제 실패 또는 취소
        String failMsg = "결제가 취소되었습니다.";
        if (result is PaymentResponse && result.message != null) {
          failMsg = result.message!;
        }
        print("⚠️ 결제 실패: $failMsg");

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failMsg)));
      }
    } catch (e) {
      print("❌ 에러 발생: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
      }
    } finally {
      // 6. 로딩 종료 (성공해서 페이지가 이동했다면 실행 안 됨)
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("마음 전하기"),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 메인 콘텐츠
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProjectInfo(),
                      const SizedBox(height: 32),
                      const Text(
                        "후원 금액 선택",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textHeading,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPresetList(),
                      const SizedBox(height: 32),
                      _buildAmountField(),
                      const SizedBox(height: 32),
                      const Text(
                        "응원 메시지 (선택)",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textHeading,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMessageField(),
                      const SizedBox(height: 40), // 하단 여백 확보
                    ],
                  ),
                ),
              ),
              _buildBottomButton(),
            ],
          ),

          // 로딩 오버레이
          if (_isUpdating)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "처리 중입니다...",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- UI 위젯들 (이전 디자인 복원) ---

  // 1. 프로젝트 정보 카드
  Widget _buildProjectInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.project.thumbnailUrl != null
                ? Image.network(
                    widget.project.thumbnailUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 64,
                    height: 64,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.project.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textHeading,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 2. 금액 프리셋 버튼 리스트
  Widget _buildPresetList() {
    return Row(
      children: _presetAmounts
          .map((a) => Expanded(child: _buildPresetButton(a)))
          .toList(),
    );
  }

  // 3. 개별 프리셋 버튼 스타일
  Widget _buildPresetButton(int a) {
    bool isSel = _selectedAmount == a && !_focusNode.hasFocus;
    return GestureDetector(
      onTap: () => _selectPreset(a),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? AppTheme.primary : AppTheme.borderColor,
          ),
          boxShadow: isSel
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            "${a ~/ 10000}만",
            style: TextStyle(
              color: isSel ? Colors.white : AppTheme.textBody,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // 4. 금액 직접 입력 필드
  Widget _buildAmountField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _amountController,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textHeading,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "0",
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "원",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textHeading,
            ),
          ),
        ],
      ),
    );
  }

  // 5. 메시지 입력 필드
  Widget _buildMessageField() {
    return TextField(
      controller: _msgController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: "따뜻한 응원의 한마디를 남겨주세요!",
        fillColor: Colors.white,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
      ),
    );
  }

  // 6. 하단 후원하기 버튼
  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _selectedAmount > 0 && !_isUpdating
                ? _onDonatePressed
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              "${currencyFormat.format(_selectedAmount)}원 후원하기",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
