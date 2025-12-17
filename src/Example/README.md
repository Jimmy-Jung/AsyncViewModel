# AsyncViewModel Example

AsyncViewModel 라이브러리를 활용한 계산기 예제 프로젝트입니다.

## 프로젝트 구조

이 프로젝트는 **UIKit**, **SwiftUI**, **ReactorKit**, **TCA** 네 가지 아키텍처 패턴으로 분리된 모듈 구조를 가지고 있습니다.

### 모듈 구성

```
Modules/Features/
├── CalculatorDomain/        # 공통 도메인 로직
│   ├── Entity/              # CalculatorState, CalculatorOperation
│   ├── Error/               # CalculatorError
│   └── UseCase/             # CalculatorUseCase
│
├── UIKitFeature/            # UIKit + AsyncViewModel
│   ├── ViewModel/           # CalculatorUIKitViewModel
│   ├── View/                # Code 기반 + Storyboard 기반 ViewController
│   └── Resources/           # Storyboard 파일
│
├── SwiftUIFeature/          # SwiftUI + AsyncViewModel
│   ├── ViewModel/           # CalculatorSwiftUIViewModel
│   └── View/                # SwiftUI View
│
├── ReactorKitFeature/       # ReactorKit 패턴
│   ├── Reactor/             # CalculatorReactor
│   └── View/                # UIKit ViewController
│
└── TCAFeature/              # TCA (The Composable Architecture)
    ├── Feature/             # CalculatorTCAFeature
    └── View/                # SwiftUI View + UIKit ViewController
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
make setup     # 최초 설정 (의존성 설치 + 프로젝트 생성)
make generate  # 프로젝트 생성
make build     # 빌드
make test      # 테스트 실행
make cache     # 빌드 시간 80% 단축 (바이너리 캐싱)
make clean     # 정리
make graph     # 의존성 그래프 시각화
```

### 📚 자세한 가이드

- [Tuist 전체 가이드](../../README-TUIST.md) - 상세 설명 및 트러블슈팅

## 기능

각 모듈은 동일한 계산기 기능을 구현하며, 다음 기능을 제공합니다:

- 기본 사칙연산 (+, -, ×, ÷)
- 계산 후 5초 자동 클리어
- 에러 처리 (0으로 나누기, 오버플로우 등)
- 입력 검증

## 아키텍처 비교

### UIKitFeature
- **패턴**: UIKit + AsyncViewModel
- **특징**: 
  - Code 기반 UI (PinLayout)
  - Storyboard 기반 UI
  - Combine을 통한 반응형 바인딩

### SwiftUIFeature
- **패턴**: SwiftUI + AsyncViewModel
- **특징**:
  - 선언형 UI
  - @StateObject를 통한 상태 관리
  - SwiftUI 네이티브 컴포넌트 활용

### ReactorKitFeature
- **패턴**: ReactorKit
- **특징**:
  - 단방향 데이터 플로우
  - RxSwift 기반
  - Action-Mutation-State 패턴

### TCAFeature
- **패턴**: The Composable Architecture
- **특징**:
  - 함수형 프로그래밍
  - Effect 기반 부수효과 관리
  - SwiftUI + UIKit 모두 지원
  - 테스트 친화적

## 의존성

- **AsyncViewModelKit**: 비동기 뷰모델 프레임워크
- **ReactorKit**: 반응형 아키텍처 프레임워크
- **ComposableArchitecture**: Point-Free의 TCA 프레임워크
- **RxSwift**: 반응형 프로그래밍
- **PinLayout**: 레이아웃 라이브러리

## 라이센스

이 프로젝트는 예제 목적으로 제공됩니다.

