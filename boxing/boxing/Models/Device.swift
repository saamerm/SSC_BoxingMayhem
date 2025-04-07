//
//   Device.swift
//   SSC_BoxingMayhem
//
//   Created by Kurnia Kharisma Agung Samiadjie on 23/02/25.
//

import Foundation
import SwiftUI

@MainActor
enum Device {
#if canImport(UIKit)
    static let width: CGFloat = UIScreen.main.bounds.width
    static let height: CGFloat = UIScreen.main.bounds.height
#endif
#if canImport(AppKit)
    static let width: CGFloat = 1080//500
    static let height: CGFloat = 500//1080
#endif

}
