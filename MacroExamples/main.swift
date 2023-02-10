
import Foundation
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
// let text = "oops"
// #myWarning(text)

struct Font: ExpressibleByFontLiteral {
  init(fontLiteralName: String, size: Int, weight: MacroExamplesLib.FontWeight) {
  }
}

let _: Font = #fontLiteral(name: "Comic Sans", size: 14, weight: .thin)

// TODO: February 2, 2023 snapshot toolchain cannot handle this, so disable it
// for now. The bug has been fixed on main and should be available in the next
// snapshot.
#if false
// Use the "wrapStoredProperties" macro to deprecate all of the stored
// properties.
@wrapStoredProperties(#"available(*, deprecated, message: "hands off my data")"#)
struct OldStorage {
  var x: Int
}

// The deprecation warning below comes from the deprecation attribute
// introduced by @wrapStoredProperties on OldStorage.
_ = OldStorage(x: 5).x
#endif

// Move the storage from each of the stored properties into a dictionary
// called `_storage`, turning the stored properties into computed properties.
@DictionaryStorage
struct Point {
  var x: Int = 1
  var y: Int = 2
}

var point = Point()
print("Point storage begins as an empty dictionary: \(point)")
print("Default value for point.x: \(point.x)")
point.y = 17
print("Point storage contains only the value we set:  \(point)")

// MARK: - ObservableMacro

struct Treat {}

@Observable
final class Dog: Observable {
  var name: String?
  var treat: Treat?

  var isHappy: Bool = true

  init() {}

  func bark() {
    print("bork bork")
  }
}

let dog = Dog()
print(dog.name ?? "")
dog.name = "George"
dog.treat = Treat()
print(dog.name ?? "")
dog.bark()

// MARK: NewType

@NewType(String.self)
struct Hostname:
  NewTypeProtocol,
  Hashable,
  CustomStringConvertible
{ }

@NewType(String.self)
struct Password:
  NewTypeProtocol,
  Hashable,
  CustomStringConvertible
{
  var description: String { "(redacted)" }
}

let hostname = Hostname("localhost")
print("hostname: description=\(hostname) hashValue=\(hostname.hashValue)")

let password = Password("squeamish ossifrage")
print("password: description=\(password) hashValue=\(password.hashValue)")

// MARK: CustomCodable

@CustomCodable
struct Party: Codable {
  enum Theme: Codable {
    case halloween
    case birthday
    case piratesAndMonstersAndUnicornsAndEverythingElse
  }
  
  @CustomKey("host_name")
  var hostName: String
  var theme: Theme
  var numberOfGuests: Int = 0 {
    didSet {
      print("Someone came! Or went, I don't know...")
    }
  }
  
  var description: String {
    "\(hostName) has invited \(numberOfGuests) \(theme == .halloween ? "ghosts" : "guests")!"
  }
}

let party = Party(
  hostName: "Jim",
  theme: .halloween,
  numberOfGuests: 2
)
let encoder = JSONEncoder()
let partyData = try encoder.encode(party)
print(String(data: partyData, encoding: .utf8)!)
let decoder = JSONDecoder()
let partyCopy = try decoder.decode(Party.self, from: partyData)
print(partyCopy.description)
