import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:superfile/core/state/superfile_state_manager.dart';
import 'package:superfile/main.dart';

void main() {
  testWidgets('SuperfileApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SuperfileStateManager(),
        child: const SuperfileApp(),
      ),
    );
    expect(find.text('SUPERFILE'), findsWidgets);
  });
}
