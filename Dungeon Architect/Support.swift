import SwiftUI
import AudioToolbox
import UIKit

// MARK: - Sound

enum DASound {
    case uiTap, build, erase, coin, trapSnap, hit, heroDown, monsterDown, win, lose, unlock
}

final class SoundBox {
    static let shared = SoundBox()
    var enabled: Bool = true

    private init() {}

    func play(_ s: DASound) {
        guard enabled else { return }
        let id: SystemSoundID
        switch s {
        case .uiTap: id = 1104
        case .build: id = 1105
        case .erase: id = 1155
        case .coin: id = 1057
        case .trapSnap: id = 1103
        case .hit: id = 1130
        case .heroDown: id = 1109
        case .monsterDown: id = 1107
        case .win: id = 1025
        case .lose: id = 1073
        case .unlock: id = 1117
        }
        AudioServicesPlaySystemSound(id)
    }
}

// MARK: - Haptics

enum Haptics {
    static var enabled: Bool = true

    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func thud() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func failure() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
