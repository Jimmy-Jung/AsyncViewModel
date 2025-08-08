import SwiftUI
import CalculatorFeature

@main
struct AsyncViewModelExampleApp: App {
    var body: some Scene {
        WindowGroup {
            CalculatorView(CalculatorAsyncViewModel())
        }
    }
}
