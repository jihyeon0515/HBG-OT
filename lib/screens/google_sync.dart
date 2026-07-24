import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/google_sheets_service.dart';
import '../theme.dart';

/// 구글 드라이브 전체(스프레드시트)를 실시간으로 읽어오는 화면.
///
/// - 최초 1회 OAuth 클라이언트 ID 입력(브라우저에 저장)
/// - 구글 계정 인증(팝업) 후 드라이브의 모든 스프레드시트 목록 표시
/// - 시트 선택 → 탭 선택 → 셀 데이터 표로 조회
class GoogleSyncScreen extends StatefulWidget {
  const GoogleSyncScreen({super.key});

  @override
  State<GoogleSyncScreen> createState() => _GoogleSyncScreenState();
}

class _GoogleSyncScreenState extends State<GoogleSyncScreen> {
  static const _clientIdKey = 'hbgym_google_client_id';

  final _clientIdCtrl = TextEditingController();
  GoogleSheetsService? _svc;

  bool _loading = false;
  String? _error;

  List<DriveFile> _files = const [];
  String _filter = '';

  DriveFile? _openFile;
  List<String> _tabs = const [];
  String? _openTab;
  List<List<String>> _rows = const [];

  @override
  void initState() {
    super.initState();
    _loadClientId();
  }

  @override
  void dispose() {
    _clientIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadClientId() async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getString(_clientIdKey) ?? '';
    if (!mounted) return;
    setState(() => _clientIdCtrl.text = saved);
  }

  Future<void> _saveClientId(String id) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_clientIdKey, id.trim());
  }

  Future<void> _run(Future<void> Function() body) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await body();
    } on GoogleApiException catch (e) {
      if (e.needsReauth) _svc?.signOut();
      _error = e.message;
    } catch (e) {
      _error = '오류: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _authorizeAndList() async {
    final clientId = _clientIdCtrl.text.trim();
    if (clientId.isEmpty) {
      setState(() => _error = 'OAuth 클라이언트 ID를 먼저 입력해주세요.');
      return;
    }
    await _saveClientId(clientId);
    final svc = GoogleSheetsService(clientId);
    await _run(() async {
      await svc.authorize();
      final files = await svc.listSpreadsheets();
      _svc = svc;
      _files = files;
      _openFile = null;
      _tabs = const [];
      _openTab = null;
      _rows = const [];
    });
  }

  Future<void> _openSpreadsheet(DriveFile f) async {
    final svc = _svc;
    if (svc == null) return;
    await _run(() async {
      final tabs = await svc.listTabs(f.id);
      _openFile = f;
      _tabs = tabs;
      _openTab = null;
      _rows = const [];
      if (tabs.isNotEmpty) {
        _openTab = tabs.first;
        _rows = await svc.readValues(f.id, tabs.first);
      }
    });
  }

  Future<void> _openTabValues(String tab) async {
    final svc = _svc;
    final f = _openFile;
    if (svc == null || f == null) return;
    await _run(() async {
      _openTab = tab;
      _rows = await svc.readValues(f.id, tab);
    });
  }

  void _signOut() {
    _svc?.signOut();
    setState(() {
      _svc = null;
      _files = const [];
      _openFile = null;
      _tabs = const [];
      _openTab = null;
      _rows = const [];
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authorized = _svc?.isAuthorized ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('구글 드라이브 연동'),
        actions: [
          if (authorized)
            IconButton(
              tooltip: '연결 해제',
              icon: const Icon(Icons.logout),
              onPressed: _loading ? null : _signOut,
            ),
        ],
      ),
      body: Stack(
        children: [
          if (!authorized) _configView() else _dataView(),
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x22000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  // ---- 인증 전: 클라이언트 ID 입력 + 안내 ----
  Widget _configView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('구글 계정 연결',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                const SizedBox(height: 6),
                const Text(
                  '내 구글 드라이브의 모든 스프레드시트를 실시간으로 불러옵니다.\n'
                  '최초 1회 OAuth 클라이언트 ID가 필요합니다. (브라우저에만 저장)',
                  style: TextStyle(color: kMuted, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _clientIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'OAuth 클라이언트 ID',
                    hintText: 'xxxxxxxx.apps.googleusercontent.com',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _authorizeAndList,
                    icon: const Icon(Icons.link),
                    label: const Text('구글 계정으로 연결'),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _errorBox(_error!),
                ],
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('클라이언트 ID 발급 방법',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 8),
                _Step('1', 'Google Cloud Console → API 및 서비스 → 라이브러리에서 '
                    'Google Drive API, Google Sheets API 사용 설정'),
                _Step('2', 'OAuth 동의 화면 구성(외부/테스트) 후 본인 계정을 테스트 사용자로 추가'),
                _Step('3', '사용자 인증 정보 → OAuth 클라이언트 ID → 애플리케이션 유형: 웹'),
                _Step('4', '승인된 JavaScript 원본에 배포 주소와 http://localhost 추가'),
                _Step('5', '생성된 클라이언트 ID를 위 칸에 붙여넣기'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---- 인증 후: 시트 목록 / 데이터 ----
  Widget _dataView() {
    if (_openFile != null) return _fileView();

    final filtered = _filter.isEmpty
        ? _files
        : _files
            .where((f) => f.name.toLowerCase().contains(_filter.toLowerCase()))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 20),
                    hintText: '스프레드시트 이름 검색',
                  ),
                  onChanged: (v) => setState(() => _filter = v),
                ),
              ),
              const SizedBox(width: 8),
              Text('${filtered.length}개',
                  style: const TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: _errorBox(_error!),
          ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('스프레드시트가 없습니다.',
                      style: TextStyle(color: kMuted)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final f = filtered[i];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.table_chart, color: kYellowDark),
                        title: Text(f.name,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: f.modifiedTime != null
                            ? Text('수정 ${_fmtDate(f.modifiedTime!)}',
                                style: const TextStyle(color: kMuted, fontSize: 12))
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _loading ? null : () => _openSpreadsheet(f),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _fileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _loading
                    ? null
                    : () => setState(() {
                          _openFile = null;
                          _tabs = const [];
                          _openTab = null;
                          _rows = const [];
                        }),
              ),
              Expanded(
                child: Text(_openFile!.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        if (_tabs.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final t in _tabs)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: t == _openTab,
                      onSelected:
                          _loading ? null : (_) => _openTabValues(t),
                    ),
                  ),
              ],
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: _errorBox(_error!),
          ),
        Expanded(child: _table()),
      ],
    );
  }

  Widget _table() {
    if (_rows.isEmpty) {
      return const Center(
          child: Text('데이터가 없습니다.', style: TextStyle(color: kMuted)));
    }
    // 표시 상한 (성능): 최대 300행 x 30열
    const maxRows = 300;
    const maxCols = 30;
    final rows = _rows.take(maxRows).toList();
    final colCount =
        rows.fold<int>(0, (m, r) => r.length > m ? r.length : m).clamp(0, maxCols);
    final header = rows.first;
    final body = rows.skip(1).toList();

    String cell(List<String> r, int c) => c < r.length ? r[c] : '';

    final truncated = _rows.length > maxRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFF7F7F3)),
                columnSpacing: 22,
                headingRowHeight: 40,
                dataRowMinHeight: 34,
                dataRowMaxHeight: 48,
                columns: [
                  for (var c = 0; c < colCount; c++)
                    DataColumn(
                      label: Text(
                        cell(header, c).isEmpty ? _colLabel(c) : cell(header, c),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
                rows: [
                  for (final r in body)
                    DataRow(
                      cells: [
                        for (var c = 0; c < colCount; c++)
                          DataCell(Text(cell(r, c))),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        if (truncated)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text('행이 많아 상위 $maxRows행만 표시합니다. (전체 ${_rows.length}행)',
                style: const TextStyle(color: kMuted, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF3C0C0)),
      ),
      child: Text(msg, style: const TextStyle(color: Color(0xFFB3261E))),
    );
  }

  static String _colLabel(int index) {
    // 0 -> A, 25 -> Z, 26 -> AA
    var n = index;
    final sb = StringBuffer();
    do {
      sb.write(String.fromCharCode(65 + (n % 26)));
      n = (n ~/ 26) - 1;
    } while (n >= 0);
    return sb.toString().split('').reversed.join();
  }

  static String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}.${two(d.month)}.${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}

class _Step extends StatelessWidget {
  const _Step(this.no, this.text);
  final String no;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: kBlack,
            child: Text(no,
                style: const TextStyle(
                    color: kYellow, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(height: 1.4, color: kInk)),
          ),
        ],
      ),
    );
  }
}
