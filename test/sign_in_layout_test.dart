import 'package:asah/core/offline/local_store.dart';
import 'package:asah/core/theme/app_theme.dart';
import 'package:asah/features/auth/sign_in_screen.dart';
import 'package:asah/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The sign-in screen must fit with the keyboard up on a phone: no overflow,
/// and the phone field and the Send code button stay on screen.
void main() {
  // iPhone 17 Pro in points, and the iOS number pad's height.
  const phone = Size(402, 874);
  const keyboard = 291.0;
  const safeArea = EdgeInsets.only(top: 62, bottom: 34);

  Future<void> pump(WidgetTester tester, {required bool keyboardUp, Size size = phone}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view
      ..physicalSize = size * 3
      ..devicePixelRatio = 3
      ..padding = FakeViewPadding(top: safeArea.top * 3, bottom: safeArea.bottom * 3)
      ..viewInsets = FakeViewPadding.zero;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStoreProvider.overrideWithValue(LocalStore(prefs))],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const SignInScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (keyboardUp) {
      // As on a phone: tap the field, then the keyboard slides up.
      await tester.tap(find.byType(TextField));
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboard * 3);
      await tester.pumpAndSettle();
    }
  }

  void expectOnScreen(WidgetTester tester, Finder f, double visibleBottom) {
    final r = tester.getRect(f);
    expect(r.top, greaterThanOrEqualTo(0));
    expect(r.bottom, lessThanOrEqualTo(visibleBottom), reason: '$f ends at ${r.bottom}, screen ends at $visibleBottom');
  }

  for (final keyboardUp in [false, true]) {
    for (final size in [phone, const Size(375, 667), const Size(360, 640)]) {
      testWidgets('fits on $size, keyboard ${keyboardUp ? 'up' : 'down'}', (tester) async {
        await pump(tester, keyboardUp: keyboardUp, size: size);
        expect(tester.takeException(), isNull);
        // Raising the keyboard must not rebuild the field and drop focus (that would close the keyboard).
        if (keyboardUp) {
          expect(tester.state<EditableTextState>(find.byType(EditableText)).widget.focusNode.hasFocus, isTrue);
        }
        final visibleBottom = size.height - (keyboardUp ? keyboard : 0);
        final field = find.byType(TextField);
        final button = find.byType(FilledButton);
        // The field and the button are both on screen, the field above the button.
        expectOnScreen(tester, field, visibleBottom);
        expectOnScreen(tester, field, tester.getRect(button).top);
        // On the smallest phones the button may need a scroll while the keyboard is down.
        if (keyboardUp || size == phone) expectOnScreen(tester, button, visibleBottom);
      });
    }
  }
}
