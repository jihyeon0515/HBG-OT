import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_state.dart';
import 'models/options.dart';
import 'theme.dart';
import 'screens/member_form.dart';
import 'screens/admin_dashboard.dart';
import 'screens/trainer_ot.dart';

void main() {
  runApp(const HbGymApp());
}

/// URL 파라미터로 데모 상태 지정 (?seed=1&role=admin|trainer&trainer=이름)
void _applyQuery(AppState s) {
  final q = Uri.base.queryParameters;
  // ?reset=1 (또는 ?seed=reset): 저장된 옛 데이터를 비우고 최신 샘플로 다시 채움
  final wantReset = q['reset'] == '1' || q['seed'] == 'reset';
  if (wantReset) {
    for (final sub in s.submissions.toList()) {
      s.deleteSubmission(sub.id);
    }
    s.seedDemo();
  } else if (q['seed'] == '1' && s.submissions.isEmpty) {
    s.seedDemo();
  }
  switch (q['role']) {
    case 'admin':
      s.setRole(Role.admin);
    case 'trainer':
      s.setRole(Role.trainer, trainer: q['trainer'] ?? trainerList.first);
    case 'member':
      s.setRole(Role.member);
  }
}

class HbGymApp extends StatelessWidget {
  const HbGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final s = AppState();
        s.load().then((_) => _applyQuery(s));
        return s;
      },
      child: MaterialApp(
        title: '헬스보이짐 분당정자점',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const RootShell(),
      ),
    );
  }
}

class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/logo_full.png', height: 22),
          const SizedBox(width: 10),
          const Flexible(
            child: Text('헬스보이짐 분당정자점',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ]),
        actions: [
          if (app.role == Role.trainer) _trainerPicker(context, app),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) => _menu(context, app, v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'sample', child: Text('샘플 회원 접수(테스트)')),
              PopupMenuItem(value: 'clear', child: Text('전체 데이터 삭제')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
            child: _roleSwitcher(context, app),
          ),
        ),
      ),
      body: switch (app.role) {
        Role.member => const MemberFormScreen(),
        Role.admin => const AdminDashboardScreen(),
        Role.trainer => const TrainerListScreen(),
      },
    );
  }

  Widget _roleSwitcher(BuildContext context, AppState app) {
    Widget btn(String label, Role r, IconData icon, {int badge = 0}) {
      final on = app.role == r;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: on ? kBlack : Colors.white,
              foregroundColor: on ? kYellow : kInk,
              side: BorderSide(color: on ? kBlack : kBorder, width: on ? 1.5 : 1),
              textStyle: TextStyle(
                  fontWeight: on ? FontWeight.w900 : FontWeight.w600),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => app.setRole(r,
                trainer: r == Role.trainer
                    ? (app.currentTrainer ?? trainerList.first)
                    : null),
            icon: Icon(icon, size: 18),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                if (badge > 0) ...[
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.redAccent,
                    child: Text('$badge',
                        style: const TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final trainerBadge =
        app.currentTrainer != null ? app.trainerBadge(app.currentTrainer!) : 0;
    return Row(children: [
      btn('회원', Role.member, Icons.person),
      btn('관리자', Role.admin, Icons.admin_panel_settings, badge: app.inboxCount),
      btn('트레이너', Role.trainer, Icons.fitness_center, badge: trainerBadge),
    ]);
  }

  Widget _trainerPicker(BuildContext context, AppState app) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: app.currentTrainer ?? trainerList.first,
        dropdownColor: Colors.white,
        iconEnabledColor: Colors.white,
        style: const TextStyle(color: Colors.white),
        selectedItemBuilder: (_) => trainerList
            .map((t) => Center(
                child: Text(t, style: const TextStyle(color: Colors.white))))
            .toList(),
        items: trainerList
            .map((t) => DropdownMenuItem(
                value: t,
                child: Text(t, style: const TextStyle(color: Colors.black87))))
            .toList(),
        onChanged: (v) => app.setRole(Role.trainer, trainer: v),
      ),
    );
  }

  void _menu(BuildContext context, AppState app, String v) {
    if (v == 'sample') {
      app.createSubmission({
        'name': '김민수',
        'member_type': '신규',
        'jongmok': '헬스',
        'gender': '남',
        'age': '34',
        'job': '사무직',
        'etime': '평일 저녁 7-9시',
        'phone': '010-1234-5678',
        'purpose': ['다이어트(체지방감소)', '체형교정'],
        'visit_reason': ['체력저하', '체형불균형'],
        'history': ['고혈압'],
        'history_etc': '경미, 약 복용 중',
        'exp': ['헬스', '수영'],
        'career': '3-6개월',
        'ptsat': '중',
        'persona': ['운동에 지루함을 쉽게느낀다', '너무 힘든 것 보다는 적당한 강도가 좋다'],
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('샘플 회원이 접수되었습니다. (관리자 탭에서 확인)')));
    } else if (v == 'clear') {
      for (final s in app.submissions.toList()) {
        app.deleteSubmission(s.id);
      }
    }
  }
}
