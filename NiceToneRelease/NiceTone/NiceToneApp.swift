//
//  NiceToneApp.swift
//  NiceTone
//
//  Created by Admin on 6/5/2023.
//
import AudioKit
import AudioKitEX
import AudioKitUI
import AVFoundation
import SwiftUI

@main
struct NiceToneApp: App {
    init() {
        #if os(iOS)
            do {
                Settings.bufferLength = .short
                try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(Settings.bufferLength.duration)
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord,
                                                                options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch let err {
                print(err)
            }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
