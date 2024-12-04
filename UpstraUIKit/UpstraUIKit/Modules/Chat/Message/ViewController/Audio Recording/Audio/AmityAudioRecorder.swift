//
//  AmityAudioRecorder.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 3/12/2563 BE.
//  Copyright © 2563 BE Amity. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia

enum AmityAudioRecorderState {
    case finish
    case finishWithMaximumTime
    case fileSizeIsExceeded
    case notFinish
    case timeTooShort
    case deleteAndClose
}

protocol AmityAudioRecorderDelegate: AnyObject {
    func requestRecordPermission(isAllowed: Bool)
    func displayDuration(_ duration: String)
    func finishRecording(state: AmityAudioRecorderState)
    func voiceMonitoring(radius: CGFloat)
}

final class AmityAudioRecorder: NSObject {
    
    static let shared = AmityAudioRecorder()
    
    private var session: AVAudioSession!
    private var recorder: AVAudioRecorder!
    
    let fileName = "amity-uikit-recording.m4a"
    private var minimumTimeout: Int = 2
    private var maximumTimeout: Int = 7199
    private var duration: TimeInterval = 0.0 {
        didSet {
            displayDuration()
        }
    }
    private var timer: Timer?
    private var isRecording = false
    private var isRecordingPause = false
    // MARK: - Delegatee
    weak var delegate: AmityAudioRecorderDelegate?
    
    // MARK: - Properties
    func requestPermission() {
        if session == nil {
            session = AVAudioSession.sharedInstance()
        }
        switch session.recordPermission {
        case .granted:
            break
        default:
            do {
                try session.setCategory(.record)
                try session.setActive(true)
                session.requestRecordPermission() { [weak self] allowed in
                    self?.delegate?.requestRecordPermission(isAllowed: allowed)
                }
            } catch {
                delegate?.requestRecordPermission(isAllowed: false)
                Log.add("Error while preparing audio session \(error.localizedDescription)")
            }
        }
    }
    
    func checkPermission(completion: @escaping (_ isAllowed: Bool?, _ error: Error?) -> Void) {
        if session == nil {
            session = AVAudioSession.sharedInstance()
        }
        switch session.recordPermission {
        case .granted:
            completion(true, nil)
        default:
            do {
                try session.setCategory(.record)
                try session.setActive(true)
                session.requestRecordPermission() { allowed in
                    completion(allowed, nil)
                }
            } catch {
                completion(nil, error)
                Log.add("Error while preparing audio session \(error.localizedDescription)")
            }
        }
    }
    
    func startRecording() {
        isRecording = true
        switch session.recordPermission {
        case .granted:
            prepare()
        default:
            delegate?.requestRecordPermission(isAllowed: false)
        }
    }
    
    func pauseRecording() {
        timeStop()
        recorder.stop()
    }
    
    func resumeRecording() {
        timeStart()
        recorder.record()
    }
    
    func stopRecording(withDelete isDelete: Bool = false) {
        
        if isDelete {
            deleteFile()
            finishRecording(state: .deleteAndClose)
        } else {
            if Int(duration) <= minimumTimeout {
                deleteFile()
                finishRecording(state: .timeTooShort)
            } else {
                if let audioURL = getAudioFileURL(),
                   let audioFileAttributes = try? FileManager.default.attributesOfItem(atPath: audioURL.path),
                   let audioFileSize = audioFileAttributes[.size] as? Double, // Get audio file size
                   let limitFileSizeSettingInMB = AmityUIKitManagerInternal.shared.limitFileSize { // Get limit file size setting
                    let audiofileSizeinMB: Double = audioFileSize / (1024 * 1024)
                    if audiofileSizeinMB > limitFileSizeSettingInMB {
                        finishRecording(state: .fileSizeIsExceeded)
                    } else {
                        finishRecording(state: .finish)
                    }
                } else {
                    finishRecording(state: .finish)
                }
            }
        }
    }
    
    func updateFilename(from originFilename: String? = nil, to newFileName: String) {
        AmityFileCache.shared.updateFile(for: .audioDirectory, originFilename: originFilename ?? self.fileName, destinationFilename: newFileName + ".m4a")
    }
    
    func getAudioFileURL() -> URL? {
        return AmityFileCache.shared.getCacheURL(for: .audioDirectory, fileName: fileName)
    }
    
    func getAudioFileURL(fileName: String) -> URL? {
        return AmityFileCache.shared.getCacheURL(for: .audioDirectory, fileName: fileName)
    }
    
    func getDurationPlay() -> Double {
        let asset = AVAsset(url: getAudioFileURL()!)
        let duration = asset.duration
        let durationTime = CMTimeGetSeconds(duration)
        return durationTime
    }
    
    func getDataFile() -> Data? {
        if let _ = AmityFileCache.shared.getCacheURL(for: .audioDirectory, fileName: fileName) {
            return AmityFileCache.shared.convertToData(for: .audioDirectory, fileName: fileName)
        }
        return nil
    }
    
    // MARK: - Helper functions
    private func prepare() {
        let audioFileUrl = AmityFileCache.shared.getFileURL(for: .audioDirectory, fileName: fileName)
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            try session.setCategory(.record)
            recorder = try AVAudioRecorder(url: audioFileUrl, settings: settings)
            recorder.delegate = self
            recorder.isMeteringEnabled = true
            recorder.updateMeters()
            recorder.record()
            timeStart()
            
        } catch {
            finishRecording(state: .notFinish)
        }
    }
    
    private func timeStart() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (timer) in
            self?.recorder?.updateMeters()
            self?.duration += timer.timeInterval
            self?.monitoring()
        })
    }
    
    private func timeStop() {
        timer?.invalidate()
    }
    
    private func monitoring() {
        delegate?.voiceMonitoring(radius: normalizeSoundLevel(level: recorder.averagePower(forChannel: 0)))
        if Int(duration) == maximumTimeout {
            finishRecording(state: .finishWithMaximumTime)
        }
    }
    
    private func normalizeSoundLevel(level: Float) -> CGFloat {
        let level = max(0.2, CGFloat(level) + 50) / 2 // between 0.1 and 25
        return CGFloat(level * (250 / 25)) // scaled to max at 250
    }
    
    func finishRecording(state: AmityAudioRecorderState) {
        if recorder != nil {
            isRecording = false
            recorder.stop()
            timer?.invalidate()
            delegate?.finishRecording(state: state)
            duration = 0
            recorder = nil
        }
    }
    
    func displayDuration() {
        let time = Int(duration)
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        let display = String(format:"%02i:%02i", minutes, seconds)
        delegate?.displayDuration(display)
    }
    
    func deleteFile() {
        AmityFileCache.shared.deleteFile(for: .audioDirectory, fileName: fileName)
    }
}

extension AmityAudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {

    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            Log.add("Error while encoding audio \(error.localizedDescription)")
        }
    }
    
    func audioRecorderBeginInterruption(_ recorder: AVAudioRecorder) {
        Log.add("AudioRecorder begins interruption")
    }
}



