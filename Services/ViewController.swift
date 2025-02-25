//
//   ViewController.swift
//   SSC_BoxingMayhem
//
//   Created by Kurnia Kharisma Agung Samiadjie on 23/02/25.
//

import AVFoundation
import SwiftUI
import UIKit

@MainActor
class ViewController: UIViewController {
    var gameService: GameService?
    let videoCapture = VideoCapture()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var pointsLayer = CAShapeLayer()
    var actionTimer: DispatchSourceTimer?
    var actionPending: String?
    var lastActionTime: Date = .init(timeIntervalSince1970: 0)
    private var delegateHandler: PredictorDelegateHandler?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVideoPreview()
        setupPredictorDelegate()
    }
    
    private func setupVideoPreview() {
        videoCapture.startCaptureSession()
        previewLayer = AVCaptureVideoPreviewLayer(session: videoCapture.captureSession)
        
        guard let previewLayer = previewLayer else { return }
        
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = CGRect(x: 0.0, y: Device.height - 180, width: 320, height: 180)
        previewLayer.connection?.videoRotationAngle = 0
    }
    
    private func setupPredictorDelegate() {
        delegateHandler = PredictorDelegateHandler(viewController: self)
        videoCapture.predictor.delegate = delegateHandler
    }
    
    private func performPendingAction() {}
    
    func updatePoints(_ points: [CGPoint]) {
        guard let previewLayer = previewLayer else { return }
        
        let convertedPoints = points.map {
            previewLayer.layerPointConverted(fromCaptureDevicePoint: $0)
        }
        
        let combinedPath = CGMutablePath()
        
        for point in convertedPoints {
            let dotPath = UIBezierPath(ovalIn: CGRect(x: point.x, y: point.y, width: 10, height: 10))
            combinedPath.addPath(dotPath.cgPath)
        }
        
        pointsLayer.path = combinedPath
    }
}

@MainActor
class PredictorDelegateHandler: NSObject, PredictorDelegate {
    private weak var viewController: ViewController?
    
    init(viewController: ViewController) {
        self.viewController = viewController
        super.init()
    }
    
    nonisolated func predictor(_ predictor: Predictor, didLabelAction action: String, with confidence: Double) {
        let capturedAction = action
        let capturedConfidence = confidence
        
        if capturedConfidence >= 0.9 {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                await self.handleAction(action: capturedAction)
            }
        }
    }
    
    nonisolated func predictor(_ predictor: Predictor, didFindRecognizedPoints points: [CGPoint]) {
        let capturedPoints = points
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.handlePoints(points: capturedPoints)
        }
    }
    
    private func handleAction(action: String) async {
        guard let viewController = viewController else { return }
        viewController.gameService?.updatePlayerState(newState: action)
    }
    
    private func handlePoints(points: [CGPoint]) {
        guard let viewController = viewController else { return }
        viewController.updatePoints(points)
    }
}
