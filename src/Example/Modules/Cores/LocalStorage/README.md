# LocalStorage

`LocalStorage`는 `Codable` 데이터를 로컬 파일 시스템에 손쉽게 저장하고 관리하기 위한 경량 스위프트 패키지입니다. 비동기(Async/Await)를 지원하며 프로토콜 기반으로 설계되어 테스트가 용이합니다.

## ✨ 주요 기능

- **프로토콜 기반 설계**: `FileStorage` 프로토콜을 통해 의존성 주입 및 테스트 대역(Mocking)이 용이합니다.
- **`Codable` 지원**: 모든 `Codable` 타입을 손쉽게 JSON 형식으로 저장하고 불러올 수 있습니다.
- **비동기 API**: `async/await`를 사용하여 현대적인 비동기 코드를 작성할 수 있습니다.
- **파일 관리**: 데이터 저장, 로딩, 파일 존재 여부 확인, 삭제 등 필수적인 파일 관리 기능을 제공합니다.
- **번들 지원**: 앱 번들에 포함된 초기 데이터나 설정 파일을 쉽게 불러올 수 있습니다.
- **경량 및 제로 의존성**: 별도의 외부 라이브러리 의존성이 없습니다.

## 🚀 사용 방법

### 1. `FileStorage` 인스턴스 생성

`DefaultFileStorage`는 `FileStorage` 프로토콜의 기본 구현체입니다.

```swift
import LocalStorage

let fileStorage: FileStorage = DefaultFileStorage()
```

### 2. 저장할 데이터 모델 정의

저장하려는 모든 데이터 타입은 `Codable` 프로토콜을 준수해야 합니다.

```swift
struct UserProfile: Codable, Equatable {
    let id: UUID
    let username: String
    let email: String
    var isPremiumUser: Bool
}
```

### 3. 데이터 저장하기 (`save`)

```swift
let user = UserProfile(
    id: UUID(),
    username: "김토스",
    email: "kim.toss@example.com",
    isPremiumUser: true
)
let fileName = "user_profile.json"

do {
    try await fileStorage.save(user, to: fileName)
    print("✅ 사용자 프로필이 '\(fileName)'에 저장되었습니다.")
} catch {
    print("❌ 저장 실패: \(error.localizedDescription)")
}
```

### 4. 데이터 불러오기 (`load`)

```swift
do {
    let loadedUser = try await fileStorage.load(UserProfile.self, from: fileName)
    print("✅ 불러온 사용자: \(loadedUser.username)")
} catch {
    print("❌ 로딩 실패: \(error.localizedDescription)")
}
```

### 5. 번들에서 데이터 불러오기 (`loadFromBundle`)

앱 번들에 포함된 JSON 파일을 불러올 때 사용합니다. (예: 초기 설정)

```swift
// 'default_settings.json' 파일이 프로젝트 번들에 포함되어 있다고 가정
struct AppSettings: Codable {
    let theme: String
    let version: String
}

do {
    let settings = try await fileStorage.loadFromBundle(
        AppSettings.self,
        fileName: "default_settings.json",
        bundle: .main
    )
    print("✅ 기본 설정 로딩 완료: 테마는 '\(settings.theme)'입니다.")
} catch {
    print("❌ 번들 로딩 실패: \(error.localizedDescription)")
}
```

### 6. 파일 존재 여부 확인 (`fileExists`)

```swift
if await fileStorage.fileExists(fileName) {
    print("👍 파일이 존재합니다.")
} else {
    print("👎 파일이 존재하지 않습니다.")
}
```

### 7. 파일 삭제 (`delete`)

```swift
do {
    try await fileStorage.delete(fileName)
    print("🗑️ 파일이 성공적으로 삭제되었습니다.")
} catch {
    print("❌ 삭제 실패: \(error.localizedDescription)")
}
```

## ⚠️ 에러 처리

- **`FileStorageError.fileNotFound`**: `loadFromBundle` 실행 시 번들에서 파일을 찾지 못하면 발생하는 커스텀 에러입니다.
- **기타 Foundation 에러**: 데이터 직렬화/역직렬화, 파일 읽기/쓰기 실패 시 `Foundation` 프레임워크가 제공하는 상세한 에러(예: `DecodingError`, `CocoaError`)가 발생합니다. 이를 통해 구체적인 실패 원인을 파악할 수 있습니다.

## 📦 의존성 설정

이 모듈은 Tuist 프로젝트의 로컬 패키지로 관리됩니다. 다른 모듈에서 `LocalStorage`를 사용하려면, 해당 모듈의 `Package.swift` 또는 `Project.swift` 파일에 의존성을 추가하세요.

**`Package.swift` 예시:**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyFeature",
    // ...
    dependencies: [
        .package(path: "../Cores/LocalStorage")
    ],
    targets: [
        .target(
            name: "MyFeature",
            dependencies: [
                .product(name: "LocalStorage", package: "LocalStorage")
            ]
        ),
        // ...
    ]
)
```
