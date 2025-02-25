//
//   VideoCapture.swift
//   SSC_BoxingMayhem
//
//   Created by Kurnia Kharisma Agung Samiadjie on 23/02/25.
//

import AVFoundation
import Foundation
import Vision

protocol DodgeDelegate: AnyObject {
    func didDetectDodge(direction: String)
}

class VideoCapture: NSObject {
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    let predictor = Predictor()
    
    weak var dodgeDelegate: DodgeDelegate?
    
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let videoQueue = DispatchQueue(label: "videoQueue")
    private let bodyTracker = VNSequenceRequestHandler()
    
    private let dodgeQueue = DispatchQueue(label: "dodgeQueue")
    private var lastDodgeTime: Date = .init()
    private let dodgeCooldown: TimeInterval = 0.5
    private let dodgeThreshold: Float = 0.2
    private var baselineX: CGFloat = 0.5
    private var isCalibrated = false
    
    override init() {
        super.init()
        setupCaptureSession()
    }
    
    private func setupCaptureSession() {
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        captureSession.addInput(input)
        
        captureSession.addOutput(videoOutput)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
    }
    
    func startCaptureSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    func pauseCaptureSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            Thread.sleep(forTimeInterval: 1.0)
            self?.captureSession.startRunning()
        }
    }
    
    private func processBodyPose(_ sampleBuffer: CMSampleBuffer) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectHumanBodyPoseRequest { [weak self] request, _ in
            guard let self = self,
                  let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else { return }
            
            self.processPoseObservation(observation)
        }
        
        try? bodyTracker.perform([request], on: imageBuffer)
    }
    
    private func processPoseObservation(_ observation: VNHumanBodyPoseObservation) {
        guard let leftShoulder = try? observation.recognizedPoint(.leftShoulder),
              let rightShoulder = try? observation.recognizedPoint(.rightShoulder),
              leftShoulder.confidence > 0.7 && rightShoulder.confidence > 0.7
        else {
            return
        }
        
        let centerX = (leftShoulder.location.x + rightShoulder.location.x) / 2
        
        dodgeQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.isCalibrated {
                self.baselineX = centerX
                self.isCalibrated = true
                return
            }
            
            let currentTime = Date()
            guard currentTime.timeIntervalSince(self.lastDodgeTime) >= self.dodgeCooldown else { return }
            
            let movement = centerX - self.baselineX
            if abs(movement) > CGFloat(self.dodgeThreshold) {
                let direction = movement > 0 ? "right" : "left"
                self.lastDodgeTime = currentTime
                
                DispatchQueue.main.async {
                    self.dodgeDelegate?.didDetectDodge(direction: direction)
                }
            }
        }
    }
}

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        predictor.estimation(sampleBuffer)
        processBodyPose(sampleBuffer)
    }
}
