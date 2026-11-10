# T10 Visual and Accessibility Evidence

## Scope

This record covers the four T10 ingestion screens: Add material, Material status,
Verify concepts and Learning path preview. The captures use the same 402 × 1001
canvas as the approved source PNGs, load the app's Exo, Inter and Material Icons
fonts, and contain only synthetic fixture data. No learning text, file names,
tokens or account data from a real user are present.

The checked-in captures are Windows-only because Flutter text rasterization is
platform-specific. Behavior, semantics, responsive and reduced-motion tests are
platform-independent and run in CI.

## Visual comparison

| State | Approved source | Reproducible implementation capture | Intentional specification-driven difference |
| --- | --- | --- | --- |
| Add material, empty | [Material.png](../screens/Material.png) | [add_material_empty.png](../../mobile/test/ingestion/goldens/t10/add_material_empty.png) | Retains the subject + source workflow. Uses the detail header, upload card, paste-notes field and temporary-source notice required by UI/UX 9.9. Streak/menu chrome is T15; **Create quiz** is not shown because mission generation belongs to T13. Bottom navigation stays visible. |
| Add material, submitted receipt | [Material.png](../screens/Material.png) | [add_material_received.png](../../mobile/test/ingestion/goldens/t10/add_material_received.png) | Adds the Flow 9.3 receipt state with **View status** and **Back to Learning**. Uploading material never awards XP. |
| Material status, concepts ready | [Material.png](../screens/Material.png) | [material_status_verification_ready.png](../../mobile/test/ingestion/goldens/t10/material_status_verification_ready.png) | Material status is the authoritative re-entry destination (Flow 9.2). The concepts-ready card explains the next step and offers **Verify concepts**. |
| Material status, deletion pending | [Material.png](../screens/Material.png) | [material_status_deletion_pending.png](../../mobile/test/ingestion/goldens/t10/material_status_deletion_pending.png) | Source deletion is rendered separately from knowledge status. Committed knowledge remains previewable while the temporary source is being removed. |
| Verify concepts, review | [Material.png](../screens/Material.png) | [verify_concepts_review.png](../../mobile/test/ingestion/goldens/t10/verify_concepts_review.png) | Adds the UI/UX 9.10 verification step. High-confidence concepts are included; uncertain concepts are marked **Check this**. Confidence is conveyed with text and icons, not colour alone. Bottom navigation is hidden. |
| Verify concepts, empty | [Material.png](../screens/Material.png) | [verify_concepts_empty.png](../../mobile/test/ingestion/goldens/t10/verify_concepts_empty.png) | Adds the UIX-020 empty state. **Preview learning path** is disabled and the reason is visible. |
| Learning path preview, ready | [Material.png](../screens/Material.png) | [path_preview_ready.png](../../mobile/test/ingestion/goldens/t10/path_preview_ready.png) | Adds the UI/UX 9.11 preview before commit. **Start first mission** is deferred because `first_mission` stays null until T13. Bottom navigation is hidden. |
| Learning path preview, blocked | [Material.png](../screens/Material.png) | [path_preview_blocked.png](../../mobile/test/ingestion/goldens/t10/path_preview_blocked.png) | Renders the server `can_commit=false` reason. **Add to my learning path** is disabled; **Edit concepts** remains available. |
| Learning path preview, committed with deletion pending | [Material.png](../screens/Material.png) | [path_preview_committed_deletion_pending.png](../../mobile/test/ingestion/goldens/t10/path_preview_committed_deletion_pending.png) | The committed state renders the ready path directly. Temporary-source cleanup is shown separately and does not imply the knowledge was deleted. **Start first mission** remains disabled with an explanation until T13. |

The subject-selection concept in [Material-1.png](../screens/Material-1.png) is
retained as an accessible menu rather than a modal list that obscures the source
workflow, per UI/UX 15.

## Producing screenshots for PR evidence

From `mobile/` on Windows:

```powershell
flutter test --update-goldens test/ingestion/ingestion_visual_evidence_test.dart
flutter test test/ingestion/ingestion_visual_evidence_test.dart
```

The first command regenerates the nine checked-in PNGs under
`test/ingestion/goldens/t10/`; the second compares them without writing. Attach
those PNGs, or the comparison output, to the pull request. Do not regenerate
goldens on macOS or Linux and commit them: font rasterization differs and would
create platform-only churn.

The harness pumps each screen at 402 × 1001 logical pixels with a device pixel
ratio of 1, wraps it in a keyed `RepaintBoundary`, and captures it with
`matchesGoldenFile`. The shared fixtures in
`test/ingestion/support/ingestion_evidence_fixtures.dart` supply the synthetic
session, update snapshots, candidates and text-only picker/upload fakes.

## Automated accessibility and responsive evidence

| Requirement | Evidence |
| --- | --- |
| One primary heading per screen | `ingestion_accessibility_test.dart` asserts exactly one `Semantics(header: true)` on Add material, Material status, Verify concepts and Learning path preview, and checks the expected title label. |
| Progress is announced | The Material status processing state exposes `LinearProgressIndicator` semantics labelled **Extracting concepts**. |
| Confidence is never colour-only | The review capture and test include **High confidence**, **Medium confidence** and **Low confidence** text plus distinct icons, and each band is discoverable by semantics label. |
| 320 px width and 200% text | Each of the four screens is pumped at 320 × 640 with `TextScaler.linear(2.0)`. The tests assert the primary heading and primary action remain present and that no layout exception or overflow is thrown. |
| Reduced motion | `buildRoutePage` returns `NoTransitionPage` when `MediaQuery.disableAnimations` is true. `MemoraSkeleton` renders without an `AnimatedBuilder` under the same preference. |
| Bottom-navigation visibility | Existing route tests assert bottom navigation on Add material and Material status and its absence on Verify concepts and Learning path preview. |
| Offline recovery | Add material, Material status, Verify concepts and Learning path preview tests assert the offline banner, a single retry affordance, preserved input where applicable, and disabled network actions. |
| Deletion pending | Material status and Learning path preview tests assert the separate **Temporary source** card, pending copy, and that committed knowledge remains usable. |
| Empty, loading and error states | The state-matrix tests assert skeletons, empty-concept copy, disabled actions with reasons, and recoverable error copy with retry. |

## UI/UX 13 state-matrix mapping

| Screen | Empty | Loading | Success | Recoverable error | Blocking error | Offline | Deletion pending |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Add material | No source selected | Draft initialization covered by existing controller/widget tests | Submitted receipt | Create failure with retry and preserved text | Unsupported or rejected source blocks extraction | Offline create banner and disabled extraction | Not applicable before an update exists |
| Material status | Not applicable; every update has a durable state | Status skeleton and UIX-019 timeout view | Concepts ready, committed, failed, expired, deleted and unknown states | Refresh/retry failure banner | Missing/wrong-owner update shows shared not-found | Offline banner and retry | Separate temporary-source card |
| Verify concepts | No concepts to check; preview disabled | Candidate skeleton | Review list with confidence bands | Load/refresh failure with retry | Invalid update state explains and redirects to status | Offline banner; preview disabled | Not applicable on this screen |
| Learning path preview | No previewable concepts produces the blocked reason | Preview skeleton | Ready preview or committed ready state | Load/commit failure with retry | Wrong-state update explains and redirects to status | Offline banner; commit disabled | Separate temporary-source card; committed path remains ready |

The state-matrix tests live in `ingestion_accessibility_test.dart` under the
`UI/UX 13 state matrix` group. Per-state rendering and navigation coverage also
exists in `test/ingestion/widgets/` and `test/ingestion/ingestion_routes_test.dart`.

## Review findings closed in this pass

- Verify concepts no longer shows a second **Try again** inside its critical
  banner when the persistent offline banner is already offering retry.
- Material status initial-load failure follows the same rule: the offline banner
  owns retry, and the body keeps **Back to Learning** as its recovery action.
- The accessibility and widget tests assert one retry affordance in the offline
  state, so a future duplicate control fails the suite.

## Known deviations and follow-ups

- **Start first mission** is disabled with an explanation because `first_mission`
  remains null until T13. No mission route is opened from T10.
- The 9.8 Learning path screen remains a placeholder outside T10.
- Real offline reconciliation belongs to T22; T10 derives connectivity from the
  failed request and keeps the last safe state.
- The source PNGs show streak/menu chrome and a **Create quiz** action. Those are
  intentionally omitted because engagement is T15 and mission generation is T13.
- Manual TalkBack and physical-device walkthroughs are not claimed in this
  record. T27 owns cross-feature manual assistive-technology QA; the automated
  semantics, responsive and reduced-motion tests above are the T10 gate evidence.

## Local verification record

| Command | Result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib/src/features/ingestion/presentation/material_status_screen.dart lib/src/features/ingestion/presentation/verify_concepts_screen.dart test/ingestion/widgets/material_status_screen_test.dart test/ingestion/ingestion_accessibility_test.dart test/ingestion/ingestion_visual_evidence_test.dart test/ingestion/support/ingestion_evidence_fixtures.dart` | Pass; 6 files, 0 changed |
| `flutter analyze` | Pass; no issues found |
| `flutter test test/ingestion/ingestion_visual_evidence_test.dart --update-goldens` | Pass; nine goldens generated |
| `flutter test test/ingestion/ingestion_visual_evidence_test.dart` | Pass; nine golden comparisons |
| `flutter test test/ingestion/ingestion_accessibility_test.dart` | Pass; 16 accessibility, responsive, reduced-motion and state-matrix tests |
| `flutter test test/ingestion` | Pass; 243 tests |
| `flutter test` | Pass; 467 tests |
| `python tools/contracts/generate_contracts.py --check` | Pass; OpenAPI and generated Dart client are drift-clean |

A repo-wide `dart format --output=none --set-exit-if-changed lib test` still
reports pre-existing line-wrap drift in seven T10 files that this commit does not
touch. Formatting those files is deferred to the Commit 10 bug-hunt pass so this
commit stays limited to evidence and the duplicate-retry fix it covers.
