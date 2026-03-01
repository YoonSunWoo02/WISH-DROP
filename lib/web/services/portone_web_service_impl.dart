import 'dart:convert';

import 'dart:js_interop';

import 'portone_web_service.dart';

/// window.requestPortOnePaymentJson(jsonStr) → Promise<JSON문자열>
@JS('requestPortOnePaymentJson')
external JSPromise<JSString> _requestPortOnePaymentJson(JSString jsonStr);

Future<PortOneWebResult> requestPaymentImpl(Map<String, dynamic> config) async {
  final jsonStr = jsonEncode(config).toJS;
  try {
    final promise = _requestPortOnePaymentJson(jsonStr);
    final resultJson = await promise.toDart;
    final resultStr = resultJson.toDart;

    if (resultStr.isEmpty) {
      return const PortOneWebResult(
        isSuccess: false,
        message: '결제 결과를 받지 못했어요.',
      );
    }

    final map = jsonDecode(resultStr);
    if (map is! Map<String, dynamic>) {
      return const PortOneWebResult(
        isSuccess: false,
        message: '결제 응답 형식 오류',
      );
    }

    final code = map['code'];
    final message = map['message'] as String?;
    final paymentId = map['paymentId'] as String?;

    // code가 null이거나 없으면 성공
    final isSuccess = code == null || code.toString() == 'null';

    return PortOneWebResult(
      isSuccess: isSuccess,
      code: code?.toString(),
      message: message,
      paymentId: paymentId ?? config['paymentId'] as String?,
    );
  } on FormatException catch (e) {
    return PortOneWebResult(
      isSuccess: false,
      message: '결제 응답 처리 중 오류: ${e.message}',
    );
  } catch (e) {
    return PortOneWebResult(
      isSuccess: false,
      message: e.toString().length > 100
          ? '결제 처리 중 문제가 발생했어요.'
          : e.toString(),
    );
  }
}
