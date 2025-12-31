//
//  CalculatorUIKitViewController.swift
//  UIKitFeature
//
//  Created by jimmy on 2025/12/29.
//

import Combine
import PinLayout
import UIKit

@MainActor
public final class CalculatorUIKitViewController: UIViewController {
    // MARK: - UI Components

    private let displayLabel = UILabel()
        .font(.systemFont(ofSize: 48, weight: .light))
        .textColor(.label)
        .textAlignment(.right)
        .text("0")
        .adjustsFontSizeToFitWidth(true, 0.5)
        .accessibilityIdentifier("calculator_display_uikit")

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

    // MARK: - ViewModel Properties

    private let viewModel: CalculatorUIKitViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    @MainActor
    public init(viewModel: CalculatorUIKitViewModel? = nil) {
        self.viewModel = viewModel ?? CalculatorUIKitViewModel()
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        viewModel = CalculatorUIKitViewModel()
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupLayout()
    }

    // MARK: - ViewModel Binding

    private func bindViewModel() {
        viewModel.$state
            .map(\.display)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] display in
                self?.displayLabel.text = display
            }
            .store(in: &cancellables)

        viewModel.$state
            .map(\.isAutoClearTimerActive)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                self?.updateTimerStatus(isActive)
            }
            .store(in: &cancellables)

        viewModel.$state
            .map(\.activeAlert)
            .removeDuplicates()
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] alertType in
                self?.handleAlert(alertType)
            }
            .store(in: &cancellables)
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor(.systemBackground)
        title = "UIKit Calculator"

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
                ("C", .systemOrange, "clear_button_uikit"),
                ("", .clear, ""),
                ("", .clear, ""),
                ("÷", .systemBlue, "operation_button_divide_uikit"),
            ],
            [
                ("7", .systemGray, "number_button_7_uikit"),
                ("8", .systemGray, "number_button_8_uikit"),
                ("9", .systemGray, "number_button_9_uikit"),
                ("×", .systemBlue, "operation_button_multiply_uikit"),
            ],
            [
                ("4", .systemGray, "number_button_4_uikit"),
                ("5", .systemGray, "number_button_5_uikit"),
                ("6", .systemGray, "number_button_6_uikit"),
                ("-", .systemBlue, "operation_button_subtract_uikit"),
            ],
            [
                ("1", .systemGray, "number_button_1_uikit"),
                ("2", .systemGray, "number_button_2_uikit"),
                ("3", .systemGray, "number_button_3_uikit"),
                ("+", .systemBlue, "operation_button_add_uikit"),
            ],
            [
                ("0", .systemGray, "number_button_0_uikit"),
                ("", .clear, ""),
                ("", .clear, ""),
                ("=", .systemGreen, "equals_button_uikit"),
            ],
        ]

        for buttonRow in buttonRows {
            buttonsStackView.addArrangedSubview(createButtonRow(buttons: buttonRow))
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
        case "0" ... "9":
            if let digit = Int(title) {
                viewModel.send(.numberButtonTapped(digit))
            }
        case "+":
            viewModel.send(.operationButtonTapped(.add))
        case "-":
            viewModel.send(.operationButtonTapped(.subtract))
        case "×":
            viewModel.send(.operationButtonTapped(.multiply))
        case "÷":
            viewModel.send(.operationButtonTapped(.divide))
        case "=":
            viewModel.send(.equalsButtonTapped)
        case "C":
            viewModel.send(.clearButtonTapped)
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

    private func handleAlert(_ alertType: CalculatorUIKitViewModel.State.AlertType) {
        switch alertType {
        case let .error(error):
            let alert = UIAlertController(
                title: "오류",
                message: error.localizedDescription,
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
                self?.viewModel.send(.alertDismissed)
            })

            present(alert, animated: true)
        }
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    CalculatorUIKitViewController()
}
