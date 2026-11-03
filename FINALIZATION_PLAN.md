# Primary goal

Deliver the existing Jamemoon Jomeh Flutter game as a cohesive, stable, release-candidate-quality Android experience while preserving the completed redesign and game rules, closing only the verified gaps, and reporting any owner-dependent store work honestly.

## Phase 0 — Documentation and baseline discovery

**How this serves the primary goal:** It prevents regressions and invented APIs by grounding every remaining change in the repository's established patterns and measured baseline.

### What to implement

- Treat the existing design system and lifecycle/session architecture as the source of truth.
- Record the verified baseline: `flutter analyze` clean, 75 tests passing, and release APK build successful.

### Documentation references

- `UPGRADE_PLAN.md` and `IMPLEMENTATION_PLAN.md` for product scope and acceptance criteria.
- `lib/app/theme/`, `lib/core/widgets/party_button.dart`, `lib/core/widgets/party_dialog.dart`, and `lib/core/widgets/game_lifecycle_guard.dart` for reusable patterns.
- Flutter `WidgetsBindingObserver`, `MediaQuery.disableAnimationsOf`, and `Navigator.pushNamed` API documentation.

### Verification checklist

- Confirm the repository is still on the same dirty working tree without discarding pre-existing changes.
- Confirm analyzer, tests, and release build baseline results are recorded.

### Anti-pattern guards

- Do not create a second component/theme system.
- Do not replace the existing `RoundClock`, lifecycle, session, or routing contracts.
- Do not claim device performance or store integration without measurement.

## Phase 1 — Honest purchase and release behavior

**How this serves the primary goal:** Users must never see simulated commerce presented as a real purchase path in a release candidate.

### What to implement

- Copy the existing `UnavailablePurchaseService` behavior into default dependency registration until a real Cafe Bazaar billing adapter and credentials exist.
- Preserve entitlement data and existing purchase abstractions so a production adapter can be added without UI rewrites.
- Add tests proving unavailable billing cannot grant an entitlement.

### Documentation references

- `lib/core/services/purchase_service.dart` for the declared purchase interface and unavailable implementation.
- `lib/app/di/service_locator.dart` for dependency registration.
- `test/core_upgrade_test.dart` for purchase-safety test patterns.

### Verification checklist

- Purchase availability is false under default registration.
- A failed/unavailable purchase never writes a purchased pack.
- Existing purchase entitlements survive reset behavior.

### Anti-pattern guards

- Do not simulate successful purchases in production/default DI.
- Do not erase purchased entitlement keys.
- Do not invent Cafe Bazaar APIs or credentials.

## Phase 2 — Small-screen and system-inset hardening

**How this serves the primary goal:** Every page remains usable on compact Android screens and under status/navigation bars.

### What to implement

- Copy the repository's established `SafeArea` + scrollable/responsive page pattern into the audited pages that still render directly inside `AnimatedPartyBackground`.
- Preserve visual hierarchy and existing shared components; make targeted layout changes only.
- Add representative compact-height and text-scale widget tests for the corrected flows.

### Documentation references

- Existing responsive patterns in `lib/features/home/presentation/home_page.dart` and game pages.
- Target pages: settings, shop, team setup, tournament lobby, custom cards, lucky wheel, and random picker.
- `test/party_redesign_test.dart` for responsive widget-test patterns.

### Verification checklist

- Target pages render at compact phone dimensions without overflow exceptions.
- Primary actions remain reachable with enlarged text.
- Back navigation and dialogs continue to behave as before.

### Anti-pattern guards

- Do not wrap fixed content blindly in nested scroll views.
- Do not introduce raw colors, buttons, cards, or duplicate dialogs.
- Do not weaken existing semantics or reduced-motion support.

## Phase 3 — Regression, device smoke test, and release evidence

**How this serves the primary goal:** The result is backed by reproducible evidence rather than visual inspection or unmeasured claims.

### What to implement

- Run formatting, static analysis, the full test suite, design capture tests, and release APK build.
- Install and launch the built APK on the connected Android device when available, then perform a bounded smoke test and inspect runtime logs for crashes.
- Update `UPGRADE_PLAN.md` execution status with actual results and explicit owner-dependent blockers.

### Documentation references

- `tool/capture_design.dart` for real-widget visual captures.
- `test/` for regression coverage.
- `README.md` for the documented release build command.

### Verification checklist

- `flutter analyze` exits successfully.
- All automated tests pass.
- Design capture test completes and artifacts exist.
- `flutter build apk --release` succeeds and APK metadata/hash are recorded.
- Device smoke test results are reported as pass/fail/untested, never inferred.

### Anti-pattern guards

- Do not mark application ID, release signing, real billing, FPS, or RAM as complete without owner inputs or measurements.
- Do not commit, push, or discard the user's dirty working tree.
- Do not call an unexecuted scenario successful.

