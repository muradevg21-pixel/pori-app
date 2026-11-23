import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pori/app.dart';
import 'package:pori/core/settings/settings_provider.dart';
import 'package:pori/core/utils/bn.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('bn converts digits', () {
    expect(bn(114), '১১৪');
    expect(bn('Juz 30'), 'Juz ৩০');
  });

  testWidgets('splash navigates to home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const PoriApp(),
    ));
    expect(find.text('পড়ি'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('আসসালামু আলাইকুম'), findsOneWidget);
    expect(find.text('কুরআন'), findsWidgets);
  });
}
