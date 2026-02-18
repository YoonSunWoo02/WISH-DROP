import 'package:flutter/material.dart';
import 'package:portone_flutter_v2/portone_flutter_v2.dart';
import 'package:wish_drop/core/theme.dart'; // 테마 경로 확인 필요

class PaymentWebViewPage extends StatelessWidget {
  final PaymentRequest paymentRequest;

  const PaymentWebViewPage({super.key, required this.paymentRequest});

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
        callback: (response) {
          // 결제 완료(성공/실패) 후 결과를 가지고 돌아감
          Navigator.pop(context, response);
        },
        onError: (e) {
          // 에러 발생 시 빈손으로 돌아감
          Navigator.pop(context, null);
          print("결제 에러 발생: $e");
        },
      ),
    );
  }
}
