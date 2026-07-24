import 'dart:convert';

import 'package:http/http.dart' as http;

// 웹에서만 dart:js_interop 구현을 쓰고, 그 외(테스트 VM)에서는 스텁을 쓴다.
import 'google_token_stub.dart'
    if (dart.library.js_interop) 'google_token_web.dart';

/// 드라이브의 스프레드시트 한 건(목록용).
class DriveFile {
  DriveFile(this.id, this.name, this.modifiedTime);
  final String id;
  final String name;
  final String? modifiedTime;
}

/// 구글 API 오류(권한 만료 포함).
class GoogleApiException implements Exception {
  GoogleApiException(this.message, {this.needsReauth = false});
  final String message;
  final bool needsReauth;
  @override
  String toString() => message;
}

/// 구글 드라이브(스프레드시트 목록) + 시트(값) 실시간 조회.
///
/// 인증은 브라우저의 Google Identity Services 팝업을 이용하므로
/// 서버/시크릿이 필요 없다. 사용자의 OAuth 클라이언트 ID만 있으면 된다.
class GoogleSheetsService {
  GoogleSheetsService(this.clientId);

  final String clientId;

  /// 목록(메타데이터)만 읽고, 시트 값은 읽기 전용으로 접근한다.
  static const String scopes =
      'https://www.googleapis.com/auth/drive.metadata.readonly '
      'https://www.googleapis.com/auth/spreadsheets.readonly';

  String? _token;
  bool get isAuthorized => _token != null;

  /// 팝업으로 구글 계정 인증 → 액세스 토큰 획득.
  Future<void> authorize() async {
    try {
      _token = await requestGoogleToken(clientId, scopes);
    } catch (e) {
      throw GoogleApiException('구글 인증에 실패했습니다: $e', needsReauth: true);
    }
  }

  void signOut() => _token = null;

  Map<String, String> get _headers => {'Authorization': 'Bearer $_token'};

  /// 내 드라이브 + 공유 드라이브의 모든 스프레드시트 목록(최근 수정 순).
  Future<List<DriveFile>> listSpreadsheets() async {
    final uri =
        Uri.parse('https://www.googleapis.com/drive/v3/files').replace(
      queryParameters: {
        'q': "mimeType='application/vnd.google-apps.spreadsheet' "
            'and trashed=false',
        'fields': 'files(id,name,modifiedTime)',
        'orderBy': 'modifiedTime desc',
        'pageSize': '500',
        'corpora': 'allDrives',
        'includeItemsFromAllDrives': 'true',
        'supportsAllDrives': 'true',
      },
    );
    final r = await http.get(uri, headers: _headers);
    _check(r);
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final files = (data['files'] as List?) ?? const [];
    return files
        .map((f) => DriveFile(
              f['id'] as String,
              (f['name'] as String?) ?? '(제목 없음)',
              f['modifiedTime'] as String?,
            ))
        .toList();
  }

  /// 한 스프레드시트의 탭(시트) 이름 목록.
  Future<List<String>> listTabs(String spreadsheetId) async {
    final uri =
        Uri.parse('https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId')
            .replace(queryParameters: {'fields': 'sheets(properties(title))'});
    final r = await http.get(uri, headers: _headers);
    _check(r);
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final sheets = (data['sheets'] as List?) ?? const [];
    return sheets
        .map((s) => ((s['properties']?['title']) ?? '') as String)
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// 한 탭의 셀 값(행 x 열). 빈 셀은 ''.
  Future<List<List<String>>> readValues(
      String spreadsheetId, String tab) async {
    final range = Uri.encodeComponent(tab);
    final uri = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$range');
    final r = await http.get(uri, headers: _headers);
    _check(r);
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final values = (data['values'] as List?) ?? const [];
    return values
        .map<List<String>>((row) =>
            (row as List).map((c) => (c ?? '').toString()).toList())
        .toList();
  }

  void _check(http.Response r) {
    if (r.statusCode == 401 || r.statusCode == 403) {
      _token = null;
      throw GoogleApiException(
        '접근 권한이 없거나 만료되었습니다. 다시 인증해주세요. (${r.statusCode})',
        needsReauth: true,
      );
    }
    if (r.statusCode >= 400) {
      throw GoogleApiException('구글 API 오류 ${r.statusCode}');
    }
  }
}
