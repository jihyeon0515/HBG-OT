import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/submission.dart';
import '../theme.dart';
import 'ot_preview.dart';
import 'member_preview.dart';

// ---------------------------------------------------------------------------
// 공용 행/섹션 헬퍼
// ---------------------------------------------------------------------------
Widget infoRow(String label, dynamic value, {String sep = ', '}) {
  String text;
  if (value == null) return const SizedBox.shrink();
  if (value is List) {
    if (value.isEmpty) return const SizedBox.shrink();
    text = value.join(sep);
  } else {
    text = value.toString();
  }
  if (text.trim().isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 96,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12.5, color: kMuted, fontWeight: FontWeight.w700))),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
      ],
    ),
  );
}

Widget infoSection(String title, List<Widget> rows) {
  final visible = rows.where((w) => w is! SizedBox).toList();
  if (visible.isEmpty) return const SizedBox.shrink();
  return Card(
    margin: const EdgeInsets.only(top: 12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 5,
                height: 17,
                decoration: BoxDecoration(
                    color: kYellow, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, color: kInk, fontSize: 15)),
          ]),
          const Divider(),
          ...rows,
        ],
      ),
    ),
  );
}

/// 특이사항 박스 — 관리자 페이지에서는 편집 가능
class SpecialNoteBox extends StatefulWidget {
  final Map data;
  final bool editable;
  final ValueChanged<String>? onChanged;
  const SpecialNoteBox(
      {super.key, required this.data, this.editable = false, this.onChanged});
  @override
  State<SpecialNoteBox> createState() => _SpecialNoteBoxState();
}

class _SpecialNoteBoxState extends State<SpecialNoteBox> {
  late final TextEditingController _ctl;
  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController(text: (widget.data['admin_note'] ?? '').toString());
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = (widget.data['admin_note'] ?? '').toString().trim();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kYellow.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kYellowDark),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.push_pin, size: 17, color: kBlack),
          SizedBox(width: 6),
          Text('관리자 MEMO',
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 15, color: kBlack)),
        ]),
        const SizedBox(height: 8),
        if (widget.editable)
          TextField(
            controller: _ctl,
            minLines: 3,
            maxLines: 8,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: '메모 입력·수정',
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: kYellowDark)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: kBorder)),
            ),
            onChanged: widget.onChanged,
          )
        else
          Text(admin.isEmpty ? '-' : admin,
              style: const TextStyle(fontSize: 13.5, color: kInk)),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// 회원이 작성한 전체 내역 (회원정보 · 운동목적 · 운동경험 · 특이사항)
// ---------------------------------------------------------------------------
class MemberInfoSections extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool includeNotes;
  final bool editableNote;
  final ValueChanged<String>? onNoteChanged;
  const MemberInfoSections(
      {super.key,
      required this.data,
      this.includeNotes = true,
      this.editableNote = false,
      this.onNoteChanged});

  @override
  Widget build(BuildContext context) {
    final d = data;
    final sec1 = infoSection('회원 정보', [
      infoRow('구분', d['member_type']),
      infoRow('이름', d['name']),
      infoRow('연락처', d['phone']),
      infoRow('성별', d['gender']),
      infoRow('나이', d['age'] != null && d['age'].toString().isNotEmpty ? '${d['age']}세' : null),
      infoRow('직업', d['job']),
      infoRow('운동시간대', d['etime']),
      infoRow('희망종목', d['jongmok']),
    ]);
    final sec2 = infoSection('운동목적 & 병력사항', [
      infoRow('방문 계기', d['visit_reason']),
      infoRow('운동목적', d['purpose']),
      infoRow('병력', d['history']),
      infoRow('기타 병력', d['history_etc']),
    ]);
    final sec3 = infoSection('운동 경험 & 성격', [
      infoRow('운동경험', d['exp']),
      infoRow('운동경력', d['career']),
      infoRow('PT 만족도', d['ptsat']),
      infoRow('PT 이유', d['ptreason_txt']),
      infoRow('운동 성격', d['persona'], sep: '\n'),
    ]);
    final noteBox = SpecialNoteBox(
        data: d, editable: editableNote, onChanged: onNoteChanged);
    final boxes = <Widget>[sec1, sec2, sec3, if (includeNotes) noteBox];
    return LayoutBuilder(builder: (ctx, cons) {
      final w = cons.maxWidth;
      // 화면 폭에 따라 한 줄에 놓는 박스 수 (모바일=1로 자동 줄바꿈)
      final cols = w >= 1080 ? 4 : (w >= 720 ? 2 : 1);
      if (cols == 1) return Column(children: boxes);
      final rows = <Widget>[];
      for (var i = 0; i < boxes.length; i += cols) {
        final children = <Widget>[];
        for (var j = 0; j < cols; j++) {
          if (j > 0) children.add(const SizedBox(width: 10));
          final idx = i + j;
          children.add(Expanded(
              child: idx < boxes.length ? boxes[idx] : const SizedBox.shrink()));
        }
        // 같은 줄 박스들의 높이를 동일하게
        rows.add(IntrinsicHeight(
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children)));
      }
      return Column(children: rows);
    });
  }
}

// ---------------------------------------------------------------------------
// 문진표 1건 전체 (상태 헤더 + 회원 내역 + 트레이너 평가)
// ---------------------------------------------------------------------------
class SubmissionView extends StatelessWidget {
  final Submission sub;
  final bool editableNote;
  final ValueChanged<String>? onNoteChanged;
  final Widget? assignHeader; // 상태 헤더 우측(담당 배정 박스)
  const SubmissionView(
      {super.key,
      required this.sub,
      this.editableNote = false,
      this.onNoteChanged,
      this.assignHeader});

  @override
  Widget build(BuildContext context) {
    final d = sub.data;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _statusHeader(),
        // 회원 작성 내용 — 폼 그대로 바로 표시 (클릭 없이)
        _sectionTitle(Icons.assignment_ind, '회원 작성 내용'),
        MemberFormView(data: d),
        // 특이사항 (관리자 편집 가능)
        if (editableNote)
          SpecialNoteBox(
              data: d, editable: true, onChanged: onNoteChanged),
        // 트레이너 OT 작성 내용 (이미지 문진표)
        if (_showOt(sub, d)) ...[
          _sectionTitle(Icons.description, '트레이너 OT 작성 내용'),
          PreviewThumbnail(
            title: '${sub.memberName} · OT 문진표',
            builder: () => OtFormPreview(
                data: d,
                memberName: sub.memberName,
                trainerName: sub.assignedTrainer ?? ''),
          ),
        ],
      ],
    );
  }

  Widget _sectionTitle(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 6, left: 2),
        child: Row(children: [
          Icon(icon, size: 18, color: kBlack),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 15, color: kInk)),
        ]),
      );

  bool _hasTrainerWork(Map d) =>
      ['w_now', 'analysis', 'program', 'os1_prog', 'your_goal']
          .any((k) => (d[k]?.toString() ?? '').isNotEmpty);

  // 진행중·완료·성공·실패이거나 트레이너 작성 내용이 있으면 문진표 이미지 표시
  bool _showOt(Submission s, Map d) =>
      _hasTrainerWork(d) ||
      s.status == SubStatus.inProgress ||
      s.status == SubStatus.completed ||
      s.status == SubStatus.success ||
      s.status == SubStatus.failure;

  Widget _statusHeader() {
    final f = DateFormat('yyyy-MM-dd HH:mm');
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Color(sub.status.color),
                borderRadius: BorderRadius.circular(20)),
            child: Text(sub.status.label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Text(sub.memberName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 8),
        Text('접수: ${f.format(sub.createdAt)}',
            style: const TextStyle(fontSize: 12, color: kMuted)),
        if (sub.assignedTrainer != null)
          Text('담당 트레이너: ${sub.assignedTrainer}',
              style: const TextStyle(fontSize: 12, color: kMuted)),
        if (sub.completedAt != null)
          Text('완료: ${f.format(sub.completedAt!)}',
              style: const TextStyle(fontSize: 12, color: kMuted)),
      ],
    );
    return Card(
      color: Color(sub.status.color).withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: assignHeader == null
            ? info
            : LayoutBuilder(builder: (ctx, cons) {
                final wide = cons.maxWidth >= 560;
                return wide
                    ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: info),
                        const SizedBox(width: 12),
                        assignHeader!,
                      ])
                    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        info,
                        const SizedBox(height: 12),
                        assignHeader!,
                      ]);
              }),
      ),
    );
  }
}
