/// 웹이 아닌 플랫폼(테스트 VM 등)용 스텁.
/// 실제 토큰 요청은 웹에서만 동작한다.
Future<String> requestGoogleToken(String clientId, String scope) {
  throw UnsupportedError('구글 인증은 웹 브라우저에서만 지원됩니다.');
}
