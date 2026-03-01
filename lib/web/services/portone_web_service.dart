import 'dart:convert';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 웹 전용: dart:js_interop 사용 (조건부 임포트)
import 'portone_web_service_impl.dart'
    if (dart.library.io) 'portone_web_service_stub.dart' as impl;

/// 웹 전용 결제 결과
class PortOneWebResult {
  final bool isSuccess;
  final String? code;
  final String? message;
  final String? paymentId;

  const PortOneWebResult({
    required this.isSuccess,
    this.code,
    this.message,
    this.paymentId,
  });
}

/// 웹 전용 PortOne 결제 서비스 — JS Interop으로 결제창 호출
class PortOneWebService {
  static String? _createPaymentId() {
    return "payment-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(899999) + 100000}";
  }

  /// 결제 요청 객체 생성 (환경변수 기반)
  static Map<String, dynamic>? createPaymentConfig({
    required String orderName,
    required int amount,
    required String projectId,
    String? message,
  }) {
    final storeId =
        dotenv.env['STORE_ID'] ?? dotenv.env['PORTONE_STORE_ID'] ?? '';
    final channelKey = dotenv.env['CACAO_CHANNEL_KEY'] ??
        dotenv.env['PORTONE_CHANNEL_KEY'] ??
        '';

    if (storeId.isEmpty || channelKey.isEmpty) return null;

    final user = Supabase.instance.client.auth.currentUser;
    final paymentId = _createPaymentId();

    return {
      'storeId': storeId,
      'channelKey': channelKey,
      'paymentId': paymentId,
      'orderName': orderName,
      'totalAmount': amount,
      'currency': 'KRW',
      'payMethod': 'EASY_PAY',
      'customer': {
        'fullName': 'Wish Drop 후원자',
        'email': user?.email ?? 'unknown@test.com',
      },
      'customData': {
        'userId': user?.id ?? 'guest',
        'projectId': projectId,
        'message': message ?? '',
      },
      'easyPay': {},
    };
  }

  /// 결제창 호출 (JSON 문자열로 전달 → Promise → Future)
  static Future<PortOneWebResult> requestPayment(
    Map<String, dynamic> config,
  ) async {
    return impl.requestPaymentImpl(config);
  }
}
