# 무료 개인용 iPhone 설치 준비

사용자가 2026-09-08 무료 설치형 iPhone 앱 개발 재개를 요청했습니다. 기존 공개 GitHub 저장소의 표준 macOS 실행 환경에서 서명 전 IPA를 만들고 Windows AltServer의 직접 IPA 설치 기능으로 본인 iPhone에 설치하는 경로입니다. Apple Developer Program이나 TestFlight를 사용하지 않습니다. 무료 개인 서명은 7일마다 갱신해야 합니다. 현재 GitHub 계정 연결을 기다리고 있으며, 아직 IPA 생성 및 실제 iPhone 검증은 완료하지 않았습니다.

준비된 소스는 기존 Flutter 화면을 사용하는 iOS 프로젝트, Core Motion의 누적 걸음 및 복귀 시 조회, 산책 중 선택적 백그라운드 GPS 설정, 로컬 기록 저장과 산책 체크포인트입니다. 잠금화면 Live Activity에는 실제 센서 기록과 마지막 갱신 시간을 표시하며 갱신이 지연되면 마지막 기록으로 구분합니다. 중복 이벤트, 최종 걸음 반영, 재실행 복원, 권한 거절 등을 포함해 Dart 테스트 34개를 통과했습니다. Swift 및 Xcode 빌드는 아직 실행하지 못했습니다.

`.github/workflows/ios-personal.yml`은 공개 저장소의 표준 macOS 환경만 사용하며 별도 유료 빌드 서비스, 유료 실행 환경, Actions 캐시·아티팩트 저장을 사용하지 않습니다. 빌드 파일은 GitHub 초안 릴리스에 보관합니다. `tool/configure_iphone.rb`가 개인용 번들 식별자와 iOS 16.2 이상용 잠금화면 확장을 설정합니다. 기본 생성 아이콘은 아직 교체 전입니다.

설치 후 실제 아이폰에서 권한 허용·거절·취소, 잠금·복귀, 날짜 변경, 강제 종료, GPS 종료와 배터리 사용을 검증해야 합니다. iOS가 실행을 중단하면 잠금화면 갱신도 지연될 수 있습니다. 강제 종료 중 발생한 걸음은 재실행 시 Core Motion의 보관 범위 내에서 조회하며 실시간 표시를 보장하지 않습니다. Apple 계정 로그인, iPhone 케이블 연결·신뢰·개발자 모드 확인은 사용자가 본인 기기에서 수행해야 합니다. 비밀번호를 채팅이나 소스에 저장하지 않습니다.

이 소스는 완성된 네이티브 앱이 아닙니다. 기존 웹용 Google 로그인·친구 서버 연결·사진 선택·음악·공유 브리지는 아직 네이티브 포팅 전이므로 별도 연결과 검증이 필요합니다. 기존 공개 웹앱에서는 이 기능들이 계속 제공됩니다. iOS가 강제 종료한 앱의 GPS 경로를 소급 생성하거나, 영구 위치 권한을 강제로 부여하는 기능은 없습니다.

참고: [Apple 무료 개인 개발 계정](https://developer.apple.com/help/account/basics/about-your-developer-account), [GitHub Actions 비용 기준](https://docs.github.com/en/billing/concepts/product-billing/github-actions), [AltServer Windows 공식 안내](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows), [AltServer 직접 IPA 설치](https://faq.altstore.io/release-notes/altserver), [Apple Core Motion](https://developer.apple.com/documentation/coremotion/cmpedometer), [Apple 백그라운드 위치](https://developer.apple.com/documentation/corelocation/handling-location-updates-in-the-background).
