# Wingstar 프로그램 허브

현재 통합본은 이전 WingStar UI를 유지하면서 최신 걸음·GPS 엔진을 연결합니다. 실행 방법과 데모 범위는 [업그레이드 안내](docs/UPGRADE.md)를 참고하세요.

Premium 월 4,900원 / Membership+ 월 9,900원으로 가격을 확정했습니다. 실제 판매는 PG 가입·계약과 서버 연결 전까지 비활성 상태입니다. 구현 범위와 남은 작업은 [결제 연결 상태](docs/PAYMENTS.md)에 기록합니다.

> **WALK FOR ME, WALK FOR EARTH.**

Wingstar는 대학생 창업동아리에서 개발하는 **걷기 + 명상 + 플로깅 + ESG** 통합 앱 프로젝트입니다.

이 저장소는 하나의 Flutter 코드베이스에서 Android, iOS, Windows, macOS, Linux용 네이티브 앱을 만드는 소스와 공개 배포 자동화 설정을 담습니다.

## 핵심 구조
- **MIND** — 마음 체크와 걷기 명상
- **MOVE** — 걸음·시간·거리 기록
- **CARE** — 플로깅과 Green Mission
- **IMPACT** — ESG 활동 기록과 리워드 확장

## 걸음 감지 MVP
- 3~5초 가속도 센서 자동 보정
- magnitude 중앙값 baseline
- High/Low threshold peak 감지
- 300ms cooldown
- 흔들림 peak 1회당 1 step

## 지원 목표
Android APK/AAB · iPhone/iPad · Windows · macOS · Linux

Windows·Android 네이티브 앱과 아이폰 Safari 홈 화면용 웹앱을 제공합니다. 웹앱은 `flutter build web --release --no-web-resources-cdn --pwa-strategy=none --output=dist`로 만들고 Sites로 배포합니다.

## 공개 다운로드
빌드가 완료되면 아래 Releases 페이지에서 기기별 설치 파일을 받을 수 있습니다.

- Android: `Wingstar-Android.apk`
- Windows: `Wingstar-Windows-x64.zip`
- macOS: `Wingstar-macOS.zip`
- Linux: `Wingstar-Linux-x64.tar.gz`
- iPhone/iPad: Apple 서명 및 TestFlight/App Store 배포 필요

Releases: https://github.com/bhaul0119-hue/Wingstar/releases

공개 릴리스는 **Actions → Wingstar Public Release**에서도 수동으로 다시 만들 수 있습니다.
