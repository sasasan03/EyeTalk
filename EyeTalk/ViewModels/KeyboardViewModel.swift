import SwiftUI
import Combine

enum KeyboardMode: Equatable { case kana, number }

// MARK: - Preference Key for global key frames

struct KeyFrameData {
    let id: String
    let anchor: Anchor<CGRect>
}

struct KeyAnchorPreferenceKey: PreferenceKey {
    static let defaultValue: [KeyFrameData] = []
    static func reduce(value: inout [KeyFrameData], nextValue: () -> [KeyFrameData]) {
        value.append(contentsOf: nextValue())
    }
}

// MARK: - ViewModel

class KeyboardViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var gazedKeyID: String? = nil
    @Published var dwellProgress: Double = 0
    @Published var gazePoint: CGPoint = .zero
    @Published var isTracking: Bool = false
    @Published var keyboardMode: KeyboardMode = .kana

    /// 現在のモードに応じたキー配列を返す。
    var currentRows: [[KeyItem]] {
        keyboardMode == .kana ? kanaRows : numberRows
    }

    var resolvedKeyFrames: [String: CGRect] = [:]

    private var dwellTime: Double = 1.0
    private var currentKeyID: String? = nil
    private var dwellStart: Date? = nil
    private var cooldownUntil: Date = .distantPast
    private var updateTimer: Timer?

    private let gazeTracker: ARFaceTrackingManager
    let speech: SpeechManager
    let settings: SettingsManager
    private var cancellables = Set<AnyCancellable>()

    /// 依存を注入し、Combine バインディングと 60fps ドウェル判定タイマーを開始する。
    init(gazeTracker: ARFaceTrackingManager, speech: SpeechManager, settings: SettingsManager) {
        self.gazeTracker = gazeTracker
        self.speech = speech
        self.settings = settings

        gazeTracker.$gazePoint
            .receive(on: RunLoop.main)
            .sink { [weak self] pt in self?.gazePoint = pt }
            .store(in: &cancellables)

        gazeTracker.$isTracking
            .receive(on: RunLoop.main)
            .sink { [weak self] v in self?.isTracking = v }
            .store(in: &cancellables)

        settings.$gazeScaleX
            .receive(on: RunLoop.main)
            .sink { [weak self] v in self?.gazeTracker.scaleX = CGFloat(v) }
            .store(in: &cancellables)

        settings.$gazeScaleY
            .receive(on: RunLoop.main)
            .sink { [weak self] v in self?.gazeTracker.scaleY = CGFloat(v) }
            .store(in: &cancellables)

        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        updateTimer = timer
    }

    deinit { updateTimer?.invalidate() }

    /// TrueDepth カメラ非搭載端末では何もしない。
    func startTracking() {
        if ARFaceTrackingManager.isSupported { gazeTracker.start() }
    }

    /// ARSession を停止し、バッテリー消費を抑える。
    func stopTracking() { gazeTracker.stop() }

    /// 60fps で呼ばれ、視線座標がキー上に滞留した時間を計測してドウェル選択を判定する。
    private func tick() {
        let point = gazePoint
        let now = Date()
        dwellTime = settings.dwellTime

        guard now >= cooldownUntil else {
            dwellProgress = 0
            return
        }

        let hitID = resolvedKeyFrames.first { $0.value.contains(point) }?.key

        if let id = hitID {
            if id == currentKeyID {
                guard let start = dwellStart else { return }
                let elapsed = now.timeIntervalSince(start)
                dwellProgress = min(elapsed / dwellTime, 1.0)
                if elapsed >= dwellTime { activateKey(id: id) }
            } else {
                currentKeyID = id
                gazedKeyID = id
                dwellStart = now
                dwellProgress = 0
            }
        } else {
            if currentKeyID != nil {
                currentKeyID = nil
                gazedKeyID = nil
                dwellStart = nil
                dwellProgress = 0
            }
        }
    }

    /// キーを確定し、誤連打防止のため 0.6 秒クールダウンを設定する。
    private func activateKey(id: String) {
        guard let key = currentRows.flatMap({ $0 }).first(where: { $0.id == id }) else { return }
        performAction(key.action)
        cooldownUntil = Date().addingTimeInterval(0.6)
        dwellStart = nil
        dwellProgress = 0
    }

    /// `KeyAction` を実行する。テストや設定画面から直接呼び出せるよう `internal` にしている。
    func performAction(_ action: KeyAction) {
        switch action {
        case .letter(let ch):
            inputText.append(ch)
            if settings.autoSpeak {
                speech.speak(ch, rate: Float(settings.speechRate), volume: Float(settings.speechVolume))
            }
        case .backspace:
            if !inputText.isEmpty { inputText.removeLast() }
        case .modeSwitch:
            keyboardMode = keyboardMode == .kana ? .number : .kana
            gazedKeyID = nil
            dwellProgress = 0
            currentKeyID = nil
        case .speak:
            speech.speak(inputText, rate: Float(settings.speechRate), volume: Float(settings.speechVolume))
        }
    }
}
