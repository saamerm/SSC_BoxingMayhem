//
//  SwiftUIView.swift
//  SSC_BoxingMayhem
//
//  Created by Kurnia Kharisma Agung Samiadjie on 24/02/25.
//

import SwiftUI

struct EndGame: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var gameService: GameService
    @Binding var result: String
    @Binding var isGamePlayed: Bool
    @State private var imageScale: CGFloat = 1

    var body: some View {
        ZStack {
            Image("podium")
                .resizable()
                .renderingMode(.original)
                .frame(width: Device.width, height: Device.height * 1.2)
                .ignoresSafeArea()

            Color.black.opacity(result == "win" ? 0.2 : 0.5)
                .ignoresSafeArea()
            VStack {
                Image("you" + result)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300)
                    .scaleEffect(imageScale)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
                    .animation(
                        .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: imageScale
                    )

                Image(result)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Device.width * 0.3, height: Device.width * 0.35)
                    .scaleEffect(imageScale)
                    .shadow(color: .black.opacity(0.4), radius: 5, x: 0, y: 5)
                    .animation(
                        .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: imageScale
                    )
            }
            .position(x: Device.width / 2, y: Device.height - 100)

            Button(action: {
                isGamePlayed = false
                gameService.resetGame()

                dismiss()
            }) {
                Text("Back to main menu")
                    .foregroundStyle(.white)
            }
            .padding()
            .font(.headline)
            .background(Color.black.opacity(0.7))
            .cornerRadius(12)
            .position(x: Device.width / 4, y: Device.height)
        }
        .onAppear {
            startImageScale()
            startSound()
            gameService.stopOpponentMove()
            print(result)
        }
        .onDisappear {
            AudioManager.shared.stopAllSounds()
            AudioManager.shared.playSound("bgm")
            AudioManager.shared.setVolume(0.3, for: "bgm")
        }
    }

    func startImageScale() {
        withAnimation(
            .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
        ) {
            imageScale = 1.05
        }
    }

    func startSound() {
        AudioManager.shared.stopAllSounds()
        AudioManager.shared.playSound(result + "-violin")

        if result == "win" {
            AudioManager.shared.playSoundWithLoop("crowd-cheer")
            AudioManager.shared.setVolume(0.2, for: "crowd-cheer")
        }
    }
}

#Preview {
    EndGame(result: .constant("win"), isGamePlayed: .constant(false))
        .environmentObject(GameService())
}
