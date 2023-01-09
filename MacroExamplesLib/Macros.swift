
/// "Stringify" the provided value and produce a tuple that includes both the
/// original value as well as the source code that generated it.
@expression public macro stringify<T>(_ value: T) -> (T, String) = MacroExamplesPlugin.StringifyMacro

/// Macro that produces a warning on "+" operators within the expression, and
/// suggests changing them to "-".
@expression public macro addBlocker<T>(_ value: T) -> T = MacroExamplesPlugin.AddBlocker

/// Macro that produces a warning, as a replacement for the built-in
/// #warning("...").
@expression public macro myWarning(_ message: String) = MacroExamplesPlugin.WarningMacro

public enum FontWeight {
  case thin
  case normal
  case medium
  case semiBold
  case bold
}

public protocol ExpressibleByFontLiteral {
  init(fontLiteralName: String, size: Int, weight: FontWeight)
}

/// Font literal similar to, e.g., #colorLiteral.
@expression public macro fontLiteral<T>(name: String, size: Int, weight: FontWeight) -> T = MacroExamplesPlugin.FontLiteralMacro
  where T: ExpressibleByFontLiteral

/// Can be called inside a function to print the function name and arguments.
@expression public macro printArguments() = MacroExamplesPlugin.PrintArgumentsMacro

@expression public macro apply<R: ResultBuilder>(resultBuilder: R.Type, to closure: () -> Void) -> (() -> String) = MacroExamplesPlugin.ResultBuilderMacro

public protocol ResultBuilder {
    associatedtype Component
    associatedtype FinalResult
    
    static func buildPartialBlock(first: Component) -> Component
    
    static func buildPartialBlock(accumulated: Component, next: Component) -> Component
    
    static func buildFinalResult(_ component: Component) -> FinalResult
}

import SwiftUI

@expression public macro apply<R>(resultBuilder2: R.Type, to closure: () -> Void) -> (() -> any View) = MacroExamplesPlugin.ResultBuilderMacro2
