import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:portone_flutter_v2/portone_flutter_v2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:wish_drop/core/theme.dart';
import 'package:wish_drop/features/wish/data/project_model.dart';
import 'package:wish_drop/features/donation/presentation/pages/donation_success_page.dart';

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

  // 🚀 결제 프로세스 시작
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

    // 포트원 V2 결제 요청 객체 생성
    final paymentRequest = PaymentRequest(
      storeId: storeId,
      channelKey: channelKey,
      paymentId: "payment-${DateTime.now().millisecondsSinceEpoch}",
      orderName: widget.project.title,
      totalAmount: _selectedAmount,
      currency: PaymentCurrency.KRW,
      payMethod: PaymentPayMethod.easyPay,
      appScheme: 'wishdrop',
      customData: {
        "userId": Supabase.instance.client.auth.currentUser?.id ?? '',
        "projectId": widget.project.id.toString(),
        "message": _msgController.text,
      },
      customer: Customer(
        fullName: "사용자", // 실무에선 유저 프로필 데이터 사용
        email:
            Supabase.instance.client.auth.currentUser?.email ?? "test@test.com",
      ),
    );

    // 결제 화면 이동 및 결과 수신
    final dynamic result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(paymentRequest: paymentRequest),
      ),
    );

    if (!mounted) return;

    // ✅ 결과 처리 로직 개선
    if (result is PaymentResponse) {
      // 결제가 성공했거나 완료된 상태인지 확인 (포트원 V2 응답 기준)
      if (result.code == null) {
        // 성공 시 (에러 코드가 없으면 성공으로 간주하거나 status 확인)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DonationSuccessPage()),
        );
      } else {
        // 실패 시 에러 메시지 노출
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('결제 실패: ${result.message}')));
      }
    } else {
      // 결제 취소 시 (null이 반환된 경우)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('결제가 취소되었습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI 빌드 코드는 기존과 동일하므로 생략 (변동 사항 없음)
    return _buildBody();
  }

  // UI 빌드 부분은 기존 코드를 그대로 유지하시면 됩니다.
  Widget _buildBody() {
    /* 기존 Scaffold 코드 */
    return Container();
  }
}

// ---------------------------------------------------------------------
// 🔥 PaymentScreen 수정 (Callback 함수 타입 일치)
// ---------------------------------------------------------------------
class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key, required this.paymentRequest});
  final PaymentRequest paymentRequest;

  @override
  Widget build(BuildContext context) {
    return PortonePayment(
      appBar: AppBar(
        title: const Text('결제하기'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      data: paymentRequest,
      initialChild: const Center(child: CircularProgressIndicator()),
      // ✅ PortOne V2 라이브러리의 PaymentResponse 타입을 명확히 처리
      callback: (PaymentResponse response) {
        Navigator.pop(context, response);
      },
      // ✅ 에러 시 에러 객체를 담아 반환하거나 로그를 남김
      onError: (dynamic error) {
        debugPrint('결제 모듈 에러: $error');
        Navigator.pop(context, error);
      },
    );
  }
}
