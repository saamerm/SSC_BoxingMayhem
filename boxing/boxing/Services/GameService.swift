// SSC_BoxingMayhem
// GameService.swift
// Created by Kurnia Kharisma Agung Samiadjie on 21 / 02 / 25.
//

import Foundation
import SwiftUI

@MainActor
class GameService: ObservableObject {
    @Published var playerState = "none"
    @Published var playerFlipped = false
    @Published var opponentState = "none"
    @Published var opponentFlipped = false
    @Published var playerHealth = 100
    @Published var opponentHealth = 100
    @Published var playerStamina = 100
    @Published var opponentStamina = 100
    @Published var knockedCounter = "ko"
    @Published var stateDelay = 0
    @Published var gameState = "countdown"
    @Published var result = ""
    @Published var playerCanAttack = true
    @Published var playerDodging = false
    @Published var dodgeDirection: String = "none"
    @Published var isGamePlayed = false
    @Published var knockoutCount = 0
    @Published var isCountingKnockout = false
    @Published var isShowingTutorial = false
    
    private var knockoutTimer: Timer?
    private let movementSet = ["jab", "hook", "uppercut"]
    private var movementTimer: Timer?
    private var staminaTimer: Timer?
    private var dodgeTimer: Timer?
    
    private let staminaRecoveryRate: Double = 5
    private let staminaRecoveryInterval: TimeInterval = 0.5
    private let dodgeDuration: TimeInterval = 0.5
    
    private var attackPatterns: [[String]] = [
        ["jab", "jab", "hook"],
        ["jab", "uppercut"],
        ["hook", "hook"],
        ["jab", "hook", "uppercut"],
        ["uppercut", "jab"],
    ]
    
    private var currentPatternIndex = 0
    private var currentMoveIndex = 0
    private var isExecutingPattern = false
    private var difficultyLevel: Double = 1.0
    private var minThinkTime: Double = 0.5
    private var maxThinkTime: Double = 2.0
    
    private let movementStaminaCost: [String: Int] = [
        "jab": 10,
        "hook": 30,
        "uppercut": 50,
    ]

    private let movementDamage: [String: Int] = [
        "jab": 4,
        "hook": 12,
        "uppercut": 20,
    ]

    init(difficulty: Double = 1.0) {
        self.difficultyLevel = difficulty
        startStaminaRecovery()
    }

    private func startStaminaRecovery() {
        staminaTimer = Timer.scheduledTimer(withTimeInterval: staminaRecoveryInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.recoverStamina()
            }
        }
    }
    
    private func recoverStamina() {
        if playerState == "none" {
            playerStamina = min(100, playerStamina + Int(staminaRecoveryRate))
        }
        if opponentState == "none" {
            opponentStamina = min(100, opponentStamina + Int(staminaRecoveryRate))
        }
    }
    
    func startOpponentMove() {
        movementTimer?.invalidate()
        movementTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if !self.isExecutingPattern {
                    self.executeNewAttackPattern()
                }
            }
        }
    }
    
    func stopOpponentMove() {
        movementTimer?.invalidate()
        staminaTimer?.invalidate()
    }
    
    private func executeNewAttackPattern() {
        guard !isExecutingPattern else { return }
        
        let shouldAttack = Double.random(in: 0...1) < (0.6 * difficultyLevel)
        
        if shouldAttack {
            isExecutingPattern = true
            currentPatternIndex = Int.random(in: 0 ..< attackPatterns.count)
            currentMoveIndex = 0
            executeNextMove()
        } else {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(Double.random(in: minThinkTime...maxThinkTime) * 1_000_000_000))
                isExecutingPattern = false
            }
        }
    }
    
    private func handleTutorialState(_ newState: String) {
        guard playerState == "none" else { return }
        
        let validStates = ["jab", "hook", "uppercut"]
        guard validStates.contains(newState) else { return }
        
        playerState = newState
        playerFlipped = Bool.random()
        consumeStamina(for: newState, isPlayer: true)
        
        AudioManager.shared.playSound("punch-1")
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            playerState = "none"
            playerFlipped = false
        }
    }

    private func executePlayerMove(_ newState: String) {
        playerState = newState
        playerFlipped = Bool.random()
        consumeStamina(for: newState, isPlayer: true)
        
        if newState != "none" && opponentState == "none" {
            let damage = movementDamage[newState] ?? 0
            AudioManager.shared.playSound("punch-1")
            opponentHealth -= damage
            
            if !updateHealth() {
                opponentState = "punched"
                opponentFlipped = playerFlipped
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    opponentState = "none"
                    opponentFlipped = false
                }
            }
        }
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            playerState = "none"
            playerFlipped = false
        }
    }

    private func executeNextMove() {
        guard isExecutingPattern,
              currentPatternIndex < attackPatterns.count,
              currentMoveIndex < attackPatterns[currentPatternIndex].count
        else {
            isExecutingPattern = false
            return
        }
        
        let currentPattern = attackPatterns[currentPatternIndex]
        let move = currentPattern[currentMoveIndex]
        
        if hasEnoughStamina(for: move, isPlayer: false) {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(Double.random(in: minThinkTime...maxThinkTime) * 1_000_000_000))
                
                updateOpponentState(newState: move)
                currentMoveIndex += 1
                
                if currentMoveIndex >= currentPattern.count {
                    isExecutingPattern = false
                } else {
                    executeNextMove()
                }
            }
        } else {
            isExecutingPattern = false
        }
    }
    
    func updatePlayerState(newState: String) {
        if isShowingTutorial && hasEnoughStamina(for: newState, isPlayer: true) {
            handleTutorialState(newState)
            return
        }
        
        guard playerState == "none" && playerCanAttack && hasEnoughStamina(for: newState, isPlayer: true) else { return }
        guard isGamePlayed == true && opponentHealth > 0 else { return }
        
        let validStates = ["jab", "hook", "uppercut"]
        guard validStates.contains(newState) else { return }
        
        executePlayerMove(newState)
    }

    func updateOpponentState(newState: String) {
        guard opponentState == "none" && hasEnoughStamina(for: newState, isPlayer: false) else { return }
        
        guard isGamePlayed == true && playerHealth > 0 else { return }
        
        opponentState = newState
        opponentFlipped = Bool.random()
        consumeStamina(for: newState, isPlayer: false)
        
        if newState != "none" && playerState == "none" {
            let damage = movementDamage[newState] ?? 0
            playerHealth -= damage
            AudioManager.shared.playSound("punch-2")
            
            if !updateHealth() {
                playerState = "punched"
                playerFlipped = opponentFlipped
                
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    playerState = "none"
                    playerFlipped = false
                }
            }
            
            playerCanAttack = false
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                playerCanAttack = true
            }
        }
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            opponentState = "none"
            opponentFlipped = false
        }
    }
    
    private func hasEnoughStamina(for movement: String, isPlayer: Bool) -> Bool {
        let requiredStamina = movementStaminaCost[movement] ?? 0
        return isPlayer ? playerStamina >= requiredStamina : opponentStamina >= requiredStamina
    }
    
    private func consumeStamina(for movement: String, isPlayer: Bool) {
        let cost = movementStaminaCost[movement] ?? 0
        if isPlayer {
            playerStamina = max(0, playerStamina - cost)
        } else {
            opponentStamina = max(0, opponentStamina - cost)
        }
    }
    
    func handleDodge(direction: String) {
        guard !playerDodging && playerState == "none" else { return }
        
        playerDodging = true
        playerState = "dodge-" + direction
        dodgeDirection = direction
        
        if opponentState != "none" {
            playerHealth += movementDamage[opponentState] ?? 0
        }
        
        playerStamina = max(0, playerStamina - 10)
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(dodgeDuration * 1_000_000_000))
            playerDodging = false
            dodgeDirection = "none"
            playerState = "none"
        }
    }
    
    private func updateHealth() -> Bool {
        if playerHealth <= 0 {
            playerState = "knock"
            stopOpponentMove()
            
            result = "lose"
            return true
        }
        
        if opponentHealth <= 0 {
            opponentState = "punched"
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 750_000_000)
                opponentState = "knock"
                
                startKnockoutCount()
            }
            return true
        }
        
        return false
    }

    func resetGame() {
        playerHealth = 100
        opponentHealth = 100
        playerStamina = 100
        opponentStamina = 100
        playerState = "none"
        opponentState = "none"
        playerFlipped = false
        opponentFlipped = false
        knockedCounter = "ko"
        result = ""
        knockoutCount = 0
        isCountingKnockout = false
        knockoutTimer?.invalidate()
        isExecutingPattern = false
        currentPatternIndex = 0
        currentMoveIndex = 0
        startStaminaRecovery()
        stopOpponentMove()
    }
    
    func setDifficulty(_ level: Double) {
        difficultyLevel = max(0.5, min(2.0, level))
        minThinkTime = max(0.3, 1.0 / difficultyLevel)
        maxThinkTime = max(0.6, 2.0 / difficultyLevel)
    }
    
    func startKnockoutCount() {
        isCountingKnockout = true
        knockoutCount += 1
        knockedCounter = "ko"
        
        knockoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                if self.playerHealth > 0 {
                    self.playerHealth = min(100, self.playerHealth + 5)
                } else if self.opponentHealth > 0 {
                    self.opponentHealth = min(100, self.opponentHealth + 5)
                }
            }
        }
    }

    func opponentGetUp() {
        let chanceOfGettingUp = 1.0 - (Double(knockoutCount) * 0.2)
            
        Task { @MainActor in
            
            if Double.random(in: 0...1) < chanceOfGettingUp {
                opponentHealth = 50
                opponentStamina = 50
                opponentState = "none"
                knockedCounter = "ko"
                isCountingKnockout = false
                knockoutTimer?.invalidate()
                    
                setDifficulty(difficultyLevel + 0.2)
            } else {
                result = "win"
                isCountingKnockout = false
                knockoutTimer?.invalidate()
            }
        }
    }
}
