import SwiftUI

// MARK: - Key View

struct KeyView: View {
    let key: KeyItem
    let isGazed: Bool
    let progress: Double

    private var bgColor: Color {
        switch key.action {
        case .backspace, .modeSwitch:
            return Color(UIColor.systemGray5)
        default:
            return .white
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(bgColor)
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)

            if isGazed && progress > 0 {
                RoundedRectangle(cornerRadius: 12)
                    .trim(from: 0, to: progress)
                    .stroke(Color.blue.opacity(0.7),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }

            Text(key.label)
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(.primary)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isGazed ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isGazed ? 1.04 : 1.0)
        .animation(.easeOut(duration: 0.08), value: isGazed)
    }
}

// MARK: - Gaze Cursor

struct GazeCursorView: View {
    let point: CGPoint
    let isTracking: Bool

    var body: some View {
        if isTracking {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 44, height: 44)
                Circle()
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: 9, height: 9)
            }
            .position(point)
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Main View

struct EyeTypingKeyboardView: View {
    @ObservedObject var vm: KeyboardViewModel

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar
                textDisplayArea
                keyboardSection
            }

            GazeCursorView(point: vm.gazePoint, isTracking: vm.isTracking)
        }
        .overlayPreferenceValue(KeyAnchorPreferenceKey.self) { prefs in
            GeometryReader { proxy in
                Color.clear
                    .onAppear { updateFrames(prefs: prefs, proxy: proxy) }
                    .onChange(of: prefs.map(\.id)) { _, _ in
                        updateFrames(prefs: prefs, proxy: proxy)
                    }
            }
            .ignoresSafeArea()
        }
        .onAppear { vm.startTracking() }
        .onDisappear { vm.stopTracking() }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            Text("コミュニケーション")
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Button {
                vm.performAction(.speak)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Text Display

    private var textDisplayArea: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(UIColor.separator), lineWidth: 0.5)
                )
            ScrollView {
                Text(vm.inputText.isEmpty ? "ボタンを選んでください" : vm.inputText)
                    .font(.title3)
                    .foregroundColor(
                        vm.inputText.isEmpty ? Color(UIColor.placeholderText) : .primary
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
        }
        .frame(height: 110)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Keyboard

    private var keyboardSection: some View {
        GeometryReader { geo in
            let rows = vm.currentRows
            let hPad: CGFloat = 8
            let vPad: CGFloat = 8
            let colSpacing: CGFloat = 8
            let rowSpacing: CGFloat = 8
            let keyHeight = (geo.size.height - vPad * 2 - CGFloat(rows.count - 1) * rowSpacing)
                            / CGFloat(rows.count)

            VStack(spacing: rowSpacing) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: colSpacing) {
                        ForEach(row) { key in
                            let isGazed = vm.gazedKeyID == key.id
                            KeyView(
                                key: key,
                                isGazed: isGazed,
                                progress: isGazed ? vm.dwellProgress : 0
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: keyHeight)
                            .anchorPreference(
                                key: KeyAnchorPreferenceKey.self,
                                value: .bounds
                            ) { [KeyFrameData(id: key.id, anchor: $0)] }
                            .onTapGesture { vm.performAction(key.action) }
                        }
                    }
                }
            }
            .padding(.horizontal, hPad)
            .padding(.vertical, vPad)
        }
    }

    // MARK: - Helpers

    private func updateFrames(prefs: [KeyFrameData], proxy: GeometryProxy) {
        vm.resolvedKeyFrames = Dictionary(
            prefs.map { ($0.id, proxy[$0.anchor]) },
            uniquingKeysWith: { $1 }
        )
    }
}

#Preview {
    EyeTypingKeyboardView(vm: KeyboardViewModel(
        gazeTracker: ARFaceTrackingManager(),
        speech: SpeechManager(),
        settings: SettingsManager.shared
    ))
}
