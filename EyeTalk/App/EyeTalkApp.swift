import SwiftUI

@main
struct EyeTalkApp: App {
    @StateObject private var vm: KeyboardViewModel

    init() {
        let tracker = ARFaceTrackingManager()
        let speech = SpeechManager()
        _vm = StateObject(wrappedValue: KeyboardViewModel(
            gazeTracker: tracker,
            speech: speech,
            settings: SettingsManager.shared
        ))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(vm: vm)
        }
    }
}
