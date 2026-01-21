//
//  ComplexStateViewModel.swift
//  AsyncViewModelExample
//
//  Created by jimmy on 2025/01/20.
//

import AsyncViewModel
import Foundation

/// 복잡한 State 변경을 테스트하기 위한 ViewModel
///
/// 중첩 구조체, 배열, Optional 등 다양한 타입을 포함한 State로
/// 구조화된 로그 출력을 테스트할 수 있습니다.
@AsyncViewModel(
    logging: .enabled,
    format: .detailed
)
final class ComplexStateViewModel: ObservableObject {
    // MARK: - Types

    enum Input: Equatable, Sendable {
        case updateProfile
        case updateAddress
        case updateSettings
        case addCartItem
        case removeCartItem(id: String)
        case updateQuantity(id: String, quantity: Int)
        case clearCart
        case toggleLoading
        case setError(String?)
        case resetAll
        case simulateAsyncUpdate
        // 3중 중첩 테스트
        case loadCompany
        case addTeamMember(departmentId: String, teamId: String)
        case updateTeamProjectCount(departmentId: String, teamId: String, count: Int)
        case updateCompanyHeadquarters
    }

    enum Action: Equatable, Sendable {
        case profileUpdated(UserProfile)
        case addressUpdated(Address)
        case settingsUpdated(Settings)
        case cartItemAdded(CartItem)
        case cartItemRemoved(id: String)
        case cartItemQuantityUpdated(id: String, quantity: Int)
        case cartCleared
        case loadingToggled
        case errorSet(String?)
        case allReset
        case asyncUpdateStarted
        case asyncUpdateCompleted
        // 3중 중첩 테스트
        case companyLoaded(Company)
        case teamMemberAdded(
            departmentId: String,
            teamId: String,
            member: Company.Department.Team.Member
        )
        case teamProjectCountUpdated(departmentId: String, teamId: String, count: Int)
        case companyHeadquartersUpdated(Address)
    }

    struct State: Equatable, Sendable {
        // 중첩 구조체
        var profile: UserProfile
        var address: Address?
        var settings: Settings

        // 배열
        var cartItems: [CartItem]

        // 3중 중첩 구조체 (Company → Department → Team → Member)
        var company: Company?

        // 기본 타입
        var isLoading: Bool
        var errorMessage: String?
        var lastUpdated: Date?
        var updateCount: Int

        static let initial = State(
            profile: UserProfile(
                name: "홍길동",
                email: "hong@example.com",
                age: 30,
                isPremium: false
            ),
            address: nil,
            settings: Settings(
                isDarkMode: false,
                notificationsEnabled: true,
                language: "ko",
                fontSize: 16
            ),
            cartItems: [],
            company: nil,
            isLoading: false,
            errorMessage: nil,
            lastUpdated: nil,
            updateCount: 0
        )
    }

    enum CancelID: Hashable, Sendable {
        case asyncUpdate
    }

    // MARK: - Properties

    @Published var state: State

    // MARK: - Initialization

    init(initialState: State = .initial) {
        state = initialState
    }

    // MARK: - Transform

    func transform(_ input: Input) -> [Action] {
        switch input {
        case .updateProfile:
            let newProfile = UserProfile(
                name: "김철수",
                email: "kim@example.com",
                age: 25,
                isPremium: true
            )
            return [.profileUpdated(newProfile)]

        case .updateAddress:
            let newAddress = Address(
                city: "서울특별시",
                street: "강남대로 123",
                zipCode: "06000"
            )
            return [.addressUpdated(newAddress)]

        case .updateSettings:
            let newSettings = Settings(
                isDarkMode: !state.settings.isDarkMode,
                notificationsEnabled: !state.settings.notificationsEnabled,
                language: state.settings.language == "ko" ? "en" : "ko",
                fontSize: state.settings.fontSize + 2
            )
            return [.settingsUpdated(newSettings)]

        case .addCartItem:
            let newItem = CartItem(
                id: UUID().uuidString,
                name: "상품 \(state.cartItems.count + 1)",
                price: Int.random(in: 1000 ... 50000),
                quantity: 1
            )
            return [.cartItemAdded(newItem)]

        case let .removeCartItem(id):
            return [.cartItemRemoved(id: id)]

        case let .updateQuantity(id, quantity):
            return [.cartItemQuantityUpdated(id: id, quantity: quantity)]

        case .clearCart:
            return [.cartCleared]

        case .toggleLoading:
            return [.loadingToggled]

        case let .setError(message):
            return [.errorSet(message)]

        case .resetAll:
            return [.allReset]

        case .simulateAsyncUpdate:
            return [.asyncUpdateStarted]

        case .loadCompany:
            return [.companyLoaded(Company.sample)]

        case let .addTeamMember(departmentId, teamId):
            let newMember = Company.Department.Team.Member(
                id: UUID().uuidString,
                name: "신입사원 \(Int.random(in: 1 ... 100))",
                role: "주니어 개발자",
                yearsOfExperience: 0,
                skills: ["Swift"]
            )
            return [.teamMemberAdded(departmentId: departmentId, teamId: teamId, member: newMember)]

        case let .updateTeamProjectCount(departmentId, teamId, count):
            return [
                .teamProjectCountUpdated(departmentId: departmentId, teamId: teamId, count: count),
            ]

        case .updateCompanyHeadquarters:
            let newAddress = Address(
                city: "판교",
                street: "판교역로 235",
                zipCode: "13494",
                coordinates: Address.Coordinates(latitude: 37.3947, longitude: 127.1109)
            )
            return [.companyHeadquartersUpdated(newAddress)]
        }
    }

    // MARK: - Reduce

    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case let .profileUpdated(profile):
            state.profile = profile
            state.updateCount += 1
            state.lastUpdated = Date()
            return [.none]

        case let .addressUpdated(address):
            state.address = address
            state.updateCount += 1
            state.lastUpdated = Date()
            return [.none]

        case let .settingsUpdated(settings):
            state.settings = settings
            state.updateCount += 1
            state.lastUpdated = Date()
            return [.none]

        case let .cartItemAdded(item):
            state.cartItems.append(item)
            state.updateCount += 1
            state.lastUpdated = Date()
            return [.none]

        case let .cartItemRemoved(id):
            state.cartItems.removeAll { $0.id == id }
            state.updateCount += 1
            state.lastUpdated = Date()
            return [.none]

        case let .cartItemQuantityUpdated(id, quantity):
            if let index = state.cartItems.firstIndex(where: { $0.id == id }) {
                state.cartItems[index].quantity = quantity
            }
            state.updateCount += 1
            state.lastUpdated = Date()
            return [.none]

        case .cartCleared:
            state.cartItems = []
            state.updateCount += 1
            state.lastUpdated = Date()
            return [.none]

        case .loadingToggled:
            state.isLoading.toggle()
            state.updateCount += 1
            return [.none]

        case let .errorSet(message):
            state.errorMessage = message
            state.updateCount += 1
            return [.none]

        case .allReset:
            state = .initial
            return [.none]

        case .asyncUpdateStarted:
            state.isLoading = true
            return [
                .sleepThen(id: .asyncUpdate, duration: 1.5, action: .asyncUpdateCompleted),
            ]

        case .asyncUpdateCompleted:
            state.isLoading = false
            state.profile.isPremium = true
            state.address = Address(
                city: "부산광역시",
                street: "해운대로 456",
                zipCode: "48000",
                coordinates: Address.Coordinates(latitude: 35.1796, longitude: 129.0756)
            )
            state.settings.isDarkMode = true
            state.updateCount += 1
            state.lastUpdated = Date()
            return [.none]

        case let .companyLoaded(company):
            state.company = company
            state.updateCount += 1
            state.lastUpdated = Date()
            return [.none]

        case let .teamMemberAdded(departmentId, teamId, member):
            guard var company = state.company,
                  let deptIndex = company.departments.firstIndex(where: { $0.id == departmentId }),
                  let teamIndex = company.departments[deptIndex].teams.firstIndex(where: {
                      $0.id == teamId
                  })
            else {
                return [.none]
            }
            company.departments[deptIndex].teams[teamIndex].members.append(member)
            state.company = company
            state.updateCount += 1
            state.lastUpdated = Date()
            return [.none]

        case let .teamProjectCountUpdated(departmentId, teamId, count):
            guard var company = state.company,
                  let deptIndex = company.departments.firstIndex(where: { $0.id == departmentId }),
                  let teamIndex = company.departments[deptIndex].teams.firstIndex(where: {
                      $0.id == teamId
                  })
            else {
                return [.none]
            }
            company.departments[deptIndex].teams[teamIndex].projectCount = count
            state.company = company
            state.updateCount += 1
            state.lastUpdated = Date()
            return [.none]

        case let .companyHeadquartersUpdated(address):
            guard var company = state.company else {
                return [.none]
            }
            company.headquarters = address
            state.company = company
            state.updateCount += 1
            state.lastUpdated = Date()
            return [.none]
        }
    }
}
