import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hbgym_ot/screens/submission_view.dart';

void main() {
  testWidgets('회원 작성 내역 전체(회원정보·방문계기·운동경험)가 렌더된다', (tester) async {
    final data = <String, dynamic>{
      'name': '김민수', 'gender': '남', 'age': '34', 'job': '사무직',
      'etime': '평일 저녁', 'phone': '010-1234-5678',
      'purpose': ['다이어트(체지방감소)', '체형교정'],
      'visit_reason': ['체력저하', '체형불균형'],
      'exp': ['헬스', '수영'], 'career': '3-6개월', 'ptsat': '중',
      'persona': ['운동에 지루함을 쉽게느낀다'],
      'history': ['고혈압'], 'history_etc': '약 복용 중',
      'member_note': '무릎 통증 있음',
    };

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: MemberInfoSections(data: data)),
      ),
    ));

    expect(find.text('회원 정보'), findsOneWidget);
    expect(find.text('방문 계기 · 운동목적'), findsOneWidget);
    expect(find.text('운동 경험 · 건강'), findsOneWidget);
    expect(find.text('사무직'), findsOneWidget);
    expect(find.text('다이어트(체지방감소), 체형교정'), findsOneWidget); // 운동목적
    expect(find.text('체력저하, 체형불균형'), findsOneWidget); // 방문 계기
    expect(find.text('헬스, 수영'), findsOneWidget);
    expect(find.text('무릎 통증 있음'), findsOneWidget);
  });
}
