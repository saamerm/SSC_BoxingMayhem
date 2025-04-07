// 
//   JoyStick.swift
//   SSC_BoxingMayhem
// 
//   Created by Kurnia Kharisma Agung Samiadjie on 23/02/25.
// 

import SwiftUI

struct JoyStick: View {
    @EnvironmentObject var gameService: GameService
    var body: some View {
        ZStack {
            VStack {
                HStack(spacing: 24) {
                    Button(action: {
                        gameService.updatePlayerState(newState: "jab")
                    }) {
                        Text("Jab")
                            .foregroundStyle(.white)
                            .fontWeight(.bold)
                    }
                    .disabled(gameService.playerState != "none" ? true : false)
                    .padding(20)
                    .background(.black)
                    .cornerRadius(10)

                    Button(action: {
                        gameService.updatePlayerState(newState: "hook")
                    }) {
                        Text("Hook")
                            .foregroundStyle(.white)
                            .fontWeight(.bold)
                    }
                    .disabled(gameService.playerState != "none" ? true : false)
                    .padding(20)
                    .background(.black)
                    .cornerRadius(10)
                }

                Button(action: {
                    gameService.updatePlayerState(newState: "uppercut")
                }) {
                    Text("uppercut")
                        .fontWeight(.bold)
                }
                .disabled(gameService.playerState != "none" ? true : false)
                .padding(20)
                .foregroundStyle(.white)
                .background(.black)
                .cornerRadius(10)

                HStack {
                    Button("Dodge Left") {
                        gameService.handleDodge(direction: "left")
                    }
                    .disabled(gameService.playerState != "none" ? true : false)
                    .padding(20)
                    .background(.black)
                    .foregroundStyle(.white)
                    .cornerRadius(10)

                    Button("Dodge Right") {
                        gameService.handleDodge(direction: "right")
                    }
                    .disabled(gameService.playerState != "none" ? true : false)
                    .padding(20)
                    .foregroundStyle(.white)
                    .background(.black)
                    .cornerRadius(10)
                }
            }
            .position(x: Device.width - 200, y: Device.height - 130)
            .zIndex(99)
        }
    }
}

#Preview {
    JoyStick()
        .environmentObject(GameService())
}
