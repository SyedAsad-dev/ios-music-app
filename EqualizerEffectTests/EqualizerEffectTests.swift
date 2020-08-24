//
//  EqualizerEffectTests.swift
//  EqualizerEffectTests
//
//  Created by Taif Mac on 24/08/2020.
//  Copyright © 2020 한승진. All rights reserved.
//

import XCTest
@testable import EqualizerEffect

class EqualizerEffectTests: XCTestCase{

    var audioManager: AudioManager?
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    
    func testAudiofileExist() {
        
        let musicUrl = Bundle.main.url(forResource: "bensound-energy", withExtension: "mp3")
        
        XCTAssertNotNil(musicUrl)
    
    }
    
}

