//
//  AmityAudioPlayer.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 3/12/2563 BE.
//  Copyright © 2563 BE Amity. All rights reserved.
//

import UIKit
import AVFoundation

protocol AmityAudioPlayerDelegate: AnyObject {
    func playing()
    func stopPlaying()
    func finishPlaying()
    func displayDuration(_ duration: String)
}

final class AmityAudioPlayer: NSObject {
    
    static let shared = AmityAudioPlayer()
    weak var delegate: AmityAudioPlayerDelegate?
    
    let playerAudio = AVQueuePlayer()
    var timeObserverToken: Any?
    var durationTime: Double = 0.0
    var isPlayFinish: Bool = false
    
    var fileName: String?
    var path: URL?
    private var _fileName: String?
    private var player: AVAudioPlayer!
    private var timer: Timer?
    private var duration: TimeInterval = 0.0 {
        didSet {
            displayDuration()
        }
    }
    func isPlaying() -> Bool {
        if playerAudio.rate == 1 {
            if _fileName == fileName {
                return false
            } else {
                return true
            }
        } else {
            if _fileName == fileName {
                return false
            } else {
                return true
            }
        }
    }
    
    func play() {
        resetTimer()
        if player == nil {
            playAudio()
        } else {
            if _fileName != fileName {
                stop()
                playAudio()
            } else {
                if player.isPlaying {
                    stop()
                } else {
                    playAudio()
                }
            }
        }
    }
    
    func stop() {
        if player != nil {
            player.stop()
            player = nil
            resetTimer()
            delegate?.stopPlaying()
        }
    }
    
    // MARK: - Helper functions
    
    private func playAudio() {
        _fileName = fileName
        prepare()
    }
    
    func setObserver() {
        NotificationCenter.default
            .addObserver(self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerAudio.currentItem
        )
    }
    
    func startAudio() {
        if playerAudio.rate == 1 {
            if _fileName == fileName {
                if isPlayFinish {
                    delegate?.playing()
                    playerAudio.pause()
                    getPlayAudio()
                    playerAudio.play()
                    isPlayFinish = false
                } else {
                    delegate?.stopPlaying()
                    playerAudio.pause()
                }
            } else {
                delegate?.stopPlaying()
                playerAudio.pause()
                getPlayAudio()
                delegate?.playing()
                playerAudio.play()
                _fileName = fileName
            }
        } else {
            if _fileName != fileName {
                playerAudio.pause()
                getPlayAudio()
                delegate?.playing()
                playerAudio.play()
                _fileName = fileName
            } else {
                delegate?.playing()
                playerAudio.play()
                _fileName = fileName
            }
        }
    }
    
    func stopAudio() {
        playerAudio.pause()
    }
    
    @objc func playerDidFinishPlaying() {
        isPlayFinish = true
        stopAudio()
        getPlayAudio()
        delegate?.finishPlaying()
    }
    
    func getPlayAudio() {
        if playerAudio.rate != 1 {
            guard let audioURL = path else {
                Log.add("Audio file not found")
                return
            }
            playerAudio.removeAllItems()
            playerAudio.insert(AVPlayerItem(url: audioURL), after: nil)
        }
    }
    
    func startObservingTime() {
        let timeInterval = CMTimeMake(value: 1, timescale: 1)
        timeObserverToken = playerAudio.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main) { [weak self] time in
            if let currentItem = self?.playerAudio.currentItem {
                let duration = currentItem.duration
                let remainingTime = duration.seconds - time.seconds.magnitude
                if remainingTime >= 0 {
                    let time = Int(remainingTime)
                    let minutes = Int(time) / 60 % 60
                    let seconds = Int(time) % 60
                    let display = String(format:"%02i:%02i", minutes, seconds)
                    self?.delegate?.displayDuration(display)
                    if time == 0 {
                        self?.isPlayFinish = true
                        self?.delegate?.finishPlaying()
                    }
                } else {
                    self?.timeObserverToken = nil
                }
            }
        }
    }
    
    private func prepare() {
        guard let url = path else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            player.volume = 1.0
            player.play()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] (timer) in
                self?.duration += timer.timeInterval
                self?.displayDuration()
            })
            timer?.tolerance = 0.2
            guard let timer = timer else { return }
            RunLoop.main.add(timer, forMode: .common)
            delegate?.playing()
        } catch {
            Log.add("Error while playing audio \(error.localizedDescription)")
            player = nil
        }
    }
    
    private func displayDuration() {
        let time = Int(duration)
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        let display = String(format:"%02i:%02i", minutes, seconds)
        delegate?.displayDuration(display)
    }
    
    private func resetTimer() {
        duration = 0
        timer?.invalidate()
    }
}

extension AmityAudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
        fileName = nil
        resetTimer()
        delegate?.finishPlaying()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            Log.add("Error while decoding \(error.localizedDescription)")
        }
    }
}
