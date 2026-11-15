import 'package:flow_sort/features/onboarding/age_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Future<void> openPrivacy(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home-settings')));
  await settle(tester);
  await tester.tap(find.byKey(const Key('setting-privacy')));
  await settle(tester);
}

void main() {
  testWidgets('ad choices button appears when consent rules require it', (
    tester,
  ) async {
    final env = TestEnv(ageBand: AgeBand.adult);
    env.ads.privacyOptionsRequired = true;
    await pumpApp(tester, env);
    await openPrivacy(tester);

    final button = find.byKey(const Key('privacy-ad-choices'));
    await tester.scrollUntilVisible(
      button,
      200,
      // The page's own list; each SelectableText also holds a Scrollable.
      scrollable:
          find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
    );
    expect(find.text('Ad privacy choices'), findsOneWidget);
    await tester.tap(button);
    await settle(tester);
    expect(env.ads.privacyOptionsShown, 1);
    await unmount(tester, env);
  });

  testWidgets('no ad choices button where it is not required', (tester) async {
    final env = TestEnv(ageBand: AgeBand.adult);
    await pumpApp(tester, env);
    await openPrivacy(tester);
    expect(find.byKey(const Key('privacy-ad-choices')), findsNothing);
    await unmount(tester, env);
  });
}
