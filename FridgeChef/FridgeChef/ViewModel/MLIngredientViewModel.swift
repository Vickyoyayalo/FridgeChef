//
//  MLIngredientViewModel.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//
import SwiftUI
import Vision
import CoreML
import PhotosUI
import Speech
import Combine

class MLIngredientViewModel: ObservableObject {
    // MARK: - Input Properties
    @Published var image: UIImage?
    @Published var recognizedText: String = ""
    @Published var quantity: String = "1"
    @Published var expirationDate: Date = Date()
    @Published var storageMethod: String = "Fridge"
    @Published var isRecording: Bool = false
    @Published var showPhotoOptions: Bool = false
    @Published var photoSource: MLIngredientView.PhotoSource?
    @Published var isSavedAlertPresented: Bool = false
    @Published var progressMessage: String = ""
    @Published var showingProgressView: Bool = false
    
    // MARK: - Dependencies
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - Callbacks
    var onSave: ((Ingredient) -> Void)?
    
    // MARK: - Initialization
    init(speechLocale: Locale = Locale(identifier: "zh-Hant")) {
        self.speechRecognizer = SFSpeechRecognizer(locale: speechLocale)
        requestSpeechRecognitionAuthorization()
    }
    
    // MARK: - Speech Recognition
    func requestSpeechRecognitionAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    // Authorized
                    break
                case .denied, .restricted, .notDetermined:
                    // Not authorized
                    self?.isRecording = false
                @unknown default:
                    fatalError("Unhandled authorization status")
                }
            }
        }
    }
    
    func startRecording() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognizer is not available.")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, when in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Couldn't start recording: \(error.localizedDescription)")
            return
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            var isFinal = false
            
            if let result = result {
                self?.recognizedText = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self?.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self?.recognitionRequest = nil
                self?.recognitionTask = nil
                self?.isRecording = false
            }
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
    }
    
    // MARK: - Image Recognition
    func recognizeFood(in image: UIImage) {
        guard let model = try? VNCoreMLModel(for: Food().model) else {
            print("Failed to load model")
            return
        }

        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                print("No results: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            DispatchQueue.main.async {
                let label = topResult.identifier
                // Translate the label from the dictionary
                let translatedLabel = TranslationDictionary.foodNames[label] ?? "未知"
                // Update UI with the translated label
                self?.recognizedText = translatedLabel
            }
        }

        guard let ciImage = CIImage(image: image) else {
            print("Unable to create \(CIImage.self) from \(image).")
            return
        }

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Text Recognition (OCR)
    func performTextRecognition(on image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            recognizedText = "Cannot process the photo"
            return
        }

        let request = VNRecognizeTextRequest { [weak self] (request, error) in
            if let error = error {
                self?.recognizedText = "文字識別錯誤: \(error.localizedDescription)"
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                self?.recognizedText = "無法識別文字"
                return
            }

            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            DispatchQueue.main.async {
                self?.recognizedText = recognizedStrings.joined(separator: "\n")
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
                    self.recognizedText = "圖片處理失敗: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Save Ingredient
    func saveIngredient() {
        let defaultAmount = 1.0  // 示例值
        let defaultUnit = "unit"    // 示例单位

        // 创建 Ingredient 实例
        var newIngredient = Ingredient(
            name: recognizedText,
            quantity: Double(Int(quantity ?? "1.00") ?? 1),
            amount: defaultAmount,
            unit: defaultUnit,
            expirationDate: expirationDate,
            storageMethod: storageMethod,
            imageBase64: image?.pngData()?.base64EncodedString()
        )
        
        isSavedAlertPresented = true
        onSave?(newIngredient)
        clearForm()
    }
    
    // MARK: - Clear Form
    func clearForm() {
        recognizedText = ""
        quantity = "1"
        expirationDate = Date()
        image = nil
        storageMethod = "Fridge"
    }
}

//import SwiftUI
//
//class MLIngredientViewModel: ObservableObject {
//    @Published var image: UIImage?
//    @Published var quantity: String = "1"
//    @Published var expirationDate: Date = Date()
//    @Published var isSavedAlertPresented = false
//    @State private var storageMethod = "Fridge"
//    let storageOptions = ["Fridge", "Freeze"]
//    var ingredient: Ingredient?
//    var onSave: ((Ingredient) -> Void)?
//    var editingFoodItem: Ingredient?
//
//    // 語音與文字識別服務
//    @ObservedObject var recognitionService = RecognitionService()
//   
//    init(onSave: ((Ingredient) -> Void)? = nil, editingFoodItem: Ingredient? = nil) {
//        self.onSave = onSave
//        self.editingFoodItem = editingFoodItem
//
//        if let item = editingFoodItem {
//            recognitionService.recognizedText = item.name
//            quantity = item.quantity ?? "1"
//            expirationDate = item.expirationDate
//            storageMethod = item.storageMethod
//            image = item.image
//        }
//    }
//    
//    func setup(with ingredient: Ingredient) {
//            self.ingredient = ingredient
//        }
//    // 保存食材
//    func saveIngredient() {
//        // 假设我们需要一些默认值或逻辑来计算 amount 和 unit
//        let defaultAmount = 1.0  // 一个示例值
//        let defaultUnit = "個"    // 一个示例单位
//        let base64String = image?.pngData()?.base64EncodedString()
//        // 创建 Ingredient 实例
//        var newIngredient = Ingredient(
//            name: recognitionService.recognizedText,
//            quantity: quantity,
//            amount: defaultAmount,
//            unit: defaultUnit,
//            expirationDate: expirationDate,
//            storageMethod: storageMethod,
//            imageBase64: image?.pngData()?.base64EncodedString()  // 转换 UIImage 为 Base64 字符串
//        )
//
//        // 调用 onSave 回调函数保存 Ingredient
//        onSave?(newIngredient)
//        isSavedAlertPresented = true
//    }
//
//    // 語音識別授權請求
//    func requestSpeechRecognitionAuthorization() {
//        recognitionService.requestSpeechRecognitionAuthorization { isAuthorized in
//            if !isAuthorized {
//                print("語音識別授權失敗")
//            }
//        }
//    }
//}

//import SwiftUI
//import Vision
//import CoreML
//import PhotosUI
//import Speech
//
//class MLIngredientViewModel: ObservableObject {
//    @Published var image: UIImage?
//    @State private var recognizedText: String = ""
//    @Published var quantity: String = "1"
//    @Published var expirationDate: Date = Date()
//    @Published var isAuthorized: Bool = false
//    @Published var isRecording: Bool = false
//    @Published var storageMethod = "冷藏"
//    let storageOptions = ["冷凍", "冷藏", "室溫"]
//
//    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
//    private var recognitionTask: SFSpeechRecognitionTask?
//    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-Hant"))
//    private let audioEngine = AVAudioEngine()
//
//    // Methods related to functionalities
//    func startRecording() {
//        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
//        let inputNode = audioEngine.inputNode
//        
//        // 确保输入节点的格式是有效的
//        let recordingFormat = inputNode.outputFormat(forBus: 0)
//        
//        // 验证采样率和声道数是否正确
//        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
//            print("無效的音頻格式: \(recordingFormat)")
//            return
//        }
//        
//        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!, resultHandler: { result, error in
//            if let result = result {
//                self.recognizedText = result.bestTranscription.formattedString
//            }
//            if error != nil || result?.isFinal == true {
//                self.audioEngine.stop()
//                inputNode.removeTap(onBus: 0)
//                self.recognitionRequest = nil
//                self.recognitionTask = nil
//                self.isRecording = false
//            }
//        })
//        
//        // 安装音频 Tap，将输入节点的音频流传递到请求
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
//            self.recognitionRequest?.append(buffer)
//        }
//        
//        audioEngine.prepare()
//        
//        do {
//            try audioEngine.start()
//            isRecording = true
//        } catch {
//            print("Couldn't start recording")
//        }
//    }
//    // 停止錄音
//    func stopRecording() {
//        audioEngine.stop()
//        recognitionRequest?.endAudio()
//        isRecording = false
//    }
//
//    func requestSpeechRecognitionAuthorization() {
//        SFSpeechRecognizer.requestAuthorization { status in
//            DispatchQueue.main.async {
//                switch status {
//                case .authorized:
//                    self.isAuthorized = true
//                case .denied, .restricted, .notDetermined:
//                    self.isAuthorized = false
//                @unknown default:
//                    fatalError("未處理的授權狀態")
//                }
//            }
//        }
//    }
//
//    func recognizeFood(in image: UIImage) {
//        guard let model = try? VNCoreMLModel(for: Food().model) else {
//            print("Failed to load model")
//            return
//        }
//        
//        let request = VNCoreMLRequest(model: model) { request, error in
//            guard let results = request.results as? [VNClassificationObservation],
//                  let topResult = results.first else {
//                      print("No results: \(error?.localizedDescription ?? "Unknown error")")
//                      return
//                  }
//            
//            DispatchQueue.main.async {
//                let label = topResult.identifier
//                // Translate the label from the dictionary
//                let translatedLabel =  TranslationDictionary.foodNames[label] ?? "未知"
//                // Update UI with the translated label
//                self.updateUIWithFoodRecognitionResult(result: translatedLabel)
//            }
//        }
//        
//        guard let ciImage = CIImage(image: image) else {
//            print("Unable to create \(CIImage.self) from \(image).")
//            return
//        }
//        
//        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                try handler.perform([request])
//            } catch {
//                print("Failed to perform classification.\n\(error.localizedDescription)")
//            }
//        }
//    }
//
//    // Helper function to update UI
//    func updateUIWithFoodRecognitionResult(result: String) {
//        // Update your UI elements, maybe using published properties or calling another method that handles UI updates
//        recognizedText = result  // This assumes `recognizedText` is accessible and updated correctly
//    }
//
//    //     使用 Vision 進行文字識別 (OCR)
//    func performTextRecognition(on image: UIImage) {
//        guard let ciImage = CIImage(image: image) else {
//            recognizedText = "無法處理圖片"
//            return
//        }
//        
//        let request = VNRecognizeTextRequest { (request, error) in
//            if let error = error {
//                self.recognizedText = "文字識別錯誤: \(error.localizedDescription)"
//                return
//            }
//            
//            guard let observations = request.results as? [VNRecognizedTextObservation] else {
//                self.recognizedText = "無法識別文字"
//                return
//            }
//            
//            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
//            DispatchQueue.main.async {
//                self.recognizedText = recognizedStrings.joined(separator: "\n")
//            }
//        }
//        
//        request.recognitionLanguages = ["zh-Hant", "en-US"]
//        request.recognitionLevel = .accurate
//        
//        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
//        
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                try handler.perform([request])
//            } catch {
//                DispatchQueue.main.async {
//                    self.recognizedText = "圖片處理失敗: \(error.localizedDescription)"
//                }
//            }
//        }
//    }
//}
//
