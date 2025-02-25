//
//  Character.swift
//  SSC_BoxingMayhem
//
//  Created by Kurnia Kharisma Agung Samiadjie on 23/02/25.
//

import SpriteKit
import SwiftUI

import SpriteKit

class CharacterScene: SKScene {
    private var character: SKSpriteNode!
    private var currentState: String = "none"
    private let isOpponent: Bool
    private let scale: CGFloat
    
    private var textures: [String: [SKTexture]] = [:]
    
    init(size: CGSize, isOpponent: Bool) {
        self.isOpponent = isOpponent
        self.scale = isOpponent ? 0.5 : 0.4
         
        super.init(size: size)
             
        self.backgroundColor = .clear
        self.isPaused = false
        self.scaleMode = .resizeFill
             
        loadTextures()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadTextures() {
        let prefix = isOpponent ? "opponent" : "player"
            
        func configureTexture(_ texture: SKTexture) -> SKTexture {
            texture.filteringMode = .nearest
            return texture
        }
            
        // Load idle animation frames
        for frameName in ["none0", "none1", "none2", "none1"] {
            if let image = UIImage(named: "\(prefix)-\(frameName)")?.cgImage {
                let texture = SKTexture(cgImage: image)
                texture.filteringMode = .nearest
                    
                if frameName == "none0" {
                    textures["none"] = [texture]
                } else {
                    textures["none"]?.append(texture)
                }
            }
        }
            
        // Load regular states
        for state in ["jab", "hook", "uppercut", "punched"] {
            if let image = UIImage(named: "\(prefix)-\(state)")?.cgImage {
                let texture = SKTexture(cgImage: image)
                texture.filteringMode = .nearest
                textures[state] = [texture]
            }
        }

        // Load knock animation frames
        var knockFrames: [SKTexture] = []
        for i in 0...1 {
            if let image = UIImage(named: "\(prefix)-knock\(i)")?.cgImage {
                let texture = SKTexture(cgImage: image)
                texture.filteringMode = .nearest
                knockFrames.append(texture)
            }
        }
        textures["knock"] = knockFrames
    }

        
    override func didMove(to view: SKView) {
        view.allowsTransparency = true
        view.backgroundColor = .clear
        view.isOpaque = false
           
        view.ignoresSiblingOrder = true
        view.shouldCullNonVisibleNodes = true
           
        setupCharacter()
        startIdleAnimation()
    }
    
    private func setupCharacter() {
        guard let initialTexture = textures["none"]?.first else { return }
            
        character = SKSpriteNode(texture: initialTexture)
        character.position = CGPoint(x: frame.midX, y: frame.midY)
        character.setScale(scale)
            
        character.color = .clear
        character.colorBlendFactor = 0
        character.blendMode = .alpha
            
        addChild(character)
    }
    
    private func startIdleAnimation() {
        guard let idleFrames = textures["none"] else { return }
        character.removeAllActions()
        let idleAction = SKAction.repeatForever(
            SKAction.animate(with: idleFrames, timePerFrame: 0.5)
        )
        character.run(idleAction, withKey: "idle")
        character.color = .clear
        currentState = "none"
    }
    
    func updateState(_ newState: String) {
        guard newState != currentState else { return }
        
        character.removeAllActions()
        
        if newState == "none" {
            startIdleAnimation()
            return
        }
        
        if newState == "knock" {
            startKnockAnimation()
            return
        }
        
        // Handle other states
        if let stateTextures = textures[newState] {
            character.texture = stateTextures.first
            
            let returnToIdle = SKAction.sequence([
                SKAction.wait(forDuration: 0.4),
                SKAction.run { [weak self] in
                    self?.startIdleAnimation()
                }
            ])
            
            character.run(returnToIdle, withKey: "returnToIdle")
        }
        
        currentState = newState
    }

    private func startKnockAnimation() {
        guard let knockFrames = textures["knock"] else { return }
        
        let knockAnimation = SKAction.sequence([
            SKAction.animate(with: knockFrames, timePerFrame: 0.5),
            SKAction.repeatForever(
                SKAction.animate(with: [knockFrames[1]], timePerFrame: 0.5)
            )
        ])
        
        character.run(knockAnimation, withKey: "knock")
        currentState = "knock"
    }

    
    func flip(_ isFlipped: Bool) {
        character.xScale = isFlipped ? -abs(scale) : abs(scale)
    }
}

struct CharacterSpriteView: View {
    @MainActor
    class SceneWrapper: ObservableObject {
        let scene: CharacterScene
        
        init(isOpponent: Bool) {
            let size = CGSize(width: 300, height: 300)
            self.scene = CharacterScene(size: size, isOpponent: isOpponent)
        }
    }
    
    @StateObject private var sceneWrapper: SceneWrapper
    @Binding var state: String
    @Binding var isFlipped: Bool
    
    init(state: Binding<String>, isFlipped: Binding<Bool>, isOpponent: Bool) {
        _state = state
        _isFlipped = isFlipped
        _sceneWrapper = StateObject(wrappedValue: SceneWrapper(isOpponent: isOpponent))
    }
    
    var body: some View {
        SpriteView(scene: sceneWrapper.scene, options: [.allowsTransparency])
            .frame(width: 300, height: 300)
            .background(Color.clear)
            .contentShape(Rectangle())
            .onChange(of: state) { newState in
                Task { @MainActor in
                    sceneWrapper.scene.updateState(newState)
                }
            }
            .onChange(of: isFlipped) { newValue in
                Task { @MainActor in
                    sceneWrapper.scene.flip(newValue)
                }
            }
    }
}

struct Character: View {
    let info: CharInfo
    @Binding var state: String
    @Binding var isFlipped: Bool
    
    var body: some View {
        CharacterSpriteView(
            state: $state,
            isFlipped: $isFlipped,
            isOpponent: info == CharInfo.opponent
        )
    }
}
