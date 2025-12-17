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
    case missingMainActorAttribute
    case missingObservableObjectConformance
    case missingStateProperty
    case missingRequiredTypes([String])
    
    public var description: String {
        switch self {
        case .onlyApplicableToClass:
            return "@AsyncViewModel can only be applied to a class"
        case .missingMainActorAttribute:
            return "@AsyncViewModel requires @MainActor attribute on the class"
        case .missingObservableObjectConformance:
            return "@AsyncViewModel requires the class to conform to ObservableObject"
        case .missingStateProperty:
            return "@AsyncViewModel requires a '@Published var state: State' property"
        case .missingRequiredTypes(let types):
            return "@AsyncViewModel requires the following types to be defined: \(types.joined(separator: ", "))"
        }
    }
}

// MARK: - AsyncViewModelMacroImpl

/// AsyncViewModel 프로토콜의 보일러플레이트 프로퍼티를 생성하는 매크로 구현
public struct AsyncViewModelMacroImpl: MemberMacro, ExtensionMacro {
    
    // MARK: - MemberMacro Implementation
    
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // 클래스에만 적용 가능
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw AsyncViewModelMacroError.onlyApplicableToClass
        }
        
        // 매크로 파라미터 추출
        let (isLoggingEnabled, logLevel) = extractMacroParameters(from: attribute)
        
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
        
        // isLoggingEnabled 프로퍼티
        if !existingProperties.contains("isLoggingEnabled") {
            members.append(
                """
                public var isLoggingEnabled: Bool = \(raw: isLoggingEnabled)
                """
            )
        }
        
        // logLevel 프로퍼티
        if !existingProperties.contains("logLevel") {
            members.append(
                """
                public var logLevel: LogLevel = \(raw: logLevel)
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
        
        return members
    }
    
    // MARK: - ExtensionMacro Implementation
    
    public static func expansion(
        of attribute: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // 클래스에만 적용 가능
        guard declaration.is(ClassDeclSyntax.self) else {
            throw AsyncViewModelMacroError.onlyApplicableToClass
        }
        
        // AsyncViewModelProtocol 프로토콜 준수를 위한 extension 생성
        let extensionDecl: DeclSyntax = """
            extension \(type.trimmed): AsyncViewModelProtocol {}
            """
        
        guard let extensionDeclSyntax = extensionDecl.as(ExtensionDeclSyntax.self) else {
            return []
        }
        
        return [extensionDeclSyntax]
    }
    
    // MARK: - Helper Methods
    
    /// 매크로 파라미터를 추출합니다.
    private static func extractMacroParameters(
        from attribute: AttributeSyntax
    ) -> (isLoggingEnabled: String, logLevel: String) {
        var isLoggingEnabled = "true"
        var logLevel = ".info"
        
        guard let arguments = attribute.arguments?.as(LabeledExprListSyntax.self) else {
            return (isLoggingEnabled, logLevel)
        }
        
        for argument in arguments {
            if argument.label?.text == "isLoggingEnabled",
               let boolExpr = argument.expression.as(BooleanLiteralExprSyntax.self) {
                isLoggingEnabled = boolExpr.literal.text
            } else if argument.label?.text == "logLevel" {
                logLevel = argument.expression.description.trimmingCharacters(in: .whitespaces)
            }
        }
        
        return (isLoggingEnabled, logLevel)
    }
    
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
}

// MARK: - Plugin Registration

@main
struct AsyncViewModelMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AsyncViewModelMacroImpl.self,
    ]
}


