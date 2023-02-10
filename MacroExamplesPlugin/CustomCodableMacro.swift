import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum CustomCodableMacro {}

extension CustomCodableMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    
    let storedProperties = declaration.members.members.compactMap {
      StoredProperty(potentialPropertyDeclaration: $0.decl, diagnosticHandler: context.diagnose)
    }
    
    let codingKeyDefinitions = storedProperties.map { property in
      "\(property.name) = \(property.keyLiteral)"
    }
    
    let codingKeysSyntax: DeclSyntax = """
      enum CodingKeys: String, CodingKey {
        case \(raw: codingKeyDefinitions.joined(separator: ", "))
      }
      """
    
    let encodingCode = storedProperties
      .map { property in
        "  try container.encode(\(property.name), forKey: .\(property.name))"
      }
      .joined(separator: "\n")
    
    let encodeFunctionSyntax: DeclSyntax = """
      func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
      \(raw: encodingCode)
      }
      """
    
    let decodingCode = storedProperties
      .map { property in
        "  self.\(property.name) = try container._decodeInferredType(forKey: .\(property.name))"
      }
      .joined(separator: "\n")
    
    let decodingInitializerSyntax: DeclSyntax = """
      init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
      \(raw: decodingCode)
      }
      """
    
    let propertiesWithTypeAnnotations = storedProperties.filter { $0.typeName != nil }
    
    let parameterList = propertiesWithTypeAnnotations
      .map { property in
        "\(property.name): \(property.typeName!)\(property.initializer.map { " " + $0 } ?? "")"
      }
      .joined(separator: ", ")
    
    let propertyAssignmentList = propertiesWithTypeAnnotations
      .map { property in
        "self.\(property.name) = \(property.name)"
      }
      .joined(separator: "\n  ")
    
    let memberwiseInitializer: DeclSyntax = """
      init(
        \(raw: parameterList)
      ) {
        \(raw: propertyAssignmentList)
      }
      """
    
    return [codingKeysSyntax, encodeFunctionSyntax, decodingInitializerSyntax, memberwiseInitializer]
  }
}

// MARK: - StoredProperty

fileprivate struct StoredProperty {
  var name: String
  var typeName: String?
  var keyLiteral: String
  var initializer: String?
}

extension StoredProperty {
  init?(potentialPropertyDeclaration: DeclSyntax, diagnosticHandler: (Diagnostic) -> Void) {
    guard let property = potentialPropertyDeclaration.as(VariableDeclSyntax.self) else {
      return nil
    }
    
    self.init(property, diagnosticHandler: diagnosticHandler)
  }
  
  init?(_ property: VariableDeclSyntax, diagnosticHandler: (Diagnostic) -> Void) {
    guard
      property.isStoredProperty,
      let binding = property.bindings.first,
      let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier
    else {
      return nil
    }
    
    let attributes = property.attributes ?? []
    let key = attributes
      .compactMap { syntax -> String? in
        guard
          let attributeSyntax = syntax.as(AttributeSyntax.self),
          attributeSyntax.attributeName.trimmedDescription == "CustomKey",
          let argument = attributeSyntax.argument
        else {
          return nil
        }
        
        return argument.trimmedDescription
      }
      .first
    
    self.name = identifier.text
    self.typeName = binding.typeAnnotation?.type.trimmedDescription
    self.keyLiteral = key ?? "\"\(identifier.text)\""
    self.initializer = binding.initializer?.trimmedDescription
    
    if typeName == nil {
      let message = SimpleDiagnosticMessage(
        message: "@CustomCodable requires that all properties have an explicit type annotation",
        diagnosticID: .init(domain: "test", id: "error"),
        severity: .warning
      )
      diagnosticHandler(.init(node: binding.initializer?.as(Syntax.self) ?? property.as(Syntax.self)!, message: message))
    }
  }
}

// MARK: - CustomKeyDummyMacro

/// This macro does nothing. It is only used as a hint for `CustomCodableMacro`.
public enum CustomKeyDummyMacro {}

extension CustomKeyDummyMacro: AccessorMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AccessorDeclSyntax] {
    return []
  }
}
