//
//   VideoPreview.swift
//   SSC_BoxingMayhem
//
//   Created by Kurnia Kharisma Agung Samiadjie on 23/02/25.
//

import SwiftUI
#if canImport(UIKit)
struct VideoPreview: UIViewControllerRepresentable {
    @EnvironmentObject var gameService: GameService

    func makeUIViewController(context: Context) -> ViewController {
        let viewController = ViewController()
        viewController.gameService = gameService
        return viewController
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        
    }
}
#endif
#if canImport(AppKit)
struct VideoPreview: NSViewControllerRepresentable {
    @EnvironmentObject var gameService: GameService

    func makeNSViewController(context: Context) -> ViewController {
        let viewController = ViewController()
        viewController.gameService = gameService
        return viewController
    }

    func updateNSViewController(_ nsViewController: ViewController, context: Context) {
        
    }
}
#endif
