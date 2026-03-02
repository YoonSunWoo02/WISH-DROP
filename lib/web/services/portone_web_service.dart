import 'dart:convert';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 웹 전용: dart:js_interop 사용 (조건부 임포트)
import 'portone_web_service_impl.dart'
    if (dart.library.io) 'portone_web_service_stub.dart'
    as impl;

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
  /// 결제 요청 객체 생성 (환경변수 기반)
  static Map<String, dynamic>? createPaymentConfig({
    required String orderName,
    required int amount,
    required String projectId,
    String? message,
  }) {
    final storeId =
        dotenv.env['STORE_ID'] ?? dotenv.env['PORTONE_STORE_ID'] ?? '';
    final channelKey =
        dotenv.env['CACAO_CHANNEL_KEY'] ??
        dotenv.env['PORTONE_CHANNEL_KEY'] ??
        '';

    if (storeId.isEmpty || channelKey.isEmpty) return null;

    final user = Supabase.instance.client.auth.currentUser;
    // payment-{projectId}-{timestamp}-{random} → 웹훅에서 customData 없어도 projectId 추출
    final paymentId =
        'payment-$projectId-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(899999) + 100000}';

    // 웹훅 URL: QR 결제 등 클라이언트에서 결과 못 받을 때 donations 저장
    final supabaseUrl = (dotenv.env['SUPABASE_URL'] ?? '').replaceAll(
      RegExp(r'/$'),
      '',
    );
    final noticeUrls = supabaseUrl.isNotEmpty
        ? ['$supabaseUrl/functions/v1/portone-webhook']
        : <String>[];

    return {
      'storeId': storeId,
      'channelKey': channelKey,
      'paymentId': paymentId,
      'orderName': orderName,
      'totalAmount': amount,
      'currency': 'KRW',
      'payMethod': 'EASY_PAY',
      if (noticeUrls.isNotEmpty) 'noticeUrls': noticeUrls,
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
