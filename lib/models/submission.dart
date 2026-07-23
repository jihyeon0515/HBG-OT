import 'dart:convert';

/// 워크플로 상태
enum SubStatus { submitted, assigned, inProgress, completed, success, failure }

extension SubStatusX on SubStatus {
  String get label => switch (this) {
        SubStatus.submitted => '접수',
        SubStatus.assigned => '배정완료',
        SubStatus.inProgress => '진행중',
        SubStatus.completed => '완료',
        SubStatus.success => '성공',
        SubStatus.failure => '실패',
      };

  /// 상태 색(0xAARRGGBB)
  int get color => switch (this) {
        SubStatus.submitted => 0xFF2F80ED, // 접수 - 파랑
        SubStatus.assigned => 0xFFE0A800, // 배정완료 - 노랑(골드)
        SubStatus.inProgress => 0xFF9B51E0, // 진행중 - 보라
        SubStatus.completed => 0xFF64748B, // 완료 - 회색(중립)
        SubStatus.success => 0xFF27AE60, // 성공 - 초록
        SubStatus.failure => 0xFFEB5757, // 실패 - 빨강
      };
}

/// 문진표 1건. 설문 데이터는 유연하게 Map으로 보관(HTML 버전과 동일 키).
class Submission {
  String id;
  SubStatus status;

  /// 회원 작성란 + 상담 문항 (name, gender, age, inflow[], purpose[], ...)
  Map<String, dynamic> data;

  String? assignedTrainer;
  DateTime createdAt;
  DateTime? assignedAt;
  DateTime? completedAt;

  Submission({
    required this.id,
    this.status = SubStatus.submitted,
    Map<String, dynamic>? data,
    this.assignedTrainer,
    DateTime? createdAt,
    this.assignedAt,
    this.completedAt,
  })  : data = data ?? {},
        createdAt = createdAt ?? DateTime.now();

  String get memberName => (data['name'] ?? '').toString().trim().isEmpty
      ? '(이름 미입력)'
      : data['name'].toString();

  String get goal => (data['your_goal'] ?? data['purpose'] is List
          ? ((data['purpose'] as List?)?.join(', ') ?? '')
          : '')
      .toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status.name,
        'data': data,
        'assignedTrainer': assignedTrainer,
        'createdAt': createdAt.toIso8601String(),
        'assignedAt': assignedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Submission.fromJson(Map<String, dynamic> j) => Submission(
        id: j['id'] as String,
        status: SubStatus.values.firstWhere((e) => e.name == j['status'],
            orElse: () => SubStatus.submitted),
        data: Map<String, dynamic>.from(j['data'] as Map? ?? {}),
        assignedTrainer: j['assignedTrainer'] as String?,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        assignedAt: j['assignedAt'] != null
            ? DateTime.tryParse(j['assignedAt'])
            : null,
        completedAt: j['completedAt'] != null
            ? DateTime.tryParse(j['completedAt'])
            : null,
      );

  static String encodeList(List<Submission> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<Submission> decodeList(String s) {
    final raw = jsonDecode(s) as List;
    return raw
        .map((e) => Submission.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
