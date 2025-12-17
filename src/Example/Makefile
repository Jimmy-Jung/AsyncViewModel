# Makefile for AsyncViewModel Project
# Tuist 명령어를 간편하게 실행

.PHONY: help install generate build test clean graph edit setup open

# 기본 타겟
help:
	@echo "AsyncViewModel Tuist Project Makefile"
	@echo ""
	@echo "사용 가능한 명령어:"
	@echo "  make install   - 외부 의존성 설치"
	@echo "  make generate  - Xcode 프로젝트 생성"
	@echo "  make build     - 프로젝트 빌드"
	@echo "  make test      - 테스트 실행"
	@echo "  make clean     - 생성된 파일 정리"
	@echo "  make graph     - 의존성 그래프 시각화"
	@echo "  make edit      - 매니페스트 파일 편집"
	@echo "  make setup     - 최초 설정 (install + generate + open)"
	@echo "  make open      - Xcode에서 워크스페이스 열기"

# 외부 의존성 설치
install:
	@echo "📦 외부 의존성 설치 중..."
	tuist install

# Xcode 프로젝트 생성
generate:
	@echo "🔨 Xcode 프로젝트 생성 중..."
	tuist generate

# 빌드
build:
	@echo "🏗️  빌드 중..."
	tuist build

# 테스트
test:
	@echo "🧪 테스트 실행 중..."
	tuist test

# 정리
clean:
	@echo "🧹 정리 중..."
	tuist clean
	rm -rf *.xcodeproj
	rm -rf *.xcworkspace
	rm -rf .tuist-cache
	rm -rf Derived

# 의존성 그래프
graph:
	@echo "📊 의존성 그래프 생성 중..."
	tuist graph --format png
	@echo "graph.png 파일이 생성되었습니다."

# 매니페스트 편집
edit:
	@echo "✏️  매니페스트 편집 모드..."
	tuist edit

# Xcode 열기
open:
	@echo "🚀 Xcode에서 워크스페이스 열기..."
	open AsyncViewModel.xcworkspace

# 최초 설정
setup: install generate
	@echo "✅ 설정 완료!"
	@echo ""
	@echo "다음 명령어로 Xcode를 열 수 있습니다:"
	@echo "  make open"
	@echo ""
	@echo "또는 직접:"
	@echo "  open AsyncViewModel.xcworkspace"

# 전체 정리 후 재생성
reset: clean setup
	@echo "🔄 프로젝트가 리셋되었습니다."
