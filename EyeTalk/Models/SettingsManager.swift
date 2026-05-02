import Foundation
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var dwellTime: Double    { didSet { save("dwellTime",    dwellTime) } }
    @Published var speechRate: Double   { didSet { save("speechRate",   speechRate) } }
    @Published var speechVolume: Double { didSet { save("speechVolume", speechVolume) } }
    @Published var gazeScaleX: Double   { didSet { save("gazeScaleX",   gazeScaleX) } }
    @Published var gazeScaleY: Double   { didSet { save("gazeScaleY",   gazeScaleY) } }
    @Published var autoSpeak: Bool      { didSet { save("autoSpeak",    autoSpeak) } }

    private init() {
        let ud = UserDefaults.standard
        dwellTime    = ud.object(forKey: "dwellTime")    as? Double ?? 1.0
        speechRate   = ud.object(forKey: "speechRate")   as? Double ?? 0.5
        speechVolume = ud.object(forKey: "speechVolume") as? Double ?? 1.0
        gazeScaleX   = ud.object(forKey: "gazeScaleX")   as? Double ?? 5000
        gazeScaleY   = ud.object(forKey: "gazeScaleY")   as? Double ?? 5500
        autoSpeak    = ud.object(forKey: "autoSpeak")     as? Bool   ?? false
    }

    private func save(_ key: String, _ value: Any) {
        UserDefaults.standard.set(value, forKey: key)
    }
}
