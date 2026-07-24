import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/options.dart';
import '../models/submission.dart';
import '../theme.dart';
import '../widgets/form_fields.dart';
import 'member_preview.dart';
import 'ot_preview.dart';
import 'submission_view.dart';

/// 트레이너가 OT 평가 · 프로그램을 작성하는 화면
class TrainerOtPage extends StatefulWidget {
  final String id;
  const TrainerOtPage({super.key, required this.id});
  @override
  State<TrainerOtPage> createState() => _TrainerOtPageState();
}

class _TrainerOtPageState extends State<TrainerOtPage> {
  late Map<String, dynamic> data;
  late String memberName;

  @override
  void initState() {
    super.initState();
    final sub = context.read<AppState>().byId(widget.id);
    data = Map<String, dynamic>.from(sub?.data ?? {});
    memberName = sub?.memberName ?? '';
  }

  void _c() => setState(() {});

  void _openMemberRecord() {
    final sub = context.read<AppState>().byId(widget.id);
    if (sub == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('$memberName · 작성 내역')),
          body: SubmissionView(sub: sub),
        ),
      ),
    );
  }

  /// 회원이 작성한 전체 내역 (읽기 전용) — 회색 카드로 명확히 구분
  Widget _memberSummary() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9D9D2), width: 1.4),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: kBlack, borderRadius: BorderRadius.circular(8)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.person, size: 15, color: kYellow),
              SizedBox(width: 5),
              Text('회원 작성 (읽기 전용)',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 13, color: kYellow)),
            ]),
          ),
        ]),
        const SizedBox(height: 4),
        const Text('회원이 작성한 내역입니다. 트레이너는 수정할 수 없습니다.',
            style: TextStyle(fontSize: 11.5, color: kMuted)),
        const SizedBox(height: 10),
        MemberFormView(data: data),
      ]),
    );
  }

  /// 트레이너 작성 영역 시작 헤더 — 노란 배너로 회원란과 뚜렷이 구분
  Widget _trainerHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kYellow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kYellowDark, width: 1.4),
      ),
      child: const Row(children: [
        Icon(Icons.edit_note, size: 22, color: kBlack),
        SizedBox(width: 8),
        Expanded(
          child: Text('트레이너 작성 (OT 평가 · 프로그램)',
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 15.5, color: kBlack)),
        ),
      ]),
    );
  }

  // outcome null = 임시저장, success/failure = OT 완료 + 결과 지정
  void _save({SubStatus? outcome}) {
    // 프로그램명 = 운동목적 자동
    if ((data['your_goal'] ?? '').toString().isNotEmpty) {
      data['prog_title'] = data['your_goal'];
    }
    final app = context.read<AppState>();
    if (outcome != null) {
      app.completeSubmission(widget.id, data);
      app.setOutcome(widget.id, outcome); // 관리자 페이지에 성공/실패 반영
    } else {
      app.saveTrainerWork(widget.id, data);
    }
    final msg = outcome == null
        ? '임시저장되었습니다.'
        : outcome == SubStatus.success
            ? '성공으로 완료되었습니다.'
            : '실패로 완료되었습니다.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
    if (outcome != null) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$memberName · OT 작성'),
        actions: [
          IconButton(
            tooltip: '회원 작성 내역',
            onPressed: _openMemberRecord,
            icon: const Icon(Icons.assignment_ind, color: kYellow),
          ),
          TextButton(
            onPressed: () => _save(),
            child: const Text('임시저장', style: TextStyle(color: kYellow)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _memberSummary(),
          _trainerHeader(),
          FormSection(title: '① InBody 분석', children: [
            _pair('체중', 'w_now', '목표', 'w_goal'),
            _pair('체지방량', 'f_now', '목표', 'f_goal'),
            _pair('근육량', 'm_now', '목표', 'm_goal'),
            _pair('기초대사량', 'b_now', '목표', 'b_goal'),
          ]),
          for (var i = 1; i <= 3; i++) _sessionSection(i),
          FormSection(title: '③ 특이사항 메모', children: [
            TextField2(data, 'trainer_note', '트레이너 메모',
                maxLines: 3, onChanged: _c),
          ]),
          // ---- 오티문진표 미리보기 (입력값 실시간 반영) ----
          const SizedBox(height: 6),
          Row(children: [
            Container(
              width: 5, height: 20,
              decoration: BoxDecoration(color: kYellow, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 8),
            const Text('📋 오티문진표 미리보기',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: kInk)),
          ]),
          const SizedBox(height: 4),
          const Text('입력하신 내용이 실시간 반영됩니다. 미리보기를 누르면 전체 화면으로 볼 수 있습니다.',
              style: TextStyle(fontSize: 12, color: kMuted)),
          const SizedBox(height: 10),
          PreviewThumbnail(
            title: '$memberName · OT 문진표',
            builder: () => OtFormPreview(
              data: data,
              memberName: memberName,
              trainerName: context.read<AppState>().currentTrainer ?? '',
            ),
          ),
          const SizedBox(height: 16),
          const Text('OT 완료 처리 — 성공/실패를 선택하세요',
              style: TextStyle(fontWeight: FontWeight.w800, color: kMuted, fontSize: 13)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  onPressed: () => _save(outcome: SubStatus.success),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('성공으로 완료'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEB5757),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  onPressed: () => _save(outcome: SubStatus.failure),
                  icon: const Icon(Icons.cancel),
                  label: const Text('실패로 완료'),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _pair(String la, String ka, String lb, String kb) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
              child: TextField2(data, ka, la,
                  keyboardType: TextInputType.number, onChanged: _c)),
          const Padding(
            padding: EdgeInsets.only(bottom: 18, left: 4, right: 4),
            child: Text('→'),
          ),
          Expanded(
              child: TextField2(data, kb, lb,
                  keyboardType: TextInputType.number, onChanged: _c)),
        ],
      );

  Widget _sessionSection(int i) {
    final p = 'os$i';
    // 다음 오티 일정 = 다음 회차(i+1)의 날짜/시간과 같은 값 → 입력하면 다음 회차에 자동 반영
    final nextDateKey = i < 3 ? 'os${i + 1}_date' : 'os3_ndate';
    final nextTimeKey = i < 3 ? 'os${i + 1}_time' : 'os3_ntime';
    return FormSection(title: '②-$i  $i회차 오티', children: [
      Row(children: [
        Expanded(child: DateField(data, '${p}_date', '날짜', onChanged: _c)),
        const SizedBox(width: 6),
        Expanded(
            child: DropdownField(data, '${p}_time', '시간', timeOptions,
                onChanged: _c)),
      ]),
      TextField2(data, '${p}_prog', '운동 프로그램 내용', maxLines: 3, onChanged: _c),
      TextField2(data, '${p}_tip', '메모', maxLines: 2, onChanged: _c),
      // 다음 오티 일정 (날짜 + 시간 드롭다운)
      Container(
        margin: const EdgeInsets.only(top: 4, bottom: 6),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kYellowDark),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.event_repeat, size: 16, color: kBlack),
            const SizedBox(width: 5),
            Text(
                i < 3
                    ? '다음 오티 일정  (입력 시 ${i + 1}회차 날짜·시간에 자동 입력)'
                    : '다음 오티 일정',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: kBlack)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
                child: DateField(data, nextDateKey, '날짜', onChanged: _c)),
            const SizedBox(width: 6),
            Expanded(
                child: DropdownField(data, nextTimeKey, '시간', timeOptions,
                    onChanged: _c)),
          ]),
        ]),
      ),
      const SizedBox(height: 4),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _signBox('회원 서명', memberName, '${p}_msign', '${p}_mfont')),
        const SizedBox(width: 10),
        Expanded(
            child: _signBox(
                '관리자 서명',
                context.read<AppState>().currentTrainer ?? '관리자',
                '${p}_asign',
                '${p}_afont')),
      ]),
    ]);
  }

  /// 이름을 손글씨 글꼴로 렌더링해 '실제 서명'처럼 보여주는 입력 위젯.
  /// 버튼이 아니라 글꼴만 선택하면 이름이 그대로 서명으로 입력된다.
  Widget _signBox(String label, String name, String signKey, String fontKey) {
    final font = (data[fontKey] ?? '').toString();
    final signed = (data[signKey] ?? '').toString().isNotEmpty && font.isNotEmpty;
    final preview = name.isEmpty ? '가' : name.substring(0, 1);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: kInk)),
      ),
      // 서명 표시
      Container(
        width: double.infinity,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAF8),
          border: Border.all(color: signed ? kYellowDark : kBorder),
          borderRadius: BorderRadius.circular(9),
        ),
        child: signed
            ? Text(name,
                style: TextStyle(
                    fontFamily: font, fontSize: 28, color: kInk, height: 1.0))
            : const Text('글꼴을 선택하면 이름이 서명됩니다',
                style: TextStyle(fontSize: 11.5, color: kMuted)),
      ),
      const SizedBox(height: 6),
      // 글꼴 선택 (이름과 동일하게 선택만)
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final f in signFonts)
          _fontChip(
            f['name']!,
            f['family']!,
            preview,
            selected: signed && font == f['family'],
            onTap: () {
              data[fontKey] = f['family'];
              data[signKey] = name;
              _c();
            },
          ),
        InkWell(
          onTap: () {
            data[fontKey] = '';
            data[signKey] = '';
            _c();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(20)),
            child: const Text('지우기',
                style: TextStyle(fontSize: 12, color: kMuted)),
          ),
        ),
      ]),
    ]);
  }

  Widget _fontChip(String label, String family, String preview,
      {required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? kBlack : Colors.white,
          border: Border.all(color: selected ? kBlack : kBorder),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('$label ',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? kYellow : kInk)),
          Text(preview,
              style: TextStyle(
                  fontFamily: family,
                  fontSize: 16,
                  color: selected ? kYellow : kMuted)),
        ]),
      ),
    );
  }
}

/// 트레이너 배정 목록
class TrainerListScreen extends StatelessWidget {
  const TrainerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, s, __) {
        final trainer = s.currentTrainer;
        if (trainer == null) {
          return const Center(child: Text('상단에서 트레이너를 선택하세요.'));
        }
        final active = s.forTrainer(trainer);
        final done = s.submissions
            .where((e) =>
                e.assignedTrainer == trainer &&
                (e.status == SubStatus.completed ||
                    e.status == SubStatus.success ||
                    e.status == SubStatus.failure))
            .toList();
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text('$trainer 트레이너',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            if (active.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('배정된 회원이 없습니다.',
                    style: TextStyle(color: Colors.black45)),
              ),
            for (final sub in active) _card(context, sub, s),
            if (done.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(top: 16, bottom: 6),
                child: Text('완료한 회원',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
              ),
              for (final sub in done) _card(context, sub, s),
            ],
          ],
        );
      },
    );
  }

  Widget _card(BuildContext context, Submission sub, AppState s) {
    final isNew = sub.status == SubStatus.assigned;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(sub.status.color),
          child: Text(sub.status.label[0],
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
        title: Row(children: [
          Text(sub.memberName,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          if (isNew) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                  color: Colors.red, borderRadius: BorderRadius.circular(20)),
              child: const Text('NEW',
                  style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ],
        ]),
        subtitle: Text([
          if ((sub.data['visit_reason'] is List) &&
              (sub.data['visit_reason'] as List).isNotEmpty)
            (sub.data['visit_reason'] as List).join(', '),
          sub.status.label,
        ].where((e) => e.toString().isNotEmpty).join('  ·  ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => TrainerOtPage(id: sub.id))),
      ),
    );
  }
}
