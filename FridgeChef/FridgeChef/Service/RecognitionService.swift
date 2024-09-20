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
    // 語音辨識相關
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-Hant"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    @Published var recognizedText: String = ""
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var isRecording: Bool = false
    
    // 加入 AlertService
    private let alertService = AlertService()
    
    // 食物分類辨識
    func recognizeFood(in image: UIImage, completion: @escaping (String) -> Void) {
        guard let model = try? VNCoreMLModel(for: Food().model) else {
            print("無法加載 CoreML 模型")
            completion("無法識別食物")
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                print("食物識別錯誤: \(error.localizedDescription)")
                completion("無法識別食物")
                return
            }
            
            guard let results = request.results as? [VNClassificationObservation], let topResult = results.first else {
                print("無法識別結果")
                completion("無法識別食物")
                return
            }
            
            DispatchQueue.main.async {
                // 取得辨識結果並返回
                let label = topResult.identifier
                let translatedLabel = TranslationDictionary.foodNames[label] ?? "未知食物"
                completion(translatedLabel)
            }
        }
        
        guard let ciImage = CIImage(image: image) else {
            print("無法將 \(image) 轉換為 CIImage")
            return
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("食物分類識別失敗: \(error.localizedDescription)")
            }
        }
    }
    
    // 文字辨識 (OCR)
    func performTextRecognition(on image: UIImage, completion: @escaping (String) -> Void) {
        guard let ciImage = CIImage(image: image) else {
            completion("無法處理圖片")
            return
        }
        
        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                completion("文字識別錯誤: \(error.localizedDescription)")
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("無法識別文字")
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
                    completion("圖片處理失敗: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 語音辨識相關邏輯，保持不變
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
                    fatalError("未知的語音識別授權狀態")
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
            print("無法開始錄音")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
    }
    
    // 顯示語音識別被拒的警告
    private func showSpeechRecognitionDeniedAlert() {
        alertTitle = "無法使用語音識別"
        alertMessage = "語音識別功能已被拒絕。請前往設定中允許語音識別。"
        showAlert = true
    }
    
    // 顯示語音識別無法使用的警告
    private func showSpeechRecognitionUnavailableAlert() {
        alertTitle = "無法使用語音識別"
        alertMessage = "語音識別功能無法使用，可能由於設備限制。"
        showAlert = true
    }
}
