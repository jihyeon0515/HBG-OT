import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/options.dart';
import '../theme.dart';
import '../widgets/form_fields.dart';

class MemberFormScreen extends StatefulWidget {
  const MemberFormScreen({super.key});
  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  Map<String, dynamic> data = {};
  void _c() => setState(() {});

  void _submit() {
    if ((data['name'] ?? '').toString().trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이름을 입력해주세요.')));
      return;
    }
    context.read<AppState>().createSubmission(data);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('제출 완료 ✅'),
        content: const Text('문진표가 관리자에게 전송되었습니다.\n상담을 기다려주세요!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => data = {});
            },
            child: const Text('확인'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sec1 = FormSection(title: '① 기본 정보', children: [
      // 구분 · 희망종목
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: ChipsField(data, 'member_type', '구분', memberTypeOptions, multi: false, onChanged: _c)),
        const SizedBox(width: 10),
        Expanded(child: ChipsField(data, 'jongmok', '희망종목', jongmokOptions, multi: false, onChanged: _c)),
      ]),
      // 이름 · 연락처 · 성별 · 나이 (좁으면 2줄로 줄바꿈)
      LayoutBuilder(builder: (ctx, cons) {
        final row1 = [
          Expanded(flex: 3, child: TextField2(data, 'name', '이름', onChanged: _c)),
          const SizedBox(width: 10),
          Expanded(flex: 4, child: TextField2(data, 'phone', '연락처', keyboardType: TextInputType.phone, onChanged: _c)),
        ];
        final row2 = [
          Expanded(flex: 2, child: ChipsField(data, 'gender', '성별', genders, multi: false, onChanged: _c)),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: TextField2(data, 'age', '나이', keyboardType: TextInputType.number, onChanged: _c)),
        ];
        if (cons.maxWidth < 520) {
          return Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: row1),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: row2),
          ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start,
            children: [...row1, const SizedBox(width: 10), ...row2]);
      }),
      // 직업 · 운동 시간대
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: TextField2(data, 'job', '직업', onChanged: _c)),
        const SizedBox(width: 10),
        Expanded(child: TextField2(data, 'etime', '운동 시간대', onChanged: _c)),
      ]),
    ]);
    final sec2 = FormSection(title: '② 방문 계기 & 운동목적 (중복선택)', children: [
      ChipsField(data, 'visit_reason', '헬스보이짐 분당정자점을 방문하게 된 계기',
          visitReasonOptions, onChanged: _c),
      const SizedBox(height: 4),
      ChipsField(data, 'purpose', '운동목적', purposeOptions, onChanged: _c),
    ]);
    final sec3 = FormSection(title: '③ 건강 & 병력사항 (중복선택)', children: [
      ChipsField(data, 'history', '병력사항', historyOptions, onChanged: _c),
      TextField2(data, 'history_etc', '기타 병력 / 수술 이력', onChanged: _c),
    ]);
    final sec4 = FormSection(title: '④ 운동 경험 (중복선택)', children: [
      ChipsField(data, 'exp', '운동경험', expOptions, onChanged: _c),
      ChipsField(data, 'career', '운동경력', careerOptions, multi: false, onChanged: _c),
      ChipsField(data, 'ptsat', 'PT 경험 만족도', ptSatOptions, multi: false, onChanged: _c),
      TextField2(data, 'ptreason_txt', 'PT 만족 / 불만족 이유', maxLines: 2, onChanged: _c),
    ]);
    final sec5 = FormSection(title: '⑤ 운동 성격 (중복선택)', children: [
      ChipsField(data, 'persona', '', personaOptions, onChanged: _c),
    ]);
    final sec6 = FormSection(title: '⑥ 특이사항', children: [
      TextField2(data, 'member_note',
          '통증 부위, 알레르기, 원하는 시간대 등 트레이너에게 전할 내용 (선택)',
          maxLines: 4, onChanged: _c),
    ]);
    final rest = [sec2, sec3, sec4, sec5, sec6];

    return Column(
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text('신규회원 상담 문진표',
                        style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                  ),
                  const Text('아래 항목을 작성 후 제출해주세요.',
                      style: TextStyle(color: Colors.black54, fontSize: 14)),
                  const SizedBox(height: 14),
                  sec1,
                  // 넓은 화면(가로 태블릿) 2열 / 좁은 화면 1열 자동 줄바꿈
                  LayoutBuilder(builder: (ctx, cons) {
                    if (cons.maxWidth < 900) return Column(children: rest);
                    // 좌: 방문계기·운동경험 / 우: 건강병력·운동성격·특이사항
                    // (특이사항을 운동성격 아래 빈 자리에 배치)
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Column(children: [sec2, sec4])),
                        const SizedBox(width: 12),
                        Expanded(child: Column(children: [sec3, sec5, sec6])),
                      ],
                    );
                  }),
                  // 문진표 하단 — 상담직원 선택
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 2),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 240,
                        child: DropdownField(
                            data, 'staff', '상담직원', staffList, onChanged: _c),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    style: kYellowCta,
                    onPressed: _submit,
                    icon: const Icon(Icons.send),
                    label: const Text('작성 완료 · 전송'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
