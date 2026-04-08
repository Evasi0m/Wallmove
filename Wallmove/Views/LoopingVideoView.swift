import AVFoundation
import SwiftUI

struct LoopingVideoView: NSViewRepresentable {
    let playerController: LoopingVideoPlayerController
    let videoGravity: AVLayerVideoGravity

    func makeNSView(context: Context) -> PlayerLayerView {
        let view = PlayerLayerView(frame: .zero)
        view.playerLayer.videoGravity = videoGravity
        playerController.attach(to: view)
        return view
    }

    func updateNSView(_ nsView: PlayerLayerView, context: Context) {
        nsView.playerLayer.videoGravity = videoGravity
        playerController.attach(to: nsView)
    }
}
