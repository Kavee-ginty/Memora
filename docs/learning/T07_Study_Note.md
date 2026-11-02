# T07 Auth Bootstrap Mobile and Guarded Routes

## Contract

T07 owns the Flutter startup/authentication boundary: secure provider-session
restoration, generated session bootstrap, three-step onboarding, authentication
and recovery, the four-root shell, consent recovery, typed route guards,
single-use return locations, bounded token refresh, and safe local sign-out.

Home uses only `SessionBootstrapResponse` data. Mission totals, due dates, XP,
streak projections, reef health, ingestion, mission execution, Progress, and
Profile workflows remain owned by their successor tasks.

## Authentication and storage

Supabase Flutter provides email/password, account creation, recovery, Google
OAuth, session refresh, and auth-state events. Provider session material is
stored through `flutter_secure_storage`; passwords and bootstrap DTOs are never
durable. Refresh failure and sign-out clear provider credentials, account-scoped
state, and pending return locations while preserving approved non-sensitive
onboarding state.

Storage records are versioned and account-scoped where private. Corrupt,
incompatible, or cross-account records are discarded. A process restart restores
only approved local state and performs a fresh server bootstrap.

## Generated API boundary

The mobile repositories call the committed generated Dart `SessionApi` and
`ProfileApi`. Generated DTOs are mapped into immutable Riverpod domain state;
presentation code does not construct API URLs or parse response JSON.

API failures deserialize through the generated `ErrorEnvelope` serializer.
Only allowlisted codes reach domain failures, and raw server/provider messages,
tokens, and authorization headers are never exposed to UI or logs. One failed
authenticated safe read may perform one single-flight refresh and one replay.

## Consent decision

`/consent` displays only server-required policies. Because the API returns policy
identity and version but no policy text or URL, the screen shows a human-readable
policy name, server version, and an explicit acceptance checkbox without
inventing legal content.

Each policy acceptance sends its generated wire identifier as the sole
`accepted_scopes` value and retains one idempotency key while that policy/version
is unresolved. Partial success reloads current consent, version conflicts require
acceptance of the new version, and unknown required policy identifiers fail
closed with Retry and Sign out.

## Routing and guards

The router consumes typed `RouteAccessResult` values in this order: session,
account status, recent authentication, consent, ownership, workflow state, and
active-mission constraints. Public/auth routes remain outside the four-branch
root shell.

Canonical guarded details are `/learning/:subjectId` and
`/missions/:missionId/preview`. IDs are canonical UUIDs before lookup. Subjects
must occur in the bootstrap authorization set; mission previews must match the
bootstrap active mission and an approved previewable state. Missing and
wrong-owner resources share the same not-found response, malformed routes make
no private request, and invalid workflow state returns to a stable parent.

Return locations are allowlisted internal routes, revalidated after bootstrap,
consumed once, and cleared on expiry, sign-out, or account change. Root navigation
is route-driven and preserved with `StatefulShellRoute.indexedStack`.

## Presentation and accessibility

Onboarding uses the exact UI/UX 9.2–9.4 copy. The source mockup's universal
24-hour promise is removed because review timing adapts by learner and material.
Home renders bootstrap-authoritative setup and pending/active presence only.

Authentication forms define logical focus traversal, keep persistent labels,
expose password visibility state, and move focus to one live-region validation
summary after multi-field failure. T07 routes remove transitions when reduced
motion is requested. Widget coverage includes 320 px width, 200% text, combined
responsive states, blocked/retry/offline states, semantics, focus, and 48 px
targets.

Six deterministic 402 × 1001 captures compare the three onboarding steps,
sign-in, create-account, and bootstrap-backed Home with the approved source PNGs.
See `docs/evidence/T07_Visual_Accessibility_Evidence.md`.

## Verification

The mobile format check, analyzer, full widget/unit suite, Android debug build,
and deterministic visual comparisons pass. The OpenAPI and generated-client
drift check passes through the documented backend virtual environment.

Before T07 is marked Done, record a configured Android/iOS run covering OAuth,
session restoration, TalkBack/VoiceOver, keyboard/switch focus, and OS reduced
motion. Then commit, open the task PR with exact command/evidence logs, merge only
after review, and recalculate the task board.
