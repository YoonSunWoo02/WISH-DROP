import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:portone_flutter_v2/portone_flutter_v2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:wish_drop/core/theme.dart';
import 'package:wish_drop/features/data/project_model.dart';
import 'package:wish_drop/features/pages/donation_success_page.dart';

class DonationInputPage extends StatefulWidget {
  final ProjectModel project;

  const DonationInputPage({super.key, required this.project});

  @override
  State<DonationInputPage> createState() => _DonationInputPageState();
}

class _DonationInputPageState extends State<DonationInputPage> {
  int _selectedAmount = 10000;

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

  // 🚀 [수정됨] 결제 버튼 로직
  void _onDonatePressed() async {
    if (_selectedAmount <= 0) return;

    final storeId = dotenv.env['STORE_ID'] ?? '';
    final channelKey = dotenv.env['CACAO_CHANNEL_KEY'] ?? '';

    if (storeId.isEmpty || channelKey.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('오류: .env 설정이 누락되었습니다.')));
      return;
    }

    // ✅ [수정 1] customData를 Map<String, String>으로 만듭니다.
    // 모든 값은 문자열(String)이어야 합니다.
    Map<String, String> customDataMap = {
      "userId": Supabase.instance.client.auth.currentUser?.id ?? '',
      "projectId": widget.project.id.toString(), // int -> String 변환
      "message": _msgController.text,
    };

    final paymentRequest = PaymentRequest(
      storeId: storeId,
      channelKey: channelKey,
      paymentId: "payment-${DateTime.now().millisecondsSinceEpoch}",
      orderName: widget.project.title,
      totalAmount: _selectedAmount.toInt(),
      currency: PaymentCurrency.KRW,
      payMethod: PaymentPayMethod.easyPay,
      appScheme: 'wishdrop',

      // ✅ Map 그대로 전달 (jsonEncode 안 함)
      customData: customDataMap,

      customer: Customer(
        fullName: "홍길동",
        phoneNumber: "010-1234-5678",
        email: "test@test.com",
      ),
    );

    // 결제 화면으로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(paymentRequest: paymentRequest),
      ),
    );

    // 결제 성공 처리 (DB 저장은 서버가 함)
    if (result != null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DonationSuccessPage()),
      );
    } else {
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
                  // 프로젝트 정보 UI
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

                  // 금액 선택 UI
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

                  // 금액 입력창 UI
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

                  // 응원 메시지 UI
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

          // 하단 버튼
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
// 🔥 [수정 2] PaymentScreen (onError 추가)
// ---------------------------------------------------------------------
class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key, required this.paymentRequest});
  final PaymentRequest paymentRequest;

  @override
  Widget build(BuildContext context) {
    return PortonePayment(
      appBar: AppBar(title: const Text('결제하기')),
      data: paymentRequest,
      initialChild: const Center(child: CircularProgressIndicator()),
      callback: (PaymentResponse response) {
        // 결제 완료 (성공/취소 등) -> 결과 반환
        Navigator.pop(context, response);
      },
      // ✅ onError는 필수 항목입니다!
      onError: (String error) {
        debugPrint('결제 모듈 에러: $error');
        Navigator.pop(context, null); // 에러 시 null 반환
      },
    );
  }
}
