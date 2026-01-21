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
            "@AsyncViewModel can only be applied to a class"
        case .missingObservableObjectConformance:
            "@AsyncViewModel requires the class to conform to ObservableObject"
        case .missingStateProperty:
            "@AsyncViewModel requires a '@Published var state: State' property"
        case let .missingRequiredTypes(types):
            "@AsyncViewModel requires the following types to be defined: \(types.joined(separator: ", "))"
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
        if !existingProperties.contains("loggingConfig") {
            let loggingMode = extractLoggingMode(from: node)
            let loggerMode = extractLoggerMode(from: node)
            let loggingOptions = extractLoggingOptions(from: node)

            let code = if let options = loggingOptions {
                // 커스텀 옵션이 설정됨
                "public let loggingConfig: ViewModelLoggingConfig = ViewModelLoggingConfig(mode: \(loggingMode), loggerMode: \(loggerMode), customOptions: \(options))"
            } else {
                // 전역 설정 사용
                "public let loggingConfig: ViewModelLoggingConfig = ViewModelLoggingConfig(mode: \(loggingMode), loggerMode: \(loggerMode), customOptions: nil)"
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
        if member.as(StructDeclSyntax.self) != nil {
            return []
        }

        if member.as(EnumDeclSyntax.self) != nil {
            return []
        }

        // 이미 @MainActor가 있는지 확인
        if let attributedNode = member.asProtocol(WithAttributesSyntax.self) {
            let hasMainActor = attributedNode.attributes.contains { attribute in
                if case let .attribute(attr) = attribute,
                   let identifier = attr.attributeName.as(IdentifierTypeSyntax.self) {
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
            atSign: .atSignToken(),
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
    private static func extractLoggingMode(from node: AttributeSyntax) -> String {
        // 기본값: .enabled
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

            // .only(...), .excluding(...) 같은 함수 호출 케이스
            if let functionCall = expression.as(FunctionCallExprSyntax.self) {
                let functionName = functionCall.calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.text ?? ""

                switch functionName {
                case "only":
                    loggingMode = parseOnlyLoggingMode(from: functionCall)
                case "excluding":
                    loggingMode = parseExcludingLoggingMode(from: functionCall)
                default:
                    loggingMode = ".\(functionName)"
                }
                break
            }

            // .enabled, .disabled, .minimal, .noStateChanges 같은 단순 케이스
            if let memberAccess = expression.as(MemberAccessExprSyntax.self) {
                let memberName = memberAccess.declName.baseName.text
                loggingMode = ".\(memberName)"
                break
            }
        }

        return loggingMode
    }

    /// 매크로 어트리뷰트에서 Logger 모드를 추출합니다.
    private static func extractLoggerMode(from node: AttributeSyntax) -> String {
        // 기본값: .shared
        var loggerMode = ".shared"

        // 인자 목록 확인
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return loggerMode
        }

        // logger 파라미터 찾기
        for argument in arguments {
            guard let label = argument.label?.text, label == "logger" else {
                continue
            }

            let expression = argument.expression

            // .shared 케이스
            if let memberAccess = expression.as(MemberAccessExprSyntax.self) {
                loggerMode = ".\(memberAccess.declName.baseName.text)"
                break
            }

            // .custom(SomeLogger()) 케이스
            if let functionCall = expression.as(FunctionCallExprSyntax.self) {
                if let memberAccess = functionCall.calledExpression.as(MemberAccessExprSyntax.self),
                   memberAccess.declName.baseName.text == "custom" {
                    let argumentsText = functionCall.arguments.map(\.expression.description).joined(separator: ", ")
                    loggerMode = ".custom(\(argumentsText))"
                }
                break
            }
        }

        return loggerMode
    }

    /// .only(...) 모드 파싱
    private static func parseOnlyLoggingMode(from call: FunctionCallExprSyntax) -> String {
        let categories = call.arguments.compactMap { argument in
            argument.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
        }
        if !categories.isEmpty {
            return ".only(Set([\(categories.map { ".\($0)" }.joined(separator: ", "))]))"
        }
        return ".enabled"
    }

    /// .excluding(...) 모드 파싱
    private static func parseExcludingLoggingMode(from call: FunctionCallExprSyntax) -> String {
        let categories = call.arguments.compactMap { argument in
            argument.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
        }
        if !categories.isEmpty {
            return ".excluding(Set([\(categories.map { ".\($0)" }.joined(separator: ", "))]))"
        }
        return ".enabled"
    }

    /// 매크로 어트리뷰트에서 로깅 옵션을 추출합니다.
    /// format 파라미터가 설정되어 있으면 LoggingOptions 생성 코드 반환, 없으면 nil 반환
    private static func extractLoggingOptions(from node: AttributeSyntax) -> String? {
        // 인자 목록 확인
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }

        // format 파라미터 찾기
        for argument in arguments {
            guard let label = argument.label?.text, label == "format" else { continue }
            let expression = argument.expression

            // .compact, .standard, .detailed 같은 단순 케이스
            if let memberAccess = expression.as(MemberAccessExprSyntax.self) {
                let formatName = memberAccess.declName.baseName.text
                // 단일 포맷: 모든 카테고리에 동일하게 적용
                return "LoggingOptions(actionFormat: .\(formatName), stateFormat: .\(formatName), effectFormat: .\(formatName))"
            }

            // .perCategory(...), .action(...), .state(...), .effect(...) 같은 함수 호출 케이스
            if let functionCall = expression.as(FunctionCallExprSyntax.self) {
                if let memberAccess = functionCall.calledExpression.as(MemberAccessExprSyntax.self) {
                    let functionName = memberAccess.declName.baseName.text

                    switch functionName {
                    case "perCategory":
                        return parsePerCategoryFormat(from: functionCall)
                    case "action":
                        if let format = extractSingleFormat(from: functionCall) {
                            return "LoggingOptions(actionFormat: .\(format))"
                        }
                    case "state":
                        if let format = extractSingleFormat(from: functionCall) {
                            return "LoggingOptions(stateFormat: .\(format))"
                        }
                    case "effect":
                        if let format = extractSingleFormat(from: functionCall) {
                            return "LoggingOptions(effectFormat: .\(format))"
                        }
                    default:
                        break
                    }
                }
            }
        }

        return nil
    }

    /// .perCategory(action: .compact, state: .detailed, effect: .standard) 파싱
    private static func parsePerCategoryFormat(from call: FunctionCallExprSyntax) -> String {
        var actionFormat = ".standard"
        var stateFormat = ".standard"
        var effectFormat = ".standard"

        for argument in call.arguments {
            guard let label = argument.label?.text else { continue }

            if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                let format = ".\(memberAccess.declName.baseName.text)"
                switch label {
                case "action":
                    actionFormat = format
                case "state":
                    stateFormat = format
                case "effect":
                    effectFormat = format
                default:
                    break
                }
            }
        }

        return "LoggingOptions(actionFormat: \(actionFormat), stateFormat: \(stateFormat), effectFormat: \(effectFormat))"
    }

    /// 단일 포맷 함수 호출에서 포맷 추출 (예: .action(.compact))
    private static func extractSingleFormat(from call: FunctionCallExprSyntax) -> String? {
        guard let firstArg = call.arguments.first else { return nil }
        return firstArg.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
    }
}

// MARK: - Plugin Registration

@main
struct AsyncViewModelMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AsyncViewModelMacroImpl.self
    ]
}
