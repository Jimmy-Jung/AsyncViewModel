# GitHub Actions & CI/CD 설정 가이드

AsyncViewModel 프로젝트의 GitHub Actions 및 CI/CD 설정에 대한 완전한 가이드입니다.

## 목차

- [개요](#개요)
- [워크플로우](#워크플로우)
- [설정 파일](#설정-파일)
- [뱃지 설정](#뱃지-설정)
- [릴리스 프로세스](#릴리스-프로세스)
- [CI/CD 최적화](#cicd-최적화)
- [문제 해결](#문제-해결)

## 개요

AsyncViewModel 프로젝트는 다음과 같은 자동화를 제공합니다:

- ✅ 자동 빌드 및 테스트 (CI)
- 📦 자동 릴리스 생성
- 📊 코드 커버리지 리포팅
- 📚 문서 자동 생성
- 🔄 의존성 자동 업데이트
- 🏷️ 이슈 및 PR 템플릿

## 워크플로우

### 1. CI Workflow (`.github/workflows/ci.yml`)

**트리거 조건 (최적화됨):**
1. **Pull Request**: `main`, `develop` 브랜치로의 PR 생성/업데이트 시 (주요 검증)
2. **수동 실행**: workflow_dispatch를 통한 수동 트리거
3. **직접 Push**: `main`, `develop` 브랜치로의 직접 push (hotfix 등)
   - ✅ **중복 방지**: PR merge로 인한 push는 자동으로 스킵됨 (이미 PR에서 검증됨)

> **최적화 포인트**: PR에서 이미 테스트를 통과한 코드는 main merge 후 재실행하지 않아 CI 시간과 비용을 절약합니다.

**실행 Job (모든 Job에 중복 방지 조건 적용):**

#### Job 1: 통합 빌드 및 테스트 (Core + Macros)
```yaml
- macOS 15 러너 사용
- AsyncViewModel 패키지 릴리스 빌드
- 테스트 실행 (코드 커버리지 활성화, 병렬 실행)
- Codecov에 커버리지 리포트 업로드
```

#### Job 2: 패키지 검증
```yaml
- Package.swift 구조 검증
- 의존성 트리 확인
```

#### Job 3: 코드 스타일 (SwiftLint)
```yaml
- SwiftLint 설치 (없는 경우)
- 코드 스타일 검사 실행 (--strict 모드)
```

#### Job 4: Example 프로젝트 빌드 (Tuist)
```yaml
- Tuist 설치
- 의존성 설치
- Xcode 프로젝트 생성
- Example 앱 빌드 (iOS 16 Pro 시뮬레이터)
```

**예상 실행 시간:** 
- PR: 약 10-15분
- Merge 후: 스킵됨 (0분) ⚡️

### 2. Release Workflow (`.github/workflows/release.yml`)

**트리거 조건:**
- 버전 태그 푸시: `1.0.0`, `1.0.0-beta.1`, `1.0.0-alpha.1`

**실행 단계:**
```yaml
1. 소스 체크아웃
2. Xcode 16.1 선택
3. 버전 태그에서 버전 추출
4. AsyncViewModel 패키지 빌드 및 테스트
5. AsyncViewModelMacros 패키지 빌드 및 테스트
6. 이전 태그부터의 변경 내역 생성
7. GitHub Release 생성
   - 설치 가이드 포함
   - 문서 링크 포함
   - 변경 내역 포함
   - alpha/beta 태그는 prerelease로 표시
```

**릴리스 예제:**
```bash
# 정식 릴리스
git tag 1.0.0
git push origin 1.0.0

# Beta 릴리스
git tag 1.0.0-beta.1
git push origin 1.0.0-beta.1

# Alpha 릴리스
git tag 1.0.0-alpha.1
git push origin 1.0.0-alpha.1
```

### 3. Documentation Workflow (`.github/workflows/documentation.yml`)

**트리거 조건:**
- `main` 브랜치에 push (소스 파일 또는 문서 변경 시)
- 수동 실행 (workflow_dispatch)

**실행 단계:**
```yaml
1. DocC를 사용하여 AsyncViewModel 문서 생성
2. DocC를 사용하여 AsyncViewModelMacros 문서 생성
3. GitHub Pages에 배포
```

**문서 URL:**
- AsyncViewModel: `https://jimmy.github.io/AsyncViewModel/docs/`
- AsyncViewModelMacros: `https://jimmy.github.io/AsyncViewModel/macros/`

## 설정 파일

### 1. SwiftLint (`.swiftlint.yml`)

프로젝트의 코드 스타일을 자동으로 검사합니다.

**포함 경로:**
- `src/AsyncViewModel/Sources`
- `src/AsyncViewModelMacros/Sources`
- `src/Example/AsyncViewModelExample/Sources`

**제외 경로:**
- `.build`, `.swiftpm`
- 테스트 파일
- Tuist 생성 파일

**주요 규칙:**
- 식별자 길이: 최소 1자, 최대 60자
- 함수 파라미터: 최대 6개 (경고), 8개 (에러)
- MainActor 사용 권장 (커스텀 규칙)

### 2. Codecov (`.codecov.yml`)

코드 커버리지를 추적하고 리포트합니다.

**목표:**
- 프로젝트 전체: 80% 이상
- 패치 (새로운 코드): 80% 이상

**플래그:**
- `asyncviewmodel`: AsyncViewModel 패키지
- `macros`: AsyncViewModelMacros 패키지

**제외 경로:**
- 테스트 파일
- Example 프로젝트
- 생성된 파일 (`*.generated.swift`, `*.pb.swift`)

### 3. Dependabot (`.github/dependabot.yml`)

의존성을 자동으로 업데이트합니다.

**업데이트 주기:** 매주 월요일

**업데이트 대상:**
- GitHub Actions
- Swift 패키지 (AsyncViewModel)
- Swift 패키지 (AsyncViewModelMacros)

**PR 제한:** 패키지당 최대 5개

### 4. CODEOWNERS (`.github/CODEOWNERS`)

코드 리뷰어를 자동으로 할당합니다.

**소유자:**
- 전체 프로젝트: @jimmy
- AsyncViewModel 패키지: @jimmy
- AsyncViewModelMacros 패키지: @jimmy
- 문서: @jimmy
- CI/CD: @jimmy

## Issue 및 PR 템플릿

### Issue 템플릿

#### 1. Bug Report (`.github/ISSUE_TEMPLATE/bug_report.yml`)

**포함 항목:**
- 버그 설명
- 재현 방법
- 예상 동작 vs 실제 동작
- 코드 예제
- 환경 정보 (패키지, 버전, 플랫폼, OS, Xcode, Swift)

#### 2. Feature Request (`.github/ISSUE_TEMPLATE/feature_request.yml`)

**포함 항목:**
- 해결하려는 문제
- 제안하는 해결 방법
- 대안
- API 예제
- Breaking Change 여부

### PR 템플릿

#### 1. 기본 템플릿 (`.github/PULL_REQUEST_TEMPLATE.md`)

**체크리스트:**
- [ ] Swift API Design Guidelines 준수
- [ ] 모든 테스트 통과
- [ ] 테스트 추가
- [ ] 문서 업데이트
- [ ] Breaking Change 확인
- [ ] SwiftLint 경고 없음

#### 2. 자동화 PR 템플릿 (`.github/PULL_REQUEST_TEMPLATE/automated_pr.md`)

Dependabot이나 자동화 워크플로우가 생성하는 PR용 템플릿

## 뱃지 설정

README에 다음 뱃지가 추가되었습니다:

```markdown
[![CI](https://github.com/jimmy/AsyncViewModel/actions/workflows/ci.yml/badge.svg)](https://github.com/jimmy/AsyncViewModel/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/jimmy/AsyncViewModel/branch/main/graph/badge.svg)](https://codecov.io/gh/jimmy/AsyncViewModel)
```

**사용 가능한 추가 뱃지:**
- Release: `[![Release](https://img.shields.io/github/v/release/jimmy/AsyncViewModel)](https://github.com/jimmy/AsyncViewModel/releases)`
- Swift Package Manager: `[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)`

## 릴리스 프로세스

### 1. 버전 결정

Semantic Versioning을 따릅니다:
- **Major (1.0.0)**: Breaking Changes
- **Minor (1.1.0)**: 새로운 기능 (하위 호환)
- **Patch (1.0.1)**: 버그 수정

### 2. 변경 사항 정리

릴리스 전에 변경 사항을 정리합니다:

```bash
# 이전 태그부터의 변경 사항 확인
git log v1.0.0..HEAD --oneline
```

### 3. 태그 생성 및 푸시

```bash
# 태그 생성
git tag -a 1.1.0 -m "Release 1.1.0"

# 태그 푸시
git push origin 1.1.0
```

### 4. 자동 릴리스 생성

태그를 푸시하면 Release Workflow가 자동으로:
1. 패키지 빌드 및 테스트
2. 변경 내역 생성
3. GitHub Release 생성
4. 설치 가이드 포함

### 5. 릴리스 확인

GitHub Releases 페이지에서 생성된 릴리스를 확인합니다:
- 변경 내역이 정확한지 확인
- 설치 가이드가 올바른지 확인
- 필요시 수동으로 Release Notes 편집

## 보안 정책

보안 취약점은 `.github/SECURITY.md`에 정의된 절차에 따라 리포트해주세요:

1. 공개 이슈로 리포트하지 말 것
2. GitHub Security Advisories 사용
3. 24시간 이내 확인
4. 72시간 이내 초기 평가
5. 심각도에 따라 7-30일 이내 패치

## 기여 가이드

프로젝트에 기여하려면 `.github/CONTRIBUTING.md`를 참고하세요:

- 브랜치 전략
- 코딩 규칙
- 커밋 컨벤션
- PR 프로세스
- 테스트 작성 가이드

## 라벨 설정

`.github/labels.yml`에 정의된 라벨:

**Priority:**
- `priority: critical`, `priority: high`, `priority: medium`, `priority: low`

**Type:**
- `bug`, `enhancement`, `documentation`, `performance`, `refactoring`, `testing`

**Component:**
- `core`, `macros`, `logger`, `example`

**Status:**
- `status: blocked`, `status: in progress`, `status: needs review`, `status: needs discussion`

**Other:**
- `dependencies`, `breaking change`, `good first issue`, `help wanted`

라벨을 적용하려면:
```bash
# GitHub CLI 사용
gh label create "priority: high" --color "ff6b6b" --description "High priority issue"
```

또는 GitHub 웹 인터페이스에서 수동으로 생성할 수 있습니다.

## CI/CD 최적화

### 중복 실행 방지

AsyncViewModel 프로젝트는 CI 비용과 시간을 절약하기 위해 다음과 같이 최적화되었습니다:

**문제점:**
- PR에서 이미 빌드/테스트를 실행했는데, main 브랜치로 merge 후 다시 실행됨
- 불필요한 중복 실행으로 인한 시간 낭비 (약 10-15분)
- GitHub Actions 무료 플랜의 분당 제한 소모

**해결 방법:**
모든 CI job에 다음 조건 추가:
```yaml
if: |
  github.event_name == 'pull_request' || 
  github.event_name == 'workflow_dispatch' ||
  (github.event_name == 'push' && !contains(github.event.head_commit.message, 'Merge pull request'))
```

**동작 방식:**
1. ✅ **PR 생성/업데이트**: 전체 CI 실행 (주요 검증)
2. ✅ **수동 실행**: workflow_dispatch로 언제든지 실행 가능
3. ✅ **Hotfix push**: main/develop에 직접 push 시 CI 실행
4. ⏭️ **PR merge**: "Merge pull request" 메시지를 감지하여 자동 스킵

**효과:**
- ⚡️ PR merge 후 CI 실행 시간 0분 (완전 스킵)
- 💰 GitHub Actions 분당 제한 절약
- 🎯 PR에서만 집중적으로 검증

### 추가 최적화 팁

1. **Concurrency 설정**: 같은 브랜치의 새 push가 있으면 이전 실행 취소
   ```yaml
   concurrency:
     group: ${{ github.workflow }}-${{ github.ref }}
     cancel-in-progress: true
   ```

2. **병렬 테스트**: `swift test --parallel`로 테스트 속도 향상

3. **캐싱**: 향후 Swift 패키지 의존성 캐싱 추가 가능
   ```yaml
   - uses: actions/cache@v4
     with:
       path: .build
       key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
   ```

## 문제 해결

### CI가 실패하는 경우

1. **빌드 실패:**
   - 로컬에서 `swift build` 실행
   - Xcode 버전 확인 (16.1 이상)

2. **테스트 실패:**
   - 로컬에서 `swift test` 실행
   - 실패한 테스트 확인 및 수정

3. **SwiftLint 실패:**
   - 로컬에서 `swiftlint` 실행
   - 경고 수정

### Codecov 업로드 실패

1. Codecov 토큰 확인
2. GitHub Secrets에 `CODECOV_TOKEN` 설정
3. 커버리지 파일 경로 확인

### Release가 생성되지 않는 경우

1. 태그 형식 확인 (`1.0.0` 형식)
2. GitHub Actions 권한 확인
3. `GITHUB_TOKEN` 권한 확인

## 추가 설정

### Codecov 토큰 설정

1. [Codecov](https://codecov.io/)에서 프로젝트 생성
2. 토큰 복사
3. GitHub Repository Settings > Secrets > Actions
4. `CODECOV_TOKEN` 추가

### GitHub Pages 활성화

1. Repository Settings > Pages
2. Source: GitHub Actions 선택
3. Documentation Workflow 실행

---

모든 설정이 완료되었습니다! 🎉

변경 사항을 커밋하고 푸시하면 CI가 자동으로 실행됩니다.
