//
//   StartGameCount.swift
//   SSC_BoxingMayhem
//
//   Created by Kurnia Kharisma Agung Samiadjie on 23/02/25.
//
import SwiftUI

struct StartGameCount: View {
    @EnvironmentObject var gameService: GameService
    @State private var countDown = 3
    @State private var timer: Timer? = nil

    var body: some View {
        ZStack {
            Image("\(countDown)")
                .id(countDown)
                .transition(.scale.animation(.bouncy))
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
                .onAppear {
                    startTimer()
                    startSound()
                }
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

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task {
                await updateGameCount()
            }
        }
    }

    func startSound() {
        AudioManager.shared.playSound("countdownStart")
    }

    @MainActor
    func updateGameCount() {
        if countDown == 1 {
            countDown = 0
            timer?.invalidate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                gameService.gameState = "fight"
                gameService.startOpponentMove()
            }
        } else {
            countDown -= 1
        }
    }
}

#Preview {
    StartGameCount()
        .environmentObject(GameService())
}
