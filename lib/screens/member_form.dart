import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/options.dart';
import '../theme.dart';
import '../widgets/form_fields.dart';

// 종이 문진표 색
const _blue = Color(0xFF0B3F8F);
const _line = Color(0xFF222222);
const _hdrFill = Color(0xFFFFF3C4);

class MemberFormScreen extends StatefulWidget {
  const MemberFormScreen({super.key});
  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  Map<String, dynamic> data = {};
  int _epoch = 0; // 제출 후 입력칸 초기화용
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
              setState(() {
                data = {};
                _epoch++;
              });
            },
            child: const Text('확인'),
          )
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // 종이 양식(이미지) 인터랙티브 요소
  // ---------------------------------------------------------------
  Widget _psection(String title, List<Widget> rows) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(border: Border.all(color: _line, width: 1.2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            color: _hdrFill,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
          ),
          Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: rows),
          ),
        ]),
      );

  Widget _plabel(String t) => Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 4),
        child: Text(t,
            style: const TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.black87)),
      );

  Widget _pkv(String label, Widget value, {double labelW = 78}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
              width: labelW,
              child: Text(label,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700))),
          Expanded(child: value),
        ]),
      );

  /// 체크박스형 선택 (탭하면 ☑/☐ 토글). column=true 면 한 줄에 하나씩.
  Widget _pchk(String field, List<String> opts,
      {bool multi = true, bool column = false}) {
    Set<String> sel() {
      if (multi) {
        final v = data[field];
        return v is List ? v.map((e) => e.toString()).toSet() : <String>{};
      }
      return data[field] != null && data[field].toString().isNotEmpty
          ? {data[field].toString()}
          : <String>{};
    }

    final s = sel();
    Widget item(String o) {
      final on = s.contains(o);
      final box = Text(on ? '☑' : '☐',
          style: TextStyle(
              fontSize: 15,
              color: on ? _blue : Colors.black45,
              fontWeight: FontWeight.w700));
      final txt = Text(o,
          style: TextStyle(
              fontSize: 12.5,
              color: on ? _blue : Colors.black87,
              fontWeight: on ? FontWeight.w700 : FontWeight.w400));
      return InkWell(
        onTap: () {
          if (multi) {
            final list = (data[field] is List)
                ? List<String>.from(data[field])
                : <String>[];
            on ? list.remove(o) : list.add(o);
            data[field] = list;
          } else {
            data[field] = on ? null : o;
          }
          _c();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: column ? 3 : 1),
          child: Row(
            mainAxisSize: column ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              box,
              const SizedBox(width: 3),
              column ? Expanded(child: txt) : txt,
            ],
          ),
        ),
      );
    }

    if (column) {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: opts.map(item).toList());
    }
    return Wrap(spacing: 12, runSpacing: 4, children: opts.map(item).toList());
  }

  /// 밑줄형 직접 입력칸
  Widget _ptext(String field,
      {String hint = '', int maxLines = 1, TextInputType? kb}) {
    return TextFormField(
      key: ValueKey('$field-$_epoch'),
      initialValue: (data[field] ?? '').toString(),
      maxLines: maxLines,
      keyboardType: kb,
      style: const TextStyle(
          fontSize: 12.5, color: _blue, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle:
            const TextStyle(color: Colors.black38, fontWeight: FontWeight.w400),
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFBBBBBB))),
        focusedBorder:
            const UnderlineInputBorder(borderSide: BorderSide(color: _blue)),
      ),
      onChanged: (v) => data[field] = v,
    );
  }

  /// 직원 MEMO — 종이 이미지 아래 (관리자 메모와 동일한 스타일)
  Widget _staffMemo() {
    return Container(
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
          Text('직원 MEMO',
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 15, color: kBlack)),
        ]),
        const SizedBox(height: 8),
        TextFormField(
          key: ValueKey('staff_memo-$_epoch'),
          initialValue: (data['staff_memo'] ?? '').toString(),
          minLines: 3,
          maxLines: 8,
          style: const TextStyle(fontSize: 13.5),
          decoration: InputDecoration(
            hintText: '상담 직원이 작성하는 메모 (선택)',
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
          onChanged: (v) => data['staff_memo'] = v,
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('신규회원 상담 문진표',
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text('아래 항목을 작성 후 제출해주세요.',
                      style: TextStyle(color: Colors.black54, fontSize: 14)),
                  const SizedBox(height: 12),
                  // 상담직원 · 등록종목 (이미지 제외 — 일반 드롭다운)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                        child: DropdownField(
                            data, 'staff', '상담직원', staffList, onChanged: _c)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: DropdownField(data, 'reg_item', '등록종목',
                            regItemOptions, onChanged: _c)),
                  ]),
                  const SizedBox(height: 12),
                  // ===== 종이 양식(이미지) — 각 칸 탭하여 선택/입력 =====
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _line, width: 1.4),
                        borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Image.asset('assets/logo.png', height: 30),
                            const SizedBox(width: 8),
                            const Text('신규회원 상담 문진표',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w900)),
                          ]),
                          Container(
                              height: 4,
                              color: _line,
                              margin: const EdgeInsets.symmetric(vertical: 8)),
                          // 회원 정보
                          _psection('회원 정보', [
                            _pkv('구분',
                                _pchk('member_type', memberTypeOptions, multi: false)),
                            _pkv('희망종목',
                                _pchk('jongmok', jongmokOptions, multi: false)),
                            _pkv('이름', _ptext('name', hint: '이름')),
                            _pkv('연락처',
                                _ptext('phone', hint: '010-0000-0000', kb: TextInputType.phone)),
                            _pkv('성별', _pchk('gender', genders, multi: false)),
                            _pkv(
                                '나이',
                                Row(children: [
                                  SizedBox(
                                      width: 70,
                                      child: _ptext('age', kb: TextInputType.number)),
                                  const SizedBox(width: 4),
                                  const Text('세', style: TextStyle(fontSize: 12)),
                                ])),
                            _pkv('직업', _ptext('job')),
                            _pkv('운동시간대', _ptext('etime', hint: '예: 평일 저녁')),
                          ]),
                          // 방문 계기 & 운동목적
                          _psection('방문 계기 & 운동목적 (중복선택)', [
                            _plabel('헬스보이짐 분당정자점을 방문하게 된 계기'),
                            _pchk('visit_reason', visitReasonOptions),
                            const SizedBox(height: 8),
                            _plabel('운동목적'),
                            _pchk('purpose', purposeOptions),
                          ]),
                          // 건강 & 병력사항
                          _psection('건강 & 병력사항 (중복선택)', [
                            _pchk('history', historyOptions),
                            const SizedBox(height: 6),
                            _pkv('기타 병력·수술', _ptext('history_etc'), labelW: 84),
                          ]),
                          // 운동 경험
                          _psection('운동 경험 (중복선택)', [
                            _plabel('운동경험'),
                            _pchk('exp', expOptions),
                            const SizedBox(height: 8),
                            _plabel('운동경력'),
                            _pchk('career', careerOptions, multi: false),
                            const SizedBox(height: 8),
                            _plabel('PT 경험 만족도'),
                            _pchk('ptsat', ptSatOptions, multi: false),
                            const SizedBox(height: 6),
                            _pkv('PT 만족·불만족 이유', _ptext('ptreason_txt', maxLines: 2),
                                labelW: 110),
                          ]),
                          // 운동 성격
                          _psection('운동 성격 (중복선택)', [
                            _pchk('persona', personaOptions, column: true),
                          ]),
                          // 특이사항 (회원작성)
                          _psection('특이사항 (회원작성)', [
                            _ptext('member_note',
                                hint: '통증 부위, 알레르기, 원하는 시간대 등 트레이너에게 전할 내용 (선택)',
                                maxLines: 3),
                          ]),
                        ]),
                  ),
                  const SizedBox(height: 12),
                  // 이미지 아래 — 직원 MEMO
                  _staffMemo(),
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
                constraints: const BoxConstraints(maxWidth: 720),
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
