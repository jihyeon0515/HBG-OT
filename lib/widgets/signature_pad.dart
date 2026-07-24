import 'package:flutter/material.dart';

// 서명 데이터는 정규화(0~1) 좌표의 스트로크 목록으로 저장한다.
// 형식: List<stroke> / stroke = List<point> / point = [x, y]
List<List<Offset>> decodeStrokes(dynamic raw) {
  final out = <List<Offset>>[];
  if (raw is List) {
    for (final s in raw) {
      if (s is List) {
        final pts = <Offset>[];
        for (final p in s) {
          if (p is List && p.length >= 2) {
            pts.add(Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()));
          }
        }
        if (pts.isNotEmpty) out.add(pts);
      }
    }
  }
  return out;
}

List encodeStrokes(List<List<Offset>> strokes) => strokes
    .where((s) => s.isNotEmpty)
    .map((s) => s.map((o) => [o.dx, o.dy]).toList())
    .toList();

class _SigPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color color;
  _SigPainter(this.strokes, {this.color = const Color(0xFF0B3F8F)});

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final s in strokes) {
      if (s.isEmpty) continue;
      if (s.length == 1) {
        canvas.drawCircle(
            Offset(s[0].dx * size.width, s[0].dy * size.height), 1.4, dot);
        continue;
      }
      final path = Path()
        ..moveTo(s[0].dx * size.width, s[0].dy * size.height);
      for (var i = 1; i < s.length; i++) {
        path.lineTo(s[i].dx * size.width, s[i].dy * size.height);
      }
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(covariant _SigPainter oldDelegate) => true;
}

/// 저장된 서명을 읽기 전용으로 렌더 (부모 크기에 맞춰 채움)
class SignatureView extends StatelessWidget {
  final dynamic strokes;
  final double? width;
  final double? height;
  final Color color;
  const SignatureView(
      {super.key,
      this.strokes,
      this.width,
      this.height,
      this.color = const Color(0xFF0B3F8F)});

  @override
  Widget build(BuildContext context) {
    final s = decodeStrokes(strokes);
    final paint = CustomPaint(
      painter: _SigPainter(s, color: color),
      child: const SizedBox.expand(),
    );
    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: paint);
    }
    return paint;
  }
}

/// 직접 그리는 서명 패드 (다이얼로그 안에서 사용 — 스크롤 충돌 없음)
class SignaturePad extends StatefulWidget {
  final dynamic initial;
  final double height;
  final ValueChanged<List>? onChanged;
  const SignaturePad(
      {super.key, this.initial, this.height = 200, this.onChanged});
  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  late List<List<Offset>> _strokes;
  Size _size = const Size(1, 1);

  @override
  void initState() {
    super.initState();
    _strokes = decodeStrokes(widget.initial);
  }

  void clear() {
    setState(() => _strokes = []);
    widget.onChanged?.call(const []);
  }

  Offset _n(Offset p) => Offset(
        (p.dx / _size.width).clamp(0.0, 1.0),
        (p.dy / _size.height).clamp(0.0, 1.0),
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      _size = Size(c.maxWidth, widget.height);
      return GestureDetector(
        onPanStart: (d) => setState(() => _strokes.add([_n(d.localPosition)])),
        onPanUpdate: (d) => setState(() {
          if (_strokes.isNotEmpty) _strokes.last.add(_n(d.localPosition));
        }),
        onPanEnd: (_) => widget.onChanged?.call(encodeStrokes(_strokes)),
        child: Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFBBBBBB))),
          child: CustomPaint(
            painter: _SigPainter(_strokes),
            size: Size(c.maxWidth, widget.height),
          ),
        ),
      );
    });
  }
}

/// 서명 그리기 다이얼로그 — 저장 시 정규화 스트로크(List) 반환, 취소면 null
Future<List?> showSignatureDialog(BuildContext context,
    {required String title, dynamic initial}) {
  List latest = (initial is List) ? List.from(initial) : const [];
  final key = GlobalKey<SignaturePadState>();
  return showDialog<List>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 320,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('아래 영역에 손가락/마우스로 서명해 주세요.',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 8),
          SignaturePad(
            key: key,
            initial: initial,
            height: 200,
            onChanged: (e) => latest = e,
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () {
              key.currentState?.clear();
              latest = const [];
            },
            child: const Text('지우기')),
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, latest),
            child: const Text('저장')),
      ],
    ),
  );
}
