# Analyze, then run the same suite on the Dart VM (Android/iOS/desktop)
# and on Chrome (web). Physical phones are not in this package — run those
# in the consuming app.
$ErrorActionPreference = "Stop"

Write-Host "flutter analyze"
flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "flutter test (VM — Android/iOS/Windows/macOS/Linux Dart)"
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "flutter test --platform chrome (web: unit + platform suite)"
flutter test --platform chrome test/one_request_platform_test.dart test/one_request_unit_test.dart
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "All platform compatibility gates passed."
