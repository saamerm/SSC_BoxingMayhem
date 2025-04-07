import CoreML
import Foundation
import Vision

class BoxingClassifier {
    private var model: MLModel?
    
    init() throws {
//        if let urls = Bundle.main.urls(forResourcesWithExtension: "mlmodelc", subdirectory: "boxing") {
//            print("Found MLModels:")
//            for url in urls {
//                print(" - \(url.lastPathComponent)")
//            }
//        } else {
//            print("No MLModels found in the MLModels directory.")
//        }
//        if let urls = Bundle.main.urls(forResourcesWithExtension: "mlmodelc", subdirectory: "") {
//            print("Found MLModels:")
//            for url in urls {
//                print(" - \(url.lastPathComponent)")
//            }
//        } else {
//            print("No MLModels found in the MLModels directory.")
//        }
//        if let urls = Bundle.main.urls(forResourcesWithExtension: "mlmodelc", subdirectory: "MLModels") {
//            print("Found MLModels:")
//            for url in urls {
//                print(" - \(url.lastPathComponent)")
//            }
//        } else {
//            print("No MLModels found in the MLModels directory.")
//        }

//        guard let modelURL = Bundle.main.url(forResource: "BoxingHand_Refined", withExtension: "mlmodelc") else {
//            throw NSError(domain: "ModelNotFound", code: -1, userInfo: nil)
//        }
//        
//        let compiledModelURL = try MLModel.compileModel(at: modelURL)
//        model = try MLModel(contentsOf: compiledModelURL)
        model = try BoxingHand_Refined(configuration: MLModelConfiguration()).model
    }
    
    func prediction(poses: MLMultiArray) throws -> (label: String, labelProbabilities: [String: Double]) {
        guard let model = model else {
            throw NSError(domain: "ModelNotInitialized", code: -1, userInfo: nil)
        }
        
        let input = try MLDictionaryFeatureProvider(dictionary: ["poses": poses])
        let output = try model.prediction(from: input)
        
        guard let label = output.featureValue(for: "label")?.stringValue,
              let probabilities = output.featureValue(for: "labelProbabilities")?.dictionaryValue as? [String: Double]
        else {
            throw NSError(domain: "PredictionError", code: -1, userInfo: nil)
        }
        
        return (label: label, labelProbabilities: probabilities)
    }
}

// Predictor Delegate Protocol
protocol PredictorDelegate: AnyObject {
    func predictor(_ predictor: Predictor, didFindRecognizedPoints points: [CGPoint])
    func predictor(_ predictor: Predictor, didLabelAction action: String, with confidence: Double)
}

class Predictor: ObservableObject {
    // MARK: - Properties

    weak var delegate: PredictorDelegate?
    private var boxingClassifier: BoxingClassifier?
    
    let predictionWindowSize = 30
    var posesWindow: [VNHumanHandPoseObservation] = []
    
    private var lastActionTime: Date = .init()
    private var minimumActionInterval: TimeInterval = 0.8
    private var confidenceThreshold: Double = 0.9
    private var lastAction: String?
    private var actionCounter: Int = 0
    private var maxConsecutiveActions: Int = 3
    private var actionBuffer: [String] = []
    private let bufferSize = 4
    
    // MARK: - Initialization

    init() {
        posesWindow.reserveCapacity(predictionWindowSize)
        setupClassifier()
    }
    
    private func setupClassifier() {
        do {
            boxingClassifier = try BoxingClassifier()
        } catch {
            print("Error initializing classifier: \(error)")
        }
    }
    
    // MARK: - Hand Pose Detection

    func estimation(_ sampleBuffer: CMSampleBuffer) {
        let requestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up)
        let request = VNDetectHumanHandPoseRequest(completionHandler: handPoseHandler)
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Error performing hand pose detection: \(error)")
        }
    }
    
    func handPoseHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNHumanHandPoseObservation] else {
            print("No hand pose observations found")
            return
        }
        
        if let result = observations.first {
            storeObservation(result)
            
            // Get recognized points for visualization if needed
            do {
                let recognizedPoints = try result.recognizedPoints(.all)
                let cgPoints = recognizedPoints.values.compactMap { point -> CGPoint? in
                    guard point.confidence > 0.7 else { return nil }
                    return CGPoint(x: point.location.x, y: point.location.y)
                }
                delegate?.predictor(self, didFindRecognizedPoints: cgPoints)
            } catch {
                print("Error getting recognized points: \(error)")
            }
        }
        
        labelActionType()
    }
    
    // MARK: - Action Recognition

    func labelActionType() {
        guard let classifier = boxingClassifier,
              let poseMultiArray = prepareInputWithObservation(posesWindow)
        else {
            return
        }
        
        do {
            let predictions = try classifier.prediction(poses: poseMultiArray)
            let label = predictions.label
            let confidence = predictions.labelProbabilities[label] ?? 0.0
            
            actionBuffer.append(label)
            if actionBuffer.count > bufferSize {
                actionBuffer.removeFirst()
            }
            
            let isConsistent = actionBuffer.allSatisfy { $0 == label }
            let currentTime = Date()
            let timeSinceLastAction = currentTime.timeIntervalSince(lastActionTime)
            
            if isConsistent && confidence >= confidenceThreshold && timeSinceLastAction >= minimumActionInterval {
                if label == lastAction {
                    actionCounter += 1
                    if actionCounter >= maxConsecutiveActions {
                        return
                    }
                } else {
                    actionCounter = 0
                }
                
                lastAction = label
                lastActionTime = currentTime
                
                delegate?.predictor(self, didLabelAction: label, with: confidence)
                actionBuffer.removeAll()
            }
        } catch {
            print("Prediction error: \(error)")
        }
    }
    
    func adjustSensitivity(confidenceThreshold: Double = 0.75,
                           cooldownInterval: TimeInterval = 0.8,
                           maxConsecutive: Int = 2)
    {
        self.confidenceThreshold = confidenceThreshold
        minimumActionInterval = cooldownInterval
        maxConsecutiveActions = maxConsecutive
    }
    
    func prepareInputWithObservation(_ observations: [VNHumanHandPoseObservation]) -> MLMultiArray? {
        let numAvailableFrames = observations.count
        let observationsNeeded = 30
        var multiArrayBuffer = [MLMultiArray]()
        
        for frameIndex in 0 ..< min(numAvailableFrames, observationsNeeded) {
            let pose = observations[frameIndex]
            do {
                let oneFrameMultiArray = try pose.keypointsMultiArray()
                multiArrayBuffer.append(oneFrameMultiArray)
            } catch {
                print("Error creating frame multi array: \(error)")
                continue
            }
        }
        
        if numAvailableFrames < observationsNeeded {
            for _ in 0 ..< (observationsNeeded - numAvailableFrames) {
                do {
                    let oneFrameMultiArray = try MLMultiArray(shape: [1, 3, 21], dataType: .double)
                    try resetMultiArray(oneFrameMultiArray)
                    multiArrayBuffer.append(oneFrameMultiArray)
                } catch {
                    print("Error creating padding multi array: \(error)")
                    continue
                }
            }
        }
        
        do {
            return try MLMultiArray(concatenating: [MLMultiArray](multiArrayBuffer), axis: 0, dataType: .float)
        } catch {
            print("Error concatenating multi arrays: \(error)")
            return nil
        }
    }
    
    func resetMultiArray(_ predictionWindow: MLMultiArray, with value: Double = 0.0) throws {
        let pointer = try UnsafeMutableBufferPointer<Double>(predictionWindow)
        pointer.initialize(repeating: value)
    }
    
    func storeObservation(_ observation: VNHumanHandPoseObservation) {
        if posesWindow.count >= predictionWindowSize {
            posesWindow.removeFirst()
        }
        posesWindow.append(observation)
    }
}
