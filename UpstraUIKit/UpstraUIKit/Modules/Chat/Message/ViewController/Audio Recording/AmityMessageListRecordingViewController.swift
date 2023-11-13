//
//  AmityMessageListRecordingViewController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 26/11/2563 BE.
//  Copyright © 2563 BE Amity. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

final class AmityMessageListRecordingViewController: UIViewController {

    // MARK: - IBOutlet Properties
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var recordingView: UIView!
    @IBOutlet private var timerLabel: UILabel!
    @IBOutlet weak var butPauseRecord: UIButton!
    @IBOutlet weak var lblMaximumLength: UILabel!
    @IBOutlet weak var butSendAudio: UIButton!
    @IBOutlet weak var butPlayAudio: UIButton!
    @IBOutlet weak var butStopPlayAudio: UIButton!
    
    // MARK: - Properties
    var finishRecordingHandler: ((AmityAudioRecorderState) -> Void)?
    
    let player = AVQueuePlayer()
    var timeObserverToken: Any?
    var duration: String = ""
    
    // this vc doesn't support swipe back gesture
    // it requires setting a presenter to define who is using this vc
    // and then temporarily disable the gesture
    weak var presenter: AmityViewController?
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        AmityAudioRecorder.shared.delegate = self
        setupView()
    }
    
    static func make() -> AmityMessageListRecordingViewController {
        let vc = AmityMessageListRecordingViewController(nibName: AmityMessageListRecordingViewController.identifier, bundle: AmityUIKitManager.bundle)
        return vc
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.removeSwipeBackGesture()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presenter?.setupFullWidthBackGesture()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lblMaximumLength.isHidden = false
        butPauseRecord.isHidden = false
        butPlayAudio.isHidden = true
        butStopPlayAudio.isHidden = true
        duration = "00:00"
        startRecording()
    }
    
    func startRecording() {
        AmityAudioRecorder.shared.startRecording()
    }
    
    func pauseRecording() {
        AmityAudioRecorder.shared.pauseRecording()
    }
    
    func resumeRecording() {
        AmityAudioRecorder.shared.resumeRecording()
    }
    
    func stopRecording() {
        AmityAudioRecorder.shared.stopRecording()
    }
    
    func deleteRecording() {
        AmityAudioRecorder.shared.stopRecording(withDelete: true)
    }
    
    func deletingRecording() {
    }
    
    func cancelingDelete() {
    }
    
    @IBAction func butActionDelete(_ sender: Any) {
        stopAudio()
        deleteRecording()
    }
    
    @IBAction func butActionSendAudio(_ sender: Any) {
        stopAudio()
        stopRecording()
    }
    
    @IBAction func butActionPause(_ sender: Any) {
        pauseRecording()
        getPlayAudio()
        butPauseRecord.isHidden = true
        butPlayAudio.isHidden = false
    }
    
    @IBAction func butActionPlayRecord(_ sender: Any) {
        startAudio()
        startObservingTime()
        butPauseRecord.isHidden = true
        butPlayAudio.isHidden = true
        butStopPlayAudio.isHidden = false
    }
    
    @IBAction func butActionStopPlayAudio(_ sender: Any) {
        stopAudio()
        butPauseRecord.isHidden = true
        butPlayAudio.isHidden = false
        butStopPlayAudio.isHidden = true
    }
}

extension AmityMessageListRecordingViewController {
    
    func getPlayAudio() {
        guard let audioURL = AmityAudioRecorder.shared.getAudioFileURL() else {
            Log.add("Audio file not found")
            return
        }
        player.removeAllItems()
        player.insert(AVPlayerItem(url: audioURL), after: nil)
        
    }
    
    func startAudio() {
        do {
            // Add audio session
            try AVAudioSession.sharedInstance().setCategory(.playback)
            // Play audio
            player.play()
        } catch {
            Log.add("Error while preparing audio session [playing audio in recording view]: \(error.localizedDescription)")
        }
        
    }
    
    func stopAudio() {
        player.pause()
    }
    
    @objc func playerDidFinishPlaying(note: NSNotification) {
        getPlayAudio()
        stopAudio()
        timerLabel.text = duration
        butPauseRecord.isHidden = true
        butPlayAudio.isHidden = false
        butStopPlayAudio.isHidden = true
    }
    
    func startObservingTime() {
        let timeInterval = CMTimeMake(value: 1, timescale: 1)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main) { [weak self] time in
            if let currentItem = self?.player.currentItem {
                let duration = currentItem.duration
                let remainingTime = duration.seconds - time.seconds
                if remainingTime >= 0 {
                    let time = Int(remainingTime)
                    let minutes = Int(time) / 60 % 60
                    let seconds = Int(time) % 60
                    let display = String(format:"%02i:%02i", minutes, seconds)
                    self?.timerLabel.text = display
                } else {
                    self?.timeObserverToken = nil
                }
                
            }
        }
    }
    
}

// MARK: - Setup View
private extension AmityMessageListRecordingViewController {
    
    func setupView() {
        view.isOpaque = false
        view.backgroundColor = UIColor.clear
        NotificationCenter.default
            .addObserver(self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
        setupRecordingButton()
        setupTimerLabel()
        setupMaximumLabel()
        setupDeleteButton()
        setupSendButton()
        setupPlayButton()
        setupStopButton()
    }
    
    func setupRecordingButton() {
        butPauseRecord.setImage(AmityIconSet.Chat.iconAudioStopRecord, for: .normal)
    }
    
    func setupTimerLabel() {
        timerLabel.text = "00:00"
        timerLabel.textColor = UIColor.white
        timerLabel.font = AmityFontSet.title
    }
    
    func setupMaximumLabel() {
        lblMaximumLength.textColor = UIColor.white
        lblMaximumLength.font = AmityFontSet.caption
    }
    
    func setupSendButton() {
        butSendAudio.setImage(AmityIconSet.Chat.iconAudioSendAudio, for: .normal)
        butSendAudio.layer.cornerRadius = butSendAudio.frame.height / 2
    }
    
    func setupPlayButton() {
        butPlayAudio.setImage(AmityIconSet.Chat.iconAudioPlay, for: .normal)
        butPlayAudio.layer.cornerRadius = butPlayAudio.frame.height / 2
    }
    
    func setupStopButton() {
        butStopPlayAudio.setImage(AmityIconSet.Chat.iconAudioPause, for: .normal)
        butStopPlayAudio.layer.cornerRadius = butStopPlayAudio.frame.height / 2
    }
    
    func setupDeleteButton() {
        deleteButton.setImage(AmityIconSet.Chat.iconAudioDelete, for: .normal)
        deleteButton.layer.cornerRadius = deleteButton.frame.height / 2
    }
    
}

// MARK: - Update Views
private extension AmityMessageListRecordingViewController {
    
    func deletingButtonUI() {
        deleteButton.backgroundColor = AmityColorSet.alert
        deleteButton.tintColor = AmityColorSet.baseInverse
        deleteButton.setImage(AmityIconSet.Chat.iconDelete2, for: .normal)
    }
    
}

extension AmityMessageListRecordingViewController: AmityAudioRecorderDelegate {
    
    func finishRecording(state: AmityAudioRecorderState) {
        finishRecordingHandler?(state)
    }
    
    func requestRecordPermission(isAllowed: Bool) {
        
    }
    
    func displayDuration(_ duration: String) {
        timerLabel.text = duration
        self.duration = duration
    }
    
    func voiceMonitoring(radius: CGFloat) {
        let pulse = AmityPulseAnimation(numberOfPulse: 1, radius: radius + (radius * 0.15), postion: recordingView.center)
        pulse.animationDuration = 3.0
        pulse.backgroundColor = UIColor.green.withAlphaComponent(0.8).cgColor
        view.layer.insertSublayer(pulse, below: recordingView.layer)
    }
    
}
