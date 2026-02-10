import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // .env 사용
import 'package:portone_flutter_v2/portone_flutter_v2.dart'; // ✅ V2 패키지

import 'package:wish_drop/core/theme.dart';
import 'package:wish_drop/features/data/project_model.dart';
import 'package:wish_drop/features/pages/donation_success_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DonationInputPage extends StatefulWidget {
  final ProjectModel project;

  const DonationInputPage({super.key, required this.project});

  @override
  State<DonationInputPage> createState() => _DonationInputPageState();
}

class _DonationInputPageState extends State<DonationInputPage> {
  // 기본 선택 금액
  int _selectedAmount = 10000;

  // 텍스트 필드 제어용
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

  // 🚀 [핵심] 결제 버튼 눌렀을 때 실행되는 함수
  void _onDonatePressed() async {
    if (_selectedAmount <= 0) return;

    // 1. .env에서 키 값 확인
    final storeId = dotenv.env['STORE_ID'] ?? '';
    final channelKey = dotenv.env['CACAO_CHANNEL_KEY'] ?? '';

    if (storeId.isEmpty || channelKey.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('오류: .env 설정이 누락되었습니다.')));
      return;
    }

    // 2. PaymentRequest 데이터 생성
    final paymentRequest = PaymentRequest(
      storeId: storeId,
      channelKey: channelKey,
      paymentId: "payment-${DateTime.now().millisecondsSinceEpoch}",
      orderName: widget.project.title,
      totalAmount: _selectedAmount.toInt(), // int형 사용
      currency: PaymentCurrency.KRW,
      payMethod: PaymentPayMethod.easyPay, // ✅ 카카오페이 등 간편결제는 easyPay 필수
      appScheme: 'wishdrop', // AndroidManifest/Info.plist 설정 필요
      customer: Customer(
        fullName: "홍길동",
        phoneNumber: "010-1234-5678",
        email: "test@test.com",
      ),
    );

    // 3. 결제 화면(PaymentScreen)으로 이동하여 결과 대기
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(paymentRequest: paymentRequest),
      ),
    );

    // 4. 결제 결과 처리
    if (result != null && result is PaymentResponse) {
      // ✅ [추가된 부분] 결제가 성공했으면 DB에 기록하기!
      try {
        final supabase = Supabase.instance.client;

        // donations 테이블에 추가 (트리거가 작동해서 총액도 같이 오름)
        await supabase.from('donations').insert({
          'project_id': widget.project.id, // 프로젝트 ID
          'user_id': supabase.auth.currentUser!.id, // 로그인한 유저 ID
          'amount': _selectedAmount, // 후원 금액
          'message': _msgController.text, // 응원 메시지
          'created_at': DateTime.now().toIso8601String(),
          // 'payment_id': result.paymentId, // (선택) 나중에 대조해볼 때 필요함
        });

        if (!mounted) return;

        // 성공 페이지로 이동!
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DonationSuccessPage()),
        );
      } catch (e) {
        // DB 저장 실패 시 (돈은 나갔는데 DB 에러난 경우 - 실제론 환불 로직이 필요하지만 일단 에러 표시)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('결제는 성공했으나 기록 저장 실패: $e')));
      }
    } else {
      // 결제 취소 또는 실패
      if (!mounted) return;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("마음 전하기"),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로젝트 정보 (기존 유지)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.project.thumbnailUrl ?? '',
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 64,
                                  height: 64,
                                  color: Colors.grey[100],
                                  child: const Icon(
                                    Icons.image,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "🎁 선물 후원하기",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.project.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textHeading,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 금액 선택 (기존 유지)
                  const Text(
                    "얼마를 후원하시겠어요?",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textHeading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ..._presetAmounts.map(
                        (amount) => Expanded(child: _buildPresetButton(amount)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: _enableDirectInput,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _focusNode.hasFocus
                                  ? AppTheme.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _focusNode.hasFocus
                                    ? AppTheme.primary
                                    : AppTheme.borderColor,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "직접입력",
                                style: TextStyle(
                                  color: _focusNode.hasFocus
                                      ? Colors.white
                                      : AppTheme.textBody,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 금액 입력 (기존 유지)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
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
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) {
                              String clean = value.replaceAll(',', '');
                              if (clean.isNotEmpty) {
                                String formatted = currencyFormat.format(
                                  int.parse(clean),
                                );
                                if (value != formatted) {
                                  _amountController.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                      offset: formatted.length,
                                    ),
                                  );
                                }
                              }
                            },
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
                  ),
                  const SizedBox(height: 32),

                  // 응원 메시지 (기존 유지)
                  const Text(
                    "응원 메시지 (선택)",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textHeading,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _msgController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "따뜻한 응원의 한마디를 남겨주세요!",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      fillColor: Colors.white,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 결제 버튼
          Container(
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
                  onPressed: _selectedAmount > 0 ? _onDonatePressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[200],
                    disabledForegroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _selectedAmount > 0
                        ? "${currencyFormat.format(_selectedAmount)}원 후원하기"
                        : "금액을 입력해주세요",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(int amount) {
    bool isSelected = _selectedAmount == amount && !_focusNode.hasFocus;
    return GestureDetector(
      onTap: () => _selectPreset(amount),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.textHeading : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.textHeading : AppTheme.borderColor,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.textHeading.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            "${amount ~/ 10000}만",
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textBody,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 🔥 [수정된 부분] PaymentScreen
// ---------------------------------------------------------------------
class PaymentScreen extends StatelessWidget {
  // 생성자 매개변수 이름을 'paymentRequest'로 맞췄습니다.
  const PaymentScreen({super.key, required this.paymentRequest});
  final PaymentRequest paymentRequest;

  @override
  Widget build(BuildContext context) {
    // 위젯 이름 확인: PortonePayment (소문자 o)
    return PortonePayment(
      appBar: AppBar(title: const Text('결제하기')),
      data: paymentRequest,
      initialChild: const Center(child: CircularProgressIndicator()),
      callback: (PaymentResponse response) {
        // 결제 완료 (성공/실패 여부는 response 안에 있음)
        Navigator.pop(context, response);
      },
      onError: (Object? error) {
        // 결제 모듈 자체 에러
        debugPrint('결제 에러: $error');
        Navigator.pop(context, null);
      },
    );
  }
}
