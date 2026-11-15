# Flow Sort

Coloured items ride a belt; tap switches to route each one into the bin of the same colour. Built from [FLOW_SORT_PLAN.md](FLOW_SORT_PLAN.md).

## Layout

| Path | What it is |
|---|---|
| `packages/flow_core` | Pure Dart rules: models, `flip`/`step`, boosters, scoring, seeded RNG, JSON codec. No Flutter imports. |
| `packages/flow_solver` | Solver (fewest flips, traps) and the difficulty score. |
| `packages/flow_levelgen` | Level generator, the 30 hand-made levels, and the `flow_levelgen` CLI. |
| `app` | The Flutter app (Flame scene, screens, services). |
| `tools/gen_audio.py` | Regenerates the placeholder sounds. |

The repository is a Dart pub workspace: run `flutter pub get` once at the root.

## Run it

```bash
cd app && flutter run
```

With no extra flags the app runs in **local mode**: no Firebase, simulated "Test ad" screens and simulated purchases. Simulated services exist only in debug and profile builds; a release build without store keys shows no ads and an unavailable shop rather than pretending.

Android has `dev` and `prod` flavors, so on Android add `--flavor dev`.

To use real SDKs, pass a config file:

```bash
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

`app/config/dev.json` turns on AdMob with Google's public test ad units. Copy `app/config/prod.example.json` to `app/config/prod.json` (git-ignored) and fill in the real ids for store builds.

## Test

```bash
(cd packages/flow_core && dart test)
(cd packages/flow_solver && dart test)
(cd packages/flow_levelgen && dart test)
(cd app && flutter analyze && flutter test)
```

## Levels

```bash
# Rebuild the bundled campaign (30 hand-made + 210 generated levels)
dart run flow_levelgen:flow_levelgen campaign

# Solve every level in a pack and print its metrics
dart run flow_levelgen:flow_levelgen grade app/assets/levels/core_002.json

# Generate a standalone pack for one difficulty band
dart run flow_levelgen:flow_levelgen generate --band 3 --count 50 --seed 1000 --out packs/core_003.json

# Print the daily challenge for a date
dart run flow_levelgen:flow_levelgen daily --date 2026-11-14
```

A test fails if `app/assets/levels/` no longer matches the generator, so re-run `campaign` after changing the generator or the hand-made levels.

New packs can be shipped without an app update: upload the JSON to Cloud Storage and list it in the `level_pack_manifest` Remote Config key as `[{"id":"core_003","version":1,"url":"https://…"}]`. For each pack id the highest version on the device wins.

## Generated code

Two kinds of generated files are committed. Regenerate them after changing their sources:

```bash
cd app
dart run build_runner build --delete-conflicting-outputs   # drift database
flutter gen-l10n                                           # after editing lib/l10n/*.arb
```

## Before a store release

These need your accounts, so they are not done:

1. **Firebase** — run `flutterfire configure` for the Android (and iOS) apps. The Gradle plugins switch on automatically once `google-services.json` exists. Then set `USE_FIREBASE` to true.
2. **AdMob** — set `ADMOB_APP_ID_ANDROID` in `app/android/gradle.properties`, replace `GADApplicationIdentifier` in `app/ios/Runner/Info.plist`, and put the ad unit ids in `config/prod.json`.
3. **RevenueCat** — create the products `remove_ads`, `starter_pack`, `coins_small`, `coins_medium`, `coins_large`, an entitlement named `remove_ads`, and attach them to the current offering. Put the SDK keys in `config/prod.json`.
4. **Signing** — create `app/android/key.properties` (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`).
5. **Privacy** — host the privacy policy and set `PRIVACY_POLICY_URL`; have the age, ads and analytics handling reviewed (see plan §8).
6. **Art and sound** — sticker art is drawn in code and the sounds are synthesised placeholders (`tools/gen_audio.py`). Replace the `.wav` files in `app/assets/audio/` keeping the names.

## Sharing a result

The win sheet has a **Share** button. It draws a 1080×1350 result card (level, stars, flips) in code and hands it, with a caption, to the system share sheet, so the player picks WhatsApp, Instagram or anything else installed. The card holds only game facts. Players who are not confirmed adults pass the parental gate first. Code: `app/lib/features/share/`. This uses the `share_plus` package, which is not in the plan's §3 list.

## Where the age rules live

`app/lib/features/onboarding/age_policy.dart` is the only place that decides what an age band may do. Services read its flags and decide nothing themselves. Firebase is pinned to the plugin line whose iOS SDK is still on CocoaPods; see the note in `app/pubspec.yaml`.
