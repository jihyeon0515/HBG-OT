import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hbgym_ot/main.dart';

void main() {
  testWidgets('앱이 뜬다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const HbGymApp());
    await tester.pump();
    expect(find.textContaining('헬스보이짐'), findsWidgets);
  });
}
