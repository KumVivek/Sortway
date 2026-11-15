# Flow Sort — Build Plan

> Single source of truth for building Flow Sort with an AI coding assistant (Claude).
> Work **one phase at a time**, in order. Each phase ends with acceptance criteria — do not start the next phase until they pass.

---

## 0. How to use this file (instructions for the AI assistant)

- Read this whole file before writing code. Re-read the relevant phase before starting it.
- Build in **small, reviewable steps**: one feature per change, with tests.
- **Game rules live in pure Dart** (`packages/flow_core`) with **no Flutter imports**. Flame components only draw and animate.
- Every external service (ads, IAP, analytics, remote config, storage) sits behind a Dart interface with a **fake implementation** for tests and for under-18 mode.
- All tunable numbers come from `RemoteConfigService` with the **local defaults listed in §9**.
- Do not add a dependency that is not in §3 without explaining why and getting approval.
- Keep `flutter analyze` clean and all tests green at the end of every step.
- If a requirement is ambiguous, ask — don't guess on anything that touches **privacy, ads, purchases or age handling** (§8).

---

## 1. Product summary

| Item | Decision |
|---|---|
| Name (working) | Flow Sort |
| Genre | Hybrid-casual sort puzzle (ads + light in-app purchases) |
| Core loop | Coloured items ride a belt; the player taps switches to route each item into the bin of the same colour |
| Audience | All ages, designed to appeal to teens. Play Console target audience **13+**. Not marketed to children. |
| Platforms | Android first (soft launch), iOS from week 13. One Flutter codebase. |
| Session | Levels of 1–3 min; natural stopping point every 10–15 min ("set complete") |
| Monetization | Rewarded video (main), interstitials after level 10, Remove Ads IAP, coin packs; season pass later |
| Meta | Sticker/creature collection album, daily challenge, weekly event |
| Team | 1 developer (~25 h/week) + freelance 2D artist (~40 h) + bought SFX pack |
| Timeline | Android soft launch week 9–12; iOS + Tier-1 test weeks 13–16 |

**Design principles**
1. One finger, one rule. Understandable in 5 seconds without text.
2. Fun to come back to — not manipulative. Streaks never punish; no loot boxes; no countdown pressure on purchases.
3. Offline first. The game never needs a network connection to play.
4. Everything tunable remotely.

---

## 2. Game design spec

### 2.1 Board elements
- **Belt**: ordered queue of items. Advances one slot per tick. Tick length from config (`belt_tick_ms`, default 600 ms; slower on early levels).
- **Item**: has a `colour` (one of up to 7) and optional modifiers (see mechanics).
- **Switch**: a junction node in a binary tree. State `left | right`. Player taps to flip. Flip is instant.
- **Bin**: a leaf of the switch tree. Has `colour` and `capacity`. Shows fill count.
- **Lives**: 3 per level. Wrong bin or overflow (bin full) = −1 life. 0 lives = level failed.
- **Win**: all items on the belt delivered with ≥1 life left.
- **Stars**: 3 stars = no lives lost; 2 = one lost; 1 = two lost.

### 2.2 Mechanics roadmap (introduce one at a time, each with 2–3 tutorial levels)
| # | Mechanic | First level | Phase |
|---|---|---|---|
| M0 | Basic routing (2–3 colours, 1–2 switches) | 1 | P1 |
| M1 | More colours/bins, deeper switch tree | 8 | P1 |
| M2 | **Locked bin** — opens after N items delivered elsewhere | 31 | P2 |
| M3 | **Colour gate** — a gate on a branch changes an item's colour as it passes | 46 | P2 |
| M4 | **Mystery item** — colour hidden until it reaches the first switch | 61 | post-launch |
| M5 | **Second belt** — two belts feed the same tree | 76 | post-launch |
| M6 | **Rush level** — faster ticks, bonus coins | every 10th from 50 | post-launch |

### 2.3 Boosters
| Booster | Effect | Price (coins) | Ad alternative |
|---|---|---|---|
| Undo | Rewinds last delivery, restores a life if lost | 100 | Yes (rewarded) |
| Extra life | +1 life now | 150 | Yes, once per level |
| Slow belt | Tick length ×1.6 for 10 ticks | 120 | No |

### 2.4 Meta
- **Collection album**: sets of 12 stickers (themes e.g. "Ocean Pals"). Each level complete grants 1 sticker pull from the current set (no duplicates within a set until the set is complete; **no paid random pulls**). Completing a set grants coins + an album page animation.
- **Level map**: linear path, a set boundary every 12 levels.
- **Daily challenge**: one generated level per day, seeded from the date (`seed = yyyymmdd`), identical for everyone, no server needed. Reward: coins + streak counter. Missing a day does **not** reset a reward tier; streak just restarts counting.
- **Weekly event** (P4+): a themed pack of 7 levels available Mon–Sun, config-driven.

### 2.5 Economy defaults (all in Remote Config)
- Level complete: 20 coins (+10 per star above 1).
- Set complete: 300 coins.
- Daily challenge: 100 coins.
- Starting coins: 300.
- Rewarded "double coins" on level complete: once per level.

---

## 3. Tech stack

| Area | Package / service | Notes |
|---|---|---|
| Framework | Flutter (latest stable), Dart 3 | |
| Game loop | `flame` | Belt, items, switches, bins, effects |
| Animation | `rive` + Flame effects | Artist animations for UI/celebrations |
| Audio | `flame_audio` | SFX + music |
| State | `flutter_riverpod` | App state (wallet, progress, settings) |
| Local DB | `drift` (+ `sqlite3_flutter_libs`) | Progress, wallet, collection |
| Settings | `shared_preferences` | Sound, haptics, age band |
| Analytics | `firebase_analytics` | Disabled/aggregate for minors (§8) |
| Crashes | `firebase_crashlytics` | No user IDs |
| Live config | `firebase_remote_config` | Defaults in §9 |
| Level hosting | Firebase Cloud Storage | Downloadable JSON packs |
| Ads | `google_mobile_ads` | Child-safe flags for minors (§8); UMP consent for EU/UK |
| IAP | `purchases_flutter` (RevenueCat) | Receipt validation without own backend |
| Routing | `go_router` | |
| Tests | `flutter_test`, `integration_test`, golden tests | |
| CI/CD | GitHub Actions + Fastlane | Play internal track, TestFlight |

---

## 4. Repository structure

```
flow_sort/
├─ packages/
│  ├─ flow_core/        # pure Dart: models, rules, tick simulation, scoring, seeded RNG
│  ├─ flow_solver/      # pure Dart: solver + difficulty metrics
│  └─ flow_levelgen/    # pure Dart CLI: generate, grade, export level packs (JSON)
├─ app/
│  ├─ lib/
│  │  ├─ game/                 # Flame: FlowGame, BeltComponent, ItemComponent, SwitchComponent, BinComponent, effects
│  │  ├─ features/
│  │  │  ├─ levels/            # level map, loader, progress
│  │  │  ├─ meta/              # album, daily challenge, events
│  │  │  ├─ economy/           # wallet, boosters, offers
│  │  │  ├─ monetization/      # AdsService, PurchasesService, entitlements
│  │  │  ├─ onboarding/        # age check, consent, tutorial
│  │  │  └─ settings/
│  │  ├─ services/             # analytics, remote_config, storage, audio, haptics (interfaces + impls + fakes)
│  │  ├─ ui/                   # theme, shared widgets
│  │  └─ app.dart              # router, providers
│  ├─ assets/ (sprites/, rive/, audio/, levels/)
│  ├─ test/
│  └─ integration_test/
├─ tools/               # upload_level_pack.dart, build scripts
├─ .github/workflows/   # ci.yml (analyze + test), release.yml
└─ FLOW_SORT_PLAN.md
```

Use a Dart workspace (pub workspaces) or `melos` to manage the packages.

---

## 5. Core model (`flow_core`)

```dart
enum ItemColour { red, blue, green, yellow, purple, orange, pink }
enum SwitchDir { left, right }

class Item { final ItemColour colour; final ItemModifier? modifier; }

sealed class Node { final String id; }
class SwitchNode extends Node { final Node left, right; }        // state held in GameState
class GateNode extends Node { final ItemColour toColour; final Node next; } // M3
class BinNode extends Node { final ItemColour colour; final int capacity; final int? unlockAfter; } // M2

class LevelDef {
  final String id; final int seed;
  final Node root;                 // tree entry point (belt feeds root)
  final List<Item> belt;           // in order
  final int tickMs; final int lives; // default 3
  final Map<String, SwitchDir> initialSwitches;
  final LevelMeta meta;            // difficulty score, par flips, mechanics
}

class GameState {             // immutable; produced by step()
  final int tick; final int lives;
  final Map<String, SwitchDir> switches;
  final Map<String, int> binFill;
  final int nextItemIndex; final int delivered;
  final GameStatus status;    // playing | won | lost
}

// Pure functions
GameState flip(GameState s, String switchId);
GameState step(LevelDef level, GameState s); // advance one tick, deliver item if it reaches a bin
```

**Simplification for v1:** an item is routed through the whole tree at the moment it leaves the belt (on its tick), using the switch states at that instant. Animation in Flame then shows it travelling. This keeps the simulation discrete and solver-friendly.

**Tests required:** routing, gates, locked bins, overflow, lives, win/lose, determinism (same seed + same inputs = same result).

---

## 6. Level format (JSON)

```json
{
  "packId": "core_002",
  "version": 3,
  "levels": [
    {
      "id": "L031",
      "seed": 918273,
      "tickMs": 600,
      "lives": 3,
      "tree": {
        "type": "switch", "id": "s1",
        "left":  { "type": "bin", "id": "b1", "colour": "red",  "capacity": 4 },
        "right": { "type": "switch", "id": "s2",
                   "left":  { "type": "bin", "id": "b2", "colour": "blue", "capacity": 3, "unlockAfter": 4 },
                   "right": { "type": "bin", "id": "b3", "colour": "green", "capacity": 3 } }
      },
      "initialSwitches": { "s1": "left", "s2": "right" },
      "belt": ["red","green","red","blue","green","red","blue","red","green","blue"],
      "meta": { "difficulty": 0.42, "parFlips": 7, "mechanics": ["locked_bin"] }
    }
  ]
}
```

- Bundled packs live in `app/assets/levels/`. Downloaded packs are cached on device; the app prefers the highest `version` it has.
- Remote Config key `level_pack_manifest` lists available pack IDs, versions and Storage URLs.

---

## 7. Solver and generator

### 7.1 Solver (`flow_solver`)
- Model: between two ticks the player may flip at most `k` switches (**reaction budget**; `k = 2` easy, `k = 1` hard).
- Search: BFS / A* over `(tick, switchStates, binFill, lives)`; prune states with lives < 1.
- Output: `solvable`, `minFlips`, `minTightestGap` (smallest number of ticks between two required flips), `trapCount` (flips that look right but cause a later failure), `optimalPath`.
- Must solve any v1 level (≤ 8 bins, ≤ 40 items) in < 200 ms on a laptop.

### 7.2 Generator (`flow_levelgen` CLI)
```
dart run flow_levelgen generate --band 3 --count 50 --seed 1000 --out packs/core_003.json
dart run flow_levelgen grade packs/core_003.json
```
1. Pick template by difficulty band: colours (2–7), bins (2–8), tree depth, belt length (8–40), allowed mechanics.
2. Build tree + belt from a seeded RNG.
3. Solve. Reject if unsolvable, or solvable with ≤ 1 flip, or too similar to an existing level (hash of tree + belt).
4. Score difficulty: weighted sum of `minFlips`, `1/minTightestGap`, `trapCount`, colours, mechanics.
5. Keep top candidates per band; output JSON with meta.

### 7.3 Difficulty curve
- Sawtooth: rises over ~5 levels, then one easier "breather"; a marked **Hard** level every 10th.
- First 30 levels are **hand-designed** (tutorial). Everything after is generated, then playtested by a human.
- Remote Config `difficulty_offset` (−2..+2 bands) shifts the curve per country.

---

## 8. Age check, ads and privacy (must be exact)

On first launch, show a neutral **year-of-birth picker** (no default value, no hint of a "right" answer). Store the resulting `AgeBand` locally: `adult` (18+), `minor` (<18), `unknown` (skipped). Treat `unknown` as `minor`. Allow reset from Settings.

| Setting | adult | minor / unknown |
|---|---|---|
| Ads | Personalized allowed after UMP consent (EU/UK) | Non-personalized only. `RequestConfiguration`: `tagForUnderAgeOfConsent = true`, `tagForChildDirectedTreatment = true` (for under-13 bands), `maxAdContentRating = G` |
| Ad networks | AdMob (mediation added later) | AdMob only |
| Analytics | Firebase Analytics on | `setAnalyticsCollectionEnabled(false)`; consent mode: ad_storage / ad_user_data / ad_personalization / analytics_storage = denied |
| Crashlytics | On, no user ID | On, no user ID, no custom keys with personal data |
| Purchases | Normal flow | Behind a **parental gate** (e.g. multi-digit arithmetic), real-money price shown clearly |
| Push notifications | Opt-in, max 1/day | Off by default |
| Personal data | None collected in v1 | None |
| Social / chat / free-text names | None | None |

Also:
- Play Console: target audience 13+; complete Data safety and content rating honestly.
- Plain-language privacy policy listing every SDK.
- **No** loot boxes, paid random rewards, fake timers, or misleading "X" buttons on ads.
- Re-check before May 2027 (India DPDP under-18 rules fully in force). Get a privacy lawyer to review before launch.

Implementation: `AgePolicy` provider exposes flags (`personalizedAds`, `analyticsEnabled`, `purchasesNeedGate`). Services read only from `AgePolicy`; no service decides on its own.

---

## 9. Remote Config keys (local defaults)

| Key | Default | Purpose |
|---|---|---|
| `interstitial_first_level` | 10 | No interstitials before this level |
| `interstitial_min_gap_levels` | 3 | Levels between interstitials |
| `interstitial_min_gap_seconds` | 90 | Time between interstitials |
| `rewarded_double_coins_enabled` | true | |
| `belt_tick_ms_base` | 600 | |
| `difficulty_offset` | 0 | −2..+2 |
| `coins_level_complete` | 20 | |
| `coins_set_complete` | 300 | |
| `coins_daily` | 100 | |
| `starting_coins` | 300 | |
| `booster_prices` | `{"undo":100,"life":150,"slow":120}` | |
| `level_pack_manifest` | bundled packs only | |
| `weekly_event` | `null` | Event config JSON |
| `force_update_min_version` | `1.0.0` | |

---

## 10. Analytics events

Only fired when `AgePolicy.analyticsEnabled` is true.

| Event | Params |
|---|---|
| `age_check_done` | band (adults only; for minors nothing is sent — use Play Console demographics for the audience mix) |
| `tutorial_step` | step |
| `level_start` | level, pack, mechanic |
| `level_complete` | level, time_s, lives_left, stars, boosters_used |
| `level_fail` | level, reason (`wrong_bin` / `overflow`) |
| `level_quit` | level, seconds_in |
| `booster_used` | type, level, source (`coins` / `ad`) |
| `ad_offer_shown` / `ad_watched` | placement, level |
| `interstitial_shown` | level |
| `iap_view` / `iap_purchase` | product, price |
| `sticker_earned` / `set_complete` | set, index |
| `daily_challenge` | result, streak |
| `session_end` | levels_played, minutes |

---

## 11. Phases, tasks and acceptance criteria

### Phase 0 — Setup (week 1)
- [ ] Monorepo with `app` + `flow_core` + `flow_solver` + `flow_levelgen`; workspace config; `analysis_options.yaml` (strict).
- [ ] GitHub Actions: `flutter analyze`, `dart test` for packages, `flutter test` for app on every push.
- [ ] Firebase project (Android), `flutterfire configure`; flavors `dev` and `prod`.
- [ ] Theme, fonts, colour-blind-safe palette (each colour also has a shape icon).

**Accept when:** CI is green on an empty app that launches on Android with dev flavor.

### Phase 1 — Prototype (weeks 1–2)
- [ ] `flow_core` model + `flip` + `step` + full unit tests (§5).
- [ ] Flame scene: belt, items, tappable switches with clear state arrow, bins with fill counter, lives display.
- [ ] Level loader from bundled JSON; 30 hand-made levels (M0–M1).
- [ ] Win/lose screens, restart, next level; local progress (drift).
- [ ] SFX + haptics for correct/wrong delivery and win.

**Accept when:** 30 levels playable start-to-finish on a ₹8–10K Android phone at 60 fps; `flow_core` coverage ≥ 90%.
**Gate 1:** 10 testers play; ≥ 6 replay without being asked.

### Phase 2 — MVP (weeks 3–6)
- [ ] `flow_solver` + `flow_levelgen` CLI (§7); generate and grade 200+ levels; curve applied.
- [ ] Mechanics M2 (locked bin) and M3 (colour gate) with tutorials.
- [ ] Level map, collection album, daily challenge, coins, boosters (§2).
- [ ] `RemoteConfigService` with all §9 defaults.
- [ ] Age check + `AgePolicy` + all §8 behaviour, with tests for both bands.
- [ ] `AdsService` (rewarded + interstitial with frequency caps), `PurchasesService` (Remove Ads, restore), parental gate.
- [ ] Analytics events (§10), Crashlytics.
- [ ] Save on every level end; survives app kill mid-level.

**Accept when:** 230+ levels; all monetization paths work with test ads/sandbox purchases; minor band shows only non-personalized ads and sends no analytics (verified with Firebase DebugView); cold start < 3 s; no crash in a 1-hour session.
**Gate 2:** performance + stability as above.

### Phase 3 — Polish (weeks 6–8)
- [ ] Start Play **closed test (≥ 12 testers, 14 continuous days)** in week 6 — required for new personal developer accounts before production.
- [ ] Final art, Rive animations, celebration effects, music.
- [ ] Settings: sound, music, haptics, language (English + Hindi), privacy page, age reset.
- [ ] Store listing: icon, 6 screenshots, short video, description; privacy policy URL; Data safety; content rating.
- [ ] Three 15-second gameplay ad videos.

**Accept when:** closed test complete; testers average 30+ levels; production access approved.
**Gate 3:** store-ready.

### Phase 4 — Soft launch (weeks 9–12)
- [ ] Release Android in India + Philippines; ~$300 test UA, 3 creatives.
- [ ] Weekly loop: read funnels → fix worst drop-off → tune via Remote Config.
- [ ] First weekly event; second sticker season; level pack upload tool (`tools/upload_level_pack.dart`).

**Gate 4:** Day-1 ≥ 35%, Day-7 ≥ 12%, crash-free users ≥ 99.5%. If missed: fix first 10 minutes, or switch to backup mechanic (arrow tap-out) on the same engine.

### Phase 5 — iOS + Tier-1 test (weeks 13–16)
- [ ] iOS build, App Store Connect, StoreKit products via RevenueCat, ATT prompt for adults only, TestFlight.
- [ ] Coin packs, starter pack; AdMob mediation with 2–3 networks (adults only).
- [ ] Small US/UK/Canada test; compare CPI vs revenue per user.

**Decision:** scale with own budget, pitch publishers with the data, or pivot.

---

## 12. Backend

### 12.1 Phases 0–4: no custom backend
Everything server-like is handled by managed services:

| Need | Solution |
|---|---|
| Progress, coins, collection | On device (drift) |
| New levels / events | JSON packs in Firebase Cloud Storage + manifest in Remote Config |
| Tuning, A/B tests | Firebase Remote Config |
| Daily challenge | Seeded from date on device |
| Purchases + receipts | RevenueCat |
| Analytics / crashes | Firebase |

### 12.2 After Gate 4: small .NET backend (only what the data asks for)
**Stack:** ASP.NET Core (.NET 8/9) minimal APIs, single service · PostgreSQL · Redis (leaderboards, cache) · Firebase Auth ID-token validation · Azure Container Apps or AWS App Runner (India region) · OpenAPI → generated Dart client.

**Build order**
1. Cloud save + account linking (adults, or behind parental gate).
2. Event/season config served from the API.
3. Daily challenge leaderboards (preset nicknames only, no free text).
4. RevenueCat webhooks → server-granted entitlements.
5. Optional web shop.

**Endpoints**
```
POST /v1/players/link              # link Firebase UID to install ID
GET  /v1/save                      # returns { version, data, updatedAt }
PUT  /v1/save                      # optimistic concurrency on version
GET  /v1/events/active
POST /v1/daily/{date}/score        # body: move list; server replays with flow_core rules
GET  /v1/daily/{date}/leaderboard
POST /v1/webhooks/revenuecat
```

**Rules**
- Offline first: the game must work if the API is down.
- Minors: store only game progress; no names, email or location; fixed retention period.
- Never trust client scores — replay the move list server-side (port `flow_core` rules to C# or run a Dart service).
- Expected cost: ~$20–60/month at a few thousand DAU.

---

## 13. KPI targets (soft launch)

| KPI | Target |
|---|---|
| Tutorial completion | ≥ 85% |
| Day-1 retention | ≥ 35% (aim 40%) |
| Day-7 retention | ≥ 12% (aim 15–20%) |
| Day-30 retention | ≥ 5% |
| Avg session | ≥ 8 min |
| Levels in first session | ≥ 10 |
| Rewarded ad opt-in (DAU) | ≥ 30% |
| Crash-free users | ≥ 99.5% |
| Store rating | ≥ 4.4 |

---

## 14. Risks

| Risk | Early warning | Response |
|---|---|---|
| Core not fun | Gate 1 < 6/10 replay | Backup mechanic (arrow tap-out) on same engine |
| Too hard for younger players | High fails on levels 5–15 | Slower belt, bigger reaction budget |
| Low-end Android performance | Frame drops | Sprite atlases, fewer particles |
| Part-time pace slips | Phase 2 past week 7 | Cut M3 + daily challenge to post-launch |
| Art late | No style board by week 2 | Ship clean flat placeholder style |
| Policy rejection | Pre-launch report / review | All age/ads flags in `AgePolicy`; fix and resubmit |

---

## 15. Open questions (owner: Vivek)
- [ ] Real weekly hours available (plan assumes ~25)
- [ ] Personal vs organization Play account (organization skips the 12-tester rule; needs D-U-N-S)
- [ ] Budget ceiling for art + soft-launch ads (plan assumes ₹1.5–2.5 lakh total)
- [ ] Launch languages beyond English + Hindi
- [ ] Final name and visual theme

---

## 16. First prompt to start building

> Read `FLOW_SORT_PLAN.md`. Do **Phase 0** only: create the monorepo structure in §4, set up CI from Phase 0, and a minimal Flutter app that launches. Then stop and summarize what you created and what's next.
