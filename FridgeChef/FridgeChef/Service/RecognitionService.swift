//
//  RecognitionService.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/19.
//

import CoreML
import Vision
import UIKit
import Speech

class RecognitionService: ObservableObject {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-Hant"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    @Published var recognizedText: String = ""
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var isRecording: Bool = false
    
    private let alertService = AlertService()
    
    func recognizeFood(in image: UIImage, completion: @escaping (String) -> Void) {
        guard let model = try? VNCoreMLModel(for: Food(configuration: MLModelConfiguration()).model) else {
            print("Failed to load CoreML model.")
            completion("Unable to recognize food.")
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                print("Unable to recognize food: \(error.localizedDescription)")
                completion("Unable to recognize food.")
                return
            }
            
            guard let results = request.results as? [VNClassificationObservation], let topResult = results.first else {
                print("Unable to recognize food.")
                completion("Unable to recognize food.")
                return
            }
            
            DispatchQueue.main.async {
                let label = topResult.identifier
                let translatedLabel = TranslationDictionary.foodNames[label] ?? "Unknown Food"
                completion(translatedLabel)
            }
        }
        
        guard let ciImage = CIImage(image: image) else {
            print("Cannot \(image) transfer to CIImage")
            return
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Food category identification failed: \(error.localizedDescription)")
            }
        }
    }
    
    func performTextRecognition(on image: UIImage, completion: @escaping (String) -> Void) {
        guard let ciImage = CIImage(image: image) else {
            completion("Unable to recognize photos.")
            return
        }
        
        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                completion("Unable to recognize text: \(error.localizedDescription)")
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("Unable to recognize text.")
                return
            }
            
            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            DispatchQueue.main.async {
                completion(recognizedStrings.joined(separator: "\n"))
            }
        }
        
        request.recognitionLanguages = ["zh-Hant", "en-US"]
        request.recognitionLevel = .accurate
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion("Photo identification failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func requestSpeechRecognitionAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    completion(true)
                case .denied:
                    self.showSpeechRecognitionDeniedAlert()
                    completion(false)
                case .restricted, .notDetermined:
                    self.showSpeechRecognitionUnavailableAlert()
                    completion(false)
                @unknown default:
                    fatalError("Unknown speech recognition authorization status.")
                }
            }
        }
    }
    
    func startRecording() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { result, error in
            if let result = result {
                self.recognizedText = result.bestTranscription.formattedString
            }
            if error != nil || result?.isFinal == true {
                self.stopRecording()
            }
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.outputFormat(forBus: 0)) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Unable to use speech recognition.")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
    }
    
    private func showSpeechRecognitionDeniedAlert() {
        alertTitle = "Unknown speech recognition authorization status."
        alertMessage = "Speech recognition has been denied. Please go to settings and allow speech recognition."
        showAlert = true
    }
    
    private func showSpeechRecognitionUnavailableAlert() {
        alertTitle = "Unable to use speech recognition."
        alertMessage = "Speech recognition has been denied. Please go to settings and allow speech recognition."
        showAlert = true
    }
}

