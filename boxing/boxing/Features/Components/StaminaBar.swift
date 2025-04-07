//
//   StaminaBar.swift
//   SSC_BoxingMayhem
//
//   Created by Kurnia Kharisma Agung Samiadjie on 23/02/25.
//

import SwiftUI

struct StaminaBar: View {
    let charInfo: CharInfo
    @EnvironmentObject var gameService: GameService
    var frameWidth = Device.width * 0.4

    private var staminaValue: Int {
        charInfo == .player ? gameService.playerStamina : gameService.opponentStamina
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: frameWidth, height: 20)
                    .foregroundColor(.black.opacity(0.5))

                Rectangle()
                    .frame(width: CGFloat(staminaValue) / 100 * frameWidth, height: 20)
                    .foregroundColor(.yellow)
            }
            .cornerRadius(10)
        }
    }
}
