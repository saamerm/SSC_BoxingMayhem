//
//  AudioManager.swift
//  SSC_BoxingMayhem
//
//  Created by Kurnia Kharisma Agung Samiadjie on 24/02/25.
//
import AVFoundation
import Foundation

@MainActor
class AudioManager {
    static let shared = AudioManager()
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var defaultVolume: Float = 1.0
    
    private init() {
#if canImport(UIKit)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
#endif
    }
    
    func setDefaultVolume(_ volume: Float) {
        defaultVolume = min(max(volume, 0.0), 1.0)
    }
    
    func setVolume(_ volume: Float, for soundName: String) {
        if let player = audioPlayers[soundName] {
            player.volume = min(max(volume, 0.0), 1.0)
        }
    }
    
    func getVolume(for soundName: String) -> Float {
        return audioPlayers[soundName]?.volume ?? defaultVolume
    }
    
    func playSound(_ soundName: String, volume: Float? = nil) {
        guard let sound = loadSound(soundName) else { return }
        if let volume = volume {
            sound.volume = min(max(volume, 0.0), 1.0)
        }
        sound.numberOfLoops = 0
        sound.play()
    }
    
    func playSoundWithLoop(_ soundName: String, volume: Float? = nil) {
        guard let sound = loadSound(soundName) else { return }
        if let volume = volume {
            sound.volume = min(max(volume, 0.0), 1.0)
        }
        sound.numberOfLoops = -1
        sound.play()
    }
    
    func stopSound(_ soundName: String) {
        audioPlayers[soundName]?.stop()
    }
    
    func stopAllSounds() {
        audioPlayers.values.forEach { $0.stop() }
    }
    
    private func loadSound(_ soundName: String) -> AVAudioPlayer? {
        if let player = audioPlayers[soundName] {
            player.currentTime = 0
            player.volume = defaultVolume
            return player
        }
        
        let nameComponents = soundName.components(separatedBy: ".")
        let name = nameComponents[0]
        
        let possiblePaths: [(resource: String, directory: String?)] = [
            (name, nil),
            (name, "Sounds"),
            (name.components(separatedBy: "/").last ?? name, "Sounds")
        ]
        
        for (resource, directory) in possiblePaths {
            if let path = Bundle.main.path(forResource: resource, ofType: "mp3", inDirectory: directory) {
                do {
                    let url = URL(fileURLWithPath: path)
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.volume = defaultVolume
                    audioPlayers[soundName] = player
                    return player
                } catch {
                    print("Error loading sound \(soundName): \(error.localizedDescription)")
                }
            }
        }
        
        return nil
    }
}
