//
//  EqualizerViewController.swift
//  EqualizerEffect
//
//  Created by Taif Mac on 23/08/2020.
//  Copyright © 2020 한승진. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

class EqualizerViewController: UIViewController {
    
    // Outlets
    @IBOutlet weak var switchMusicOn: UISwitch!
    @IBOutlet weak var switchBypass: UISwitch!
    @IBOutlet var freqsSlides: [UISlider]!
    @IBOutlet weak var spectrumView: SpectrumView!
    // Variables
    var audioManager: AudioManager?
    
    let frequencies: [Int] = [0, 32, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000] // frequencies
    var preSets: [[Float]] = [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], // My setting
        [3.2, 4, 6, 5, 0, 1, 3, 5, 4.5, 3.5, 0], // Dance
        [1.45, 4, 3, 2, 2.5, -1.5, -1.5, 0, 1, 2, 3], // Jazz
        [1.65, 5, 4, 3.5, 3, 1, 0, 0, 0, 0, 0] // Base Main
    ]
    
    var grantPermissionToAccessLibrary = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Visual Audio Equalizer"
        
        // Permission for Open Iphone Library
        permissionForMusicLibrary { (Status) in
            if Status{
                // open library to select music
                self.openMusicLibrary()
            }else{
                // Play default music
                guard let musicUrl = Bundle.main.url(forResource: "bensound-energy", withExtension: "mp3") else { return }
                self.MusicPlay(filename: musicUrl)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        let barSpace = spectrumView.frame.width / CGFloat(audioManager?.analyzer.frequencyBands ?? 20 * 3 - 1)
         spectrumView.barWidth = barSpace * 2
         spectrumView.space = barSpace
     }
}

// MARK: localMethods
extension EqualizerViewController {
    
      // Permission for Open Iphone Library
    func permissionForMusicLibrary(completionHandler: @escaping CompletionHandler){
        MPMediaLibrary.requestAuthorization({(newPermissionStatus: MPMediaLibraryAuthorizationStatus) in
            // This code will be called after the user allows or denies your app permission.
            switch (newPermissionStatus) {
            case MPMediaLibraryAuthorizationStatus.authorized:
               // permission status is authorized
                self.grantPermissionToAccessLibrary = true
            case MPMediaLibraryAuthorizationStatus.notDetermined:
                // permission status is not determined
                self.grantPermissionToAccessLibrary = false
            case MPMediaLibraryAuthorizationStatus.denied:
                // permission status is denied
                self.grantPermissionToAccessLibrary = false
            case MPMediaLibraryAuthorizationStatus.restricted:
                // permission status is restricted
                self.grantPermissionToAccessLibrary = false
            }
            completionHandler(self.grantPermissionToAccessLibrary)
        })
        
         
    }
    
    // Iphone Library Open
      func openMusicLibrary(){
          let mediaPicker: MPMediaPickerController = MPMediaPickerController.self(mediaTypes:MPMediaType.music)
          mediaPicker.delegate = self
          mediaPicker.allowsPickingMultipleItems = false
          mediaPicker.prompt = NSLocalizedString("Chose audio file", comment: "Please chose an audio file")
          self.present(mediaPicker, animated: true, completion: nil)
      }
    
        // Music Play with frequencies
      func MusicPlay(filename: URL){
        audioManager = AudioManager(musicUrl: filename, frequencies: frequencies)
         if let audioManager = audioManager {
              audioManager.delegate = self
              audioManager.setEquailizerOptions(gains: preSets[0])
              audioManager.engineStart()
            audioManager.play()
         
          }
       }
}


// MARK: MPMediaPickerControllerDelegate
extension EqualizerViewController: MPMediaPickerControllerDelegate {
    
   
    // Media Item has been picked from Ipghone Library
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
           self.dismiss(animated: true, completion: nil)
        
           // Music url from Iphone music Library
           let url = mediaItemCollection.items[0].value(forProperty: MPMediaItemPropertyAssetURL) as? NSURL
        self.MusicPlay(filename: url! as URL)
             
       }
    
  
     // clicked on cancel
     func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
         self.dismiss(animated: true, completion: nil)
         ////No file selected  default music play
           guard let musicUrl = Bundle.main.url(forResource: "bensound-energy", withExtension: "mp3") else { return }
         MusicPlay(filename: musicUrl)
         
     }

}
//

// MARK: AudioManagerDelegate
extension EqualizerViewController: AudioManagerDelegate {
    
   func player(_ player: AudioManager, didGenerateSpectrum spectra: [[Float]]) {
           DispatchQueue.main.async {
               self.spectrumView.spectra = spectra
           }
    }
    
    func audioManager(didStart manager: AudioManager) {
     //   music play
    }
    
    func audioManager(didStop manager: AudioManager) {
    //    music stop
    }
    
    func audioManager(didPause manager: AudioManager) {
     //  music pause
    }
}


// MARK: Events
extension EqualizerViewController {
    
    // UISwich
    @IBAction func switchValueChanged(_ sender: Any) {
        if let sender = sender as? UISwitch, let audio = audioManager {
            // Music OnOff
            if sender == switchMusicOn {
                if sender.isOn {
                    audio.play()
               
                } else {
                    audio.pause()
                  
                }
            }
                // Use bypass
            else if sender == switchBypass {
                audio.setBypass(sender.isOn)
            }
        }
    }
    
    // UISlider
    @IBAction func sliderValueChanged(_ sender: Any) {
        if let slider = sender as? UISlider {
            guard let audioManager = audioManager else {
                return
            }
            var preSet = audioManager.getEquailizerOptions()
            
            // movement of Preamp(slider.tag == 10), move all other sliders also
            if slider.tag == 10{
                for (index, slide) in freqsSlides.enumerated() {
                    // slider value changes
                    
                    preSet[index] = slider.value
                    // animate movement of slider
                    slide.setValue(slider.value , animated: true)
                }
            }else{
                // Just slider value changes
                preSet[slider.tag] = slider.value
            }
            audioManager.setEquailizerOptions(gains: preSet)
        }
    }
    
    // segmentedControl
    @IBAction func segmentedControlValueChanged(_ sender: Any) {
        if let segmentedControl = sender as? UISegmentedControl {
 
            guard let audioManager = audioManager else {
                return
            }
            let index = segmentedControl.selectedSegmentIndex
            audioManager.setEquailizerOptions(gains: preSets[index])
            
            let preSet = audioManager.getEquailizerOptions()
            for (index, slide) in freqsSlides.enumerated() {
                slide.value = preSet[index]
            }
        }
    }
}
