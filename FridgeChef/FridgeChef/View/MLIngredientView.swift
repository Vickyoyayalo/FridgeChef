//
//  ContentView.swift
//  ScanAndRecognizeText
//
//  Created by Gabriel Theodoropoulos.
//

// MVVM架構前可操作的程式碼
import SwiftUI
import Vision
import CoreML
import PhotosUI
import Speech

@available(iOS 16.0, *)
struct MLIngredientView: View {
    @State private var image: UIImage?
    @State private var recognizedText: String = ""
    @State private var quantity: String = "1"
    @State private var expirationDate: Date = Date()

    // 麥克風使用權限
    @State private var isAuthorized = false
    @State private var isRecording = false

    // 語音識別相關的狀態變量
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-Hant"))
    private let audioEngine = AVAudioEngine()

    // Picker 選項和當前選中的存儲方式
    @State private var storageMethod = "冷藏"
    let storageOptions = ["冷凍", "冷藏", "室溫"]

    // 顯示相機選擇器
    @State private var isPickerPresented = false
    @State private var selectedItem: PhotosPickerItem?

    // 用於控制 Alert 顯示的狀態
    @State private var isShowingCameraAlert = false

    // 用於控制相機視圖顯示的狀態
    @State private var isShowingCamera = false

    init() {
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.white // 改變選中的顏色
        UISegmentedControl.appearance().backgroundColor = UIColor.orange
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.orange], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
    }

    var body: some View {
        CustomNavigationBarView(title: "") {
            VStack(spacing: 10) {
                // 上方標題和按鈕
                HStack {
                    Text("食材紀錄")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.black)

                    Spacer()

                    // 相機和照片按鈕
                    HStack {
                        Button(action: {
                            isShowingCameraAlert = true
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                        .alert(isPresented: $isShowingCameraAlert) {
                            Alert(
                                title: Text("開啟相機"),
                                message: Text("你確定要開啟相機嗎？"),
                                primaryButton: .default(Text("是")) {
                                    isShowingCamera = true
                                },
                                secondaryButton: .cancel(Text("否"))
                            )
                        }

                        Button(action: {
                            isPickerPresented = true
                        }) {
                            Image(systemName: "photo.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.horizontal)

                // 圖片顯示區域
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .padding(.bottom)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 150)
                        .overlay(
                            Text("請選擇圖片")
                                .foregroundColor(.gray)
                        )
                        .cornerRadius(10)
                        .padding()
                }

                // Picker 使用全局樣式
                Picker("選擇存儲方式", selection: $storageMethod) {
                    ForEach(storageOptions, id: \.self) { option in
                        Text(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color.white)
                .cornerRadius(8)

                // 名稱、數量、到期日與各自的 TextField 排列為 HStack
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("名稱")
                            .font(.headline)

                        // 名稱輸入框及語音按鈕
                        HStack {
                            TextField("辨識結果", text: $recognizedText)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )

                            // 麥克風按鈕
                            Button(action: {
                                if isRecording {
                                    stopRecording()
                                } else {
                                    startRecording()
                                }
                            }) {
                                Image(systemName: isRecording ? "mic.fill" : "mic")
                                    .font(.title2)
                                    .foregroundColor(isRecording ? .red : .orange)
                            }
                            .padding(.leading, 5)
                        }
                    }

                    HStack {
                        Text("數量")
                            .font(.headline)

                        TextField("請輸入數量", text: $quantity)
                            .keyboardType(.numberPad)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }

                    HStack {
                        Text("到期日")
                            .font(.headline)

                        DatePicker("", selection: $expirationDate, displayedComponents: .date)
                            .labelsHidden()
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .onAppear {
                requestSpeechRecognitionAuthorization()
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraView(onImagePicked: { image in
                    self.image = image
                    recognizeFood(in: image)
                    isShowingCamera = false
                }, onCancel: {
                    isShowingCamera = false
                })
            }
        }
        .photosPicker(isPresented: $isPickerPresented, selection: $selectedItem)
        .onChange(of: selectedItem) { newItem in
            Task {
                if let newItem = newItem {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        self.image = uiImage
                        performTextRecognition(on: uiImage) // Existing OCR functionality
                        recognizeFood(in: uiImage) // New food recognition functionality
                    }
                }
            }
        }
    }

    func recognizeFood(in image: UIImage) {
        guard let model = try? VNCoreMLModel(for: Food().model) else {
            print("Failed to load model")
            return
        }

        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                      print("No results: \(error?.localizedDescription ?? "Unknown error")")
                      return
                  }

            DispatchQueue.main.async {
                let label = topResult.identifier
                // Translate the label from the dictionary
                let translatedLabel =  TranslationDictionary.foodNames[label] ?? "未知"
                // Update UI with the translated label
                updateUIWithFoodRecognitionResult(result: translatedLabel)
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

    // Helper function to update UI
    func updateUIWithFoodRecognitionResult(result: String) {
        // Update your UI elements, maybe using published properties or calling another method that handles UI updates
        recognizedText = result  // This assumes `recognizedText` is accessible and updated correctly
    }

    //     使用 Vision 進行文字識別 (OCR)
    func performTextRecognition(on image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            recognizedText = "無法處理圖片"
            return
        }

        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                recognizedText = "文字識別錯誤: \(error.localizedDescription)"
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                recognizedText = "無法識別文字"
                return
            }

            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            DispatchQueue.main.async {
                self.recognizedText = recognizedStrings.joined(separator: "\n")
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

    // 請求語音識別授權
    func requestSpeechRecognitionAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.isAuthorized = true
                case .denied, .restricted, .notDetermined:
                    self.isAuthorized = false
                @unknown default:
                    fatalError("未處理的授權狀態")
                }
            }
        }
    }

    // 開始錄音
    func startRecording() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode

        // 确保输入节点的格式是有效的
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // 验证采样率和声道数是否正确
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            print("無效的音頻格式: \(recordingFormat)")
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!, resultHandler: { result, error in
            if let result = result {
                self.recognizedText = result.bestTranscription.formattedString
            }
            if error != nil || result?.isFinal == true {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isRecording = false
            }
        })

        // 安装音频 Tap，将输入节点的音频流传递到请求
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Couldn't start recording")
        }
    }
    // 停止錄音
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
    }
}
