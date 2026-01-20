//
//  ComplexStateView.swift
//  AsyncViewModelExample
//
//  Created by jimmy on 2025/01/20.
//

import AsyncViewModel
import SwiftUI

/// 복잡한 State 변경을 테스트하는 뷰
///
/// 다양한 State 변경을 트리거하고 콘솔에서 구조화된 로그를 확인할 수 있습니다.
struct ComplexStateView: View {
    @StateObject private var viewModel = ComplexStateViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 로그 안내
                logInfoSection

                // 현재 상태 표시
                currentStateSection

                // 액션 버튼들
                actionButtonsSection
            }
            .padding()
        }
        .navigationTitle("복합 상태 테스트")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.state.isLoading {
                loadingOverlay
            }
        }
    }

    // MARK: - Log Info Section

    private var logInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("구조화된 로그 테스트", systemImage: "doc.text.magnifyingglass")
                .font(.headline)
                .foregroundColor(.primary)

            Text("버튼을 누르면 State가 변경되고, 콘솔에서 구조화된 로그를 확인할 수 있습니다.")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("LogFormat 설정에 따라 compact, standard, detailed 형식으로 출력됩니다.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Current State Section

    private var currentStateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("현재 상태")
                .font(.headline)

            // 프로필
            stateCard(title: "프로필", icon: "person.fill") {
                StateRow(label: "이름", value: viewModel.state.profile.name)
                StateRow(label: "이메일", value: viewModel.state.profile.email)
                StateRow(label: "나이", value: "\(viewModel.state.profile.age)")
                StateRow(label: "프리미엄", value: viewModel.state.profile.isPremium ? "✓" : "✗")
            }

            // 주소
            stateCard(title: "주소", icon: "location.fill") {
                if let address = viewModel.state.address {
                    StateRow(label: "도시", value: address.city)
                    StateRow(label: "거리", value: address.street)
                    StateRow(label: "우편번호", value: address.zipCode)
                } else {
                    Text("주소 없음")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 설정
            stateCard(title: "설정", icon: "gearshape.fill") {
                StateRow(label: "다크모드", value: viewModel.state.settings.isDarkMode ? "ON" : "OFF")
                StateRow(label: "알림", value: viewModel.state.settings.notificationsEnabled ? "ON" : "OFF")
                StateRow(label: "언어", value: viewModel.state.settings.language)
                StateRow(label: "폰트 크기", value: "\(viewModel.state.settings.fontSize)")
            }

            // 장바구니
            stateCard(title: "장바구니 (\(viewModel.state.cartItems.count)개)", icon: "cart.fill") {
                if viewModel.state.cartItems.isEmpty {
                    Text("비어 있음")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.state.cartItems) { item in
                        HStack {
                            Text(item.name)
                                .font(.caption)
                            Spacer()
                            Text("₩\(item.price) × \(item.quantity)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    HStack {
                        Text("총액")
                            .font(.caption.bold())
                        Spacer()
                        Text("₩\(viewModel.state.cartItems.reduce(0) { $0 + $1.totalPrice })")
                            .font(.caption.bold())
                    }
                }
            }

            // 회사 (3중 중첩)
            companySection

            // 메타 정보
            stateCard(title: "메타 정보", icon: "info.circle.fill") {
                StateRow(label: "로딩 중", value: viewModel.state.isLoading ? "예" : "아니오")
                StateRow(label: "에러", value: viewModel.state.errorMessage ?? "없음")
                StateRow(label: "업데이트 횟수", value: "\(viewModel.state.updateCount)")
                if let lastUpdated = viewModel.state.lastUpdated {
                    StateRow(label: "마지막 업데이트", value: dateFormatter.string(from: lastUpdated))
                }
            }
        }
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Text("액션 버튼")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 개별 업데이트
            VStack(spacing: 12) {
                Text("개별 업데이트")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ComplexStateActionButton(
                        title: "프로필 변경",
                        icon: "person.fill",
                        color: .blue
                    ) {
                        viewModel.send(.updateProfile)
                    }

                    ComplexStateActionButton(
                        title: "주소 추가",
                        icon: "location.fill",
                        color: .green
                    ) {
                        viewModel.send(.updateAddress)
                    }

                    ComplexStateActionButton(
                        title: "설정 변경",
                        icon: "gearshape.fill",
                        color: .orange
                    ) {
                        viewModel.send(.updateSettings)
                    }

                    ComplexStateActionButton(
                        title: "상품 추가",
                        icon: "cart.badge.plus",
                        color: .purple
                    ) {
                        viewModel.send(.addCartItem)
                    }
                }
            }

            // 3중 중첩 테스트
            VStack(spacing: 12) {
                Text("3중 중첩 구조 테스트")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ComplexStateActionButton(
                    title: "회사 데이터 로드",
                    icon: "building.2.fill",
                    color: .indigo,
                    isFullWidth: true
                ) {
                    viewModel.send(.loadCompany)
                }

                if viewModel.state.company != nil {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ComplexStateActionButton(
                            title: "본사 이전",
                            icon: "building.columns.fill",
                            color: .brown
                        ) {
                            viewModel.send(.updateCompanyHeadquarters)
                        }

                        ComplexStateActionButton(
                            title: "iOS팀 신입",
                            icon: "person.badge.plus",
                            color: .mint
                        ) {
                            viewModel.send(.addTeamMember(departmentId: "dev", teamId: "ios"))
                        }

                        ComplexStateActionButton(
                            title: "프로젝트 +1",
                            icon: "folder.badge.plus",
                            color: .teal
                        ) {
                            let currentCount = viewModel.state.company?.departments
                                .first(where: { $0.id == "dev" })?
                                .teams.first(where: { $0.id == "ios" })?
                                .projectCount ?? 0
                            viewModel.send(.updateTeamProjectCount(
                                departmentId: "dev",
                                teamId: "ios",
                                count: currentCount + 1
                            ))
                        }

                        ComplexStateActionButton(
                            title: "UX팀 신입",
                            icon: "person.badge.plus",
                            color: .pink
                        ) {
                            viewModel.send(.addTeamMember(departmentId: "design", teamId: "ux"))
                        }
                    }
                }
            }

            // 복합 업데이트
            VStack(spacing: 12) {
                Text("복합 업데이트")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ComplexStateActionButton(
                    title: "비동기 다중 업데이트 (1.5초 후)",
                    icon: "arrow.triangle.2.circlepath",
                    color: .cyan,
                    isFullWidth: true
                ) {
                    viewModel.send(.simulateAsyncUpdate)
                }

                ComplexStateActionButton(
                    title: "에러 상태 설정",
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    isFullWidth: true
                ) {
                    viewModel.send(.setError("네트워크 연결 실패"))
                }
            }

            // 리셋
            VStack(spacing: 12) {
                Text("초기화")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    ComplexStateActionButton(
                        title: "장바구니 비우기",
                        icon: "cart.badge.minus",
                        color: .gray
                    ) {
                        viewModel.send(.clearCart)
                    }

                    ComplexStateActionButton(
                        title: "전체 초기화",
                        icon: "arrow.counterclockwise",
                        color: .gray
                    ) {
                        viewModel.send(.resetAll)
                    }
                }
            }
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)

                Text("업데이트 중...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(16)
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func stateCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                content()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }

    // MARK: - Company Section (3중 중첩)

    @ViewBuilder
    private var companySection: some View {
        stateCard(title: "회사 (3중 중첩)", icon: "building.2.fill") {
            if let company = viewModel.state.company {
                // 1단계: 회사 정보
                VStack(alignment: .leading, spacing: 8) {
                    StateRow(label: "회사명", value: company.name)
                    StateRow(label: "설립년도", value: "\(company.foundedYear)")
                    StateRow(label: "본사", value: "\(company.headquarters.city) \(company.headquarters.street)")
                    StateRow(
                        label: "좌표",
                        value: "(\(String(format: "%.4f", company.headquarters.coordinates.latitude)), \(String(format: "%.4f", company.headquarters.coordinates.longitude)))"
                    )

                    // 2단계: 부서 목록
                    ForEach(company.departments) { dept in
                        Divider()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("📁 \(dept.name)")
                                .font(.caption.bold())
                            StateRow(label: "예산", value: "₩\(formatNumber(dept.budget))")

                            // 3단계: 팀 목록
                            ForEach(dept.teams) { team in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("  👥 \(team.name) (프로젝트: \(team.projectCount)개)")
                                        .font(.caption)
                                        .foregroundColor(.primary)

                                    // 4단계: 멤버 목록
                                    ForEach(team.members) { member in
                                        Text("    • \(member.name) - \(member.role) (\(member.yearsOfExperience)년)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.leading, 8)
                    }
                }
            } else {
                Text("회사 데이터 없음")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - StateRow

private struct StateRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption.monospaced())
                .foregroundColor(.primary)
        }
    }
}

// MARK: - ComplexStateActionButton

private struct ComplexStateActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var isFullWidth: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))

                Text(title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(10)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ComplexStateView()
    }
}
