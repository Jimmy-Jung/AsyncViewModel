import XCTest
import Combine
@testable import AsyncViewModel
@testable import AsyncViewModelExample

@MainActor
final class AsyncViewModelExampleTests: XCTestCase {

    var store: AsyncTestStore<ContentViewModel>!
    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        let viewModel = ContentViewModel()
        store = AsyncTestStore(viewModel: viewModel)
    }

    override func tearDown() {
        store = nil
        cancellables.removeAll()
        super.tearDown()
    }

    func test_incrementAction_incrementsCount() {
        // Given
        let expectation = XCTestExpectation(description: "Increment count")
        let initialCount = store.state.count

        // When
        store.send(.incrementButtonTapped)
            .sink {
                // Then
                XCTAssertEqual(self.store.state.count, initialCount + 1)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }

    func test_decrementAction_decrementsCount() {
        // Given
        let expectation = XCTestExpectation(description: "Decrement count")
        let initialCount = store.state.count
        
        // When
        store.send(.decrementButtonTapped)
            .sink {
                // Then
                XCTAssertEqual(self.store.state.count, initialCount - 1)
                expectation.fulfill()
            }
            .store(in: &cancellables)
            
        wait(for: [expectation], timeout: 1.0)
    }

    func test_fetchNumberAction_updatesCountAfterDelay() {
        // Given
        let expectation = XCTestExpectation(description: "Fetch number")
        
        // When
        store.send(.fetchNumberButtonTapped)
            .sink {
                // Then: First state change (isLoading = true)
                XCTAssertTrue(self.store.state.isLoading)
                
                // Wait for the second state change (isLoading = false, count updated)
                self.store.viewModel.objectWillChange
                    .sink {
                        XCTAssertFalse(self.store.state.isLoading)
                        XCTAssertNotEqual(self.store.state.count, 0)
                        expectation.fulfill()
                    }
                    .store(in: &self.cancellables)
            }
            .store(in: &cancellables)
            
        wait(for: [expectation], timeout: 2.0)
    }
}
