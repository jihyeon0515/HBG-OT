import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hbgym_ot/screens/ot_preview.dart';

void main() {
  testWidgets('오티문진표 미리보기가 값과 함께 렌더된다', (tester) async {
    final data = <String, dynamic>{
      'gender': '남',
      'prog_title': '체지방 감소', 'your_goal': '체지방 감소',
      'start_date': '2026-07-21', 'expire': '2027-07-20',
      'set_per_day': '15', 'rec_days': '4', 'time_min': '60', 'target_hr': '130~150',
      'w_now': '82', 'w_goal': '74', 'f_now': '24', 'f_goal': '16',
      's1_name': '벤치프레스', 's1_w1': '40', 's1_w2': '50', 's1_rep': '10', 's1_lv': '중',
      'checkpoint': '라운드 숄더', 'analysis': '상체 근력 부족', 'program': '분할 운동', 'period': '3개월',
      'os1_date': '2026-07-23', 'os1_time': '19:00', 'os1_prog': '스쿼트 / 레그프레스',
      'os1_cardio': ['런닝머신'], 'os1_ctime': '20분', 'os1_msign': '김민수', 'os1_asign': '박트레이너',
    };

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: OtFormPreview(data: data, memberName: '김민수', trainerName: '박트레이너'),
        ),
      ),
    ));
    tester.takeException(); // 에셋 이미지 로드 예외(테스트 번들) 무시

    expect(find.text('ORIENTATION PROGRAM'), findsOneWidget);
    expect(find.textContaining('STEP.2'), findsOneWidget);
    expect(find.text('1회차'), findsOneWidget);
    expect(find.byType(Image), findsWidgets); // 로고 + 인체 이미지
    expect(find.text('벤치프레스'), findsOneWidget);
    expect(find.text('스쿼트 / 레그프레스'), findsOneWidget);
    expect(find.text('라운드 숄더'), findsOneWidget);
  });
}
