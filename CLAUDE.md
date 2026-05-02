# CLAUDE.md — EyeTalk
視線追跡でQWERTYキーボードを操作し、AVFoundation で読み上げる iOS アプリ。

## プロジェクト構成（MVVM）

```
EyeTalk/
├── App/
│   └── EyeTalkApp.swift          # 全依存を生成して KeyboardViewModel に注入するエントリーポイント
├── Models/
│   ├── ARFaceTrackingManager.swift  # ARSession 管理、lookAtPoint→画面座標変換、EMA 平滑化
│   ├── SpeechManager.swift          # AVSpeechSynthesizer ラッパー
│   ├── SettingsManager.swift        # UserDefaults による永続設定（シングルトン）
│   └── KeyItem.swift                # KeyAction, KeyItem, keyboardRows の定義
├── ViewModels/
│   └── KeyboardViewModel.swift      # ドウェル判定、gazePoint/isTracking の公開、KeyAnchorPreferenceKey
└── Views/
    ├── ContentView.swift            # TabView（KeyboardViewModel を受け取る）
    ├── EyeTypingKeyboardView.swift  # メイン UI、gaze cursor、dwell progress ring
    └── SettingsView.swift           # 設定画面（SettingsManager.shared を直接参照）
```

**依存の流れ**: `EyeTalkApp` → `KeyboardViewModel` ← `ARFaceTrackingManager / SpeechManager / SettingsManager`

**注記**: Xcode 16+ の `PBXFileSystemSynchronizedRootGroup` を使用しているため、`project.pbxproj` にファイル個別のエントリは存在しない。フォルダ移動時に `project.pbxproj` の編集は不要。

## 必須環境

- **実機必須**: ARKit ARFaceTrackingConfiguration は TrueDepth カメラが必要（iPhone X 以降）。シミュレータ不可。
- iOS 26.0+、Swift 5.0、Bundle ID: `com.sako.EyeTalk`
- Xcode で実機ビルド後、Xcode console のログで ARSession 状態を確認する。

## 重要な設計パターン

### Actor Isolation
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` が有効なため、ARSessionDelegate は必ず次のパターンを使う:

```swift
// NG: MainActor メソッドを ARSessionDelegate から直接呼ぶ
func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) { ... }

// OK
nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    Task { [weak self] @MainActor in
        // UI 更新
    }
}
```
### キーのグローバル座標解決
キーフレームは `anchorPreference + overlayPreferenceValue(.ignoresSafeArea())` で解決する。
`GeometryReader` で直接座標を取ると SafeArea オフセットがズレるため使用禁止。

### ドウェル選択
- 選択後 **0.6秒クールダウン** を入れる（誤連打防止）
- ドウェル方式はウィンク方式より誤検知が少ないため採用。新しい選択トリガーを追加する場合もドウェルベースを原則とする。

### 視線スケーリング
`scaleX=5000 / scaleY=5500` はデフォルト値。設定画面から校正可能にしているため、ハードコードを増やさないこと。

## 開発ワークフロー

### 複雑な変更は Plan モードから始める
実機テストのサイクルが長いため、実装前に計画を立てて一発で仕上げる。

### 修正後は CLAUDE.md を更新する
設計判断・制約・ハマりポイントが発生したら、このファイルに追記する:
> 修正後: "この失敗を繰り返さないよう CLAUDE.md を更新して"

### UI の動作確認
型チェックやビルド成功だけでは不十分。実機で以下を必ず確認:
1. 視線カーソルが画面全体に追従するか
2. ドウェルで正しくキーが選択されるか
3. AVSpeechSynthesizer が発話するか
4. 設定変更がリアルタイムに反映されるか

## コーディング規約

- **コメントは「なぜ」だけ書く**。コードが自明なことは書かない。
- `@Published` + `ObservableObject` パターンで状態を管理。SwiftUI の `@StateObject` / `@ObservedObject` を使う。
- エラーハンドリングは ARSession / AVSpeechSynthesizer 等のシステム境界のみ。内部ロジックは guard/precondition で十分。
- 新機能追加時は既存の Actor isolation パターン（`nonisolated` + `Task { @MainActor in }`）を踏襲する。
- 抽象化は3箇所以上で同じパターンが出てから検討する。

## よくある問題

| 症状 | 原因 | 対処 |
|---|---|---|
| 視線が画面端に張り付く | scaleX/Y が大きすぎる | 設定画面で校正、またはデフォルト値を調整 |
| キー座標がズレる | GeometryReader で SafeArea 含む座標を使っている | anchorPreference パターンに戻す |
| ARSession が起動しない | TrueDepth カメラなし or 権限なし | 実機確認、Info.plist の NSCameraUsageDescription を確認 |
| MainActor 警告/エラー | ARSessionDelegate から直接 @Published を更新 | nonisolated + Task パターンを使う |

## 重要ルール
- 実装前に必ず計画を提案すること
- ユーザーが承認してから初めてコードを書くこと
- 計画は日本語の箇条書きで提示すること
- 実装後はエラーが発生した状態で終了しないこと