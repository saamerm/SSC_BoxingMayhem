//
//   CharInfo.swift
//   SSC_BoxingMayhem
//
//   Created by Kurnia Kharisma Agung Samiadjie on 23/02/25.
//

import SwiftUI

enum CharInfo {
    case player
    case opponent

    var type: String {
        switch self {
        case .player:
            return "player"
        case .opponent:
            return "opponent"
        }
    }
}
