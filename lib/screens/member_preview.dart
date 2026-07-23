import 'package:flutter/material.dart';
import '../models/options.dart';
import '../theme.dart';
import '../widgets/form_fields.dart';

/// 회원이 작성한 내용을 '회원 폼과 동일한 모양'으로 읽기전용 표시 (클릭 없이 바로 노출)
class MemberFormView extends StatelessWidget {
  final Map<String, dynamic> data;
  const MemberFormView({super.key, required this.data});

  String _s(String k) => (data[k] ?? '').toString();
  Set<String> _selOf(String k) =>
      data[k] is List ? (data[k] as List).map((e) => e.toString()).toSet() : {};

  Widget _text(String label, String field, {int maxLines = 1, bool fit = false}) {
    final value = _s(field).isEmpty ? '-' : _s(field);
    Widget valueText = Text(value,
        maxLines: maxLines,
        overflow: TextOverflow.clip,
        style: const TextStyle(fontSize: 13.5, color: kInk));
    // fit=true: 좁은 칸에서도 한 줄에 들어가도록 폭에 맞춰 자동 축소
    if (fit) {
      valueText = Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(fontSize: 13.5, color: kInk)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        fieldLabel(label),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: maxLines > 1 ? 58 : 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
              color: const Color(0xFFFAFAF8),
              border: Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(9)),
          child: valueText,
        ),
      ]),
    );
  }

  Widget _chips(String label, String field, List<String> options,
      {bool multi = true}) {
    final sel = multi ? _selOf(field) : {_s(field)};
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (label.isNotEmpty) fieldLabel(label),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((o) {
            final on = sel.contains(o);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                  color: on ? kBlack : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: on ? kBlack : kBorder)),
              child: Text(o,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: on ? FontWeight.w800 : FontWeight.w500,
                      color: on ? kYellow : kInk)),
            );
          }).toList(),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      FormSection(title: '① 기본 정보', children: [
        LayoutBuilder(builder: (ctx, c) {
          // 화면(칸) 폭이 좁으면(모바일) 줄을 나눠 성별 칩이 세로로 눌리지 않게 함
          final narrow = c.maxWidth < 560;
          final typeRow = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _chips('구분', 'member_type', memberTypeOptions, multi: false)),
                const SizedBox(width: 8),
                Expanded(child: _chips('희망종목', 'jongmok', jongmokOptions, multi: false)),
              ]);
          final jobRow = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _text('직업', 'job')),
                const SizedBox(width: 8),
                Expanded(child: _text('운동 시간대', 'etime')),
              ]);
          if (narrow) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  typeRow,
                  // 이름 · 연락처
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: _text('이름', 'name')),
                    const SizedBox(width: 8),
                    Expanded(flex: 4, child: _text('연락처', 'phone', fit: true)),
                  ]),
                  // 성별 · 나이
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _chips('성별', 'gender', genders, multi: false)),
                    const SizedBox(width: 8),
                    Expanded(child: _text('나이', 'age')),
                  ]),
                  jobRow,
                ]);
          }
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                typeRow,
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: _text('이름', 'name')),
                  const SizedBox(width: 8),
                  Expanded(flex: 4, child: _text('연락처', 'phone', fit: true)),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: _chips('성별', 'gender', genders, multi: false)),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: _text('나이', 'age')),
                ]),
                jobRow,
              ]);
        }),
      ]),
      FormSection(title: '② 방문 계기 & 운동목적 (중복선택)', children: [
        _chips('헬스보이짐 분당정자점을 방문하게 된 계기', 'visit_reason', visitReasonOptions),
        _chips('운동목적', 'purpose', purposeOptions),
      ]),
      FormSection(title: '③ 건강 & 병력사항 (중복선택)', children: [
        _chips('병력사항', 'history', historyOptions),
        _text('기타 병력 / 수술 이력', 'history_etc'),
      ]),
      FormSection(title: '④ 운동 경험 (중복선택)', children: [
        _chips('운동경험', 'exp', expOptions),
        _chips('운동경력', 'career', careerOptions, multi: false),
        _chips('PT 경험 만족도', 'ptsat', ptSatOptions, multi: false),
        _text('PT 만족 / 불만족 이유', 'ptreason_txt', maxLines: 2),
      ]),
      FormSection(title: '⑤ 운동 성격 (중복선택)', children: [
        _chips('', 'persona', personaOptions),
      ]),
      FormSection(title: '⑥ 특이사항', children: [
        _text('회원 작성', 'member_note', maxLines: 3),
      ]),
    ]);
  }
}

const _blue = Color(0xFF0B3F8F);
const _line = Color(0xFF222222);
const _hdr = Color(0xFFFFF3C4);

/// 회원이 작성한 상담 문진표를 종이 양식(이미지) 형태로 렌더
class MemberFormPreview extends StatelessWidget {
  final Map<String, dynamic> data;
  final String memberName;
  const MemberFormPreview({super.key, required this.data, this.memberName = ''});

  String _s(String k) => (data[k] ?? '').toString();
  Set<String> _sel(String k) =>
      data[k] is List ? (data[k] as List).map((e) => e.toString()).toSet() : {};

  Widget _val(String k, {String suffix = ''}) {
    final t = _s(k);
    return Text(t.isEmpty ? '-' : '$t$suffix',
        style: const TextStyle(
            color: _blue, fontWeight: FontWeight.w700, fontSize: 12));
  }

  Widget _chk(bool on, String label) => Padding(
        padding: const EdgeInsets.only(right: 10, bottom: 3),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(on ? '☑' : '☐',
              style: TextStyle(
                  fontSize: 13,
                  color: on ? _blue : Colors.black45,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11.5,
                  color: on ? _blue : Colors.black87,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w400)),
        ]),
      );

  Widget _chkMulti(String field, List<String> opts) {
    final sel = _sel(field);
    return Wrap(children: opts.map((o) => _chk(sel.contains(o), o)).toList());
  }

  Widget _chkSingle(String field, List<String> opts) {
    final v = _s(field);
    return Wrap(children: opts.map((o) => _chk(v == o, o)).toList());
  }

  Widget _kv(String label, Widget value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 70,
              child: Text('$label',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700))),
          Expanded(child: value),
        ]),
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 3),
        child: Text(t,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black87)),
      );

  Widget _section(String title, List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(border: Border.all(color: _line, width: 1.2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            color: _hdr,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final gender = _s('gender');
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _line, width: 1.4),
          borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Image.asset('assets/logo.png', height: 34),
          const SizedBox(width: 10),
          const Text('신규회원 상담 문진표',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ]),
        Container(height: 5, color: _line, margin: const EdgeInsets.symmetric(vertical: 8)),
        _section('회원 정보', [
          Row(children: [
            const Text('구분 ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
            ..._sel0('member_type', memberTypeOptions),
            const SizedBox(width: 14),
            const Text('희망종목 ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
            ..._sel0('jongmok', jongmokOptions),
          ]),
          const SizedBox(height: 4),
          _kv('이름', _val('name')),
          _kv('연락처', _val('phone')),
          _kv('성별',
              Row(children: [_chk(gender == '남', '남'), _chk(gender == '여', '여')])),
          _kv('나이', _val('age', suffix: '세')),
          _kv('직업', _val('job')),
          _kv('운동시간대', _val('etime')),
        ]),
        _section('방문 계기 & 운동목적', [
          _label('방문 계기'),
          _chkMulti('visit_reason', visitReasonOptions),
          const SizedBox(height: 4),
          _label('운동목적'),
          _chkMulti('purpose', purposeOptions),
        ]),
        _section('건강 & 병력사항', [
          _chkMulti('history', historyOptions),
          if (_s('history_etc').isNotEmpty) _kv('기타 병력', _val('history_etc')),
        ]),
        _section('운동 경험', [
          _label('운동경험'),
          _chkMulti('exp', expOptions),
          const SizedBox(height: 4),
          _label('운동경력'),
          _chkSingle('career', careerOptions),
          const SizedBox(height: 4),
          _label('PT 경험 만족도'),
          _chkSingle('ptsat', ptSatOptions),
          if (_s('ptreason_txt').isNotEmpty) _kv('PT 이유', _val('ptreason_txt')),
        ]),
        _section('운동 성격', [
          _chkMulti('persona', personaOptions),
        ]),
        _section('특이사항 (회원 작성)', [
          Text(_s('member_note').isEmpty ? '-' : _s('member_note'),
              style: const TextStyle(color: _blue, fontWeight: FontWeight.w600, fontSize: 12)),
        ]),
      ]),
    );
  }

  // 라벨 옆 인라인 단일선택 체크
  List<Widget> _sel0(String field, List<String> opts) {
    final v = _s(field);
    return opts.map((o) => _chk(v == o, o)).toList();
  }
}
