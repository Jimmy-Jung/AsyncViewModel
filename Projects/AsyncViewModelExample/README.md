# AsyncViewModel Example

AsyncViewModel 라이브러리를 활용한 실전 예제 프로젝트입니다.

## 프로젝트 구조

이 프로젝트는 AsyncViewModel의 핵심 기능을 보여주는 다양한 예제로 구성되어 있습니다.

### 주요 예제

```
Features/
├── Calculator/              # 계산기 예제
│   ├── ViewModel/          # AsyncViewModel 패턴
│   ├── View/               # SwiftUI View
│   └── Domain/             # 비즈니스 로직
│
├── Timer/                   # 타이머 관련 예제
│   ├── Countdown/          # 카운트다운 타이머
│   ├── AutoRefresh/        # 자동 새로고침
│   ├── Stopwatch/          # 스톱워치
│   └── MultiTimer/         # 다중 타이머 관리
│
└── Examples/                # 기타 예제
    ├── LoggerIntegrationExample.swift    # 로깅 통합
    └── HandleErrorExample.swift          # 에러 처리
```

## 실행 방법

### 🚀 빠른 시작

```bash
# 1. Tuist 설치 (최초 1회)
curl -Ls https://install.tuist.io | bash

# 2. Example 디렉토리로 이동
cd src/Example

# 3. 의존성 설치 및 프로젝트 생성
make setup

# 또는 수동으로:
tuist install      # 외부 의존성 설치
tuist generate     # Xcode 프로젝트 생성

# 4. Xcode에서 실행
open AsyncViewModel.xcworkspace
```

### ⚡ Makefile 명령어

```bash
# 프로젝트 설정
make setup     # 최초 설정 (의존성 설치 + 프로젝트 생성)
make generate  # 프로젝트 생성
make build     # 빌드

# 테스트
make test         # Example 테스트 실행
make test-all     # 모든 패키지 테스트 (Core + Macros + Example)
make test-core    # AsyncViewModel Core 테스트만
make test-macros  # AsyncViewModelMacros 테스트만

# 기타
make clean     # 정리
make graph     # 의존성 그래프 시각화
```

### 📚 자세한 가이드

- [Tuist 전체 가이드](../../README-TUIST.md) - 상세 설명 및 트러블슈팅

## 주요 기능

### 계산기 (Calculator)
AsyncViewModel의 기본 패턴을 보여주는 계산기 구현:
- 기본 사칙연산 (+, -, ×, ÷)
- 계산 후 5초 자동 클리어 (AsyncTimer 활용)
- 에러 처리 (0으로 나누기, 오버플로우)
- 입력 검증

### 타이머 예제 (Timer)
AsyncTimer의 다양한 활용 사례:

#### 1. Countdown Timer
- 카운트다운 타이머 구현
- 일시정지/재개 기능
- 완료 시 알림

#### 2. Auto Refresh
- 주기적 자동 새로고침
- 새로고침 간격 설정
- 수동 새로고침 지원

#### 3. Stopwatch
- 스톱워치 기능
- 랩 타임 기록
- 시간 포맷팅

#### 4. Multi Timer
- 여러 타이머 동시 관리
- 각 타이머 독립 제어
- 타이머 추가/삭제

### 기타 예제

#### Logger Integration
- TraceKit 로깅 통합
- 커스텀 로거 구현
- 로그 레벨 관리

#### Error Handling
- `.runCatchingError` 활용
- 에러를 상태로 관리
- 사용자 친화적 에러 표시

## 의존성

- **AsyncViewModel**: 비동기 뷰모델 프레임워크 (Core + Macros)
- **TraceKit**: 로깅 라이브러리 (선택적)

## 라이센스

이 프로젝트는 예제 목적으로 제공됩니다.

