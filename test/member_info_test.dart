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
    expect(find.text('운동목적 & 병력사항'), findsOneWidget);
    expect(find.text('운동 경험 & 성격'), findsOneWidget);
    expect(find.text('사무직'), findsOneWidget);
    expect(find.text('다이어트(체지방감소), 체형교정'), findsOneWidget); // 운동목적
    expect(find.text('체력저하, 체형불균형'), findsOneWidget); // 방문 계기
    expect(find.text('헬스, 수영'), findsOneWidget);
    expect(find.text('무릎 통증 있음'), findsOneWidget);
  });

  testWidgets('넓은 화면에서 세 섹션(회원정보·방문계기및목적·운동경험)이 가로로 배치된다',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = <String, dynamic>{
      'name': '홍길동', 'phone': '010-0000-0000',
      'visit_reason': ['체력저하'], 'purpose': ['다이어트(체지방감소)'],
      'exp': ['헬스'],
    };
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: SingleChildScrollView(child: MemberInfoSections(data: data))),
    ));
    final x1 = tester.getTopLeft(find.text('회원 정보')).dx;
    final x2 = tester.getTopLeft(find.text('운동목적 & 병력사항')).dx;
    final x3 = tester.getTopLeft(find.text('운동 경험 & 성격')).dx;
    expect(x1 < x2, isTrue); // 좌 → 우로 나란히
    expect(x2 < x3, isTrue);
  });

  testWidgets('목적/경험 박스가 동일 높이이고 관리자 특이사항 편집칸이 뜬다', (tester) async {
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = <String, dynamic>{
      'name': '홍길동',
      'visit_reason': ['체력저하', '체형불균형'],
      'purpose': ['다이어트(체지방감소)', '근육량증가'],
      'history': ['고혈압', '당뇨', '관절질환'],
      'history_etc': '과거 수술 이력 있음',
      'exp': ['헬스'],
      'career': '1년이상',
    };
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: MemberInfoSections(
              data: data, editableNote: true, onNoteChanged: (_) {}),
        ),
      ),
    ));
    // 관리자 특이사항 편집칸
    expect(find.byType(TextField), findsOneWidget);
    // 목적 박스와 경험 박스 높이 동일 (IntrinsicHeight)
    final h2 = tester
        .getSize(find
            .ancestor(
                of: find.text('운동목적 & 병력사항'), matching: find.byType(Card))
            .first)
        .height;
    final h3 = tester
        .getSize(find
            .ancestor(
                of: find.text('운동 경험 & 성격'), matching: find.byType(Card))
            .first)
        .height;
    expect((h2 - h3).abs() < 1.0, isTrue);
  });
}
