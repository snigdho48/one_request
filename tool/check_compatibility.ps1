# Analyze, then run the same suite on the Dart VM (Android/iOS/desktop)
# and on Chrome (web). Physical phones are not in this package — run those
# in the consuming app.
$ErrorActionPreference = "Stop"

Write-Host "flutter analyze"
flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "example analyze"
Push-Location example
try {
  flutter pub get
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  flutter analyze
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
  Pop-Location
}

Write-Host "flutter test (VM — Android/iOS/Windows/macOS/Linux Dart)"
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "flutter test -d chrome (web: unit + platform + socket + connectivity)"
flutter test -d chrome test/one_request_platform_test.dart test/one_request_unit_test.dart test/one_socket_test.dart test/one_connectivity_test.dart
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "All platform compatibility gates passed."
