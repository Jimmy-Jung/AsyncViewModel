//
//  ComplexStateModels.swift
//  AsyncViewModelExample
//
//  Created by jimmy on 2025/01/20.
//

import Foundation

// MARK: - UserProfile

/// 사용자 프로필 정보
struct UserProfile: Equatable, Sendable {
    var name: String
    var email: String
    var age: Int
    var isPremium: Bool
}

// MARK: - Address

/// 주소 정보 (2단계 중첩 - 좌표 포함)
struct Address: Equatable, Sendable {
    var city: String
    var street: String
    var zipCode: String
    var coordinates: Coordinates

    /// 좌표 정보
    struct Coordinates: Equatable, Sendable {
        var latitude: Double
        var longitude: Double
    }

    /// 좌표 없이 주소만 생성 (기본 좌표 사용)
    init(city: String, street: String, zipCode: String) {
        self.city = city
        self.street = street
        self.zipCode = zipCode
        coordinates = Coordinates(latitude: 0, longitude: 0)
    }

    /// 좌표 포함 전체 생성
    init(city: String, street: String, zipCode: String, coordinates: Coordinates) {
        self.city = city
        self.street = street
        self.zipCode = zipCode
        self.coordinates = coordinates
    }
}

// MARK: - Settings

/// 설정 정보
struct Settings: Equatable, Sendable {
    var isDarkMode: Bool
    var notificationsEnabled: Bool
    var language: String
    var fontSize: Int
}

// MARK: - CartItem

/// 장바구니 아이템
struct CartItem: Equatable, Sendable, Identifiable {
    let id: String
    var name: String
    var price: Int
    var quantity: Int

    var totalPrice: Int { price * quantity }
}

// MARK: - Company (3중 중첩 타입)

/// 회사 정보 (1단계)
///
/// 3중 중첩 구조: Company → Department → Team → Member
struct Company: Equatable, Sendable {
    var name: String
    var foundedYear: Int
    var headquarters: Address
    var departments: [Department]

    /// 부서 정보 (2단계)
    struct Department: Equatable, Sendable, Identifiable {
        let id: String
        var name: String
        var budget: Int
        var teams: [Team]

        /// 팀 정보 (3단계)
        struct Team: Equatable, Sendable, Identifiable {
            let id: String
            var name: String
            var members: [Member]
            var projectCount: Int

            /// 멤버 정보 (4단계 - 최하위)
            struct Member: Equatable, Sendable, Identifiable {
                let id: String
                var name: String
                var role: String
                var yearsOfExperience: Int
                var skills: [String]
            }
        }
    }
}

// MARK: - Company Sample Data

extension Company {
    static let sample = Company(
        name: "테크 주식회사",
        foundedYear: 2020,
        headquarters: Address(
            city: "서울",
            street: "테헤란로 123",
            zipCode: "06000",
            coordinates: Address.Coordinates(latitude: 37.5665, longitude: 126.9780)
        ),
        departments: [
            Department(
                id: "dev",
                name: "개발부",
                budget: 1_000_000_000,
                teams: [
                    Department.Team(
                        id: "ios",
                        name: "iOS 팀",
                        members: [
                            Department.Team.Member(
                                id: "m1",
                                name: "김개발",
                                role: "시니어 개발자",
                                yearsOfExperience: 7,
                                skills: ["Swift", "UIKit", "SwiftUI"]
                            ),
                            Department.Team.Member(
                                id: "m2",
                                name: "이주니어",
                                role: "주니어 개발자",
                                yearsOfExperience: 2,
                                skills: ["Swift", "SwiftUI"]
                            ),
                        ],
                        projectCount: 3
                    ),
                    Department.Team(
                        id: "android",
                        name: "Android 팀",
                        members: [
                            Department.Team.Member(
                                id: "m3",
                                name: "박안드",
                                role: "리드 개발자",
                                yearsOfExperience: 5,
                                skills: ["Kotlin", "Jetpack Compose"]
                            ),
                        ],
                        projectCount: 2
                    ),
                ]
            ),
            Department(
                id: "design",
                name: "디자인부",
                budget: 500_000_000,
                teams: [
                    Department.Team(
                        id: "ux",
                        name: "UX 팀",
                        members: [
                            Department.Team.Member(
                                id: "m4",
                                name: "최디자인",
                                role: "UX 디자이너",
                                yearsOfExperience: 4,
                                skills: ["Figma", "Sketch", "Prototyping"]
                            ),
                        ],
                        projectCount: 5
                    ),
                ]
            ),
        ]
    )
}
