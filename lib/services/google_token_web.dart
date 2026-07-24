import 'dart:js_interop';

/// web/index.html 의 window.hbgRequestGoogleToken 를 호출한다.
/// 팝업으로 구글 로그인/동의를 받고 OAuth 액세스 토큰을 돌려준다.
@JS('hbgRequestGoogleToken')
external JSPromise<JSString> _hbgRequestGoogleToken(
    JSString clientId, JSString scope);

Future<String> requestGoogleToken(String clientId, String scope) async {
  final token =
      await _hbgRequestGoogleToken(clientId.toJS, scope.toJS).toDart;
  return token.toDart;
}
