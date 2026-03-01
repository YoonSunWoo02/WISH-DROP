import 'portone_web_service.dart';

/// 비웹 플랫폼용 스텁 (실제로는 웹에서만 사용)
Future<PortOneWebResult> requestPaymentImpl(Map<String, dynamic> config) {
  throw UnsupportedError('PortOne 웹 결제는 웹 플랫폼에서만 지원됩니다.');
}
