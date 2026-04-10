import AVFoundation

@MainActor
final class LoopingVideoPlayerController: ObservableObject {
    private weak var attachedView: PlayerLayerView?
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var currentURL: URL?
    private var isPaused = false

    func attach(to view: PlayerLayerView) {
        if attachedView !== view {
            attachedView?.playerLayer.player = nil
        }

        attachedView = view
        view.playerLayer.player = player
    }

    func loadVideo(url: URL?) {
        guard currentURL != url else {
            updatePlaybackState()
            return
        }

        tearDownCurrentPlayer()
        currentURL = url

        guard let url else {
            return
        }

        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = true
        queuePlayer.preventsDisplaySleepDuringVideoPlayback = false
        queuePlayer.actionAtItemEnd = .none
        queuePlayer.automaticallyWaitsToMinimizeStalling = false

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

    private func tearDownCurrentPlayer() {
        looper = nil
        player?.pause()
        player?.removeAllItems()
        attachedView?.playerLayer.player = nil
        player = nil
    }
}
