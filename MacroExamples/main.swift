
import MacroExamplesLib

let x = 1
let y = 2
let z = 3

// "Stringify" macro turns the expression into a string.
print(#stringify(x + y))

// "AddBlocker" complains about addition operations. We emit a warning
// so it doesn't block compilation.
print(#addBlocker(x * y + z))

#myWarning("remember to pass a string literal here")

// Uncomment to get an error out of the macro.
//   let text = "oops"
//   #myWarning(text)


struct Font: ExpressibleByFontLiteral {
  init(fontLiteralName: String, size: Int, weight: MacroExamplesLib.FontWeight) {
  }
}

let font: Font = #fontLiteral(name: "Comic Sans", size: 14, weight: .thin)

func doSomething(_ a: Int, b: Int, c d: Int, e _: Int, _: Int, _ _: Int) {
    #printArguments()
}

// Prints doSomething(42, b: 256, c: 512, e: _, _, _)
doSomething(42, b: 256, c: 512, e: 600, 1024, 2048)

@resultBuilder
struct StringAppender: ResultBuilder {
    enum Either<First, Second> {
        case first(First)
        case second(Second)
    }
    
    static func buildExpression(_ expression: String) -> String {
        expression
    }
    
    static func buildExpression<T>(_ expression: T) -> String {
        String(describing: expression)
    }
    
    static func buildEither<First, Second>(first: First) -> Either<First, Second> {
        .first(first)
    }
    
    static func buildEither<First, Second>(second: Second) -> Either<First, Second> {
        .second(second)
    }
    
    static func buildPartialBlock(first: String) -> String {
        first
    }
    
    static func buildPartialBlock(accumulated: String, next: String) -> String {
        accumulated + " " + next
    }
    
    
    static func buildFinalResult(_ component: String) -> String {
        component
    }
}

@StringAppender
var string: String {
    "This"
    "is"
    "a"
    "sentence."
}

let stringClosure = #apply(resultBuilder: StringAppender.self, to: {
    "This"
    "is"
    "a"
    "sentence."
})

//let stringClosure = { () -> String in
//    let __macro_local_0 = StringAppender.buildPartialBlock(first: StringAppender.buildExpression("This"));
//    let __macro_local_1 = StringAppender.buildPartialBlock(accumulated: __macro_local_0, next: StringAppender.buildExpression("is"));
//    let __macro_local_2 = StringAppender.buildPartialBlock(accumulated: __macro_local_1, next: StringAppender.buildExpression("a"));
//    let abc = {
//        if false {
//            return true ? StringAppender.buildEither(first: "") : StringAppender.buildEither(second: "")
//        } else if true {
//            return StringAppender.buildEither(first: "")
//        } else {
//            return StringAppender.buildEither(second: "")
//        }
//    }()
//    let a = (true) ? StringAppender.buildEither(first: "") : StringAppender.buildEither(second: "")
//    let __macro_local_3 = StringAppender.buildPartialBlock(accumulated: __macro_local_2, next: StringAppender.buildExpression("sentence."));
//    return StringAppender.buildFinalResult(__macro_local_3)
//    }

func abc() -> String {
    print("Function was executed")
    return "abc"
}

//print(type(of: false ? abc() : nil).)

print(string)
print(stringClosure())

import SwiftUI

@ViewBuilder var ogView: some View {
    Text("This")
        .foregroundColor(.red)
    Text("is")
    Text("a")
    if long {
        Text("long")
            .bold()
    }
    let lastWord = "Sentence"
    Text(lastWord)
}

print(type(of: ogView))

let very = true
let long = true

let view = #apply(resultBuilder2: ViewBuilder.self) {
    Text("This")
    Text("is")
    Text("a")
    if very {
        Text("very")
    }
    if long {
        Text("long")
    } else {
        Text("short")
    }
    let lastWord = "Sentence"
    Text(lastWord)
}

print(type(of: view()))
