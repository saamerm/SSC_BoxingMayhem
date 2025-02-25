//
//   VideoPreview.swift
//   SSC_BoxingMayhem
//
//   Created by Kurnia Kharisma Agung Samiadjie on 23/02/25.
//

import SwiftUI

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
