import ARKit
import Combine

class ARFaceTrackingManager: NSObject, ObservableObject {
    @Published var gazePoint: CGPoint = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
    @Published var isTracking: Bool = false

    static let isSupported = ARFaceTrackingConfiguration.isSupported

    var scaleX: CGFloat = 5000
    var scaleY: CGFloat = 5500

    private let session = ARSession()
    private var smoothed: CGPoint = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
    private let alpha: CGFloat = 0.2

    override init() {
        super.init()
        session.delegate = self
    }

    func start() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let config = ARFaceTrackingConfiguration()
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    func stop() {
        session.pause()
        isTracking = false
    }

    fileprivate func applyGaze(_ look: simd_float3) {
        let screen = UIScreen.main.bounds
        let rawX = screen.midX + CGFloat(look.x) * scaleX
        let rawY = screen.midY - CGFloat(look.y) * scaleY
        let cx = max(0, min(screen.width, rawX))
        let cy = max(0, min(screen.height, rawY))
        smoothed = CGPoint(
            x: smoothed.x + alpha * (cx - smoothed.x),
            y: smoothed.y + alpha * (cy - smoothed.y)
        )
        gazePoint = smoothed
        isTracking = true
    }
}

extension ARFaceTrackingManager: ARSessionDelegate {
    // ARKit callbacks arrive on a background queue; nonisolated + Task @MainActor hops to main actor.
    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let face = anchors.first(where: { $0 is ARFaceAnchor }) as? ARFaceAnchor else { return }
        let look = face.lookAtPoint
        Task { @MainActor in
            self.applyGaze(look)
        }
    }

    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        Task { @MainActor in self.isTracking = false }
    }

    nonisolated func sessionWasInterrupted(_ session: ARSession) {
        Task { @MainActor in self.isTracking = false }
    }

    nonisolated func sessionInterruptionEnded(_ session: ARSession) {
        Task { @MainActor in self.start() }
    }
}
