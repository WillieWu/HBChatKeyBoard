//
//  HBRecordTool.swift
//  HBChatKeyBoard_Example
//
//  Created by 伍宏彬 on 2019/3/5.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation

public class HBRecordTool: NSObject {
    
    public static let `default` = HBRecordTool()
    public var maxRecordSeconds: TimeInterval = 60
    public var minRecordSeconds: TimeInterval = 1
    
    fileprivate var audioRecord: AVAudioRecorder?
    fileprivate var link: CADisplayLink?
    fileprivate var audioURL: URL?
    
    fileprivate var currentSecond: ((_ time: TimeInterval) -> ())?
    fileprivate var voicePercent: ((_ percentVaule: Float) ->())?
    fileprivate var maxSecondComplation: ((_ audioPath: URL, _ audioSeconds: TimeInterval) ->())?
    fileprivate var minSecondComplation: (() -> ())?
    fileprivate let recordSetting: [String: Any] = [AVFormatIDKey: kAudioFormatAppleIMA4,//kAudioFormatAppleIMA4 - kAudioFormatMPEGLayer3
                                                    AVSampleRateKey: 44100.0,
                                                    AVNumberOfChannelsKey: 1,
                                                    AVLinearPCMBitDepthKey: 16,
//                                                    AVLinearPCMIsFloatKey: false,
//                                                    AVEncoderAudioQualityKey: AVAudioQuality.high
    ]
    
    @objc fileprivate func p_updateRecordVaule() {
        self.audioRecord?.updateMeters()
        let recordSecond = self.audioRecord?.currentTime ?? 0
        self.currentSecond?(recordSecond)
        var level: Float = 0
        let minDecibels: Float = -80.0
        let decibels = self.audioRecord?.averagePower(forChannel: 0)
        if (decibels! < minDecibels){
            level = 0.0
        }else if (decibels! >= 0.0){
            level = 1.0
        }else{
            let root: Float            = 2.0
            let minAmp          = powf(10.0, 0.05 * minDecibels);
            let inverseAmpRange = 1.0 / (1.0 - minAmp);
            let amp             = powf(10.0, 0.05 * decibels!);
            let adjAmp          = (amp - minAmp) * inverseAmpRange;
            level = powf(adjAmp, 1.0 / root);
        }
        let voiceVaule = roundf(level * 120)
        self.voicePercent?(min(voiceVaule, 70)/70)
    }
    
}

//MARK: 录制
extension HBRecordTool {
    
    /// 开始录音
    ///
    /// - Parameters:
    ///   - percent: 检测录音的声音大小 percentVaule = [0, 1]
    ///   - second: 当前录制时间（秒）
    ///   - complation: 已到最大录制时间（秒）
    public func startRecord(speakerVaule percent: @escaping ((_ percentVaule: Float) ->()),
                            currentRecord second: @escaping ((_ second: TimeInterval) -> ()),
                            maxSecond maxComplation: @escaping ((_ audioPath: URL, _ audioSeconds: TimeInterval) -> ()),
                            minSecond minComplation: @escaping (() -> ())) {
        self.requestRecordAuthor { (isAuthor) in
            if !isAuthor {
                print("请去设置语音授权才可录音")
                return
            }
            do {
                guard self.p_canRecord() else { return }
                self.voicePercent = percent
                self.currentSecond = second
                self.maxSecondComplation = maxComplation
                self.minSecondComplation = minComplation
                self.audioURL = self.p_createAudioFileURL()
                try self.audioRecord = AVAudioRecorder(url: self.audioURL!, settings: self.recordSetting)
                self.audioRecord?.isMeteringEnabled = true
                self.audioRecord?.delegate = self
                self.audioRecord?.prepareToRecord()
                self.audioRecord?.record(forDuration: self.maxRecordSeconds)
                self.link = CADisplayLink(target: self, selector: #selector(HBRecordTool.p_updateRecordVaule))
                self.link?.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
            } catch let error  {
                print("AVAudioRecorder init Faile: \(error)")
            }
        }
    }
    
    /// 停止录音
    ///
    /// - Parameter complation: 录制完成后（录音文件路径, 录音时间）
    public func stopRecord(audioFilePath complation: ((_ audioPath: URL, _ audioSeconds: TimeInterval) -> ()) ) {
        guard p_canStopRecord() else { return }
        let second = self.audioRecord!.currentTime
        guard second > minRecordSeconds else {
            self.minSecondComplation?()
            self.deleteRecord()
            return
        }
        excute {
            complation(self.audioURL!, second)
        }
    }
    
    public func deleteRecord() {
        excute {
            
        }
    }
    
    public func deleteAllLocalRecord() {
        let recordDir = p_cachePath()
        try? FileManager.default.removeItem(atPath: recordDir!)
    }
    
    public func requestRecordAuthor(_ complation: @escaping ((_ canRecord: Bool) -> ())) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            print("AVAudioSession:setCategory Faile: \(error)")
        }
        switch AVAudioSession.sharedInstance().recordPermission() {
        case .denied:
            complation(false)
        case .granted:
            complation(true)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { (isAuthor) in
                complation(isAuthor)
            }
        }
    }
    
    public func reset() {
        if self.audioRecord != nil {
            self.audioRecord = nil
        }
        if self.currentSecond != nil {
            self.currentSecond = nil
        }
        if self.link != nil {
            self.link?.invalidate()
            self.link = nil
        }
        if self.voicePercent != nil {
            self.voicePercent = nil
        }
        self.voicePercent = nil
        self.currentSecond = nil
        self.maxSecondComplation = nil
        self.minSecondComplation = nil
        self.audioURL = nil
    }
}

extension HBRecordTool {
    //MARK: 文件路径和名称
    fileprivate func p_createAudioFileURL() -> URL? {
        var cachePath = self.p_cachePath()
        guard cachePath != nil else {
            return nil
        }
        cachePath!.append("/\(self.p_audioName()).caf")
        return URL(fileURLWithPath: cachePath!)
    }
    fileprivate func p_cachePath() -> String? {
        var cachePath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first
        cachePath?.append("/recordFiles")
        if !FileManager.default.fileExists(atPath: cachePath!) {
            try! FileManager.default.createDirectory(atPath: cachePath!, withIntermediateDirectories: true, attributes: nil)
        }
        return cachePath
    }
    fileprivate func p_audioName() -> String {
        return "\(Int(Date().timeIntervalSince1970))"
    }
    //MARK: 判断录音状态
    fileprivate func p_canRecord() -> Bool {
        if self.audioRecord != nil {
            return !self.audioRecord!.isRecording
        }
        return true
    }
    fileprivate func p_canStopRecord() -> Bool {
        if self.audioRecord != nil {
            return self.audioRecord!.isRecording
        }
        return false
    }
    
    fileprivate func excute(stopRecord complation: (() -> ())) {
        self.audioRecord?.stop()
        complation()
        reset()
    }
}

extension HBRecordTool: AVAudioRecorderDelegate {
    private func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        excute {
            guard self.audioURL != nil else { return }
            self.maxSecondComplation?(self.audioURL!, maxRecordSeconds)
        }
    }
    private func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("录音错误：\(error.debugDescription)")
    }

}
