# AsyncViewModel 1.0.0 릴리스 체크리스트

## 📋 릴리스 전 체크리스트

### ✅ 코드 품질

- [ ] 모든 테스트 통과
  ```bash
  cd src/AsyncViewModel && swift test
  cd src/AsyncViewModelMacros && swift test
  ```
- [ ] SwiftLint 경고 없음
  ```bash
  swiftlint
  ```
- [ ] 빌드 성공 확인
  ```bash
  cd src/AsyncViewModel && swift build -c release
  cd src/AsyncViewModelMacros && swift build -c release
  ```
- [ ] Example 프로젝트 빌드 및 실행 확인

### ✅ 문서

- [x] README.md 오픈소스 표준에 맞게 업데이트
  - [x] 헤더 및 뱃지
  - [x] "왜 AsyncViewModel인가?" 섹션
  - [x] 프레임워크 비교 표
  - [x] 설치 가이드 (1.0.0)
  - [x] 로드맵
  - [x] 커뮤니티 섹션
  - [x] 라이선스 전문
  - [x] 감사의 말
- [x] CONTRIBUTING.md 작성
- [x] SECURITY.md 작성
- [x] GitHub Actions 가이드 작성
- [ ] API 문서 생성 (DocC)
  ```bash
  cd src/AsyncViewModel
  swift package generate-documentation
  ```

### ✅ GitHub 설정

- [x] .github/workflows/ci.yml 설정
- [x] .github/workflows/release.yml 설정
- [x] .github/workflows/documentation.yml 설정
- [x] Issue 템플릿 (bug_report.yml, feature_request.yml)
- [x] PR 템플릿
- [x] CODEOWNERS 설정
- [x] Dependabot 설정
- [x] 라벨 설정 (labels.yml)
- [ ] GitHub Discussions 활성화
- [ ] GitHub Topics 설정
  - swift
  - ios
  - macos
  - swiftui
  - uikit
  - viewmodel
  - architecture
  - swift-concurrency
  - async-await
  - state-management

### ✅ 버전 관리

- [ ] Package.swift 버전 확인
- [ ] 의존성 버전 확인 (TraceKit)
- [ ] CHANGELOG.md 작성
  ```markdown
  # Changelog
  
  ## [1.0.0] - 2024-XX-XX
  
  ### Added
  - 초기 릴리스
  - AsyncViewModel Core 패키지
  - AsyncViewModelMacros 패키지
  - @AsyncViewModel 매크로
  - AsyncTestStore 테스팅 유틸리티
  - TraceKit 로깅 통합
  - 완전한 문서화
  - 예제 프로젝트
  ```

### ✅ 릴리스 준비

- [ ] main 브랜치로 병합
- [ ] 태그 생성
  ```bash
  git tag -a 1.0.0 -m "Release 1.0.0"
  ```
- [ ] 태그 푸시 (자동 릴리스 트리거)
  ```bash
  git push origin 1.0.0
  ```
- [ ] GitHub Release 확인 및 수정
- [ ] Release Notes 작성

### ✅ 배포 후

- [ ] Swift Package Index 등록
  - https://swiftpackageindex.com/add-a-package
- [ ] 블로그 포스트 작성 (선택)
- [ ] 소셜 미디어 공유 (선택)
- [ ] README 뱃지 동작 확인
  - CI 뱃지
  - Codecov 뱃지
  - Release 뱃지
  - SPM 뱃지

## 📝 릴리스 노트 템플릿

```markdown
# AsyncViewModel 1.0.0 🎉

AsyncViewModel의 첫 번째 안정 버전을 발표합니다!

## 🌟 주요 기능

- ✅ **단방향 데이터 흐름**: 예측 가능한 상태 관리
- ⚡ **Swift Concurrency 네이티브**: async/await 완벽 지원
- 🧪 **테스트 용이성**: AsyncTestStore로 간편한 테스트
- 🔄 **선언적 Effect 시스템**: 비동기 작업을 선언적으로 표현
- 🪄 **매크로 지원**: @AsyncViewModel 매크로로 보일러플레이트 자동 생성
- 📦 **제로 의존성**: 외부 라이브러리 불필요 (TraceKit만 포함)
- 🎯 **타입 세이프**: Equatable & Sendable 보장

## 📦 설치

### Swift Package Manager

\`\`\`swift
dependencies: [
    .package(url: "https://github.com/Jimmy-Jung/AsyncViewModel.git", from: "1.0.0")
]
\`\`\`

## 📚 문서

- [README](https://github.com/Jimmy-Jung/AsyncViewModel#readme)
- [Internal Architecture](https://github.com/Jimmy-Jung/AsyncViewModel/blob/main/Documents/01-Internal-Architecture.md)
- [Logger Configuration](https://github.com/Jimmy-Jung/AsyncViewModel/blob/main/Documents/02-Logger-Configuration.md)
- [GitHub Actions Guide](https://github.com/Jimmy-Jung/AsyncViewModel/blob/main/Documents/03-GitHub-Actions-Guide.md)

## 🎯 예제

프로젝트에 포함된 예제:
- SwiftUI + AsyncViewModel
- UIKit + AsyncViewModel
- ReactorKit 비교
- TCA 비교

## 🙏 감사의 말

이 프로젝트는 TCA, ReactorKit, Redux에서 영감을 받았습니다.

## 🐛 버그 리포트 & 기능 제안

이슈나 제안이 있으시면 [Issues](https://github.com/Jimmy-Jung/AsyncViewModel/issues)에 남겨주세요!
```

## 🚀 릴리스 프로세스

### 1. 최종 확인

```bash
# 1. 모든 변경사항 커밋
git status
git add .
git commit -m "chore: prepare for 1.0.0 release"

# 2. main 브랜치로 병합
git checkout main
git merge feature/example --no-ff
git push origin main

# 3. 테스트 실행
cd src/AsyncViewModel && swift test
cd src/AsyncViewModelMacros && swift test
```

### 2. 태그 생성 및 푸시

```bash
# 1. 태그 생성
git tag -a 1.0.0 -m "Release 1.0.0

AsyncViewModel 1.0.0 - First stable release

Features:
- AsyncViewModel Core package
- AsyncViewModelMacros package
- @AsyncViewModel macro
- AsyncTestStore testing utility
- TraceKit logging integration
- Complete documentation
- Example projects"

# 2. 태그 확인
git tag -l -n9 1.0.0

# 3. 태그 푸시 (자동으로 Release Workflow 실행)
git push origin 1.0.0
```

### 3. Release 확인

1. GitHub Actions 탭에서 Release Workflow 실행 확인
2. Releases 페이지에서 자동 생성된 릴리스 확인
3. Release Notes 확인 및 필요시 편집

### 4. Swift Package Index 등록

1. https://swiftpackageindex.com/add-a-package 방문
2. Repository URL 입력: `https://github.com/Jimmy-Jung/AsyncViewModel`
3. Submit

### 5. 홍보 (선택)

- [ ] Twitter/X 게시
- [ ] LinkedIn 게시
- [ ] 개인 블로그 포스트
- [ ] iOS 커뮤니티 공유

## 📊 릴리스 후 모니터링

### 1주차

- [ ] GitHub Issues 모니터링
- [ ] GitHub Discussions 확인
- [ ] Swift Package Index 인덱싱 확인
- [ ] 문서 피드백 확인

### 1개월차

- [ ] 사용 통계 확인 (GitHub Insights)
- [ ] Star/Fork 수 확인
- [ ] 커뮤니티 피드백 수집
- [ ] 버그 수정 계획 (1.0.1)
- [ ] 다음 버전 계획 (1.1.0)

## 🔧 트러블슈팅

### Release Workflow가 실패하는 경우

1. **빌드 실패:**
   - 로컬에서 `swift build -c release` 실행
   - 에러 메시지 확인 및 수정
   - 다시 태그 생성 (1.0.1)

2. **테스트 실패:**
   - 로컬에서 `swift test` 실행
   - 실패한 테스트 수정
   - 다시 태그 생성

3. **태그 삭제 및 재생성:**
   ```bash
   # 로컬 태그 삭제
   git tag -d 1.0.0
   
   # 원격 태그 삭제
   git push origin :refs/tags/1.0.0
   
   # 수정 후 다시 태그 생성
   git tag -a 1.0.0 -m "Release 1.0.0"
   git push origin 1.0.0
   ```

### Codecov 업로드 실패

1. GitHub Secrets에 CODECOV_TOKEN 추가
2. Codecov 웹사이트에서 토큰 확인
3. fail_ci_if_error: false이므로 CI는 통과함

---

**준비되셨나요? 체크리스트를 완료하고 1.0.0을 세상에 공개하세요! 🚀**
