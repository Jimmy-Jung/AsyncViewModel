# Network Module

Network 모듈은 Moya 기반의 타입 안전한 네트워킹 솔루션을 제공합니다. 비동기 처리, 자동 재시도, 세분화된 에러 처리를 지원하여 안정적인 네트워크 통신을 구현할 수 있습니다.

## 📋 요구사항

- **iOS**: 15.0+
- **Swift**: 5.10+
- **의존성**: Moya 15.0.0+

## 🏗 아키텍처

Network 모듈은 다음과 같은 구조로 구성되어 있습니다:

```
Network/
├── Core/                    # 핵심 프로토콜 및 타입
│   ├── APIRequest.swift     # API 요청 프로토콜
│   ├── AccessTokenAuthorizable.swift  # 인증 프로토콜
│   ├── AuthorizationType.swift        # 인증 타입
│   └── Parameterable.swift            # 파라미터 프로토콜
├── Service/                 # 네트워크 서비스
│   ├── NetworkService.swift           # 네트워크 서비스 인터페이스
│   ├── ResponseProcessor.swift        # 응답 처리기
│   └── NetworkError.swift             # 네트워크 에러 정의
├── Dtos/                    # 데이터 전송 객체
│   └── Common/              # 공통 DTO
└── Requests/                # API 요청 구현체
    └── Coffee/
```

## 🔧 핵심 컴포넌트

### NetworkService

비동기 네트워크 요청을 처리하는 프로토콜입니다.

```swift
public protocol NetworkService {
    func request<DTO: Codable, ErrorDTO: ErrorResponseDto>(
        _ request: APIRequest,
        decodeType: DTO.Type,
        errorType: ErrorDTO.Type
    ) async throws -> DTO
}
```

**주요 기능:**
- 비동기 네트워크 요청 처리
- 자동 재시도 로직 (최대 2회, 선형 증가)
- 타입 안전한 데이터 디코딩
- 세분화된 에러 처리

### APIRequest

API 요청을 정의하는 프로토콜입니다.

```swift
public protocol APIRequest: TargetType, AccessTokenAuthorizable {
    var baseURL: URL { get }
    var path: String { get }
    var originalPath: String { get }
    var method: Moya.Method { get }
    var task: Task { get }
    var headers: [String: String]? { get }
}
```

### ResponseProcessor

HTTP 응답을 처리하고 데이터를 디코딩합니다.

**상태 코드별 처리:**
- `200-299`: 성공 응답 디코딩
- `400-499`: 클라이언트 에러 처리
- `500-599`: 서버 에러 처리
- 기타: 미처리 상태 코드 에러

## 🚀 사용 예시

### 1. API 요청 정의

```swift
import Network
import Moya

public struct GetCoffeesRequest: APIRequest {
    public typealias Response = [CoffeeDTO]
    
    public init(type: CoffeeType) {
        self.type = type
    }
    
    public var baseURL: URL {
        return URL(string: "https://api.sampleapis.com")!
    }

    public var originalPath: String {
        return "/coffee/\(type.rawValue)"
    }

    public var method: Moya.Method {
        return .get
    }

    public var task: Task {
        return .requestPlain
    }
}
```

### 2. 네트워크 서비스 사용

```swift
import Network

class CoffeeRepository {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = DefaultNetworkService()) {
        self.networkService = networkService
    }
    
    func fetchIcedCoffees() async throws -> [CoffeeDTO] {
        let request = GetCoffeesRequest(type: .iced)
        return try await networkService.request(
            request,
            decodeType: [CoffeeDTO].self,
            errorType: DefaultErrorResponseDto.self
        )
    }
}
```

### 3. 커스텀 에러 응답 처리

```swift
// 커스텀 에러 DTO 정의
struct CustomErrorDto: ErrorResponseDto {
    let message: String
    let errorCode: String
}

// 사용
try await networkService.request(
    request,
    decodeType: MyResponseDto.self,
    errorType: CustomErrorDto.self
)
```

## ⚠️ 에러 처리

Network 모듈은 다음과 같은 에러 타입을 제공합니다:

```swift
public enum NetworkError: Error {
    case decodingFailed(Error)
    case errorResponseDecodingFailed(Error)
    case noData
    case errorResponse(ErrorResponseDto)
    case unhandledStatusCode(Int)
    case serverError(Int)
    case networkFailed(Error)
    case unknown
}
```

### 에러 처리 예시

```swift
do {
    let result = try await networkService.request(
        request,
        decodeType: [CoffeeDTO].self,
        errorType: DefaultErrorResponseDto.self
    )
    // 성공 처리
} catch NetworkError.errorResponse(let errorDto) {
    // 서버 에러 응답 처리
    print("서버 에러: \(errorDto.message)")
} catch NetworkError.networkFailed(let error) {
    // 네트워크 연결 실패 처리
    print("네트워크 오류: \(error)")
} catch {
    // 기타 에러 처리
    print("알 수 없는 에러: \(error)")
}
```

## 🔄 재시도 메커니즘

Network 모듈은 자동 재시도 기능을 내장하고 있습니다:

- **최대 재시도 횟수**: 2회 (첫 요청 포함 총 3회)
- **재시도 간격**: 선형 증가 (1초, 2초)
- **재시도 가능한 에러**:
  - 5xx 서버 에러
  - 네트워크 연결 오류 (`.networkConnectionLost`)
  - 타임아웃 에러 (`.timedOut`)
  - 호스트를 찾을 수 없는 경우 (`.cannotFindHost`, `.cannotConnectToHost`)
  - DNS 조회 실패 (`.dnsLookupFailed`)
  - 인터넷 연결 없음 (`.notConnectedToInternet`)

### 재시도 로직 커스터마이징

기본 재시도 로직을 사용하지 않으려면 `DefaultNetworkService` 초기화 시 `Moya.Session`을 직접 주입하여 커스터마이징할 수 있습니다.

## 🧪 테스트

### 단위 테스트

```swift
import XCTest
@testable import Network

class NetworkServiceTests: XCTestCase {
    var networkService: NetworkService!
    
    override func setUp() {
        super.setUp()
        // 테스트용 NetworkService 설정
        networkService = DefaultNetworkService()
    }
    
    func testNetworkRequest() async throws {
        // 테스트 구현
    }
}
```

### Mock 데이터 사용

테스트 시에는 Moya의 stubbing 기능을 활용하여 Mock 데이터를 사용할 수 있습니다.

```swift
// 테스트용 NetworkService 생성
let stubProvider = MoyaProvider<MultiTarget>(stubClosure: MoyaProvider.immediatelyStub)
let testNetworkService = DefaultNetworkService(provider: stubProvider)
```

## 📝 로깅

Debug 빌드에서는 `NetworkLoggerPlugin`이 자동으로 추가되어 네트워크 요청과 응답을 로그로 출력합니다:

- 요청 URL, 메서드, 헤더, 바디
- 응답 상태 코드, 헤더, 바디
- 요청 소요 시간

## 🔧 설정

### 커스텀 플러그인 추가

```swift
let customPlugin = MyCustomPlugin()
let networkService = DefaultNetworkService(plugins: [customPlugin])
```

### 커스텀 ResponseProcessor

```swift
let customProcessor = MyCustomResponseProcessor()
let networkService = DefaultNetworkService(responseProcessor: customProcessor)
```

## 📚 참고 자료

- [Moya Documentation](https://github.com/Moya/Moya)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [JSON Decoding](https://developer.apple.com/documentation/foundation/jsondecoder)

## 📄 라이선스

이 모듈은 프로젝트의 라이선스 정책을 따릅니다.
