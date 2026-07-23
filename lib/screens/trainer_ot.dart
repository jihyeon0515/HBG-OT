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

  /// 회원이 작성한 전체 내역 (OT 작성 화면 상단)
  Widget _memberSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
              color: kBlack, borderRadius: BorderRadius.circular(10)),
          child: const Row(children: [
            Icon(Icons.assignment_ind, size: 18, color: kYellow),
            SizedBox(width: 7),
            Text('회원 작성 내역',
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 15, color: kYellow)),
          ]),
        ),
        const SizedBox(height: 8),
        MemberFormView(data: data),
        const SizedBox(height: 4),
        const Divider(thickness: 1.5),
        const Padding(
          padding: EdgeInsets.only(top: 6, bottom: 2),
          child: Text('▼ 아래부터 트레이너 작성',
              style: TextStyle(fontWeight: FontWeight.w800, color: kMuted)),
        ),
        const SizedBox(height: 6),
      ],
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
          FormSection(title: '① InBody 분석', children: [
            _pair('체중', 'w_now', '목표', 'w_goal'),
            _pair('체지방량', 'f_now', '목표', 'f_goal'),
            _pair('근육량', 'm_now', '목표', 'm_goal'),
            _pair('기초대사량', 'b_now', '목표', 'b_goal'),
          ]),
          FormSection(title: '② 근력 평가', children: [
            for (var i = 1; i <= 3; i++) ..._strength(i),
          ]),
          FormSection(title: '③ 자세 · 분석 · 컨설팅', children: [
            TextField2(data, 'checkpoint', '정적자세 Check point',
                maxLines: 2, onChanged: _c),
            TextField2(data, 'analysis', '평가분석 내용', maxLines: 3, onChanged: _c),
            TextField2(data, 'program', '권장 운동프로그램', maxLines: 3, onChanged: _c),
            ChipsField(data, 'period', '최종 기간 컨설팅', periodOptions,
                multi: false, onChanged: _c),
          ]),
          FormSection(title: '④ 오티 프로그램 목표', children: [
            DropdownField(data, 'your_goal', '운동목적 (= 프로그램명)', goalOptions,
                onChanged: _c),
            TextField2(data, 'set_per_day', '총 1일 세트',
                keyboardType: TextInputType.number, onChanged: _c),
            DropdownField(data, 'rec_days', '권장 운동일 (주 __회)', daysOptions,
                onChanged: _c),
            DropdownField(data, 'time_min', '운동 시간(분)', exTimeOptions,
                onChanged: _c),
            TextField2(data, 'target_hr', '목표 심박수', onChanged: _c),
          ]),
          for (var i = 1; i <= 3; i++) _sessionSection(i),
          FormSection(title: '⑥ 특이사항 메모', children: [
            TextField2(data, 'trainer_note',
                '통증·부상·주의사항 등 트레이너 메모', maxLines: 3, onChanged: _c),
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
          const Text('입력하신 내용이 아래 양식에 실시간 반영됩니다.',
              style: TextStyle(fontSize: 12, color: kMuted)),
          const SizedBox(height: 10),
          OtFormPreview(
            data: data,
            memberName: memberName,
            trainerName: context.read<AppState>().currentTrainer ?? '',
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

  List<Widget> _strength(int i) {
    final p = 's$i';
    return [
      DropdownField(data, '${p}_name', '$i) 운동명', exerciseOptions, onChanged: _c),
      Row(children: [
        Expanded(
            child: TextField2(data, '${p}_w1', '무게1',
                keyboardType: TextInputType.number, onChanged: _c)),
        const SizedBox(width: 6),
        Expanded(
            child: TextField2(data, '${p}_w2', '무게2',
                keyboardType: TextInputType.number, onChanged: _c)),
        const SizedBox(width: 6),
        Expanded(
            child: TextField2(data, '${p}_rep', '횟수',
                keyboardType: TextInputType.number, onChanged: _c)),
      ]),
      ChipsField(data, '${p}_lv', '강도', levelOptions, multi: false, onChanged: _c),
      const Divider(),
    ];
  }

  Widget _sessionSection(int i) {
    final p = 'os$i';
    final signedM = (data['${p}_msign'] ?? '').toString().isNotEmpty;
    final signedA = (data['${p}_asign'] ?? '').toString().isNotEmpty;
    return FormSection(title: '⑤-$i  $i회차 오티', children: [
      Row(children: [
        Expanded(child: DateField(data, '${p}_date', '날짜', onChanged: _c)),
        const SizedBox(width: 6),
        Expanded(
            child: DropdownField(data, '${p}_time', '시간', timeOptions,
                onChanged: _c)),
      ]),
      TextField2(data, '${p}_prog', '운동 프로그램 내용', maxLines: 3, onChanged: _c),
      TextField2(data, '${p}_sets', '세트 요약 (예: 40kg x 3 / …)', onChanged: _c),
      TextField2(data, '${p}_tip', 'tip 메모', maxLines: 2, onChanged: _c),
      Row(children: [
        Expanded(child: DateField(data, '${p}_next', '다음 오티 일정', onChanged: _c)),
        const SizedBox(width: 6),
        Expanded(
            child: DropdownField(data, '${p}_ctime', '유산소 시간',
                cardioTimeOptions, onChanged: _c)),
      ]),
      ChipsField(data, '${p}_cardio', '유산소 종류 (중복)', cardioOptions, onChanged: _c),
      Row(children: [
        Expanded(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('회원 서명', style: TextStyle(fontSize: 13)),
            value: signedM,
            onChanged: (v) {
              data['${p}_msign'] = v ? memberName : '';
              _c();
            },
          ),
        ),
        Expanded(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('관리자 서명', style: TextStyle(fontSize: 13)),
            value: signedA,
            onChanged: (v) {
              data['${p}_asign'] =
                  v ? (context.read<AppState>().currentTrainer ?? '관리자') : '';
              _c();
            },
          ),
        ),
      ]),
    ]);
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
