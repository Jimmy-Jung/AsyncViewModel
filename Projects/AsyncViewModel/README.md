# AsyncViewModel

Swift Concurrency 기반 단방향 데이터 흐름 ViewModel Core 라이브러리

## 패키지 구조

```
AsyncViewModel/
├── Sources/
│   ├── Core/                          # 내부 코어 모듈
│   │   ├── AsyncViewModelProtocol.swift   # 핵심 프로토콜
│   │   ├── AsyncEffect.swift              # Effect 타입
│   │   ├── AsyncOperation.swift           # Effect 실행 로직
│   │   ├── AsyncTimer.swift               # 테스트 가능한 타이머
│   │   └── SendableError.swift            # Error 래퍼
│   ├── Testing/                       # 테스트 도구
│   │   └── AsyncTestStore.swift           # 테스트 스토어
│   ├── Logging/                       # 로깅 시스템
│   │   ├── Protocol/                      # 로깅 프로토콜
│   │   ├── Configuration/                 # 로깅 설정
│   │   └── Implementations/               # 기본 구현
│   └── AsyncViewModel/                # 공개 통합 모듈
│       └── AsyncViewModel.swift       # Core + Macros re-export
└── Tests/
    └── AsyncViewModelTests/           # Core 테스트
```

## 주요 기능

- ✅ 단방향 데이터 흐름 (Unidirectional Data Flow)
- ✅ Effect 기반 비동기 작업 관리
- ✅ Swift Concurrency 완벽 지원
- ✅ 테스트 가능한 타이머 (AsyncTimer)
- ✅ 의존성 역전 기반 로깅 시스템
- ✅ AsyncTestStore로 쉬운 테스트

## 가이드

- [AsyncTimer 가이드](./ASYNC_TIMER_GUIDE.md) - 테스트 가능한 타이머 사용법
- [아키텍처 문서](./ARCHITECTURE.md) - 프로젝트 설계 원칙

## 테스트

```bash
swift test
```

## 자세한 내용

[프로젝트 루트 README](../../README.md)를 참조하세요.
