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
│   │   ├── AsyncTestStore.swift           # 테스트 도구
│   │   ├── LogLevel.swift                 # 로깅 레벨
│   │   └── SendableError.swift            # Error 래퍼
│   └── AsyncViewModel/                # 공개 통합 모듈
│       └── AsyncViewModel.swift       # Core + Macros re-export
└── Tests/
    └── AsyncViewModelTests/           # Core 테스트
```

## 테스트

```bash
swift test
```

## 자세한 내용

[프로젝트 루트 README](../../README.md)를 참조하세요.
