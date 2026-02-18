import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:portone_flutter_v2/portone_flutter_v2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  static PaymentRequest? createKakaoRequest({
    required String orderName,
    required int amount,
    required String projectId,
    String? message,
  }) {
    final storeId = dotenv.env['STORE_ID'] ?? '';
    final channelKey = dotenv.env['CACAO_CHANNEL_KEY'] ?? '';

    if (storeId.isEmpty || channelKey.isEmpty) return null;

    final user = Supabase.instance.client.auth.currentUser;

    // 🚨 [수정] ID 중복 절대 방지 (밀리초 + 랜덤 6자리)
    // 예: payment-1708234567890-123456
    final String uniqueId =
        "payment-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(899999) + 100000}";

    return PaymentRequest(
      storeId: storeId,
      channelKey: channelKey,
      paymentId: uniqueId,
      orderName: orderName,
      totalAmount: amount,
      currency: PaymentCurrency.KRW,
      payMethod: PaymentPayMethod.easyPay,
      redirectUrl: 'wishdrop://payment',
      appScheme: 'wishdrop',
      customData: {
        "userId": user?.id ?? 'guest',
        "projectId": projectId,
        "message": message ?? '',
      },
      customer: Customer(
        fullName: "Wish Drop 후원자",
        email: user?.email ?? "unknown@test.com",
      ),
    );
  }
}
