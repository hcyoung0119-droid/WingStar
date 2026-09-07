WingStar 개인 아이폰 설치용 개발 빌드입니다. App Store 및 TestFlight용이 아닙니다.

`WingStar-iPhone-unsigned.ipa`는 컴파일된 앱이며 아직 Apple 개인 서명이 없습니다. Windows의 AltServer에서 본인의 무료 Apple 계정으로 서명 후 설치해야 합니다. 비밀번호나 인증서를 이 저장소에 저장하지 않습니다. 무료 서명의 유효기간은 7일이며 만료 전에 같은 계정으로 갱신해야 합니다.

이 빌드는 실제 아이폰 검증 전입니다. 걸음수는 Core Motion의 누적 기록을 읽고, 산책 복귀 및 재실행 때 중복 없이 합산하도록 구성했습니다. GPS 거리 기록은 사용자가 켠 산책에서만 실행합니다. 기기의 강제 종료나 권한 철회를 무시할 수는 없습니다.

기존 웹앱은 https://wingstar-care.use-loing-ai.chatgpt.site/ 에서 계속 사용할 수 있습니다. 현재 네이티브 전환 중인 기능과 실기기 검증 상태는 `docs/ios-preparation.md`에 기록합니다.
