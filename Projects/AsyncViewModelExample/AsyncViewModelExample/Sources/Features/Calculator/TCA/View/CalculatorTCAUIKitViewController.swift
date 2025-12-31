//
//  CalculatorTCAUIKitViewController.swift
//  TCAFeature
//
//  Created by jimmy on 2025/12/29.
//

import Combine
import ComposableArchitecture
import PinLayout
import UIKit

public final class CalculatorTCAUIKitViewController: UIViewController {
    
    // MARK: - UI Components
    private let displayLabel = UILabel()
        .font(.systemFont(ofSize: 48, weight: .light))
        .textColor(.label)
        .textAlignment(.right)
        .text("0")
        .adjustsFontSizeToFitWidth(true, 0.5)
        .accessibilityIdentifier("calculator_display_tca_uikit")
    
    private let displayContainerView = UIView()
        .backgroundColor(.systemGray6)
        .cornerRadius(12)
    
    private let timerStatusLabel = UILabel()
        .font(.systemFont(ofSize: 12))
        .textColor(.systemOrange)
        .text("5초 후 자동 클리어됩니다")
        .isHidden(true)
    
    private let timerIconImageView = UIImageView(image: UIImage(systemName: "timer"))
        .tintColor(.systemOrange)
        .isHidden(true)
    
    private let buttonsStackView = UIStackView()
        .axis(.vertical)
        .spacing(12)
        .distribution(.fillEqually)
    
    // MARK: - TCA Properties
    private let store: StoreOf<CalculatorTCAFeature>
    private let viewStore: ViewStoreOf<CalculatorTCAFeature>
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    public init(store: StoreOf<CalculatorTCAFeature>? = nil) {
        let actualStore = store ?? Store(initialState: CalculatorTCAFeature.State()) {
            CalculatorTCAFeature()
        }
        self.store = actualStore
        self.viewStore = ViewStore(actualStore, observe: { $0 })
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindStore()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupLayout()
    }
    
    // MARK: - Store Binding
    private func bindStore() {
        viewStore.publisher.display
            .removeDuplicates()
            .sink { [weak self] display in
                self?.displayLabel.text = display
            }
            .store(in: &cancellables)
        
        viewStore.publisher.isAutoClearTimerActive
            .removeDuplicates()
            .sink { [weak self] isActive in
                self?.updateTimerStatus(isActive)
            }
            .store(in: &cancellables)
        
        viewStore.publisher.activeAlert
            .removeDuplicates()
            .compactMap { $0 }
            .sink { [weak self] alertType in
                self?.handleAlert(alertType)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor(.systemBackground)
        title = "TCA UIKit"
        
        let timerStackView = UIStackView()
            .axis(.horizontal)
            .spacing(8)
            .alignment(.center)
        
        timerStackView.addArrangedSubview(timerIconImageView)
        timerStackView.addArrangedSubview(timerStatusLabel)
        timerStackView.addArrangedSubview(UIView())
        
        displayContainerView.addSubview(timerStackView)
        displayContainerView.addSubview(displayLabel)
        
        view.addSubview(displayContainerView)
        view.addSubview(buttonsStackView)
        
        createButtonGrid()
    }
    
    private func setupLayout() {
        let safeArea = view.safeAreaInsets
        let padding: CGFloat = 20
        
        displayContainerView.pin
            .top(safeArea.top + padding)
            .left(padding)
            .right(padding)
            .height(140)
        
        if let timerStack = displayContainerView.subviews.first(where: { $0 is UIStackView }) {
            timerStack.pin
                .top(12)
                .left(16)
                .right(16)
                .height(20)
        }
        
        displayLabel.pin
            .below(of: displayContainerView.subviews.first(where: { $0 is UIStackView }) ?? displayContainerView)
            .marginTop(8)
            .left(16)
            .right(16)
            .bottom(16)
        
        buttonsStackView.pin
            .below(of: displayContainerView)
            .marginTop(padding)
            .left(padding)
            .right(padding)
            .bottom(safeArea.bottom + padding)
    }
    
    // MARK: - Button Setup
    private func createButtonGrid() {
        let buttonRows: [[(title: String, color: UIColor, accessibilityId: String)]] = [
            [
                ("C", .systemOrange, "clear_button_tca_uikit"),
                ("", .clear, ""),
                ("", .clear, ""),
                ("÷", .systemBlue, "operation_button_divide_tca_uikit")
            ],
            [
                ("7", .systemGray, "number_button_7_tca_uikit"),
                ("8", .systemGray, "number_button_8_tca_uikit"),
                ("9", .systemGray, "number_button_9_tca_uikit"),
                ("×", .systemBlue, "operation_button_multiply_tca_uikit")
            ],
            [
                ("4", .systemGray, "number_button_4_tca_uikit"),
                ("5", .systemGray, "number_button_5_tca_uikit"),
                ("6", .systemGray, "number_button_6_tca_uikit"),
                ("-", .systemBlue, "operation_button_subtract_tca_uikit")
            ],
            [
                ("1", .systemGray, "number_button_1_tca_uikit"),
                ("2", .systemGray, "number_button_2_tca_uikit"),
                ("3", .systemGray, "number_button_3_tca_uikit"),
                ("+", .systemBlue, "operation_button_add_tca_uikit")
            ],
            [
                ("0", .systemGray, "number_button_0_tca_uikit"),
                ("", .clear, ""),
                ("", .clear, ""),
                ("=", .systemGreen, "equals_button_tca_uikit")
            ]
        ]
        
        buttonRows.forEach {
            buttonsStackView.addArrangedSubview(createButtonRow(buttons: $0))
        }
    }
    
    private func createButtonRow(buttons: [(title: String, color: UIColor, accessibilityId: String)]) -> UIStackView {
        let rowStack = UIStackView()
            .axis(.horizontal)
            .spacing(12)
            .distribution(.fillEqually)
        
        for (title, color, accessibilityId) in buttons {
            if title.isEmpty {
                rowStack.addArrangedSubview(UIView())
            } else {
                let button = createCalculatorButton(title: title, color: color, accessibilityId: accessibilityId)
                setupButtonAction(button: button, title: title)
                rowStack.addArrangedSubview(button)
            }
        }
        
        return rowStack
    }
    
    private func createCalculatorButton(title: String, color: UIColor, accessibilityId: String) -> UIButton {
        let button = UIButton(configuration: .filled())
            .title(title)
            .baseForegroundColor(.white)
            .baseBackgroundColor(color)
            .cornerStyle(.medium)
            .accessibilityIdentifier(accessibilityId)
        
        return button
    }
    
    private func setupButtonAction(button: UIButton, title: String) {
        button.addAction(UIAction { [weak self] _ in
            self?.handleButtonTap(title: title)
        }, for: .touchUpInside)
    }
    
    private func handleButtonTap(title: String) {
        switch title {
        case "0"..."9":
            if let digit = Int(title) {
                viewStore.send(.numberTapped(digit))
            }
        case "+":
            viewStore.send(.operationTapped(.add))
        case "-":
            viewStore.send(.operationTapped(.subtract))
        case "×":
            viewStore.send(.operationTapped(.multiply))
        case "÷":
            viewStore.send(.operationTapped(.divide))
        case "=":
            viewStore.send(.equalsTapped)
        case "C":
            viewStore.send(.clearTapped)
        default:
            break
        }
    }
    
    // MARK: - Timer Status Update
    private func updateTimerStatus(_ isActive: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.timerIconImageView.isHidden = !isActive
            self.timerStatusLabel.isHidden = !isActive
            
            if isActive {
                self.displayContainerView.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.6).cgColor
                self.displayContainerView.layer.borderWidth = 2
            } else {
                self.displayContainerView.layer.borderWidth = 0
            }
        }
    }
    
    // MARK: - Alert Handling
    private func handleAlert(_ alertType: CalculatorTCAFeature.State.AlertType) {
        switch alertType {
        case .error(let error):
            let alert = UIAlertController(
                title: "오류",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
                self?.viewStore.send(.dismissAlert)
            })
            
            present(alert, animated: true)
        }
    }
}

// MARK: - Preview
@available(iOS 17.0, *)
#Preview {
    CalculatorTCAUIKitViewController()
}

