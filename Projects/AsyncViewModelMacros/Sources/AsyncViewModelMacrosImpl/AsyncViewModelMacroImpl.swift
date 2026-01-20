//
//  AsyncViewModelMacroImpl.swift
//  AsyncViewModelMacros
//
//  Created by 정준영 on 2025/12/17.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - AsyncViewModelMacroError

/// AsyncViewModel 매크로 에러 타입
public enum AsyncViewModelMacroError: CustomStringConvertible, Error {
    case onlyApplicableToClass
    case missingObservableObjectConformance
    case missingStateProperty
    case missingRequiredTypes([String])

    public var description: String {
        switch self {
        case .onlyApplicableToClass:
            return "@AsyncViewModel can only be applied to a class"
        case .missingObservableObjectConformance:
            return "@AsyncViewModel requires the class to conform to ObservableObject"
        case .missingStateProperty:
            return "@AsyncViewModel requires a '@Published var state: State' property"
        case let .missingRequiredTypes(types):
            return "@AsyncViewModel requires the following types to be defined: \(types.joined(separator: ", "))"
        }
    }
}

// MARK: - AsyncViewModelMacroImpl

/// AsyncViewModel 프로토콜의 보일러플레이트 프로퍼티를 생성하는 매크로 구현
public struct AsyncViewModelMacroImpl: MemberMacro, MemberAttributeMacro, ExtensionMacro {
    // MARK: - MemberMacro Implementation

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // 클래스에만 적용 가능
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw AsyncViewModelMacroError.onlyApplicableToClass
        }

        // 이미 선언된 프로퍼티 이름 수집
        let existingProperties = collectExistingProperties(from: classDecl)

        // 생성할 프로퍼티 목록
        var members: [DeclSyntax] = []

        // tasks 프로퍼티
        if !existingProperties.contains("tasks") {
            members.append(
                """
                public var tasks: [CancelID: Task<Void, Never>] = [:]
                """
            )
        }

        // effectQueue 프로퍼티
        if !existingProperties.contains("effectQueue") {
            members.append(
                """
                public var effectQueue: [AsyncEffect<Action, CancelID>] = []
                """
            )
        }

        // isProcessingEffects 프로퍼티
        if !existingProperties.contains("isProcessingEffects") {
            members.append(
                """
                public var isProcessingEffects: Bool = false
                """
            )
        }

        // actionObserver 프로퍼티
        if !existingProperties.contains("actionObserver") {
            members.append(
                """
                public var actionObserver: ((Action) -> Void)? = nil
                """
            )
        }

        // stateChangeObserver 프로퍼티
        if !existingProperties.contains("stateChangeObserver") {
            members.append(
                """
                public var stateChangeObserver: ((State, State) -> Void)? = nil
                """
            )
        }

        // effectObserver 프로퍼티
        if !existingProperties.contains("effectObserver") {
            members.append(
                """
                public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil
                """
            )
        }

        // performanceObserver 프로퍼티
        if !existingProperties.contains("performanceObserver") {
            members.append(
                """
                public var performanceObserver: ((String, TimeInterval) -> Void)? = nil
                """
            )
        }

        // timer 프로퍼티 (기본값 제공으로 자동 초기화)
        if !existingProperties.contains("timer") {
            members.append(
                """
                public var timer: any AsyncTimer = SystemTimer()
                """
            )
        }

        // loggingConfig 프로퍼티 (로깅 설정)
        // Logger는 이제 ViewModelLoggingMode에 포함됨
        if !existingProperties.contains("loggingConfig") {
            let loggingMode = extractLoggingMode(from: node)
            let loggingOptions = extractLoggingOptions(from: node)

            let code: String
            if let options = loggingOptions {
                // 커스텀 옵션이 설정됨
                code = "public let loggingConfig: ViewModelLoggingConfig = ViewModelLoggingConfig(mode: \(loggingMode), customOptions: \(options))"
            } else {
                // 전역 설정 사용
                code = "public let loggingConfig: ViewModelLoggingConfig = ViewModelLoggingConfig(mode: \(loggingMode), customOptions: nil)"
            }
            members.append(DeclSyntax(stringLiteral: code))
        }

        return members
    }

    // MARK: - MemberAttributeMacro Implementation

    public static func expansion(
        of _: AttributeSyntax,
        attachedTo _: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        // Input, Action, State, CancelID 같은 중첩 타입에는 @MainActor를 추가하지 않음
        if let structDecl = member.as(StructDeclSyntax.self) {
            return []
        }

        if let enumDecl = member.as(EnumDeclSyntax.self) {
            return []
        }

        // 이미 @MainActor가 있는지 확인
        if let attributedNode = member.asProtocol(WithAttributesSyntax.self) {
            let hasMainActor = attributedNode.attributes.contains { attribute in
                if case let .attribute(attr) = attribute,
                   let identifier = attr.attributeName.as(IdentifierTypeSyntax.self)
                {
                    return identifier.name.text == "MainActor"
                }
                return false
            }

            // 이미 @MainActor가 있으면 추가하지 않음
            if hasMainActor {
                return []
            }
        }

        // @MainActor 어트리뷰트 생성
        let mainActorAttribute = AttributeSyntax(
            atSignToken: .atSignToken(),
            attributeName: IdentifierTypeSyntax(name: .identifier("MainActor"))
        )

        return [mainActorAttribute]
    }

    // MARK: - ExtensionMacro Implementation

    public static func expansion(
        of _: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // 클래스에만 적용 가능
        guard declaration.is(ClassDeclSyntax.self) else {
            throw AsyncViewModelMacroError.onlyApplicableToClass
        }

        // AsyncViewModelProtocol 프로토콜 준수를 위한 extension 생성
        // @MainActor를 extension에 추가하여 모든 메서드가 MainActor에서 실행되도록 함
        let extensionDecl: DeclSyntax = """
        @MainActor
        extension \(type.trimmed): AsyncViewModelProtocol {}
        """

        guard let extensionDeclSyntax = extensionDecl.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [extensionDeclSyntax]
    }

    // MARK: - Helper Methods

    /// 클래스에서 이미 선언된 프로퍼티 이름을 수집합니다.
    private static func collectExistingProperties(
        from classDecl: ClassDeclSyntax
    ) -> Set<String> {
        var properties: Set<String> = []

        for member in classDecl.memberBlock.members {
            if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in variableDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        properties.insert(identifier.identifier.text)
                    }
                }
            }
        }

        return properties
    }

    /// 매크로 어트리뷰트에서 로깅 모드를 추출합니다.
    /// Logger가 ViewModelLoggingMode에 포함되어 있으므로, .enabled(.shared), .enabled(.custom(...)) 등의 형태를 처리합니다.
    private static func extractLoggingMode(from node: AttributeSyntax) -> String {
        // 기본값: .enabled (static var enabled가 .enabled(.shared) 반환)
        var loggingMode = ".enabled"

        // 인자 목록 확인
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return loggingMode
        }

        // logging 파라미터 찾기
        for argument in arguments {
            guard let label = argument.label?.text, label == "logging" else {
                continue
            }

            // 표현식 추출
            let expression = argument.expression

            // .enabled(.shared), .enabled(.custom(...)), .custom(...), .only(...), .excluding(...) 같은 함수 호출 케이스
            if let functionCall = expression.as(FunctionCallExprSyntax.self) {
                let functionName = functionCall.calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.text ?? ""

                switch functionName {
                case "enabled":
                    loggingMode = parseEnabledLoggingMode(from: functionCall)
                case "minimal":
                    loggingMode = parseMinimalLoggingMode(from: functionCall)
                case "custom":
                    loggingMode = parseCustomLoggingMode(from: functionCall)
                case "only":
                    loggingMode = parseOnlyLoggingMode(from: functionCall)
                case "excluding":
                    loggingMode = parseExcludingLoggingMode(from: functionCall)
                default:
                    loggingMode = ".\(functionName)()"
                }
                break
            }

            // .enabled, .disabled, .minimal, .noStateChanges 같은 단순 케이스 (static var 사용)
            if let memberAccess = expression.as(MemberAccessExprSyntax.self) {
                let memberName = memberAccess.declName.baseName.text
                loggingMode = ".\(memberName)"
                break
            }
        }

        return loggingMode
    }

    /// .enabled(...) 모드 파싱 (Logger 포함)
    private static func parseEnabledLoggingMode(from call: FunctionCallExprSyntax) -> String {
        // 인자가 없으면 기본 .shared
        guard let firstArg = call.arguments.first else {
            return ".enabled(.shared)"
        }

        let loggerExpr = firstArg.expression

        // .shared 케이스
        if let memberAccess = loggerExpr.as(MemberAccessExprSyntax.self) {
            return ".enabled(.\(memberAccess.declName.baseName.text))"
        }

        // .custom(SomeLogger()) 케이스
        if let functionCall = loggerExpr.as(FunctionCallExprSyntax.self) {
            if let memberAccess = functionCall.calledExpression.as(MemberAccessExprSyntax.self),
               memberAccess.declName.baseName.text == "custom"
            {
                let argumentsText = functionCall.arguments.map { $0.expression.description }.joined(separator: ", ")
                return ".enabled(.custom(\(argumentsText)))"
            }
        }

        return ".enabled(.shared)"
    }

    /// .minimal(...) 모드 파싱 (Logger 포함)
    private static func parseMinimalLoggingMode(from call: FunctionCallExprSyntax) -> String {
        // 인자가 없으면 기본 .shared
        guard let firstArg = call.arguments.first else {
            return ".minimal(.shared)"
        }

        let loggerExpr = firstArg.expression

        // .shared 케이스
        if let memberAccess = loggerExpr.as(MemberAccessExprSyntax.self) {
            return ".minimal(.\(memberAccess.declName.baseName.text))"
        }

        // .custom(SomeLogger()) 케이스
        if let functionCall = loggerExpr.as(FunctionCallExprSyntax.self) {
            if let memberAccess = functionCall.calledExpression.as(MemberAccessExprSyntax.self),
               memberAccess.declName.baseName.text == "custom"
            {
                let argumentsText = functionCall.arguments.map { $0.expression.description }.joined(separator: ", ")
                return ".minimal(.custom(\(argumentsText)))"
            }
        }

        return ".minimal(.shared)"
    }

    /// .custom(...) 모드 파싱 (categories와 logger만 지원)
    private static func parseCustomLoggingMode(from call: FunctionCallExprSyntax) -> String {
        var params: [String] = []

        for argument in call.arguments {
            guard let label = argument.label?.text else { continue }

            let expr = argument.expression

            switch label {
            case "categories":
                if let arrayExpr = expr.as(ArrayExprSyntax.self) {
                    let categories = arrayExpr.elements.compactMap { element in
                        element.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
                    }
                    if !categories.isEmpty {
                        params.append("categories: Set([\(categories.map { ".\($0)" }.joined(separator: ", "))])")
                    }
                }
            case "logger":
                // Logger 파라미터 처리
                if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
                    params.append("logger: .\(memberAccess.declName.baseName.text)")
                } else if let functionCall = expr.as(FunctionCallExprSyntax.self) {
                    if let memberAccess = functionCall.calledExpression.as(MemberAccessExprSyntax.self),
                       memberAccess.declName.baseName.text == "custom"
                    {
                        let argumentsText = functionCall.arguments.map { $0.expression.description }.joined(separator: ", ")
                        params.append("logger: .custom(\(argumentsText))")
                    }
                }
            default:
                break
            }
        }

        return ".custom(\(params.joined(separator: ", ")))"
    }

    /// .only(...) 모드 파싱
    private static func parseOnlyLoggingMode(from call: FunctionCallExprSyntax) -> String {
        let categories = call.arguments.compactMap { argument in
            argument.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
        }
        if !categories.isEmpty {
            return ".only(\(categories.map { ".\($0)" }.joined(separator: ", ")))"
        }
        return ".only()"
    }

    /// .excluding(...) 모드 파싱
    private static func parseExcludingLoggingMode(from call: FunctionCallExprSyntax) -> String {
        let categories = call.arguments.compactMap { argument in
            argument.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
        }
        if !categories.isEmpty {
            return ".excluding(\(categories.map { ".\($0)" }.joined(separator: ", ")))"
        }
        return ".excluding()"
    }

    /// 매크로 어트리뷰트에서 로깅 옵션을 추출합니다.
    /// 옵션이 하나라도 설정되어 있으면 LoggingOptions 생성 코드 반환, 없으면 nil 반환
    private static func extractLoggingOptions(from node: AttributeSyntax) -> String? {
        // 인자 목록 확인
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }

        var format: String?
        var groupEffects: String?

        for argument in arguments {
            guard let label = argument.label?.text else { continue }
            let expression = argument.expression

            switch label {
            case "format":
                if let memberAccess = expression.as(MemberAccessExprSyntax.self) {
                    format = ".\(memberAccess.declName.baseName.text)"
                }
            case "groupEffects":
                if let boolLiteral = expression.as(BooleanLiteralExprSyntax.self) {
                    groupEffects = boolLiteral.literal.text
                }
            default:
                break
            }
        }

        // 아무 옵션도 설정되지 않았으면 nil 반환 (전역 설정 사용)
        if format == nil, groupEffects == nil {
            return nil
        }

        // LoggingOptions 생성 코드 반환
        var params: [String] = []
        if let format = format {
            params.append("format: \(format)")
        }
        if let groupEffects = groupEffects {
            params.append("groupEffects: \(groupEffects)")
        }

        return "LoggingOptions(\(params.joined(separator: ", ")))"
    }
}

// MARK: - Plugin Registration

@main
struct AsyncViewModelMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AsyncViewModelMacroImpl.self,
    ]
}
