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
        if (itemFilter != null) {
          final p = e.data['purpose'];
          if (!(p is List && p.contains(itemFilter))) return false;
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
        return Column(
          children: [
            _statusBanner(base),
            _filterBar(),
            Expanded(
                child: boardView ? _board(context, base) : _list(context, shown)),
          ],
        );
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
    final on = statusFilter == st && !boardView;
    final accent = st == null ? kBlack : Color(st.color);
    return GestureDetector(
      // 배너 선택 → 해당 상태 회원을 '리스트형'으로 조회
      onTap: () => setState(() {
        statusFilter = st;
        boardView = false;
      }),
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
                    ...purposeOptions.map((o) => DropdownMenuItem(
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

  // -------------------- 트레이너별 보드 (배정~진행) --------------------
  Widget _board(BuildContext context, List<Submission> base) {
    // 필터에서 특정 담당자를 고르면 그 트레이너만, 아니면 전체
    final cols =
        trainerFilter != null ? [trainerFilter!] : List<String>.from(trainerList);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final t in cols) _trainerColumn(context, t, base)],
      ),
    );
  }

  Widget _trainerColumn(BuildContext context, String trainer, List<Submission> base) {
    // 배정완료 + 진행중 회원만
    final members = base
        .where((e) =>
            e.assignedTrainer == trainer &&
            (e.status == SubStatus.assigned ||
                e.status == SubStatus.inProgress))
        .toList()
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
              const Icon(Icons.fitness_center, size: 16, color: kYellow),
              const SizedBox(width: 6),
              Expanded(
                child: Text(trainer,
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
                    child: Text('배정된 회원 없음',
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

  // -------------------- 목록 --------------------
  Widget _list(BuildContext context, List<Submission> subs) {
    if (subs.isEmpty) {
      return const Center(
          child: Text('해당 조건의 항목이 없습니다.', style: TextStyle(color: kMuted)));
    }
    subs.sort((a, b) => sortDesc
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: subs.length,
      itemBuilder: (_, i) => _card(context, subs[i]),
    );
  }

  Widget _card(BuildContext context, Submission s) {
    final f = DateFormat('MM/dd HH:mm');
    return Card(
      child: ListTile(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => AdminDetailPage(id: s.id))),
        leading: CircleAvatar(
          backgroundColor: Color(s.status.color),
          child: Text(s.status.label[0],
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
        title: Text(s.memberName,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text([
          if ((s.data['phone'] ?? '').toString().isNotEmpty) s.data['phone'],
          if (s.assignedTrainer != null) '담당: ${s.assignedTrainer}',
          f.format(s.createdAt),
        ].join('  ·  ')),
        trailing: s.status == SubStatus.submitted
            ? FilledButton(
                onPressed: () => AdminDashboardScreen.assignDialog(context, s),
                child: const Text('배정'),
              )
            : Chip(
                label:
                    Text(s.status.label, style: const TextStyle(fontSize: 11)),
                backgroundColor: Color(s.status.color).withValues(alpha: 0.15),
                side: BorderSide.none,
              ),
      ),
    );
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
              TextButton.icon(
                onPressed: () => AdminDashboardScreen.assignDialog(context, sub),
                icon: const Icon(Icons.person_add, color: kYellow),
                label: Text(sub.status == SubStatus.submitted ? '배정' : '재배정',
                    style: const TextStyle(color: kYellow)),
              ),
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
          body: SubmissionView(sub: sub),
          bottomNavigationBar: _outcomeBar(context, s, sub),
        );
      },
    );
  }

  /// 완료 이후 결과(성공/실패) 지정 바
  Widget? _outcomeBar(BuildContext context, AppState s, Submission sub) {
    const eligible = {
      SubStatus.completed,
      SubStatus.success,
      SubStatus.failure,
    };
    if (!eligible.contains(sub.status)) return null;
    Widget btn(String label, SubStatus st) {
      final on = sub.status == st;
      final c = Color(st.color);
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: on ? c : Colors.white,
              foregroundColor: on ? Colors.white : c,
              side: BorderSide(color: c, width: 1.4),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              s.setOutcome(sub.id, st);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label(으)로 처리되었습니다.')));
            },
            icon: Icon(st == SubStatus.success ? Icons.check_circle : Icons.cancel,
                size: 18),
            label: Text(label),
          ),
        ),
      );
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: kBorder)),
        ),
        child: Row(children: [
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Text('결과',
                style: TextStyle(fontWeight: FontWeight.w800, color: kMuted, fontSize: 13)),
          ),
          btn('성공', SubStatus.success),
          btn('실패', SubStatus.failure),
        ]),
      ),
    );
  }
}
