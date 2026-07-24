import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/options.dart';
import '../models/submission.dart';
import '../theme.dart';
import 'submission_view.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  static Future<void> assignDialog(BuildContext context, Submission s) async {
    String? picked = s.assignedTrainer ?? trainerList.first;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${s.memberName} 회원 트레이너 배정'),
        content: StatefulBuilder(
          builder: (_, setS) => DropdownButtonFormField<String>(
            initialValue: picked,
            decoration: const InputDecoration(labelText: '담당 트레이너'),
            items: trainerList
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setS(() => picked = v),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(
            onPressed: () {
              if (picked != null) {
                context.read<AppState>().assignTrainer(s.id, picked!);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$picked 트레이너에게 배정·전송했습니다.')));
              }
            },
            child: const Text('전송'),
          ),
        ],
      ),
    );
  }

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  SubStatus? statusFilter; // null = 전체
  String? trainerFilter; // null = 전체 담당자
  String? itemFilter; // null = 전체 종목 (운동목적)
  String query = '';
  String periodChip = 'all';
  DateTime? fromDate;
  DateTime? toDate;
  bool sortDesc = true;
  bool boardView = true; // 기본값: 트레이너별 보드

  final _searchCtl = TextEditingController();
  final _boardScroll = ScrollController();
  final _df = DateFormat('yyyy.MM.dd');

  @override
  void initState() {
    super.initState();
    _applyChip('month'); // 기본 조회 기간 = 이번 달
    if (Uri.base.queryParameters['view'] == 'list') boardView = false;
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _boardScroll.dispose();
    super.dispose();
  }

  DateTime _d0(DateTime x) => DateTime(x.year, x.month, x.day);

  void _applyChip(String chip) {
    final now = DateTime.now();
    switch (chip) {
      case 'today':
        fromDate = _d0(now);
        toDate = _d0(now);
      case 'week':
        fromDate = _d0(now.subtract(Duration(days: now.weekday - 1)));
        toDate = _d0(now);
      case 'month':
        fromDate = DateTime(now.year, now.month, 1);
        toDate = _d0(now);
      case 'lastmonth':
        fromDate = DateTime(now.year, now.month - 1, 1);
        toDate = DateTime(now.year, now.month, 0);
      case 'all':
        fromDate = null;
        toDate = null;
    }
    periodChip = chip;
  }

  void _setChip(String chip) => setState(() => _applyChip(chip));

  bool _inRange(Submission s) {
    final d = s.assignedAt ?? s.createdAt;
    final dd = DateTime(d.year, d.month, d.day);
    if (fromDate != null && dd.isBefore(fromDate!)) return false;
    if (toDate != null && dd.isAfter(toDate!)) return false;
    return true;
  }

  List<Submission> _base(AppState s) => s.submissions.where((e) {
        if (trainerFilter != null && e.assignedTrainer != trainerFilter) {
          return false;
        }
        if (itemFilter != null && e.data['jongmok'] != itemFilter) {
          return false;
        }
        if (query.trim().isNotEmpty) {
          final n = (e.data['name'] ?? '').toString();
          final ph = (e.data['phone'] ?? '').toString();
          if (!n.contains(query.trim()) && !ph.contains(query.trim())) {
            return false;
          }
        }
        return _inRange(e);
      }).toList();

  void _reset() {
    setState(() {
      statusFilter = null;
      trainerFilter = null;
      itemFilter = null;
      query = '';
      sortDesc = true;
      _applyChip('month');
      _searchCtl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, s, __) {
        final base = _base(s);
        final shown = statusFilter == null
            ? base
            : base.where((e) => e.status == statusFilter).toList();
        return LayoutBuilder(builder: (ctx, cons) {
          final narrow = cons.maxWidth < 700;
          // 모바일 목록: 배너·필터가 리스트와 함께 세로로 스크롤되어 화면을 넓게 씀
          if (narrow && !boardView) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  _statusBanner(base),
                  _filterBar(),
                  _list(context, shown, outerScroll: false),
                ],
              ),
            );
          }
          return Column(
            children: [
              _statusBanner(base),
              _filterBar(),
              Expanded(
                  child: boardView ? _board(context, base) : _list(context, shown)),
            ],
          );
        });
      },
    );
  }

  // -------------------- 상태 배너 --------------------
  Widget _statusBanner(List<Submission> base) {
    int cnt(SubStatus? st) =>
        st == null ? base.length : base.where((e) => e.status == st).length;
    final items = <(String, SubStatus?)>[
      ('전체', null),
      ('접수', SubStatus.submitted),
      ('배정완료', SubStatus.assigned),
      ('진행중', SubStatus.inProgress),
      ('완료', SubStatus.completed),
      ('성공', SubStatus.success),
      ('실패', SubStatus.failure),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
      child: Row(children: [
        for (final it in items) Expanded(child: _statCard(it.$1, it.$2, cnt(it.$2))),
      ]),
    );
  }

  Widget _statCard(String label, SubStatus? st, int count) {
    final on = statusFilter == st;
    final accent = st == null ? kBlack : Color(st.color);
    return GestureDetector(
      // 배너 선택 → 현재 보기(목록/트레이너별) 그대로 해당 상태로 필터
      onTap: () => setState(() => statusFilter = st),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: on ? kBlack : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: on ? kBlack : kBorder, width: on ? 1.6 : 1),
        ),
        child: Column(children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: on ? kYellow : accent)),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: on ? kYellow : accent)),
          ),
        ]),
      ),
    );
  }

  // -------------------- 필터 바 (사진 스타일: 가로 한 줄) --------------------
  Widget _filterBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 검색
              SizedBox(width: 230, height: 42, child: _search()),
              // 기간 세그먼트
              _periodSegment(),
              // 날짜 범위
              _dateBtn(true),
              const Text('~', style: TextStyle(color: kMuted)),
              _dateBtn(false),
              // 종목 · 담당자
              SizedBox(
                width: 150,
                child: _dropdown<String?>(
                  value: itemFilter,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('전체 종목')),
                    ...jongmokOptions.map((o) => DropdownMenuItem(
                        value: o,
                        child: Text(o, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) => setState(() => itemFilter = v),
                ),
              ),
              SizedBox(
                width: 150,
                child: _dropdown<String?>(
                  value: trainerFilter,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('전체 담당자')),
                    ...trainerList.map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) => setState(() => trainerFilter = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 12),
          // 정렬 · 초기화 · 보기 전환
          Row(children: [
            _iconTextBtn(Icons.swap_vert, '정렬 (${sortDesc ? '최신순' : '오래된순'})',
                () => setState(() => sortDesc = !sortDesc)),
            const SizedBox(width: 6),
            _iconTextBtn(Icons.refresh, '초기화', _reset),
            const Spacer(),
            _viewToggle(),
          ]),
        ],
      ),
    );
  }

  Widget _search() => TextField(
        controller: _searchCtl,
        style: const TextStyle(fontSize: 13.5),
        decoration: InputDecoration(
          hintText: '이름 또는 연락처 검색...',
          prefixIcon: const Icon(Icons.search, size: 19, color: kMuted),
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFF7F7F4),
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: kBorder)),
        ),
        onChanged: (v) => setState(() => query = v),
      );

  Widget _periodSegment() {
    const periods = [
      ('today', '오늘'),
      ('week', '이번주'),
      ('month', '이번달'),
      ('lastmonth', '지난달'),
      ('all', '전체'),
    ];
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1EC),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final p in periods)
            GestureDetector(
              onTap: () => _setChip(p.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 13),
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: periodChip == p.$1
                    ? BoxDecoration(
                        color: kBlack, borderRadius: BorderRadius.circular(7))
                    : null,
                child: Text(p.$2,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: periodChip == p.$1
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: periodChip == p.$1 ? kYellow : kMuted)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dateBtn(bool isFrom) {
    final d = isFrom ? fromDate : toDate;
    return SizedBox(
      width: 132,
      height: 42,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: kInk,
          backgroundColor: Colors.white,
          side: const BorderSide(color: kBorder),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.centerLeft,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        icon: const Icon(Icons.calendar_today, size: 15, color: kMuted),
        label: Text(d == null ? (isFrom ? '시작일' : '종료일') : _df.format(d),
            style: TextStyle(
                fontSize: 12.5, color: d == null ? kMuted : kInk)),
        onPressed: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: d ?? now,
            firstDate: DateTime(now.year - 2),
            lastDate: DateTime(now.year + 2),
          );
          if (picked != null) {
            setState(() {
              if (isFrom) {
                fromDate = _d0(picked);
              } else {
                toDate = _d0(picked);
              }
              periodChip = 'custom';
            });
          }
        },
      ),
    );
  }

  Widget _viewToggle() {
    Widget seg(String label, bool active, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: active
                ? BoxDecoration(
                    color: kBlack, borderRadius: BorderRadius.circular(7))
                : null,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active ? kYellow : kMuted)),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: const Color(0xFFF1F1EC),
          borderRadius: BorderRadius.circular(9)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        seg('목록', !boardView, () => setState(() => boardView = false)),
        seg('트레이너별', boardView, () => setState(() => boardView = true)),
      ]),
    );
  }

  // -------------------- 트레이너별 보드 --------------------
  Widget _board(BuildContext context, List<Submission> base) {
    // 배너(상태) 필터를 보드에도 그대로 적용
    final shown = statusFilter == null
        ? base
        : base.where((e) => e.status == statusFilter).toList();
    final unassigned = shown.where((e) => e.assignedTrainer == null).toList();
    final cols =
        trainerFilter != null ? [trainerFilter!] : List<String>.from(trainerList);
    // 마우스 드래그로도 가로 스크롤 가능하게 + 스크롤바 표시
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: Scrollbar(
        controller: _boardScroll,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _boardScroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 미배정(접수) 열 — 담당자 미지정 회원
              if (trainerFilter == null && unassigned.isNotEmpty)
                _column(context, '미배정', unassigned, unassigned: true),
              for (final t in cols)
                _column(context, t,
                    shown.where((e) => e.assignedTrainer == t).toList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _column(BuildContext context, String title, List<Submission> members,
      {bool unassigned = false}) {
    members = [...members]
      ..sort((a, b) => a.status.index.compareTo(b.status.index));
    return Container(
      width: 264,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: kBlack,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(children: [
              Icon(unassigned ? Icons.inbox : Icons.fitness_center,
                  size: 16, color: kYellow),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: kYellow,
                        fontWeight: FontWeight.w900,
                        fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: kYellow, borderRadius: BorderRadius.circular(20)),
                child: Text('${members.length}',
                    style: const TextStyle(
                        color: kBlack, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ]),
          ),
          // 회원 세로 나열
          Flexible(
            child: members.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('해당 회원 없음',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kMuted, fontSize: 12.5)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: members.length,
                    itemBuilder: (_, i) => _boardCard(context, members[i]),
                  ),
          ),
        ],
      ),
    );
  }

  // 진행 중인 OT 차수 (내용이 있는 가장 높은 회차, 없으면 1)
  int _otRound(Submission s) {
    for (var i = 3; i >= 1; i--) {
      final d = (s.data['os${i}_date'] ?? '').toString();
      final p = (s.data['os${i}_prog'] ?? '').toString();
      if (d.isNotEmpty || p.isNotEmpty) return i;
    }
    return 1;
  }

  // 해당 회차의 OT 진행일 + 시간
  String _otSchedule(Submission s, int round) {
    final d = (s.data['os${round}_date'] ?? '').toString();
    final t = (s.data['os${round}_time'] ?? '').toString();
    final j = [d, t].where((e) => e.isNotEmpty).join('  ');
    return j.isEmpty ? 'OT 일정 미정' : j;
  }

  Widget _boardCard(BuildContext context, Submission s) {
    final c = Color(s.status.color);
    final round = _otRound(s);
    final statusLabel = s.status == SubStatus.inProgress
        ? '$round차 진행중'
        : s.status.label;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => AdminDetailPage(id: s.id))),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(s.memberName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: c, fontSize: 10.5, fontWeight: FontWeight.w800)),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 14),
                child: Row(children: [
                  const Icon(Icons.event, size: 13, color: kMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(_otSchedule(s, round),
                        style: const TextStyle(fontSize: 12, color: kInk, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconTextBtn(IconData icon, String label, VoidCallback onTap) =>
      TextButton.icon(
        style: TextButton.styleFrom(
            foregroundColor: kMuted,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(label),
      );

  Widget _dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      height: 42,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        style: const TextStyle(fontSize: 13, color: kInk),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: kBorder)),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  // -------------------- 목록 (표 형태) --------------------
  static const List<(String, double)> _cols = [
    ('NO', 42), ('구분', 60), ('회원명', 84), ('연락처', 116),
    ('예약일시', 136), ('종목', 120), ('담당자', 68), ('진행현황', 78), ('상태', 58),
  ];

  Widget _list(BuildContext context, List<Submission> subs,
      {bool outerScroll = true}) {
    if (subs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
            child: Text('해당 조건의 항목이 없습니다.', style: TextStyle(color: kMuted))),
      );
    }
    subs.sort((a, b) => sortDesc
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));
    final base = _cols.fold<double>(0, (s, c) => s + c.$2);
    return LayoutBuilder(builder: (ctx, cons) {
      final avail = cons.maxWidth - 20; // 좌우 패딩
      final scale = avail > base ? avail / base : 1.0; // 넓으면 가로폭 채움
      final widths = _cols.map((c) => c.$2 * scale).toList();
      final table = Container(
        width: base * scale,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Column(children: [
          _headerRow(widths),
          for (var i = 0; i < subs.length; i++)
            _rowFor(context, i + 1, subs[i], widths, last: i == subs.length - 1),
        ]),
      );
      // 헤더(배너·필터)와 함께 세로 스크롤하는 모바일에서는 자체 세로 스크롤 제거
      final horizontal = Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
            scrollDirection: Axis.horizontal, child: table),
      );
      if (!outerScroll) return horizontal;
      return Scrollbar(child: SingleChildScrollView(child: horizontal));
    });
  }

  Widget _headerRow(List<double> w) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF6F6F3),
          borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
        ),
        child: Row(children: [
          for (var i = 0; i < _cols.length; i++)
            Container(
              width: w[i],
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
              alignment: Alignment.center,
              child: Text(_cols[i].$1,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800, color: kMuted)),
            ),
        ]),
      );

  Widget _cell(double w, Widget child) => Container(
        width: w,
        height: 48,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: child,
      );

  Widget _pill(String text, int colorInt) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
            color: Color(colorInt).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                color: Color(colorInt), fontSize: 11, fontWeight: FontWeight.w800)),
      );

  Widget _rowFor(BuildContext context, int no, Submission s, List<double> w,
      {required bool last}) {
    final type = (s.data['member_type'] ?? '신규').toString();
    const typeColors = {'신규': 0xFF2F80ED, '리뉴': 0xFF9B51E0};
    final jong = (s.data['jongmok'] ?? '').toString();
    const jongColors = {'헬스': 0xFF2D9CDB, '필라': 0xFFEB5FA0};
    final prog = _progressInfo(s);
    final Widget outcome = s.status == SubStatus.success
        ? _pill('성공', 0xFF27AE60)
        : s.status == SubStatus.failure
            ? _pill('실패', 0xFFEB5757)
            : const Text('-', style: TextStyle(color: kMuted));
    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => AdminDetailPage(id: s.id))),
      child: Container(
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: kBorder)),
        ),
        child: Row(children: [
          _cell(w[0],
              Text('$no', style: const TextStyle(fontSize: 12.5, color: kMuted, fontWeight: FontWeight.w700))),
          _cell(w[1], _pill(type, typeColors[type] ?? 0xFF2F80ED)),
          _cell(w[2],
              Text(s.memberName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5), overflow: TextOverflow.ellipsis)),
          _cell(w[3],
              Text((s.data['phone'] ?? '-').toString(), style: const TextStyle(fontSize: 12))),
          _cell(w[4],
              Text(_reserveDT(s), style: const TextStyle(fontSize: 11.5), textAlign: TextAlign.center)),
          _cell(w[5],
              jong.isEmpty
                  ? const Text('-', style: TextStyle(color: kMuted))
                  : _pill(jong, jongColors[jong] ?? 0xFF2D9CDB)),
          _cell(w[6],
              Text(s.assignedTrainer ?? '-', style: const TextStyle(fontSize: 12))),
          _cell(w[7], _pill(prog.$1, prog.$2)),
          _cell(w[8], outcome),
        ]),
      ),
    );
  }

  (String, int) _progressInfo(Submission s) {
    switch (s.status) {
      case SubStatus.submitted:
        return ('접수', 0xFF2F80ED);
      case SubStatus.assigned:
        return ('배정', 0xFFE0A800);
      case SubStatus.inProgress:
        return ('${_otRound(s)}차', 0xFF9B51E0);
      case SubStatus.completed:
      case SubStatus.success:
      case SubStatus.failure:
        return ('완료', 0xFF64748B);
    }
  }

  String _reserveDT(Submission s) {
    final round = _otRound(s);
    final d = (s.data['os${round}_date'] ?? '').toString();
    final t = (s.data['os${round}_time'] ?? '').toString();
    final dt = [d, t].where((e) => e.isNotEmpty).join(' ');
    return dt.isNotEmpty
        ? dt
        : DateFormat('yyyy-MM-dd HH:mm').format(s.createdAt);
  }
}

class AdminDetailPage extends StatelessWidget {
  final String id;
  const AdminDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, s, __) {
        final sub = s.byId(id);
        if (sub == null) {
          return const Scaffold(body: Center(child: Text('삭제된 항목')));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text('${sub.memberName} 문진표'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'del') {
                    s.deleteSubmission(id);
                    Navigator.pop(context);
                  }
                },
                itemBuilder: (_) =>
                    [const PopupMenuItem(value: 'del', child: Text('삭제'))],
              ),
            ],
          ),
          body: SubmissionView(
            sub: sub,
            editableNote: true,
            onNoteChanged: (v) => s.updateData(sub.id, {'admin_note': v}),
            assignHeader: TrainerAssignBox(
              current: sub.assignedTrainer,
              onAssign: (t) {
                s.assignTrainer(sub.id, t);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$t 트레이너에게 전송했습니다.')));
              },
            ),
          ),
        );
      },
    );
  }
}

/// 상세 헤더 우측: 담당 트레이너 선택 + 전송
class TrainerAssignBox extends StatefulWidget {
  final String? current;
  final void Function(String) onAssign;
  const TrainerAssignBox({super.key, this.current, required this.onAssign});
  @override
  State<TrainerAssignBox> createState() => _TrainerAssignBoxState();
}

class _TrainerAssignBoxState extends State<TrainerAssignBox> {
  late String picked;
  @override
  void initState() {
    super.initState();
    picked = (widget.current != null && trainerList.contains(widget.current))
        ? widget.current!
        : trainerList.first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('담당 트레이너 배정',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 12.5, color: kMuted)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: DropdownButtonFormField<String>(
                  initialValue: picked,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 13.5, color: kInk),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(color: kBorder)),
                  ),
                  items: trainerList
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => picked = v ?? picked),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 42,
              child: FilledButton.icon(
                onPressed: () => widget.onAssign(picked),
                icon: const Icon(Icons.send, size: 16),
                label: const Text('전송'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
