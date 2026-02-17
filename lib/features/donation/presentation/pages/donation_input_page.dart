import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:portone_flutter_v2/portone_flutter_v2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:wish_drop/core/theme.dart';
import 'package:wish_drop/features/wish/data/project_model.dart';
import 'package:wish_drop/features/donation/presentation/pages/donation_success_page.dart';
import 'package:wish_drop/features/donation/data/donation_repository.dart';

class DonationInputPage extends StatefulWidget {
  final ProjectModel project;
  const DonationInputPage({super.key, required this.project});

  @override
  State<DonationInputPage> createState() => _DonationInputPageState();
}

class _DonationInputPageState extends State<DonationInputPage> {
  int _selectedAmount = 10000;
  bool _isUpdating = false;

  final TextEditingController _amountController = TextEditingController(
    text: "10,000",
  );
  final TextEditingController _msgController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
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

  void _selectPreset(int amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = currencyFormat.format(amount);
      _focusNode.unfocus();
    });
  }

  void _enableDirectInput() {
    setState(() {
      _amountController.clear();
      _selectedAmount = 0;
      _focusNode.requestFocus();
    });
  }

  // 🚀 카카오 결제 실행 로직
  void _onDonatePressed() async {
    if (_selectedAmount <= 0 || _isUpdating) return;

    final storeId = dotenv.env['STORE_ID'] ?? '';
    final channelKey = dotenv.env['CACAO_CHANNEL_KEY'] ?? '';

    // 💡 디버깅을 위해 키가 로드되었는지 확인합니다.
    if (storeId.isEmpty || channelKey.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('환경 설정(.env)을 확인해주세요.')));
      return;
    }

    final paymentRequest = PaymentRequest(
      storeId: storeId,
      channelKey: channelKey,
      paymentId: "payment-${DateTime.now().millisecondsSinceEpoch}",
      orderName: widget.project.title,
      totalAmount: _selectedAmount,
      currency: PaymentCurrency.KRW,
      payMethod: PaymentPayMethod.easyPay, // 간편결제(카카오페이 등) 필수 설정
      appScheme: 'wishdrop', // AndroidManifest의 scheme과 일치해야 함
      customData: {
        "userId": Supabase.instance.client.auth.currentUser?.id ?? '',
        "projectId": widget.project.id.toString(),
        "message": _msgController.text,
      },
      customer: Customer(
        fullName: "Wish Drop 후원자",
        email:
            Supabase.instance.client.auth.currentUser?.email ?? "test@test.com",
      ),
    );

    // 결제 화면으로 이동
    final dynamic result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(paymentRequest: paymentRequest),
      ),
    );

    if (!mounted) return;

    // 결제 성공 여부 판단
    if (result is PaymentResponse && result.code == null) {
      try {
        setState(() => _isUpdating = true);

        final donationRepo = DonationRepository();
        await donationRepo.donate(
          projectId: widget.project.id.toString(),
          amount: _selectedAmount,
          message: _msgController.text,
        );

        if (!mounted) return;

        // 성공 시 메인(홈)으로 돌아가기
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DonationSuccessPage()),
          (route) => route.isFirst,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('결제는 완료되었으나 데이터 기록 실패: $e')));
      } finally {
        if (mounted) setState(() => _isUpdating = false);
      }
    } else {
      // 결제 실패 또는 취소 로그
      debugPrint("결제 실패 결과: $result");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('결제가 취소되었거나 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("마음 전하기"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          _buildContent(),
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
                      "기록을 업데이트 중입니다...",
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

  // UI 헬퍼 메서드들 (이하 생략 - 기존 스타일 유지)
  Widget _buildContent() {
    return Column(
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
              ],
            ),
          ),
        ),
        _buildBottomButton(),
      ],
    );
  }

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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetList() {
    return Row(
      children: _presetAmounts
          .map((a) => Expanded(child: _buildPresetButton(a)))
          .toList(),
    );
  }

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

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key, required this.paymentRequest});
  final PaymentRequest paymentRequest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결제하기'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: PortonePayment(
        data: paymentRequest,
        initialChild: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        callback: (response) => Navigator.pop(context, response),
        onError: (e) => Navigator.pop(context, null),
      ),
    );
  }
}
