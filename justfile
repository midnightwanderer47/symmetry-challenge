default:
    @just --list

[working-directory: 'frontend']
get:
    flutter pub get

[working-directory: 'frontend']
analyze:
    flutter analyze

[working-directory: 'frontend']
format:
    dart format .

[working-directory: 'frontend']
check-format:
    dart format --output=none --set-exit-if-changed .

[working-directory: 'frontend']
test:
    flutter test

[working-directory: 'frontend']
ci:
    just test
    just analyze
    just check-format

[working-directory: 'frontend']
test-integration:
    flutter test integration_test/app_test.dart --dart-define=USE_EMULATOR=true

[working-directory: 'frontend']
run *ARGS:
    flutter run {{ ARGS }}

[working-directory: 'frontend']
codegen:
    dart run build_runner build --delete-conflicting-outputs

[working-directory: 'frontend']
codegen-watch:
    dart run build_runner watch --delete-conflicting-outputs

[working-directory: 'frontend']
clean:
    flutter clean

[working-directory: 'frontend']
build-apk *ARGS:
    flutter build apk {{ ARGS }}

[working-directory: 'frontend']
build-ios *ARGS:
    flutter build ios {{ ARGS }}
