import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/submission.dart';
import '../theme.dart';

// ---------------------------------------------------------------------------
// 공용 행/섹션 헬퍼
// ---------------------------------------------------------------------------
Widget infoRow(String label, dynamic value) {
  String text;
  if (value == null) return const SizedBox.shrink();
  if (value is List) {
    if (value.isEmpty) return const SizedBox.shrink();
    text = value.join(', ');
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

/// 특이사항 강조 카드
Widget noteCard(Map d) {
  final m = (d['member_note'] ?? '').toString().trim();
  final t = (d['trainer_note'] ?? '').toString().trim();
  if (m.isEmpty && t.isEmpty) return const SizedBox.shrink();
  Widget note(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 12.5, color: kBlack)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13.5, color: kInk)),
      ]),
    );
  }

  return Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kYellow.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kYellowDark),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.push_pin, size: 17, color: kBlack),
        SizedBox(width: 6),
        Text('특이사항 메모',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kBlack)),
      ]),
      note('회원 작성', m),
      note('트레이너 메모', t),
    ]),
  );
}

// ---------------------------------------------------------------------------
// 회원이 작성한 전체 내역 (회원정보 · 운동목적 · 운동경험 · 특이사항)
// ---------------------------------------------------------------------------
class MemberInfoSections extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool includeNotes;
  const MemberInfoSections({super.key, required this.data, this.includeNotes = true});

  @override
  Widget build(BuildContext context) {
    final d = data;
    return Column(
      children: [
        infoSection('회원 정보', [
          infoRow('이름', d['name']),
          infoRow('성별', d['gender']),
          infoRow('나이', d['age'] != null && d['age'].toString().isNotEmpty ? '${d['age']}세' : null),
          infoRow('직업', d['job']),
          infoRow('운동시간대', d['etime']),
          infoRow('연락처', d['phone']),
        ]),
        infoSection('방문 계기 · 운동목적', [
          infoRow('방문 계기', d['visit_reason']),
          infoRow('운동목적', d['purpose']),
        ]),
        infoSection('운동 경험 · 건강', [
          infoRow('운동경험', d['exp']),
          infoRow('운동경력', d['career']),
          infoRow('PT 만족도', d['ptsat']),
          infoRow('PT 이유', d['ptreason_txt']),
          infoRow('운동 성격', d['persona']),
          infoRow('병력', d['history']),
          infoRow('기타 병력', d['history_etc']),
        ]),
        if (includeNotes) noteCard(d),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 문진표 1건 전체 (상태 헤더 + 회원 내역 + 트레이너 평가)
// ---------------------------------------------------------------------------
class SubmissionView extends StatelessWidget {
  final Submission sub;
  const SubmissionView({super.key, required this.sub});

  @override
  Widget build(BuildContext context) {
    final d = sub.data;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _statusHeader(),
        MemberInfoSections(data: d),
        if (_hasTrainerWork(d))
          infoSection('트레이너 평가 · 프로그램', [
            infoRow('체중', _arrow(d['w_now'], d['w_goal'], 'kg')),
            infoRow('체지방량', _arrow(d['f_now'], d['f_goal'], 'kg')),
            infoRow('근육량', _arrow(d['m_now'], d['m_goal'], 'kg')),
            infoRow('기초대사량', _arrow(d['b_now'], d['b_goal'], 'kcal')),
            infoRow('자세 체크', d['checkpoint']),
            infoRow('평가분석', d['analysis']),
            infoRow('권장 프로그램', d['program']),
            infoRow('기간 컨설팅', d['period']),
            infoRow('운동목표', d['your_goal']),
            infoRow('주 운동일', d['rec_days'] != null ? '주 ${d['rec_days']}회' : null),
            infoRow('1일 세트', d['set_per_day']),
            infoRow('운동시간', d['time_min'] != null ? '${d['time_min']}분' : null),
            infoRow('목표심박수', d['target_hr']),
            for (var i = 1; i <= 3; i++) ..._sessionRows(d, i),
          ]),
      ],
    );
  }

  bool _hasTrainerWork(Map d) =>
      ['w_now', 'analysis', 'program', 'os1_prog', 'your_goal']
          .any((k) => (d[k]?.toString() ?? '').isNotEmpty);

  List<Widget> _sessionRows(Map d, int i) {
    final p = 'os${i}_';
    final has = ['${p}date', '${p}prog', '${p}next']
        .any((k) => (d[k]?.toString() ?? '').isNotEmpty);
    if (!has) return [];
    final cardio = d['${p}cardio'];
    return [
      infoRow('$i회차 날짜/시간',
          '${d['${p}date'] ?? ''} ${d['${p}time'] ?? ''}'.trim()),
      infoRow('$i회차 프로그램', d['${p}prog']),
      infoRow('$i회차 유산소',
          '${cardio is List ? cardio.join(', ') : ''} ${d['${p}ctime'] ?? ''}'.trim()),
      infoRow('$i회차 다음일정', d['${p}next']),
    ];
  }

  String? _arrow(dynamic a, dynamic b, String unit) {
    final sa = a?.toString() ?? '';
    final sb = b?.toString() ?? '';
    if (sa.isEmpty && sb.isEmpty) return null;
    return '$sa$unit → $sb$unit';
  }

  Widget _statusHeader() {
    final f = DateFormat('yyyy-MM-dd HH:mm');
    return Card(
      color: Color(sub.status.color).withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
        ),
      ),
    );
  }
}
