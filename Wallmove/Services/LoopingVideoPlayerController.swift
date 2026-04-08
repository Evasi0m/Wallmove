import AVFoundation
import AppKit
import Combine

@MainActor
final class LoopingVideoPlayerController: ObservableObject {
    private weak var attachedView: PlayerLayerView?
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var currentURL: URL?
    private var isPaused = false

    func attach(to view: PlayerLayerView) {
        attachedView = view
        view.playerLayer.player = player
    }

    func loadVideo(url: URL?) {
        guard currentURL != url else {
            updatePlaybackState()
            return
        }

        currentURL = url

        guard let url else {
            looper = nil
            player?.pause()
            player = nil
            attachedView?.playerLayer.player = nil
            return
        }

        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = true
        queuePlayer.preventsDisplaySleepDuringVideoPlayback = false
        queuePlayer.actionAtItemEnd = .none

        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        player = queuePlayer
        attachedView?.playerLayer.player = queuePlayer
        updatePlaybackState()
    }

    func setPaused(_ paused: Bool) {
        isPaused = paused
        updatePlaybackState()
    }

    private func updatePlaybackState() {
        guard let player else {
            return
        }

        if isPaused {
            player.pause()
        } else {
            player.play()
        }
    }
}
