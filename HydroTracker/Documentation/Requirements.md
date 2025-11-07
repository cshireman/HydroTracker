# Water Tracker — Requirements & Design v0.1

> Owner: Christopher Shireman  
> Platforms: iOS (iPhone), watchOS (Apple Watch)  
> Target Xcode: 26  
> Storage: Local-first (no subscription), optional HealthKit write/read

---

## 1) Product Vision & Goals
**Vision:** A fast, private, no‑subscription water tracking app that works great on iPhone and Apple Watch, with zero‑friction logging and reliable sync.

**Primary goals**
- One‑tap logging on watch and phone.
- Clear progress toward a daily hydration goal.
- Local‑first storage with robust iPhone ↔︎ Watch sync.
- Optional Health app integration (user‑controlled).

**Non‑goals (MVP)**
- Social features, accounts, or backend servers.
- Complex gamification or streak badges (can be v1.1+).

---

## 2) Personas & Use Cases
**Persona A — Busy Professional**
- Wants quick taps on the Watch between meetings.
- Needs gentle reminders and a clean daily chart.

**Persona B — Fitness‑minded**
- Logs water before/after workouts from the Watch.
- Syncs with Health to keep all hydration in one place.

**Top use cases**
1. Log preset amounts (e.g., 8 oz / 250 ml) with one tap.
2. Log custom amount via Digital Crown (watch) or numeric keypad (iPhone).
3. See progress ring and daily total at a glance.
4. Edit or delete a mistaken entry.
5. Receive nudges at smart times (optional).

---

## 3) MVP Scope
**Must‑have**
- Daily goal (oz/ml), units toggle.
- Quick‑add presets (2–4 configurable sizes).
- Add custom amount.
- Today view with progress ring, daily history list.
- Edit/Delete an entry (same day; multi‑day edits are acceptable but not required for MVP).
- Local storage on iPhone; local storage on Watch.
- Background‑tolerant, bidirectional sync between iPhone and Watch.
- Optional: write to HealthKit (dietaryWater). Read is optional in MVP.
- Lock Screen/Widget (iOS) and Complications (watchOS) showing progress.

**Nice‑to‑have (v1.1)**
- Read historical hydration from Health to backfill.
- Weekly trends (7/30‑day averages).
- Smart reminders (time‑aware, activity‑aware windows).
- Siri Shortcuts / App Intents ("add 8 ounces").
- Quick Actions (Haptic Touch) on the app icon.

---

## 4) Success Metrics (Local, Private)
- TTI to log on Watch ≤ 1.0s from wrist raise.
- P50 taps to log water: 1.
- Sync correctness: 0 data loss; conflicts auto‑resolved; same total on both devices within seconds.
- Crash‑free sessions ≥ 99.9%.

---

## 5) Information Architecture & Data Model
**Entities**
- `HydrationEntry`
  - `id: UUID`
  - `amountMl: Double` (canonical)
  - `createdAt: Date` (UTC)
  - `source: enum { iphone, watch, healthkit }`
  - `isDeleted: Bool` (for sync tombstones)
- `UserPrefs`
  - `dailyGoalMl: Double`
  - `unit: enum { ml, oz }`
  - `presetsMl: [Double]` (e.g., 118, 237, 355)
  - `healthWriteEnabled: Bool`
  - `healthReadEnabled: Bool` (post‑MVP)

**Indices**
- By `createdAt` for fast daily queries.
- By `isDeleted` for sync pruning.

**Derivations**
- Daily total = Σ entries in local day (respecting timezone).
- Progress = min(dailyTotal / dailyGoal, 1.0).

---

## 6) Architecture Overview
**Approach:** Local‑first on each device with lightweight, resilient sync via WatchConnectivity.

- **Storage**: Core Data (recommended for maturity) or SwiftData (if you prefer). iPhone uses persistent store in App Group to share with widgets. Watch uses an independent store.
- **Sync**: Bidirectional deltas via `WCSession` (reachability‑aware). Use an idempotent payload format carrying entries changed since `lastSyncTimestamp`.
- **Conflict resolution**: last‑writer‑wins on `HydrationEntry` by `createdAt` + `id`. Deletions win over edits.
- **Background tasks**: schedule background transfers when connectivity returns; coalesce changes.
- **HealthKit**: optional write on add (user toggled). If read is enabled later, ingest as separate source and deduplicate by (timestamp ± tolerance, amount).

**Layers**
- **Domain**: Pure models + use cases (`AddEntry`, `DeleteEntry`, `EntriesForDay`, `SyncDeltas`).
- **Data**: Core Data/SwiftData repositories, HealthKit gateway, WCSession sync client.
- **UI**: SwiftUI for iOS/watchOS. App Intents for Shortcuts/Widgets.

---

## 7) Sync Design (iPhone ↔︎ Watch)
**Payload: `SyncBatch`**
- `deviceId`
- `since: Date`
- `entries: [EntryDelta]` where `EntryDelta = { id, amountMl, createdAt, isDeleted, lastModifiedAt }`

**Flow**
1. On mutation, enqueue delta and attempt send if reachable.
2. If unreachable, persist to outbox; send on reachability change or foreground.
3. Receiver merges: upsert by id, apply LWW on `lastModifiedAt`. Acknowledge with `appliedThrough` timestamp.
4. Periodic reconciliation (e.g., daily) requests `since = lastAck` as safety net.

**Edge cases**
- Duplicate taps: UUID prevents double insert; idempotent merge.
- Clock skew: rely on `lastModifiedAt` generated per device; break ties by `deviceId` lexicographic.
- Delete vs edit: delete wins.

---

## 8) Permissions & Privacy
- **HealthKit** (optional): request write (dietaryWater). Prompt is decoupled from onboarding to avoid blocking first run.
- **Notifications**: for reminders; request after demonstrating value.
- **Privacy**: no analytics or tracking in MVP; consider local telemetry toggles later.

---

## 9) UX Requirements
**iPhone**
- Home: progress ring, goal, big Quick‑add buttons (presets), "+" custom, today log list.
- Edit sheet: change amount, delete.
- Settings: units, goal, presets, Health options, reminders.
- Widgets: Small (ring), Medium (ring + quick add), Lock Screen widget (ring).

**Watch**
- Primary screen: large Quick‑add buttons (2–3), crown to fine‑tune amount, progress ring.
- Secondary: Today list with undo/delete recent.
- Complications: modular ring with total/goal.

**Accessibility**
- VoiceOver labels on buttons (e.g., "Add 8 ounces").
- Dynamic Type, high contrast, haptics on add.

---

## 10) App Intents & Shortcuts (v1.1 suggestion)
- `LogWaterIntent(amount: Measurement<UnitVolume>)`
- `SetDailyGoalIntent(amount:)`
- Siri examples: "Log 12 ounces in AquaLog" (placeholder name).

---

## 11) Reminders (Optional)
- Simple schedule: N nudges between wake and bedtime.
- Smart spacing: avoid back‑to‑back if user recently logged.
- Quiet hours.

---

## 12) Testing Strategy
- **Unit**: domain use cases, unit conversion, sync merge logic (LWW, tombstones).
- **UI tests**: quick‑add flow, edit/delete, widget tap‑through.
- **Integration**: WCSession offline/online transitions; HealthKit write behind a feature flag.
- **Performance**: cold launch < 400 ms (watch), scrolling 60 fps list.

---

## 13) Tech Choices (proposed)
- SwiftUI everywhere.
- Core Data + NSPersistentContainer (App Group on iOS for widgets). Separate store on watch.
- WatchConnectivity with codable batches.
- App Intents for widgets/shortcuts.
- Unit conversion utilities (oz ⇄ ml) centralized in Domain.

_Alternative_: SwiftData for simplicity; assess watchOS parity and migration path.

---

## 14) Risks & Mitigations
- **Sync drift**: add reconciliation job + telemetry counters (local only) to detect divergence.
- **HealthKit duplicates**: tag sources and dedupe by (time±2min, amount).
- **Preset sprawl**: limit to 4, allow reorder.

---

## 15) Roadmap
**MVP (2–3 weeks of spare‑time dev)**
1. Data model & repositories (iOS + Watch), unit conversion.
2. Basic iPhone UI + presets + today list + edit/delete.
3. Watch UI with 2–3 presets and crown custom.
4. WCSession delta sync + reconciliation.
5. Widgets/Complications for progress.
6. Optional Health write.

**v1.1**
- Trends, reminders, App Intents, Health read.

---

## 16) Open Questions
- Name & icon.
- Do we want multi‑day editing in MVP?
- Minimum OS targets (iOS 18? watchOS 11?).
- Keep Core Data (mature) vs SwiftData (simpler) given Watch requirements.

---

## 17) Definition of Done (MVP)
- Add water on either device and see total reflected on both within ~10s.
- Edit/delete reflects on both devices with correct totals.
- Progress ring and widgets/complications update reliably.
- Health write works when enabled; off by default.
- App passes basic accessibility checks and is crash‑free.

