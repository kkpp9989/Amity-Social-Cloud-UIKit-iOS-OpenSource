//
//  LiveStreamViewController+Streaming.swift
//  AmityUIKitLiveStream
//
//  Created by Nutchaphon Rewik on 2/9/2564 BE.
//

import UIKit

extension LiveStreamBroadcastViewController {
    
    func startLiveDurationTimer() {
        startedAt = Date()
        updateStreamingStatusText()
        liveDurationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            #if DEBUG
            dispatchPrecondition(condition: .onQueue(.main))
            #endif
            self?.updateStreamingStatusText()
        }
    }
    
    func stopLiveDurationTimer() {
        liveDurationTimer?.invalidate()
        liveDurationTimer = nil
        
        timer.invalidate()
    }
    
    func updateStreamingStatusText() {
        guard let startedAt = startedAt,
              let durationText = liveDurationFormatter.string(from: startedAt, to: Date()),
              let broadcaster = broadcaster else {
            streamingStatusLabel.text = "LIVE"
            return
        }
        
        print("durationText: \(durationText)")
        if let convertedTimeString = convertTimeString(durationText) {
            switch broadcaster.state {
            case .connected:
                streamingStatusLabel.text = "LIVE \(convertedTimeString)"
            case .connecting, .disconnected, .idle:
                streamingStatusLabel.text = "CONNECTING \(convertedTimeString)"
            @unknown default:
                streamingStatusLabel.text = "LIVE \(convertedTimeString)"
            }
        } else {
            switch broadcaster.state {
            case .connected:
                streamingStatusLabel.text = "LIVE \(durationText)"
            case .connecting, .disconnected, .idle:
                streamingStatusLabel.text = "CONNECTING \(durationText)"
            @unknown default:
                streamingStatusLabel.text = "LIVE \(durationText)"
            }
        }
    }
    
    func convertTimeString(_ inputTimeString: String) -> String? {
        let components = inputTimeString.components(separatedBy: ":")
        
        if components.count == 2, let minutes = Int(components[0]), let seconds = Int(components[1]) {
            if minutes >= 60 {
                let hours = minutes / 60
                let remainingMinutes = minutes % 60
                return String(format: "%02d:%02d:%02d", hours, remainingMinutes, seconds)
            } else {
                return String(format: "%02d:%02d", minutes, seconds)
            }
        }
        
        return nil
    }
}
