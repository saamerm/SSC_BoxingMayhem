//
//
//   KnockedCount.swift
//   BoxingMayhem
//
//   Created by Kurnia Kharisma Agung Samiadjie on 26/05/24.
//

import SwiftUI

struct KnockedCount: View {
    @EnvironmentObject var gameService: GameService
    @State private var currentCount = 1
    @State private var timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Image(gameService.knockedCounter)
                .id(gameService.knockedCounter)
                .transition(.scale.animation(.bouncy))
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
                .onAppear {
                    gameService.startKnockoutCount()
//                    updateKnockedCounter()
                }
                .onReceive(timer) { _ in
                    updateKnockedCounter()
                }
        }
        .onDisappear {
            stopCountDownSound()
        }
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(Color.black.opacity(0.2))
    }
    
    private func startCountDownSound() {
        AudioManager.shared.playSound("countdown-ko")
    }
    
    private func stopCountDownSound() {
        AudioManager.shared.stopSound("countdown-ko")
    }
    
    private func updateKnockedCounter() {
        if gameService.knockedCounter == "ko" {
            gameService.knockedCounter = "1"
            currentCount = 1
                
            startCountDownSound()
                    
            return
        }
        
        if let count = Int(gameService.knockedCounter) {
            if count >= 8 && gameService.opponentHealth <= 0 {
                timer.upstream.connect().cancel()
                gameService.opponentGetUp()

                return
            }
            
            currentCount = count + 1
            gameService.knockedCounter = String(currentCount)
        }
    }
}
