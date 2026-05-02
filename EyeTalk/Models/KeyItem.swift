import SwiftUI

enum KeyAction: Equatable {
    case letter(String)
    case backspace
    case modeSwitch(String)
    case speak
}

struct KeyItem: Identifiable, Equatable {
    let id: String
    let action: KeyAction
    var label: String {
        switch action {
        case .letter(let s):      return s
        case .backspace:          return "⌫"
        case .modeSwitch(let s):  return s
        case .speak:              return "読上"
        }
    }
}

let kanaRows: [[KeyItem]] = [
    [
        KeyItem(id: "あ", action: .letter("あ")),
        KeyItem(id: "か", action: .letter("か")),
        KeyItem(id: "さ", action: .letter("さ")),
    ],
    [
        KeyItem(id: "た", action: .letter("た")),
        KeyItem(id: "な", action: .letter("な")),
        KeyItem(id: "は", action: .letter("は")),
    ],
    [
        KeyItem(id: "ま", action: .letter("ま")),
        KeyItem(id: "や", action: .letter("や")),
        KeyItem(id: "ら", action: .letter("ら")),
    ],
    [
        KeyItem(id: "123",  action: .modeSwitch("123")),
        KeyItem(id: "わ",   action: .letter("わ")),
        KeyItem(id: "⌫",   action: .backspace),
    ],
]

let numberRows: [[KeyItem]] = [
    [
        KeyItem(id: "1", action: .letter("1")),
        KeyItem(id: "2", action: .letter("2")),
        KeyItem(id: "3", action: .letter("3")),
    ],
    [
        KeyItem(id: "4", action: .letter("4")),
        KeyItem(id: "5", action: .letter("5")),
        KeyItem(id: "6", action: .letter("6")),
    ],
    [
        KeyItem(id: "7", action: .letter("7")),
        KeyItem(id: "8", action: .letter("8")),
        KeyItem(id: "9", action: .letter("9")),
    ],
    [
        KeyItem(id: "かな",   action: .modeSwitch("かな")),
        KeyItem(id: "0",     action: .letter("0")),
        KeyItem(id: "⌫_num", action: .backspace),
    ],
]
