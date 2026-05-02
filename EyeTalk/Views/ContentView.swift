import SwiftUI

struct ContentView: View {
    @ObservedObject var vm: KeyboardViewModel

    var body: some View {
        TabView {
            EyeTypingKeyboardView(vm: vm)
                .tabItem {
                    Label("キーボード", systemImage: "keyboard")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView(vm: KeyboardViewModel(
        gazeTracker: ARFaceTrackingManager(),
        speech: SpeechManager(),
        settings: SettingsManager.shared
    ))
}
