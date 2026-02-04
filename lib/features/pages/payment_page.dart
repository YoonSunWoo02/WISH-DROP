import 'package:flutter/material.dart';
import 'package:portone_flutter_v2/portone_flutter_v2.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentPage extends StatelessWidget {
  final String title; // 프로젝트 제목 (결제 이름)
  final int amount; // 결제 금액
  final String orderName; // 주문 번호 (고유 ID)

  const PaymentPage({
    super.key,
    required this.title,
    required this.amount,
    required this.orderName,
  });

  @override
  Widget build(BuildContext context) {
    // 1. .env에서 키 가져오기
    final String storeId = dotenv.env['PORTONE_STORE_ID'] ?? '';
    final String channelKey = dotenv.env['PORTONE_CHANNEL_KEY'] ?? '';

    // 2. 결제 요청 객체 생성 (PaymentRequest 사용 - 오류 없음!)
    final paymentRequest = PaymentRequest(
      storeId: storeId,
      paymentId: orderName, // 주문 번호 (Unique Key)
      orderName: title, // 결제 상품명
      totalAmount: amount.toInt(), // int 형으로 전달
      currency: PaymentCurrency.KRW,
      channelKey: channelKey,
      payMethod: PaymentPayMethod.easyPay, // 결제 수단
      appScheme: 'wish_drop', // AndroidManifest에 설정한 스킴
      // 👇 [핵심] 이 줄이 있어야 튕기지 않고 앱으로 돌아옵니다.
      redirectUrl: 'https://www.myservice.com/payment/result',

      // 고객 정보 (선택 사항)
      customer: Customer(
        fullName: "익명 후원자",
        phoneNumber: "010-0000-0000",
        email: "test@test.com",
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('후원 결제')),
      // 3. 포트원 결제 위젯 사용
      body: PortonePayment(
        data: paymentRequest,
        initialChild: const Center(child: CircularProgressIndicator()),
        callback: (PaymentResponse result) {
          // 결제 완료 후 결과 처리
          debugPrint('결제 콜백: ${result.toJson()}');

          // 이전 화면으로 결과(result)를 가지고 돌아감
          // (성공, 실패 여부는 돌아간 화면에서 result.code로 확인)
          Navigator.pop(context, result);
        },
        onError: (Object? error) {
          debugPrint('결제 에러: $error');
          // 에러 시 null을 가지고 돌아감
          Navigator.pop(context, null);
        },
      ),
    );
  }
}
