import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("視線入力") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("タップ判定時間: \(settings.dwellTime, specifier: "%.1f") 秒")
                        Slider(value: $settings.dwellTime, in: 0.3...3.0, step: 0.1)
                    }
                    Toggle("自動読み上げ（文字入力ごと）", isOn: $settings.autoSpeak)
                }

                Section("視線感度調整") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("水平感度: \(Int(settings.gazeScaleX))")
                        Slider(value: $settings.gazeScaleX, in: 1000...12000, step: 100)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("垂直感度: \(Int(settings.gazeScaleY))")
                        Slider(value: $settings.gazeScaleY, in: 1000...12000, step: 100)
                    }
                    Button("感度をリセット") {
                        settings.gazeScaleX = 5000
                        settings.gazeScaleY = 5500
                    }
                    .foregroundColor(.red)
                }

                Section("読み上げ") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("読み上げ速度: \(settings.speechRate, specifier: "%.2f")")
                        Slider(value: $settings.speechRate, in: 0.1...1.0, step: 0.05)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("音量: \(settings.speechVolume, specifier: "%.1f")")
                        Slider(value: $settings.speechVolume, in: 0.1...1.0, step: 0.1)
                    }
                }

                Section("デバイス情報") {
                    HStack {
                        Text("視線追跡サポート")
                        Spacer()
                        Text(ARFaceTrackingManager.isSupported ? "対応" : "非対応")
                            .foregroundColor(ARFaceTrackingManager.isSupported ? .green : .red)
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    SettingsView()
}
