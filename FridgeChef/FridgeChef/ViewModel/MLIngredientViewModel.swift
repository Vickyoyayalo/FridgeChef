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
import FirebaseFirestore
import FirebaseAuth
import SDWebImageSwiftUI

class MLIngredientViewModel: ObservableObject {
    // MARK: - PhotoSource Enum
    enum PhotoSource: Int, Identifiable {
        case photoLibrary = 0
        case camera = 1

        var id: Int { self.rawValue }
    }
    
    // MARK: - Published Properties
    @Published var image: UIImage?
    @Published var recognizedText: String = ""
    @Published var quantity: String = "1.00"
    @Published var expirationDate: Date = Date()
    @Published var storageMethod: String = "Fridge"
    @Published var isRecording: Bool = false
    @Published var showPhotoOptions: Bool = false
    @Published var photoSource: PhotoSource?
    @Published var isSavedAlertPresented: Bool = false
    @Published var progressMessage: String = ""
    @Published var showingProgressView: Bool = false
    @Published var showPhotoPermissionAlert: Bool = false
    @Published var photoPermissionDenied: Bool = false
    @Published var showCameraPermissionAlert: Bool = false
    @Published var cameraPermissionDenied: Bool = false
    // MARK: - Dependencies
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let firestoreService = FirestoreService()
    
    var onSave: ((Ingredient) -> Void)?
    var editingFoodItem: Ingredient?
    var ingredient: Ingredient?
   
    init(editingFoodItem: Ingredient? = nil, onSave: ((Ingredient) -> Void)? = nil) {
            self.onSave = onSave
            self.ingredient = editingFoodItem

            if let editingFoodItem = editingFoodItem {
                self.recognizedText = editingFoodItem.name
                self.quantity = String(editingFoodItem.quantity)
                self.expirationDate = editingFoodItem.expirationDate
                self.storageMethod = editingFoodItem.storageMethod
                
                if let existingImage = editingFoodItem.image {
                    self.image = existingImage
                } else if let imageURLString = editingFoodItem.imageURL, let url = URL(string: imageURLString) {
                    loadImageFromURL(url)
                }
            }
        }
    
    func loadImageFromURL(_ url: URL) {
            SDWebImageDownloader.shared.downloadImage(with: url) { [weak self] (image, data, error, finished) in
                if let image = image {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                } else {
                    print("Failed to load image from URL: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    // MARK: - Camera Permission
    func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            DispatchQueue.main.async {
                self.showCameraPermissionAlert = true
            }
        case .authorized:
            DispatchQueue.main.async {
                self.showPhotoOptions = true
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.cameraPermissionDenied = true
            }
        @unknown default:
            break
        }
    }

    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.showPhotoOptions = true
                } else {
                    self.cameraPermissionDenied = true
                }
            }
        }
    }
    
    // MARK: - PhotoLibrary Permission
    func checkPhotoLibraryPermission() {
            let status = PHPhotoLibrary.authorizationStatus()
            switch status {
            case .notDetermined:
                
                DispatchQueue.main.async {
                    self.showPhotoPermissionAlert = true
                }
            case .authorized, .limited:
               
                DispatchQueue.main.async {
                    self.showPhotoOptions = true
                }
            case .denied, .restricted:
               
                DispatchQueue.main.async {
                    self.photoPermissionDenied = true
                }
            @unknown default:
                break
            }
        }
        
        func requestPhotoLibraryPermission() {
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized, .limited:
                    DispatchQueue.main.async {
                        self.showPhotoOptions = true
                    }
                case .denied, .restricted, .notDetermined:
                    DispatchQueue.main.async {
                        self.photoPermissionDenied = true
                    }
                @unknown default:
                    break
                }
            }
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
        guard let model = try? VNCoreMLModel(for: Food(configuration: MLModelConfiguration()).model) else {
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
                let translatedLabel = TranslationDictionary.foodNames[label] ?? "Unknown"
                // Update UI with the translated label
                self?.recognizedText = translatedLabel
//                self?.recognizedText = label.isEmpty ? "Unknown" : label
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
                self?.recognizedText = "Recognition error: \(error.localizedDescription)"
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                self?.recognizedText = "Cannot recognize the words."
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
                    self.recognizedText = "Erro processing photos: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Save Ingredient
    func saveIngredient() {
            guard let quantityValue = Double(quantity) else {
              
                return
            }

            let ingredient = Ingredient(
                id: self.ingredient?.id ?? UUID().uuidString,
                name: recognizedText,
                quantity: quantityValue,
                amount: 1.0,
                unit: "unit",
                expirationDate: expirationDate,
                storageMethod: storageMethod,
                image: image,
                imageURL: self.ingredient?.imageURL
            )

            onSave?(ingredient)
   
        clearForm()

        isSavedAlertPresented = true
    }

    func calculateDaysRemaining(expirationDate: Date?) -> Int {
        guard let expirationDate = expirationDate else { return 0 }
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
        return max(0, daysRemaining)
    }

    // MARK: - Clear Form
    
    func clearForm() {
        recognizedText = ""
        quantity = "1.00"
        expirationDate = Date()
        image = nil
        storageMethod = "Fridge"
    }
}
