//
//   Game.swift
//   SSC_BoxingMayhem
//
//   Created by Kurnia Kharisma Agung Samiadjie on 26/05/24.
//

import SwiftUI

struct Game: View {
    @Binding var isGamePlayed: Bool
    @EnvironmentObject var gameService: GameService
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Image("background")
                .resizable()
                .background(Color.blue.secondary)
                .ignoresSafeArea(.all)

            // Low stamina overlay
            if gameService.playerStamina < 25 {
                Color.yellow
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: gameService.playerStamina < 25)
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HealthBar(charInfo: CharInfo.player)
                    StaminaBar(charInfo: CharInfo.player)
                    Text("State: " + gameService.playerState)
                        .padding(16)
                        .foregroundStyle(.white)
                        .fontWeight(.bold)
                        .background(.blue)
                        .cornerRadius(20)
                }
                Spacer()

                Image("vs")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 40)

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    HealthBar(charInfo: CharInfo.opponent)
                    StaminaBar(charInfo: CharInfo.opponent)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            Character(info: CharInfo.opponent, state: $gameService.opponentState, isFlipped: $gameService.opponentFlipped).position(x: Device.width/2, y: 200)

            Character(info: CharInfo.player, state: $gameService.playerState, isFlipped: $gameService.playerFlipped)
                .position(x: Device.width/2, y: Device.height - 100)

            if gameService.opponentHealth <= 0 {
                KnockedCount()
            }

            if gameService.gameState != "fight" {
                StartGameCount()
            } else {
                VideoPreview()
                    .ignoresSafeArea(.all)
                    .environmentObject(gameService)
                    
            }

            if gameService.result != "" {
                EndGame(result: $gameService.result, isGamePlayed: $gameService.isGamePlayed)
                    .environmentObject(gameService)
            }
        }
        .onAppear {
            AudioManager.shared.playSound("crowd")
            AudioManager.shared.setVolume(0.1, for: "crowd")
            AudioManager.shared.setVolume(0.02, for: "bgm")
        }
        .environmentObject(gameService)
    }
}

#Preview {
    Game(isGamePlayed: .constant(true))
        .environmentObject(GameService())
}
