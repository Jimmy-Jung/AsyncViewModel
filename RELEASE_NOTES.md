# AsyncViewModel 1.0.0 릴리스 노트

## 🎉 첫 번째 안정 버전 출시!

AsyncViewModel의 첫 번째 안정 버전 1.0.0을 발표합니다!

## 📅 릴리스 정보

- **버전**: 1.0.0
- **릴리스 브랜치**: `release/1.0.0`
- **날짜**: 2024년 12월 (예정)
- **상태**: Release Candidate

## 🌟 주요 기능

### AsyncViewModel Core
- ✅ **단방향 데이터 흐름**: 예측 가능한 상태 관리
- ⚡ **Swift Concurrency 네이티브**: async/await 완벽 지원
- 🔄 **선언적 Effect 시스템**: 복잡한 비동기 작업을 선언적으로 표현
- 🎯 **타입 세이프**: Equatable & Sendable 보장

### AsyncViewModelMacros
- 🪄 **@AsyncViewModel 매크로**: 보일러플레이트 코드 자동 생성
- 🔒 **@MainActor 자동 추가**: 모든 멤버와 extension에 자동 적용
- ⚙️ **로깅 설정 지원**: isLoggingEnabled, logLevel 파라미터

### 테스트 지원
- 🧪 **AsyncTestStore**: 비동기 테스트를 쉽게 작성
- ⏱️ **wait(for:)**: 특정 상태 변화 대기
- 📊 **액션 추적**: 실행된 액션 기록 및 검증

### 로깅 통합
- 📝 **TraceKit 통합**: 강력한 로깅 시스템 내장
- 🎚️ **로그 레벨**: verbose, debug, info, warning, error, fatal
- 👀 **관찰자 훅**: 액션, 상태 변경, Effect, 성능 메트릭

## 📦 설치

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Jimmy-Jung/AsyncViewModel.git", from: "1.0.0")
]
```

### Xcode

1. **File → Add Package Dependencies...**
2. URL: `https://github.com/Jimmy-Jung/AsyncViewModel.git`
3. Version: 1.0.0 이상

## 📚 문서

- [README](https://github.com/Jimmy-Jung/AsyncViewModel#readme)
- [Internal Architecture](https://github.com/Jimmy-Jung/AsyncViewModel/blob/main/Documents/01-Internal-Architecture.md)
- [Logger Configuration](https://github.com/Jimmy-Jung/AsyncViewModel/blob/main/Documents/02-Logger-Configuration.md)
- [GitHub Actions Guide](https://github.com/Jimmy-Jung/AsyncViewModel/blob/main/Documents/03-GitHub-Actions-Guide.md)
- [Release Checklist](https://github.com/Jimmy-Jung/AsyncViewModel/blob/main/Documents/04-Release-Checklist.md)

## 🎯 예제 프로젝트

프로젝트에 포함된 예제:
- ✅ SwiftUI + AsyncViewModel (권장)
- ✅ UIKit + AsyncViewModel
- ✅ ReactorKit 비교
- ✅ TCA 비교

## 🔄 업그레이드 가이드

이 버전이 첫 릴리스이므로 업그레이드 가이드가 없습니다.

## ⚠️ Breaking Changes

이 버전이 첫 릴리스이므로 Breaking Changes가 없습니다.

## 🐛 알려진 이슈

현재 알려진 이슈가 없습니다.

## 🙏 감사의 말

AsyncViewModel은 다음 프로젝트들에서 영감을 받았습니다:
- [TCA (The Composable Architecture)](https://github.com/pointfreeco/swift-composable-architecture)
- [ReactorKit](https://github.com/ReactorKit/ReactorKit)
- [Redux](https://redux.js.org/)

그리고 프로젝트에 기여해주신 모든 분들께 감사드립니다! 🎉

## 📝 변경 로그

### Added
- AsyncViewModel Core 패키지
- AsyncViewModelMacros 패키지
- @AsyncViewModel 매크로
- AsyncTestStore 테스팅 유틸리티
- TraceKit 로깅 통합
- 완전한 문서화
- 예제 프로젝트 (SwiftUI, UIKit, ReactorKit, TCA)
- GitHub Actions CI/CD 파이프라인
- 이슈 및 PR 템플릿
- 기여 가이드
- 보안 정책

### Changed
- 없음 (첫 릴리스)

### Deprecated
- 없음

### Removed
- 없음

### Fixed
- 없음

### Security
- 없음

## 🚀 다음 버전 계획 (v1.1.0)

- [ ] SwiftUI Preview 지원 개선
- [ ] 추가 Effect 타입 (retry, timeout)
- [ ] 성능 최적화
- [ ] 더 많은 예제 추가
- [ ] 영문 문서

## 💬 피드백

버그 리포트, 기능 제안, 질문은 다음 채널을 이용해주세요:
- [Issues](https://github.com/Jimmy-Jung/AsyncViewModel/issues)
- [Discussions](https://github.com/Jimmy-Jung/AsyncViewModel/discussions)

---

**Made with ❤️ and ☕ in Seoul, Korea**

[⬆ 맨 위로](#asyncviewmodel-100-릴리스-노트)
