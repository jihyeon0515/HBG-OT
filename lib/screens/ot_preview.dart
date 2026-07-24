import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/signature_pad.dart';

const _blue = Color(0xFF0B3F8F);
const _line = Color(0xFF222222);
const _hdrFill = Color(0xFFFFF3C4); // 옅은 노랑 라벨칸

/// 문진표(회원/OT)를 작은 썸네일로 보여주고, 탭하면 전체화면(세로 스크롤)으로 표시.
/// builder 로 매번 새 위젯을 만들어 썸네일/전체화면에서 각각 독립적으로 렌더한다.
class PreviewThumbnail extends StatelessWidget {
  final Widget Function() builder;
  final String title;
  final double naturalWidth;
  final VoidCallback? onTapOverride; // 지정 시 기본 전체화면 대신 이 동작
  const PreviewThumbnail(
      {super.key,
      required this.builder,
      required this.title,
      this.naturalWidth = 560,
      this.onTapOverride});

  void _openFull(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) {
          final w = MediaQuery.of(ctx).size.width;
          final formW = w < (naturalWidth + 40) ? w - 16 : naturalWidth;
          return Scaffold(
            backgroundColor: const Color(0xFFECECEA),
            appBar: AppBar(title: Text(title)),
            body: Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(child: SizedBox(width: formW, child: builder())),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: onTapOverride ?? () => _openFull(context),
        child: Container(
          width: 300,
          height: 300,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(children: [
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(width: naturalWidth, child: builder()),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle),
                child: const Icon(Icons.zoom_in, color: Colors.white, size: 26),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 5),
      const Text('탭하여 크게 보기',
          style: TextStyle(fontSize: 12, color: kMuted)),
    ]);
  }
}

/// 오티문진표(양식) 미리보기 — 로고·인체 이미지 포함, 입력값 실시간 반영
class OtFormPreview extends StatelessWidget {
  final Map<String, dynamic> data;
  final String memberName;
  final String trainerName;
  final bool signable; // 관리자 서명 클릭 가능 여부
  final void Function(String signKey)? onAdminSignTap;
  const OtFormPreview(
      {super.key,
      required this.data,
      required this.memberName,
      this.trainerName = '',
      this.signable = false,
      this.onAdminSignTap});

  String _s(String k) => (data[k] ?? '').toString();

  @override
  Widget build(BuildContext context) => _sheet();

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
  // 오티 문진표 (트레이너 입력 내용 그대로 반영)
  // ------------------------------------------------------------------
  Widget _cellVal(String text) => Expanded(
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Text(text.isEmpty ? '-' : text,
              style: const TextStyle(
                  fontSize: 12, color: _blue, fontWeight: FontWeight.w700)),
        ),
      );

  Widget _sheet() {
    final vline = Container(width: 1, color: _line);
    return Container(
      decoration: _paper,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 로고 + 타이틀 (트레이너 OT 기록지와 동일)
          Row(children: [
            Image.asset('assets/logo.png', height: 40),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('OT 기록지',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Text('ORIENTATION  RECORD',
                    style: TextStyle(
                        fontSize: 9.5,
                        letterSpacing: 2.5,
                        color: Colors.black45,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          Container(height: 6, color: _line, margin: const EdgeInsets.symmetric(vertical: 8)),
          // 회원 · 담당T · 회원권 정보 표
          Container(
            decoration: BoxDecoration(border: Border.all(color: _line)),
            child: Column(children: [
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SizedBox(width: 62, child: _labelCell('회원명')),
                  vline,
                  _cellVal(memberName),
                  vline,
                  SizedBox(width: 52, child: _labelCell('담당T')),
                  vline,
                  _cellVal(trainerName),
                ]),
              ),
              Container(height: 1, color: _line),
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SizedBox(width: 84, child: _labelCell('회원권 시작일')),
                  vline,
                  _cellVal(_s('mem_start')),
                  vline,
                  SizedBox(width: 84, child: _labelCell('회원권 만료일')),
                  vline,
                  _cellVal(_s('mem_end')),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          // InBody 분석
          const Text('< InBody 분석 >',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
          _inbody('체중', 'w_now', 'w_goal', 'kg'),
          _inbody('체지방량', 'f_now', 'f_goal', 'kg'),
          _inbody('근육량', 'm_now', 'm_goal', 'kg'),
          _inbody('기초대사량', 'b_now', 'b_goal', 'kcal'),
          const SizedBox(height: 10),
          // 회차별 오티
          const Text('< 회차별 오티 >',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
          const SizedBox(height: 4),
          for (var i = 1; i <= 3; i++) _sessionBlock(i),
          const SizedBox(height: 6),
          // 트레이너 메모
          const Text('< 트레이너 메모 >',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
          const SizedBox(height: 4),
          _multiline('trainer_note', '트레이너 메모'),
          const SizedBox(height: 8),
          Center(child: Image.asset('assets/logo.png', height: 26)),
        ],
      ),
    );
  }

  Widget _sessionBlock(int i) {
    final p = 'os$i';
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
        const SizedBox(height: 3),
        // 회차별 메모란
        Row(children: const [
          Text('메모', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 2),
        _multiline('${p}_tip', '메모'),
        const SizedBox(height: 4),
        Row(children: [
          const Text('다음오티 ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          _v(i < 3 ? 'os${i + 1}_date' : 'os3_ndate'),
          const SizedBox(width: 6),
          _v(i < 3 ? 'os${i + 1}_time' : 'os3_ntime'),
        ]),
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const Text('회원서명 ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          _signText('${p}_msign'),
          const SizedBox(width: 14),
          const Text('관리자서명 ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          _signText('${p}_asign', admin: true),
        ]),
      ]),
    );
  }

  // 서명: 직접 그린 서명 또는 필기체 이름. admin+signable 이면 클릭해 서명.
  Widget _signText(String signKey, {bool admin = false}) {
    final draw = data['${signKey}_draw'];
    if (draw is List && draw.isNotEmpty) {
      return SignatureView(strokes: draw, width: 96, height: 34);
    }
    final name = _s(signKey);
    if (name.isNotEmpty) {
      final t = Text(name,
          style: const TextStyle(
              fontFamily: 'NanumBrush', fontSize: 20, color: _blue));
      if (admin && signable) {
        return GestureDetector(
            onTap: () => onAdminSignTap?.call(signKey), child: t);
      }
      return t;
    }
    if (admin && signable) {
      // 빈 관리자 서명 — 클릭하면 서명
      return GestureDetector(
        onTap: () => onAdminSignTap?.call(signKey),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              border: Border.all(color: _blue),
              borderRadius: BorderRadius.circular(4)),
          child: const Text('터치하여 서명',
              style: TextStyle(fontSize: 10.5, color: _blue, fontWeight: FontWeight.w700)),
        ),
      );
    }
    return const Text('___',
        style: TextStyle(fontSize: 12, color: Colors.black38));
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

}
