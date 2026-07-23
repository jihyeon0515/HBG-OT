import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/submission.dart';

/// 데모용 역할 (실제 배포 시 로그인으로 대체)
enum Role { member, admin, trainer }

/// 앱 전체 상태 + 로컬 저장(shared_preferences).
/// 나중에 이 클래스의 저장/불러오기만 Firebase로 바꾸면 됩니다.
class AppState extends ChangeNotifier {
  static const _key = 'hbgym_submissions_v1';

  final List<Submission> _subs = [];
  List<Submission> get submissions => List.unmodifiable(_subs);

  Role role = Role.member;
  String? currentTrainer; // 트레이너 역할일 때 누구인지

  int _seq = 0;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_key);
    if (s != null && s.isNotEmpty) {
      try {
        _subs
          ..clear()
          ..addAll(Submission.decodeList(s));
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, Submission.encodeList(_subs));
  }

  void setRole(Role r, {String? trainer}) {
    role = r;
    if (r == Role.trainer) currentTrainer = trainer;
    notifyListeners();
  }

  String _newId() {
    _seq++;
    return 'S${DateTime.now().millisecondsSinceEpoch}$_seq';
  }

  // ---- 워크플로 동작 ----

  Submission createSubmission(Map<String, dynamic> data) {
    final sub = Submission(id: _newId(), data: Map.of(data));
    _subs.insert(0, sub);
    _persist();
    notifyListeners();
    return sub;
  }

  void assignTrainer(String id, String trainer) {
    final s = _byId(id);
    if (s == null) return;
    s.assignedTrainer = trainer;
    s.status = SubStatus.assigned;
    s.assignedAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  /// 트레이너가 작성 내용을 저장(진행중으로)
  void saveTrainerWork(String id, Map<String, dynamic> patch,
      {bool markInProgress = true}) {
    final s = _byId(id);
    if (s == null) return;
    s.data.addAll(patch);
    if (markInProgress && s.status == SubStatus.assigned) {
      s.status = SubStatus.inProgress;
    }
    _persist();
    notifyListeners();
  }

  /// 데이터 일부만 갱신(상태 변경 없음) — 관리자 특이사항 편집 등
  void updateData(String id, Map<String, dynamic> patch) {
    final s = _byId(id);
    if (s == null) return;
    s.data.addAll(patch);
    _persist();
    notifyListeners();
  }

  /// 완료 건의 결과(성공/실패) 지정
  void setOutcome(String id, SubStatus outcome) {
    final s = _byId(id);
    if (s == null) return;
    s.status = outcome; // SubStatus.success or SubStatus.failure
    s.completedAt ??= DateTime.now();
    _persist();
    notifyListeners();
  }

  void completeSubmission(String id, Map<String, dynamic> patch) {
    final s = _byId(id);
    if (s == null) return;
    s.data.addAll(patch);
    s.status = SubStatus.completed;
    s.completedAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  void deleteSubmission(String id) {
    _subs.removeWhere((e) => e.id == id);
    _persist();
    notifyListeners();
  }

  Submission? _byId(String id) {
    for (final s in _subs) {
      if (s.id == id) return s;
    }
    return null;
  }

  Submission? byId(String id) => _byId(id);

  // ---- 조회 ----
  List<Submission> byStatus(SubStatus st) =>
      _subs.where((s) => s.status == st).toList();

  List<Submission> forTrainer(String trainer) => _subs
      .where((s) =>
          s.assignedTrainer == trainer &&
          (s.status == SubStatus.assigned || s.status == SubStatus.inProgress))
      .toList();

  /// 트레이너 알림(새 배정) 개수
  int trainerBadge(String trainer) => _subs
      .where((s) => s.assignedTrainer == trainer && s.status == SubStatus.assigned)
      .length;

  int get inboxCount => byStatus(SubStatus.submitted).length;

  /// 데모용: 상태별 샘플 3건 생성
  void seedDemo() {
    final base = {
      'gender': '남',
      'age': '34',
      'job': '사무직',
      'etime': '평일 저녁 7-9시',
      'phone': '010-1234-5678',
      'purpose': ['다이어트(체지방감소)', '체형교정'],
      'visit_reason': ['체력저하', '체형불균형'],
      'history': ['고혈압'],
      'exp': ['헬스', '수영'],
      'career': '3-6개월',
      'ptsat': '중',
      'persona': ['운동에 지루함을 쉽게느낀다'],
      'member_note': '오른쪽 무릎에 통증이 가끔 있어요. 저녁 시간대를 선호합니다.',
    };
    createSubmission(
        {...base, 'name': '이접수', 'member_type': '신규', 'jongmok': '헬스'});
    final s2 = createSubmission(
        {...base, 'name': '박배정', 'member_type': '리뉴', 'jongmok': '필라'});
    final s3 = createSubmission({
      ...base,
      'name': '최완료',
      'member_type': '체험',
      'jongmok': '헬스',
      'your_goal': '체지방 감소'
    });
    assignTrainer(s2.id, '박트레이너');
    assignTrainer(s3.id, '김코치');
    completeSubmission(s3.id, {
      'your_goal': '체지방 감소',
      'prog_title': '체지방 감소',
      'w_now': '82', 'w_goal': '74',
      'analysis': '체지방률이 높아 유산소 병행 권장.',
      'program': '주 4회 분할 + 유산소 30분',
      'period': '3개월',
      'rec_days': '4', 'set_per_day': '15', 'time_min': '60', 'target_hr': '130~150',
      's1_name': '벤치프레스', 's1_w1': '40', 's1_w2': '50', 's1_rep': '10', 's1_lv': '중',
      'os1_date': '2026-07-23', 'os1_time': '19:00', 'os1_prog': '스쿼트 / 레그프레스',
      'os1_cardio': ['런닝머신'], 'os1_ctime': '20분', 'os1_msign': '최완료', 'os1_asign': '김코치',
      'trainer_note': '무릎 통증 고려해 하체 고중량은 4주 후부터 진행.',
    });
    setOutcome(s3.id, SubStatus.success); // 데모: 김코치가 성공으로 완료
    // 진행중 예시 (2차 진행중)
    final s4 = createSubmission(
        {...base, 'name': '정진행', 'member_type': '신규', 'jongmok': '필라'});
    assignTrainer(s4.id, '이트레이너');
    saveTrainerWork(s4.id, {
      'analysis': '자세 교정 진행 중',
      'os1_date': '2026-07-20', 'os1_time': '19:00', 'os1_prog': '스쿼트 / 레그프레스',
      'os2_date': '2026-07-24', 'os2_time': '20:00', 'os2_prog': '벤치프레스',
    });
    // 실패 예시 (정트레이너가 실패로 완료)
    final s5 = createSubmission(
        {...base, 'name': '한실패', 'member_type': '체험', 'jongmok': '헬스'});
    assignTrainer(s5.id, '정트레이너');
    completeSubmission(s5.id, {
      'analysis': '체험 종료 후 미등록',
      'os1_date': '2026-07-22', 'os1_time': '18:00', 'os1_prog': '전신 순환 운동',
    });
    setOutcome(s5.id, SubStatus.failure);
  }
}

const String trainerListDefault = '박트레이너';
