# Dart API client

`memora_api_client/` is generated from the reviewed artifact at
`contracts/openapi/memora-v1.json`. Do not edit generated files by hand.

## Regenerate

From the repository root, with Java 17+ and Dart 3.12+ on `PATH`:

```powershell
python tools/contracts/generate_contracts.py --write
```

The script verifies the pinned OpenAPI generator, exports and validates the
artifact, regenerates the client, runs `build_runner` and formats `lib/`.

To prove the committed client still matches the artifact:

```powershell
python tools/contracts/generate_contracts.py --check
```

The check regenerates into `tools/.cache/contract-check/`, installs with
`dart pub get --enforce-lockfile`, rebuilds, and fails on stale, missing or
unexpected files.

`tools/contracts/templates/pubspec.mustache` overrides the generator's pubspec
template. Generator 7.26.0 with `useOptional: true` emits `optional.dart`
importing `json_annotation` without declaring it as a dependency; the override
adds it. Keep the override aligned with the pinned generator version.

## Lock file

The generated `.gitignore` ignores `pubspec.lock`, but the lock file is
intentionally committed so `--check` and CI can install the exact dependency
graph. Force-add it when staging the client:

```powershell
git add -f contracts/dart/memora_api_client/pubspec.lock
```

## Consume from Flutter

Reference the client by path while it is unpublished:

```yaml
dependencies:
  memora_api_client:
    path: ../contracts/dart/memora_api_client
```

Pass the API base URL through `basePathOverride`:

```dart
final api = MemoraApiClient(basePathOverride: 'https://api.example.test');
```

Feature repositories wrap the generated API and DTOs. Screens and Riverpod
providers must not construct URLs or parse raw error JSON.
