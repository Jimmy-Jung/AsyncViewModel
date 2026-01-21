# AsyncViewModel Core

Swift Concurrency 기반 단방향 데이터 흐름 ViewModel Core 라이브러리

## 📦 패키지 구조

```
AsyncViewModel/
├── Sources/
│   ├── Core/                          # 핵심 프로토콜 및 타입
│   │   ├── AsyncViewModelProtocol.swift   # 메인 프로토콜
│   │   ├── AsyncViewModelProtocol+Effects.swift  # Effect 처리 로직
│   │   ├── AsyncViewModelProtocol+Logging.swift  # 로깅 로직
│   │   ├── AsyncEffect.swift              # Effect 타입 정의
│   │   ├── AsyncTimer.swift               # 테스트 가능한 타이머
│   │   ├── SendableError.swift            # Error 래퍼
│   │   └── Internal/                      # 내부 유틸리티
│   │       ├── ActionInfoConverter.swift
│   │       └── EffectInfoConverter.swift
│   │
│   ├── Testing/                       # 테스트 도구
│   │   ├── AsyncTestStore.swift           # 테스트 스토어
│   │   └── StateHistoryTracker.swift      # 상태 히스토리 추적
│   │
│   ├── Logging/                       # 로깅 시스템 (v1.3.0+)
│   │   ├── Configuration/                 # 전역 로깅 설정
│   │   ├── Models/                        # 타입 안전 데이터 모델
│   │   ├── Protocol/                      # 로깅 프로토콜
│   │   ├── Implementations/               # 기본 구현체
│   │   └── Utilities/                     # 포맷터 및 유틸리티
│   │
│   └── AsyncViewModel/                # 공개 통합 모듈
│       └── AsyncViewModel.swift       # Core re-export
│
└── Tests/
    └── AsyncViewModelTests/           # 단위 테스트
```

## 🎯 주요 기능

- ✅ **단방향 데이터 흐름** (Unidirectional Data Flow)
- ✅ **Effect 기반 비동기 작업** (.run, .concurrent, .debounce, .throttle)
- ✅ **Swift Concurrency 완벽 지원** (async/await, Actor)
- ✅ **테스트 가능한 타이머** (SystemTimer, TestTimer)
- ✅ **타입 안전 로깅 시스템** (v1.3.0+)
- ✅ **AsyncTestStore로 쉬운 테스트**
- ✅ **StateHistoryTracker로 상태 추적** (v1.3.0+)

## 📚 문서

### 상위 문서 (프로젝트 루트)
- [메인 README](../../README.md) - 전체 가이드 및 사용법
- [내부 아키텍처](../../Documents/01-Internal-Architecture.md) - 설계 원칙 및 구조
- [로깅 시스템 가이드](../../Documents/07-Logging-System-Guide.md) - 로깅 아키텍처 (v1.3.0+)
- [AsyncTestStore 가이드](../../Documents/06-AsyncTestStore-Guide.md) - 테스트 작성법 (v1.3.0+)
- [AsyncTimer 가이드](../../Documents/05-AsyncTimer-And-Lifecycle-Guide.md) - 타이머 사용법

## 🧪 테스트

```bash
# Core 테스트 실행
swift test

# 특정 테스트만 실행
swift test --filter AsyncViewModelTests
swift test --filter AsyncTimerTests
```

## 📦 SPM 통합

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/Jimmy-Jung/AsyncViewModel.git", from: "1.3.0")
]

// Target 의존성
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "AsyncViewModel", package: "AsyncViewModel")
    ]
)
```

## 🔗 관련 패키지

- **AsyncViewModelMacros**: 보일러플레이트 코드 자동 생성 매크로
- **AsyncViewModelExample**: 실전 예제 프로젝트

---

**더 자세한 내용은 [프로젝트 루트 README](../../README.md)를 참조하세요.**
