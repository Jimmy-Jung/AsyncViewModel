//
//  AsyncViewModelMacroImpl.swift
//  AsyncViewModelMacros
//
//  Created by jimmy on 2025/12/29.
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
        of _: AttributeSyntax,
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
}

// MARK: - Plugin Registration

@main
struct AsyncViewModelMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AsyncViewModelMacroImpl.self,
    ]
}
