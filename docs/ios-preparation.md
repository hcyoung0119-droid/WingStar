# iPhone 개발 준비 — 진행 보류

사용자가 2026-09-08 비용 없이 현재 카카오톡 공유 웹앱을 유지하기로 선택하여, 이 작업은 별도 브랜치에만 보관합니다. 공개 사이트에는 배포하지 않았습니다. 설치 파일, TestFlight 링크, 실제 iPhone 검증 결과는 없습니다.

준비된 소스는 기존 Flutter 화면을 사용하는 iOS 프로젝트, Core Motion의 누적 걸음 및 복귀 시 조회, 산책 중 선택적 백그라운드 GPS 설정, 로컬 기록 저장과 산책 체크포인트입니다. 중복 이벤트, 최종 걸음 반영, 재실행 복원, 권한 거절 등 관련 Dart 테스트 12개를 통과했습니다. Swift 및 Xcode 빌드는 실행하지 못했습니다.

출시 전에 Mac 또는 macOS 빌드 환경에서 컴파일하고 실제 아이폰에서 권한 허용·거절·취소, 잠금·복귀, 날짜 변경, 강제 종료, GPS 종료와 배터리 사용을 검증해야 합니다. 현재 `com.example.wingstar` 식별자와 생성된 기본 아이콘도 출시용이 아닙니다. TestFlight 배포에는 사용자 소유 Apple Developer 계정과 서명이 필요합니다.

이 소스는 완성된 네이티브 앱이 아닙니다. 기존 웹용 Google 로그인·친구 서버 연결·사진 선택·음악·공유 브리지는 아직 네이티브 포팅 전이므로 별도 연결과 검증이 필요합니다. 기존 공개 웹앱에서는 이 기능들이 계속 제공됩니다. iOS가 강제 종료한 앱의 GPS 경로를 소급 생성하거나, 영구 위치 권한을 강제로 부여하는 기능은 없습니다.

참고: [Apple Core Motion](https://developer.apple.com/documentation/coremotion/cmpedometer), [Apple 백그라운드 위치](https://developer.apple.com/documentation/corelocation/handling-location-updates-in-the-background), [Flutter iOS 개발 환경](https://docs.flutter.dev/platform-integration/ios/setup).
