//
//  ResultBuilderMacro.swift
//  MacroExamplesPlugin
//
//  Created by Stephen Kockentiedt on 25.12.22.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import _SwiftSyntaxMacros

public struct ResultBuilderMacro2: ExpressionMacro {
    public static func expansion(
        of node: MacroExpansionExprSyntax, in context: inout MacroExpansionContext
    ) throws -> ExprSyntax {
        guard
            let resultBuilderSelfExpr = node.argumentList.first?.expression.as(MemberAccessExprSyntax.self),
            let resultBuilderName = resultBuilderSelfExpr.base?.withoutTrivia().description,
            let originalClosure = node.argumentList.dropFirst().first?.expression.as(ClosureExprSyntax.self) ?? node.trailingClosure
        else {
            throw SomeError()
        }
        
        let originalStatements: [CodeBlockItemSyntax] = originalClosure.statements.map { $0.withoutTrivia() }
        return "{ () -> any View in\n\(raw: rewrittenStatements(forOriginalStatments: originalStatements, resultBuilderName: resultBuilderName, context: &context))\n}"
    }
    
    private static func rewrittenStatements(forOriginalStatments originalStatements: [CodeBlockItemSyntax], finalCall: String? = nil, resultBuilderName: String, context: inout MacroExpansionContext) -> String {
        var localNames: [String] = []
        var newStatements: [String] = []
        
        for statement in originalStatements {
            switch statement.item {
            case .expr(let expr):
                let localName = context.createUniqueLocalName().description
                newStatements.append("let \(localName) = \(expr);")
                localNames.append(localName)
            case .stmt(let stmt):
                let localName = context.createUniqueLocalName().description
                if let ifStmt = stmt.as(IfStmtSyntax.self) {
                    newStatements.append("""
                    let \(localName) = {
                        if \(ifStmt.conditions) {
                            \(rewrittenStatements(forOriginalStatments: ifStmt.body.statements.map { $0.withoutTrivia() }, finalCall: "\(resultBuilderName).buildIf", resultBuilderName: resultBuilderName, context: &context))
                        }
                        return \(resultBuilderName).buildIf(nil)
                    }()
                    """)
                    localNames.append(localName)
                } else {
                    newStatements.append(stmt.description)
                }
            default:
                newStatements.append(statement.description)
            }
        }
        
        if let finalCall {
            newStatements.append("return \(finalCall)(\(resultBuilderName).buildBlock(\(localNames.joined(separator: ", "))))")
        } else {
            newStatements.append("return \(resultBuilderName).buildBlock(\(localNames.joined(separator: ", ")))")
        }
        
        let joinedStatements = newStatements.joined(separator: "\n")
        return joinedStatements
    }
}

public struct ResultBuilderMacro: ExpressionMacro {
    public static func expansion(
        of node: MacroExpansionExprSyntax, in context: inout MacroExpansionContext
    ) throws -> ExprSyntax {
        guard
            let resultBuilderSelfExpr = node.argumentList.first?.expression.as(MemberAccessExprSyntax.self),
            let resultBuilderName = resultBuilderSelfExpr.base?.withoutTrivia().description,
            let originalClosure = node.argumentList.dropFirst().first?.expression.as(ClosureExprSyntax.self)
        else {
            throw SomeError()
        }
        
        let originalStatements: [CodeBlockItemSyntax] = Array(originalClosure.statements.map { $0.withoutTrivia() })
        guard let firstStatement = originalStatements.first else {
            throw SomeError()
        }
        
        var localName = context.createUniqueLocalName()
        var newStatements: [String] = []
        newStatements.append("let \(localName) = \(resultBuilderName).buildPartialBlock(first: \(resultBuilderName).buildExpression(\(firstStatement)));")
        
        for statement in originalStatements.dropFirst() {
            let newLocalName = context.createUniqueLocalName()
            newStatements.append("let \(newLocalName) = \(resultBuilderName).buildPartialBlock(accumulated: \(localName), next: \(resultBuilderName).buildExpression(\(statement)));")
            localName = newLocalName
        }
        
        newStatements.append("return \(resultBuilderName).buildFinalResult(\(localName))")
        
        let joinedStatements = newStatements.joined(separator: "\n")
        return "{ () -> String in\n\(raw: joinedStatements)\n}"
        
        let string: String
        string = "{ () -> String in\n\(joinedStatements)\n}"
        return "{ () -> String in \(literal: string) }"
    }
}

struct SomeError: Error {}
