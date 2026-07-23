import 'package:flutter/material.dart';
import '../theme.dart';

const _blue = Color(0xFF0B3F8F);
const _line = Color(0xFF222222);
const _hdrFill = Color(0xFFFFF3C4); // 옅은 노랑 라벨칸

/// 오티문진표(양식) 미리보기 — 로고·인체 이미지 포함, 입력값 실시간 반영
class OtFormPreview extends StatelessWidget {
  final Map<String, dynamic> data;
  final String memberName;
  final String trainerName;
  const OtFormPreview(
      {super.key,
      required this.data,
      required this.memberName,
      this.trainerName = ''});

  String _s(String k) => (data[k] ?? '').toString();
  bool _has(String k) => _s(k).trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _programSheet(),
        const SizedBox(height: 16),
        _evalSheet(),
      ],
    );
  }

  // 값 표시 (밑줄, 파란 글씨)
  Widget _v(String k, {String suffix = '', double min = 26}) {
    final t = _s(k);
    return Container(
      constraints: BoxConstraints(minWidth: min),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFBBBBBB)))),
      child: Text(t.isEmpty ? ' ' : '$t$suffix',
          style: const TextStyle(
              color: _blue, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  Widget _chk(bool on, String label) => Padding(
        padding: const EdgeInsets.only(right: 10, bottom: 2),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(on ? '☑' : '☐',
              style: TextStyle(
                  fontSize: 13,
                  color: on ? _blue : Colors.black54,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11.5,
                  color: on ? _blue : Colors.black87,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w400)),
        ]),
      );

  BoxDecoration get _paper => BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line, width: 1.4),
        borderRadius: BorderRadius.circular(6),
      );

  Widget _labelCell(String text) => Container(
        color: _hdrFill,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black)),
      );

  // ------------------------------------------------------------------
  // 2페이지: ORIENTATION PROGRAM
  // ------------------------------------------------------------------
  Widget _programSheet() {
    final gender = _s('gender');
    final cardioAll = ['런닝머신', '싸이클', '스텝퍼', '스텝밀', '마이마운틴'];
    return Container(
      decoration: _paper,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 로고 + 타이틀
          Row(children: [
            Image.asset('assets/logo.png', height: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ORIENTATION PROGRAM',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1330B8))),
                  Row(children: [
                    Expanded(child: _v('prog_title', min: 60)),
                    const SizedBox(width: 4),
                    const Text('프로그램',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ],
              ),
            ),
          ]),
          Container(height: 6, color: _line, margin: const EdgeInsets.symmetric(vertical: 8)),
          // 회원 정보 표
          Container(
            decoration: BoxDecoration(border: Border.all(color: _line)),
            child: Column(children: [
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SizedBox(width: 62, child: _labelCell('회원이름')),
                  Expanded(child: Padding(padding: const EdgeInsets.all(5), child: Text(memberName, style: const TextStyle(fontSize: 12, color: _blue, fontWeight: FontWeight.w700)))),
                  Container(width: 1, color: _line),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      _chk(gender == '남', '남'),
                      _chk(gender == '여', '여'),
                    ]),
                  ),
                ]),
              ),
              Container(height: 1, color: _line),
              Row(children: [
                SizedBox(width: 62, child: _labelCell('담당T')),
                Expanded(child: Padding(padding: const EdgeInsets.all(5), child: Text(trainerName, style: const TextStyle(fontSize: 12, color: _blue, fontWeight: FontWeight.w700)))),
                SizedBox(width: 54, child: _labelCell('시작일')),
                Expanded(child: Padding(padding: const EdgeInsets.all(5), child: _v('start_date'))),
              ]),
              Container(height: 1, color: _line),
              Row(children: [
                SizedBox(width: 62, child: _labelCell('운동목적')),
                Expanded(child: Padding(padding: const EdgeInsets.all(5), child: _v('your_goal', min: 40))),
                SizedBox(width: 54, child: _labelCell('만료일')),
                Expanded(child: Padding(padding: const EdgeInsets.all(5), child: _v('expire'))),
              ]),
            ]),
          ),
          const SizedBox(height: 6),
          // 운동목표 요약
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: _hdrFill, border: Border.all(color: _line)),
            child: Wrap(spacing: 14, runSpacing: 4, children: [
              _kvInline('총1일세트', _s('set_per_day'), 'set'),
              _kvInline('권장운동일', _has('rec_days') ? '주 ${_s('rec_days')}회' : '', ''),
              _kvInline('시간', _has('time_min') ? '${_s('time_min')}분' : '', ''),
              _kvInline('목표심박수', _s('target_hr'), ''),
            ]),
          ),
          const SizedBox(height: 8),
          // 회차 3개
          for (var i = 1; i <= 3; i++) _sessionBlock(i, cardioAll),
          const SizedBox(height: 4),
          Center(child: Image.asset('assets/logo.png', height: 26)),
        ],
      ),
    );
  }

  Widget _kvInline(String k, String v, String suffix) => RichText(
        text: TextSpan(style: const TextStyle(fontSize: 11.5, color: Colors.black), children: [
          TextSpan(text: '$k ', style: const TextStyle(fontWeight: FontWeight.w800)),
          TextSpan(
              text: v.isEmpty ? '__' : '$v$suffix',
              style: const TextStyle(color: _blue, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _sessionBlock(int i, List<String> cardioAll) {
    final p = 'os$i';
    final cardio = data['${p}_cardio'];
    final selCardio = cardio is List ? cardio.map((e) => e.toString()).toSet() : <String>{};
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(border: Border.all(color: _line, width: 1.2)),
      padding: const EdgeInsets.all(7),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: kBlack,
            child: Text('$i회차',
                style: const TextStyle(color: kYellow, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          const Text('날짜 ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          _v('${p}_date'),
          const SizedBox(width: 8),
          const Text('시간 ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          _v('${p}_time'),
        ]),
        const SizedBox(height: 5),
        _multiline('${p}_prog', '운동 프로그램'),
        if (_has('${p}_sets'))
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(children: [
              const Text('세트: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              Expanded(child: Text(_s('${p}_sets'), style: const TextStyle(fontSize: 11.5, color: _blue))),
            ]),
          ),
        if (_has('${p}_tip'))
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text('- tip: ${_s('${p}_tip')}',
                style: const TextStyle(fontSize: 11.5, color: _blue)),
          ),
        const SizedBox(height: 4),
        Row(children: [
          const Text('유산소 ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ...cardioAll.map((c) => _chk(selCardio.contains(c), c)),
        ]),
        Row(children: [
          const Text('시간 ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          _v('${p}_ctime'),
          const SizedBox(width: 12),
          const Text('다음오티 ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          _v('${p}_next'),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Text('회원서명 ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          Text(_s('${p}_msign'), style: const TextStyle(fontSize: 12, color: _blue, fontWeight: FontWeight.w700)),
          const SizedBox(width: 14),
          const Text('관리자서명 ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          Text(_s('${p}_asign'), style: const TextStyle(fontSize: 12, color: _blue, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }

  Widget _multiline(String k, String label) {
    final t = _s(k);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          color: const Color(0xFFFCFCFA),
          border: Border.all(color: const Color(0xFFDDDDDD))),
      child: Text(t.isEmpty ? label : t,
          style: TextStyle(
              fontSize: 12,
              color: t.isEmpty ? Colors.black38 : _blue,
              fontWeight: t.isEmpty ? FontWeight.w400 : FontWeight.w600)),
    );
  }

  // ------------------------------------------------------------------
  // 1페이지 STEP2: 평가분석 (인체 이미지 포함)
  // ------------------------------------------------------------------
  Widget _evalSheet() {
    final gender = _s('gender');
    return Container(
      decoration: _paper,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STEP.2  평가분석 및 운동 컨설팅',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          const Divider(color: _line),
          const Text('< InBody 분석 >', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
          _inbody('체중', 'w_now', 'w_goal', 'kg'),
          _inbody('체지방량', 'f_now', 'f_goal', 'kg'),
          _inbody('근육량', 'm_now', 'm_goal', 'kg'),
          _inbody('기초대사량', 'b_now', 'b_goal', 'kcal'),
          const SizedBox(height: 8),
          Row(children: [
            const Text('< 근력평가 >  ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
            _chk(gender == '남', '남'),
            _chk(gender == '여', '여'),
          ]),
          for (var i = 1; i <= 3; i++) _strengthRow(i),
          const SizedBox(height: 10),
          const Text('< 정적자세 평가 >', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDDDDDD))),
            padding: const EdgeInsets.all(6),
            child: Image.asset('assets/body.jpg', fit: BoxFit.contain),
          ),
          _memo('checkpoint', '- Check point'),
          const SizedBox(height: 8),
          const Text('< 분석 및 운동컨설팅 >', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
          _memo('analysis', '- 평가분석 내용'),
          _memo('program', '- 트레이너 권장 운동프로그램'),
          const SizedBox(height: 6),
          Row(children: [
            const Text('기간 컨설팅  ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
            ...['3개월', '6개월', '12개월'].map((o) => _chk(_s('period') == o, o)),
          ]),
        ],
      ),
    );
  }

  Widget _inbody(String label, String a, String b, String unit) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(width: 74, child: Text('- $label', style: const TextStyle(fontSize: 12))),
          _v(a, min: 34),
          Text(' $unit → 목표 ', style: const TextStyle(fontSize: 11.5)),
          _v(b, min: 34),
          Text(' $unit', style: const TextStyle(fontSize: 11.5)),
        ]),
      );

  Widget _strengthRow(int i) {
    final p = 's$i';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        const Text('-( ', style: TextStyle(fontSize: 11.5)),
        _v('${p}_name', min: 50),
        const Text(' ) ', style: TextStyle(fontSize: 11.5)),
        _v('${p}_w1', min: 24),
        const Text(' / ', style: TextStyle(fontSize: 11.5)),
        _v('${p}_w2', min: 24),
        const Text(' x ', style: TextStyle(fontSize: 11.5)),
        _v('${p}_rep', min: 22),
        const Text(' rep  ', style: TextStyle(fontSize: 11.5)),
        ...['상', '중', '하'].map((o) => _chk(_s('${p}_lv') == o, o)),
      ]),
    );
  }

  Widget _memo(String k, String label) {
    final t = _s(k);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF1B4FA0)),
          borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        if (t.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(t, style: const TextStyle(fontSize: 12, color: _blue, fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }
}
