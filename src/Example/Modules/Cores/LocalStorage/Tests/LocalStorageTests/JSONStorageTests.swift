import Testing
@testable import LocalStorage
import Foundation

// MARK: - Test Data Models
private struct TestUser: Codable, Equatable, Sendable {
    let name: String
    let age: Int
}

private enum TestKeys: String, StorageKey {
    case userForSave
    case userForExists
    case userForDelete
    case nonExistentKey
    case emptyUser
}

// MARK: - Test Suite
struct JSONStorageTests {

    private var storage: JSONStorage!

    init() {
        storage = JSONStorage()
    }

    // MARK: - Helper
    
    /// 테스트 후 생성된 파일을 정리합니다.
    private func cleanup(forKey key: TestKeys) async {
        do {
            try await storage.delete(forKey: key)
        } catch {
            // 파일이 이미 없거나 삭제에 실패해도 테스트는 계속 진행합니다.
            print("Cleanup failed for key \(key.rawValue), but it might already be deleted.")
        }
    }
    
    // MARK: - Tests

    @Test("데이터 저장 및 로드 성공")
    func saveAndLoadSuccess() async throws {
        // Given
        let user = TestUser(name: "John Doe", age: 30)
        let key = TestKeys.userForSave
        
        // When
        try await storage.save(user, forKey: key)
        let loadedUser: TestUser = try await storage.load(TestUser.self, fromKey: key)
        
        // Then
        #expect(loadedUser == user)
        
        // Cleanup
        await cleanup(forKey: key)
    }

    @Test("파일 존재 여부 확인")
    func fileExists() async throws {
        // Given
        let user = TestUser(name: "Jane Doe", age: 28)
        let key = TestKeys.userForExists
        
        // When
        // 실행 간 잔여 파일로 인한 간헐 실패를 방지하기 위해 선 정리
        await cleanup(forKey: key)
        let existsBeforeSave = await storage.exists(forKey: key)
        try await storage.save(user, forKey: key)
        let existsAfterSave = await storage.exists(forKey: key)
        
        // Then
        #expect(existsBeforeSave == false)
        #expect(existsAfterSave == true)
        
        // Cleanup
        await cleanup(forKey: key)
    }
    
    @Test("파일 삭제")
    func deleteSuccess() async throws {
        // Given
        let user = TestUser(name: "Will Smith", age: 50)
        let key = TestKeys.userForDelete
        // 실행 간 잔여 파일로 인한 간헐 실패를 방지하기 위해 선 정리
        await cleanup(forKey: key)
        try await storage.save(user, forKey: key)
        
        // When
        let existsBeforeDelete = await storage.exists(forKey: key)
        try await storage.delete(forKey: key)
        let existsAfterDelete = await storage.exists(forKey: key)
        
        // Then
        #expect(existsBeforeDelete == true)
        #expect(existsAfterDelete == false)
        
        // Cleanup (이중 안전)
        await cleanup(forKey: key)
    }

    @Test("존재하지 않는 키 로드 시 keyNotFound 에러 발생")
    func loadNonExistentKeyThrowsError() async {
        // Given
        let key = TestKeys.nonExistentKey

        // When & Then
        await #expect(throws: StorageError.self) {
            _ = try await storage.load(TestUser.self, fromKey: key)
        }
    }

    @Test("잘못된 타입으로 디코딩 시 decodingFailed 에러 발생")
    func loadWithWrongTypeThrowsError() async throws {
        // Given
        struct AnotherType: Codable { let id: Int }
        let user = TestUser(name: "Invalid Type", age: 99)
        let key = TestKeys.userForSave
        try await storage.save(user, forKey: key)
        
        // When & Then
        await #expect(throws: StorageError.self) {
            _ = try await storage.load(AnotherType.self, fromKey: key)
        }
        
        // Cleanup
        await cleanup(forKey: key)
    }
    
    @Test("번들에서 JSON 파일 로드 성공")
    func loadFromBundleSuccess() async throws {
        // Given
        let fileName = "Mock"
        
        // When
        let user: TestUser = try await storage.loadFromBundle(
            TestUser.self,
            fileName: fileName,
            in: .module
        )
        
        // Then
        #expect(user.name == "Mock User")
        #expect(user.age == 30)
    }

    @Test("번들에 없는 파일 로드 시 bundleResourceNotFound 에러 발생")
    func loadNonExistentBundleFileThrowsError() async {
        // Given
        let fileName = "NonExistent"
        
        // When & Then
        await #expect(throws: StorageError.self) {
            _ = try await storage.loadFromBundle(
                TestUser.self,
                fileName: fileName,
                in: .module
            )
        }
    }
}

