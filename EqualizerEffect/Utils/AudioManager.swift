//
//  AudioManager.swift
//  EqualizerEffect
//
//  Created by Taif Mac on 23/08/2020.
//  Copyright © 2020 한승진. All rights reserved.


import Foundation
import AVFoundation

protocol AudioManagerDelegate: class {
    func audioManager(didStart manager: AudioManager)
    func audioManager(didStop manager: AudioManager)
    func audioManager(didPause manager: AudioManager)
    func player(_ player: AudioManager, didGenerateSpectrum spectra: [[Float]])
}

class AudioManager{
    weak var delegate: AudioManagerDelegate?
    
    // Variables
      fileprivate let player = AVAudioPlayerNode()
      fileprivate let audioEngine = AVAudioEngine()
      fileprivate var audioFileBuffer: AVAudioPCMBuffer?
      fileprivate var EQNode: AVAudioUnitEQ?
    
    public var analyzer: RealtimeAnalyzer!
    
    public var bufferSize: Int? {
        didSet {
            if let bufferSize = self.bufferSize {
                analyzer = RealtimeAnalyzer(fftSize: bufferSize)
                audioEngine.mainMixerNode.removeTap(onBus: 0)
                audioEngine.mainMixerNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(bufferSize), format: nil, block: {[weak self](buffer, when) in
                    guard let strongSelf = self else { return }
                    if !strongSelf.player.isPlaying { return }
                    buffer.frameLength = AVAudioFrameCount(bufferSize)
                    let spectra = strongSelf.analyzer.analyse(with: buffer)
                    if strongSelf.delegate != nil {
                        strongSelf.delegate!.player(strongSelf, didGenerateSpectrum: spectra)
                    }
                })
            }
        }
    }
    
    
    init?(musicUrl: URL,frequencies: [Int]) {
        
        setUpEngine(with: musicUrl, frequencies: frequencies)
    }
    
    fileprivate func setUpEngine(with fileNameUrl: URL,frequencies: [Int]) {
        // Load a music file
        do {
            
            
             let audioFile = try AVAudioFile(forReading: fileNameUrl)
          
                    audioFileBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: UInt32(audioFile.length))
                    try audioFile.read(into: audioFileBuffer!)
              
                
                // initial Equalizer.
                EQNode = AVAudioUnitEQ(numberOfBands: frequencies.count)
                EQNode!.globalGain = 1
                for i in 0...(EQNode!.bands.count-1) {
                    EQNode!.bands[i].frequency  = Float(frequencies[i])
                    EQNode!.bands[i].gain       = 0
                    EQNode!.bands[i].bypass     = false
                    EQNode!.bands[i].filterType = .parametric
                }
                
                // Attach nodes to an engine.
                audioEngine.attach(EQNode!)
                audioEngine.attach(player)
                
                // Connect player to the EQNode.
                let mixer = audioEngine.mainMixerNode
                audioEngine.connect(player, to: EQNode!, format: mixer.outputFormat(forBus: 0))
                
                // Connect the EQNode to the mixer.
                audioEngine.connect(EQNode!, to: mixer, format: mixer.outputFormat(forBus: 0))
                
                // Schedule player to play the buffer on a loop.
                if let audioFileBuffer = audioFileBuffer {
                    player.scheduleBuffer(audioFileBuffer, at: nil, options: .loops, completionHandler: nil)
                }
            } catch {
                  assertionFailure("failed to load the music. Error: \(error)")
                  return
              }
            }
}


// MARK: State Update
extension AudioManager {
    public func isEngineRunning() -> Bool {
        return audioEngine.isRunning
    }
    
    public func engineStart() {
        audioEngine.prepare()
        do {
            
            try audioEngine.start()
            
            do {
                     self.bufferSize = 2048
            }
            
        } catch {
            assertionFailure("failed to audioEngine start. Error: \(error)")
        }
    }
    
    public func play() {
       
        player.play()
        delegate?.audioManager(didStart: self)
    }
    
    public func stop() {
    
        player.stop()
        delegate?.audioManager(didStop: self)
    }
    
    public func pause() {
  
        player.pause()
        delegate?.audioManager(didStart: self)
    }
}


// MARK: GET, SET
extension AudioManager {
    public func setBypass(_ isOn: Bool) {
        for i in 0...(EQNode!.bands.count-1) {
            EQNode!.bands[i].bypass = isOn
        }
    }
    
    public func setEquailizerOptions(gains: [Float]) {
        guard let EQNode = EQNode else {
            return
        }
        for i in 0...(EQNode.bands.count-1) {
            EQNode.bands[i].gain = gains[i]
        }
    }
    
    public func getEquailizerOptions() -> [Float] {
        guard let EQNode = EQNode else {
            return []
        }
        return EQNode.bands.map { $0.gain }
    }
}
