import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hbgym_ot/models/submission.dart';
import 'package:hbgym_ot/screens/submission_view.dart';

void main() {
  testWidgets('트레이너 OT 작성이 있으면 상세 하단에 이미지 문진표가 뜬다', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sub = Submission(id: 'x', assignedTrainer: '박트레이너', data: {
      'name': '홍길동',
      'w_now': '80', 'w_goal': '72',
      'analysis': '유산소 병행 권장',
      'your_goal': '체지방 감소',
      'os1_prog': '스쿼트', 'os1_date': '2026-07-23', 'os1_time': '19:00',
    });
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SubmissionView(sub: sub))),
    );
    tester.takeException(); // 에셋 이미지 로드 예외 무시

    expect(find.text('트레이너 OT 작성 내용'), findsOneWidget);
    expect(find.text('ORIENTATION PROGRAM'), findsOneWidget); // 문진표 이미지 폼
    expect(find.byType(Image), findsWidgets); // 로고/인체 이미지
  });
}
