//
//  CalculatorReactorViewController.swift
//  ReactorKitFeature
//
//  Created by 정준영 on 2025/12/17
//

import PinLayout
import ReactorKit
import RxCocoa
import RxSwift
import UIKit

public final class CalculatorReactorViewController: UIViewController, ReactorKit.View {
    
    // MARK: - UI Components
    private let displayLabel = UILabel()
        .font(.systemFont(ofSize: 48, weight: .light))
        .textColor(.label)
        .textAlignment(.right)
        .text("0")
        .adjustsFontSizeToFitWidth(true, 0.5)
        .accessibilityIdentifier("calculator_display_reactor")
    
    private let displayContainerView = UIView()
        .backgroundColor(.systemGray6)
        .cornerRadius(12)
    
    private let buttonsStackView = UIStackView()
        .axis(.vertical)
        .spacing(12)
        .distribution(.fillEqually)
    
    // MARK: - Properties
    public var disposeBag = DisposeBag()
    
    // MARK: - Initialization
    public init(reactor: CalculatorReactor = CalculatorReactor()) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupLayout()
    }
    
    // MARK: - ReactorKit.View
    public func bind(reactor: CalculatorReactor) {
        reactor.state
            .map { $0.display }
            .distinctUntilChanged()
            .bind(to: displayLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state
            .map { $0.activeAlert }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] alertType in
                self?.handleAlert(alertType)
            })
            .disposed(by: disposeBag)
        
        setupButtons(reactor: reactor)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor(.systemBackground)
        title = "ReactorKit Calculator"
        
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
            .height(120)
        
        displayLabel.pin.all()
        
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
                ("C", .systemOrange, "clear_button_reactor"),
                ("", .clear, ""),
                ("", .clear, ""),
                ("÷", .systemBlue, "operation_button_divide_reactor")
            ],
            [
                ("7", .systemGray, "number_button_7_reactor"),
                ("8", .systemGray, "number_button_8_reactor"),
                ("9", .systemGray, "number_button_9_reactor"),
                ("×", .systemBlue, "operation_button_multiply_reactor")
            ],
            [
                ("4", .systemGray, "number_button_4_reactor"),
                ("5", .systemGray, "number_button_5_reactor"),
                ("6", .systemGray, "number_button_6_reactor"),
                ("-", .systemBlue, "operation_button_subtract_reactor")
            ],
            [
                ("1", .systemGray, "number_button_1_reactor"),
                ("2", .systemGray, "number_button_2_reactor"),
                ("3", .systemGray, "number_button_3_reactor"),
                ("+", .systemBlue, "operation_button_add_reactor")
            ],
            [
                ("0", .systemGray, "number_button_0_reactor"),
                ("", .clear, ""),
                ("", .clear, ""),
                ("=", .systemGreen, "equals_button_reactor")
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
    
    private func setupButtons(reactor: CalculatorReactor) {
        for i in 0...9 {
            if let button = view.viewWithAccessibilityIdentifier("number_button_\(i)_reactor") as? UIButton {
                button.rx.tap
                    .map { CalculatorReactor.Action.inputNumber(i) }
                    .bind(to: reactor.action)
                    .disposed(by: disposeBag)
            }
        }
        
        if let addButton = view.viewWithAccessibilityIdentifier("operation_button_add_reactor") as? UIButton {
            addButton.rx.tap
                .map { CalculatorReactor.Action.setOperation(.add) }
                .bind(to: reactor.action)
                .disposed(by: disposeBag)
        }
        
        if let subtractButton = view.viewWithAccessibilityIdentifier("operation_button_subtract_reactor") as? UIButton {
            subtractButton.rx.tap
                .map { CalculatorReactor.Action.setOperation(.subtract) }
                .bind(to: reactor.action)
                .disposed(by: disposeBag)
        }
        
        if let multiplyButton = view.viewWithAccessibilityIdentifier("operation_button_multiply_reactor") as? UIButton {
            multiplyButton.rx.tap
                .map { CalculatorReactor.Action.setOperation(.multiply) }
                .bind(to: reactor.action)
                .disposed(by: disposeBag)
        }
        
        if let divideButton = view.viewWithAccessibilityIdentifier("operation_button_divide_reactor") as? UIButton {
            divideButton.rx.tap
                .map { CalculatorReactor.Action.setOperation(.divide) }
                .bind(to: reactor.action)
                .disposed(by: disposeBag)
        }
        
        if let equalsButton = view.viewWithAccessibilityIdentifier("equals_button_reactor") as? UIButton {
            equalsButton.rx.tap
                .map { CalculatorReactor.Action.calculate }
                .bind(to: reactor.action)
                .disposed(by: disposeBag)
        }
        
        if let clearButton = view.viewWithAccessibilityIdentifier("clear_button_reactor") as? UIButton {
            clearButton.rx.tap
                .map { CalculatorReactor.Action.clear }
                .bind(to: reactor.action)
                .disposed(by: disposeBag)
        }
    }
    
    // MARK: - Alert Handling
    private func handleAlert(_ alertType: CalculatorReactor.AlertType?) {
        guard let alertType = alertType else { return }
        
        switch alertType {
        case .error(let error):
            let alert = UIAlertController(
                title: "오류",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
                self?.reactor?.action.onNext(.dismissAlert)
            })
            
            present(alert, animated: true)
        }
    }
}

// MARK: - UIView Extension
extension UIView {
    func viewWithAccessibilityIdentifier(_ identifier: String) -> UIView? {
        if self.accessibilityIdentifier == identifier {
            return self
        }
        
        for subview in subviews {
            if let found = subview.viewWithAccessibilityIdentifier(identifier) {
                return found
            }
        }
        
        return nil
    }
}

// MARK: - Preview
@available(iOS 17.0, *)
#Preview {
    CalculatorReactorViewController()
}

