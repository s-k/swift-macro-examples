import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `wrapStoredProperties` macro, which can be
/// used to apply an attribute to all of the stored properties of a type.
///
/// This macro demonstrates member-attribute macros, which allow an attribute
/// written on a type or extension to apply attributes to the members
/// declared within that type or extension.
public struct WrapStoredPropertiesMacro: MemberAttributeMacro {
  public static func expansion<
    Declaration: DeclGroupSyntax,
    Context: MacroExpansionContext
  >(
    of node: AttributeSyntax,
    attachedTo decl: Declaration,
    providingAttributesFor member: some DeclSyntaxProtocol,
    in context: Context
  ) throws -> [AttributeSyntax] {
    guard let property = member.as(VariableDeclSyntax.self),
          property.isStoredProperty
    else {
      return []
    }

    guard case let .argumentList(arguments) = node.argument,
        let firstElement = arguments.first,
        let stringLiteral = firstElement.expression
      .as(StringLiteralExprSyntax.self),
          stringLiteral.segments.count == 1,
          case let .stringSegment(wrapperName)? = stringLiteral.segments.first else {
      throw CustomError.message("macro requires a string literal containing the name of an attribute")
    }

    return [
      AttributeSyntax(
        attributeName: SimpleTypeIdentifierSyntax(
          name: .identifier(wrapperName.content.text)
        )
      )
      .with(\.leadingTrivia, [.newlines(1), .spaces(2)])
    ]
  }
}

extension VariableDeclSyntax {
  /// Determine whether this variable has the syntax of a stored property.
  ///
  /// This syntactic check cannot account for semantic adjustments due to,
  /// e.g., accessor macros or property wrappers.
  var isStoredProperty: Bool {
    if bindings.count != 1 {
      return false
    }

    let binding = bindings.first!
    switch binding.accessor {
    case .none:
      return true

    case .accessors(let node):
      for accessor in node.accessors {
        switch accessor.accessorKind.tokenKind {
        case .keyword(.willSet), .keyword(.didSet):
          // Observers can occur on a stored property.
          break

        default:
          // Other accessors make it a computed property.
          return false
        }
      }

      return true

    case .getter:
      return false

    @unknown default:
      return false
    }
  }
}

extension DeclGroupSyntax {
  /// Enumerate the stored properties that syntactically occur in this
  /// declaration.
  func storedProperties() -> [VariableDeclSyntax] {
    return members.members.compactMap { member in
      guard let variable = member.decl.as(VariableDeclSyntax.self),
            variable.isStoredProperty else {
        return nil
      }

      return variable
    }
  }
}
