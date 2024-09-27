//
//  MLIngredientView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//

//MARK: GOOD!
import SwiftUI
import Vision
import CoreML
import PhotosUI
import Speech
import IQKeyboardManagerSwift

struct MLIngredientView: View {
    var onSave: ((Ingredient) -> Void)? = nil
    var editingFoodItem: Ingredient?
    @Environment(\.dismiss) var dismiss
    @State private var image: UIImage?
    @State private var recognizedText: String = ""
    @State private var quantity: String = "1"
    @State private var expirationDate: Date = Date()

    @State private var isAuthorized = false
    @State private var isRecording = false

    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-Hant"))
    private let audioEngine = AVAudioEngine()

    @State private var storageMethod = "冷藏"
    let storageOptions = ["冷凍", "冷藏", "室溫"]

    @State private var showPhotoOptions = false
    @State private var photoSource: PhotoSource?

    @State private var isSavedAlertPresented = false
    @State private var savedIngredients: [Ingredient] = []

    init(onSave: ((Ingredient) -> Void)? = nil, editingFoodItem: Ingredient? = nil) {
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.white // 改變選中的顏色
        UISegmentedControl.appearance().backgroundColor = UIColor.orange
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.orange], for: .selected) // 選中項目文字為白色
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)

        self.onSave = onSave
        self.editingFoodItem = editingFoodItem

        if let item = editingFoodItem {
            // 如果有傳入要編輯的食材，初始化相關值
            _recognizedText = State(initialValue: item.name)
            _quantity = State(initialValue: item.quantity)
            _expirationDate = State(initialValue: item.expirationDate)
            _storageMethod = State(initialValue: item.storageMethod)
            _image = State(initialValue: item.image)
        }
    }

    enum PhotoSource: Identifiable {
        case photoLibrary
        case camera

        var id: Int { self.hashValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    // 圖片顯示區域（點擊後選擇相機或照片庫）
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 20.0))
                            .padding(.bottom)
                            .onTapGesture {
                                showPhotoOptions = true
                            }
                    } else {
                        Image("newphoto")  // Provide a placeholder
                            .resizable()
                            .scaledToFit()  // 保持比例並完整顯示圖片
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 20.0))
                            .padding(.bottom)
                            .onTapGesture {
                                showPhotoOptions = true
                            }
                    }

                    // Picker 使用全局樣式
                    Picker("選擇存儲方式", selection: $storageMethod) {
                        ForEach(storageOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .cornerRadius(8)

                    // 名稱、數量、到期日與各自的 TextField 排列為 HStack
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("名稱")
                                .font(.headline)

                            HStack {
                                TextField("辨識結果", text: $recognizedText)
                                    .padding()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                    )
                                    .overlay(
                                        // 麥克風按鈕放在右邊
                                        Button(action: {
                                            if isRecording {
                                                stopRecording()
                                                isRecording = false
                                            } else {
                                                startRecording()
                                                isRecording = true
                                            }
                                        }) {
                                            Image(systemName: isRecording ? "mic.fill" : "mic")
                                                .font(.title2)
                                                .foregroundColor(isRecording ? .red : .orange)
                                                .padding(.trailing, 10)  // 確保按鈕位於TextField的內部邊緣
                                        }
                                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing) // 將按鈕對齊到TextField的右側
                                    )
                                    .padding(.horizontal)

                            }
                        }

                        HStack {
                            Text("數量    ")
                                .font(.headline)

                            TextField("請輸入數量", text: $quantity)
                                .padding()
                                .frame(width: 255, alignment: .center)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                                .keyboardType(.numberPad)

                        }

                        HStack {
                            Text("到期日")
                                .font(.headline)

                            DatePickerTextField(date: $expirationDate, label: "")
                                .environment(\.locale, Locale(identifier: "zh-Hant"))
                        }
                    }
                    .padding(.horizontal)

                    // 儲存按鈕
                    Button(action: saveIngredient) {
                        Text("儲存")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)

                    }
                    .padding()
                    .alert(isPresented: $isSavedAlertPresented) {
                        Alert(title: Text("成功"), message: Text("食材已儲存"), dismissButton: .default(Text("確定")))
                    }
                }
                .padding()
                .confirmationDialog("選擇你的相片來源", isPresented: $showPhotoOptions, titleVisibility: .visible) {
                    Button("相機") { photoSource = .camera }
                    Button("相冊") { photoSource = .photoLibrary }
                }
                .fullScreenCover(item: $photoSource) { source in
                    switch source {
                    case .photoLibrary:
                        ImagePicker(image: $image, sourceType: .photoLibrary)
                            .ignoresSafeArea()
                            .onDisappear {
                                if let image = image {
                                    recognizeFood(in: image)
//                                    performTextRecognition(on: image)
                                }
                            }
                    case .camera:
                        ImagePicker(image: $image, sourceType: .camera)
                            .ignoresSafeArea()
                            .onDisappear {
                                if let image = image {
                                    recognizeFood(in: image)
//                                    performTextRecognition(on: image)
                                }
                            }
                    }
                }
                .onAppear {
                    requestSpeechRecognitionAuthorization()
                }
            }
            .navigationTitle("Add Ingredient")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.orange)
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
        recognizedText = result
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

    // 儲存食材資料的函數
    func saveIngredient() {
        let defaultAmount = 1.0  // 一个示例值
        let defaultUnit = "個"    // 一个示例单位

        // 创建 Ingredient 实例
        var newIngredient = Ingredient(
            name: recognizedText,
            quantity: quantity,
            amount: defaultAmount,
            unit: defaultUnit,
            expirationDate: expirationDate,
            storageMethod: storageMethod,
            imageBase64: image?.pngData()?.base64EncodedString()  
        )
        savedIngredients.append(newIngredient)
        isSavedAlertPresented = true
        onSave?(newIngredient)
        clearForm()
        dismiss()
    }
    // 清空表單欄位
      func clearForm() {
          recognizedText = ""
          quantity = "1"
          expirationDate = Date()
          image = nil
          storageMethod = ""
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

        let recordingFormat = inputNode.outputFormat(forBus: 0)

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

#Preview {
    MLIngredientView()
}

//MARK: TODO這其實整理的很好只是功能好像有問題，可以未來用這個Textfiled架構去整理
//import SwiftUI
//import Vision
//import CoreML
//import PhotosUI
//import Speech
//
//struct MLIngredientView: View {
//    @Environment(\.dismiss) var dismiss
//    @State private var image: UIImage?
//    @State private var recognizedText: String = ""
//    @State private var quantity: String = "1"
//    @State private var expirationDate: Date = Date()
//    @State private var showDatePicker: Bool = false
//
//    @State private var isAuthorized = false
//    @State private var isRecording = false
//
//    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
//    @State private var recognitionTask: SFSpeechRecognitionTask?
//
//    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-Hant"))
//    private let audioEngine = AVAudioEngine()
//
//    @State private var storageMethod = "冷藏"
//    let storageOptions = ["冷凍", "冷藏", "室溫"]
//
//    @State private var showPhotoOptions = false
//    @State private var photoSource: PhotoSource?
//
//    @State private var isSavedAlertPresented = false
//
//    // 定義結構來保存食材資料
//    struct Ingredient: Identifiable {
//        let id = UUID()
//        var name: String
//        var quantity: String
//        var expirationDate: Date
//        var storageMethod: String
//        var image: UIImage?
//    }
//
//    // 儲存已保存的食材資料
//    @State private var savedIngredients: [Ingredient] = []
//
//    init() {
//        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.white // 改變選中的顏色
//        UISegmentedControl.appearance().backgroundColor = UIColor.orange
//        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.orange], for: .selected)
//        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
//    }
//
//    enum PhotoSource: Identifiable {
//        case photoLibrary
//        case camera
//
//        var id: Int { self.hashValue }
//    }
//
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                VStack(spacing: 20) {
//                    // 圖片顯示區域
//                    Group {
//                        if let image = image {
//                            Image(uiImage: image)
//                                .resizable()
//                                .scaledToFit()
//                                .frame(minWidth: 0, maxWidth: .infinity)
//                                .frame(height: 200)
//                                .background(Color(.systemGray5))
//                                .clipShape(RoundedRectangle(cornerRadius: 20.0))
//                                .padding(.bottom)
//                        } else {
//                            Image("newphoto")  // Provide a placeholder
//                                .resizable()
//                                .scaledToFit()
//                                .frame(minWidth: 0, maxWidth: .infinity)
//                                .frame(height: 200)
//                                .background(Color(.systemGray5))
//                                .clipShape(RoundedRectangle(cornerRadius: 20.0))
//                                .padding(.bottom)
//                        }
//                    }
//                    .onTapGesture {
//                        showPhotoOptions = true
//                    }
//                    .padding(.horizontal)
//                    .confirmationDialog("選擇你的相片來源", isPresented: $showPhotoOptions, titleVisibility: .visible) {
//                        Button("相機") { photoSource = .camera }
//                        Button("您的相冊") { photoSource = .photoLibrary }
//                    }
//                    .fullScreenCover(item: $photoSource) { source in
//                        switch source {
//                        case .photoLibrary:
//                            ImagePicker(image: $image, sourceType: .photoLibrary)
//                                .ignoresSafeArea()
//                        case .camera:
//                            ImagePicker(image: $image, sourceType: .camera)
//                                .ignoresSafeArea()
//                        }
//                    }
//                    Picker("選擇存儲方式", selection: $storageMethod) {
//                        ForEach(storageOptions, id: \.self) { option in
//                            Text(option)
//                        }
//                    }
//                    .pickerStyle(SegmentedPickerStyle())
//                    .padding(.horizontal)
//
//                    // 將 TextField 進一步抽象化
//                    InputFieldWithMic(label: "名稱", text: $recognizedText)
//                    InputField(label: "數量", text: $quantity, keyboardType: .numberPad)
//
//                    DatePickerField(label: "到期日", date: $expirationDate, showDatePicker: $showDatePicker)
//                        .onTapGesture {
//                            self.showDatePicker = true
//                        }
//
//                    // 儲存按鈕
//                    Button(action: saveIngredient) {
//                        Text("儲存")
//                            .font(.headline)
//                            .padding()
//                            .frame(maxWidth: .infinity)
//                            .background(Color.orange)
//                            .foregroundColor(.white)
//                            .cornerRadius(8)
//                    }
//                    .padding()
//                    .alert(isPresented: $isSavedAlertPresented) {
//                        Alert(title: Text("成功"), message: Text("食材已儲存"), dismissButton: .default(Text("確定")))
//                    }
//
//                    // 顯示已儲存的食材列表
//                    if !savedIngredients.isEmpty {
//                        VStack(alignment: .leading) {
//                            Text("已儲存的食材")
//                                .font(.headline)
//                                .padding(.bottom, 5)
//
//                            ForEach(savedIngredients) { ingredient in
//                                VStack(alignment: .leading) {
//                                    Text("名稱: \(ingredient.name)")
//                                    Text("數量: \(ingredient.quantity)")
//                                    Text("保存方式: \(ingredient.storageMethod)")
//                                    Text("到期日: \(ingredient.expirationDate, formatter: DateFormatter.shortDate)")
//                                }
//                                .padding(.vertical, 10)
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .background(Color(.systemGray6))
//                                .cornerRadius(10)
//                                .padding(.bottom, 5)
//                            }
//                        }
//                        .padding(.horizontal)
//                    }
//                }
//                .padding()
//                .confirmationDialog("選擇你的相片來源", isPresented: $showPhotoOptions, titleVisibility: .visible) {
//                    Button("相機") { photoSource = .camera }
//                    Button("您的相冊") { photoSource = .photoLibrary }
//                }
//                .fullScreenCover(item: $photoSource) { source in
//                    switch source {
//                    case .photoLibrary:
//                        ImagePicker(image: $image, sourceType: .photoLibrary)
//                            .ignoresSafeArea()
//                            .onDisappear {
//                                if let image = image {
//                                    recognizeFood(in: image)
//                                    performTextRecognition(on: image)
//                                }
//                            }
//                    case .camera:
//                        ImagePicker(image: $image, sourceType: .camera)
//                            .ignoresSafeArea()
//                            .onDisappear {
//                                if let image = image {
//                                    recognizeFood(in: image)
//
//                                }
//                            }
//                    }
//                }
//
//                .onAppear {
//                    requestSpeechRecognitionAuthorization()
//                }
//            }
//            .navigationTitle("Add Ingredient")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: { dismiss() }) {
//                        Image(systemName: "xmark.circle.fill")
//                            .foregroundColor(.orange)
//                    }
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
//                print("Recognition failed with error: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
//            DispatchQueue.main.async {
//                self.recognizedText = topResult.identifier  // Assuming 'identifier' is what you want to display
//                print("Recognized Text Updated: \(self.recognizedText)")
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
//        recognizedText = result
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
//                recognizedText = "文字識別錯誤: \(error.localizedDescription)"
//                return
//            }
//
//            guard let observations = request.results as? [VNRecognizedTextObservation] else {
//                recognizedText = "無法識別文字"
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
//
//
//    // 儲存食材資料的函數
//    func saveIngredient() {
//        let newIngredient = Ingredient(
//            name: recognizedText,
//            quantity: quantity,
//            expirationDate: expirationDate,
//            storageMethod: storageMethod,
//            image: image
//        )
//        savedIngredients.append(newIngredient)
//        isSavedAlertPresented = true
//    }
//
//    // 請求語音識別授權
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
//    // 開始錄音
//    func startRecording() {
//        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
//        let inputNode = audioEngine.inputNode
//
//        let recordingFormat = inputNode.outputFormat(forBus: 0)
//
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
//
//    // 停止錄音
//    func stopRecording() {
//        audioEngine.stop()
//        recognitionRequest?.endAudio()
//        isRecording = false
//    }
//    struct InputFieldWithMic: View {
//        let label: String
//        @Binding var text: String
//        @State private var isRecording = false
//
//        var body: some View {
//            HStack {
//                Text(label)
//                    .font(.headline)
//                TextField("請輸入\(label.lowercased())", text: $text)
//                    .padding()
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 8)
//                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
//                    )
//                    .overlay(
//                        Button(action: {
//                            isRecording.toggle()
//                        }) {
//                            Image(systemName: isRecording ? "mic.fill" : "mic")
//                                .foregroundColor(isRecording ? .red : .orange)
//                        }
//                            .padding(.trailing, 10),
//                        alignment: .trailing
//                    )
//            }
//            .padding(.horizontal)
//        }
//    }
//
//    struct InputField: View {
//        let label: String
//        @Binding var text: String
//        var keyboardType: UIKeyboardType
//
//        var body: some View {
//            HStack {
//                Text(label)
//                    .font(.headline)
//                TextField("請輸入\(label.lowercased())", text: $text)
//                    .keyboardType(keyboardType)
//                    .padding()
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 8)
//                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
//                    )
//            }
//            .padding(.horizontal)
//        }
//    }
//}
//    struct DatePickerField: View {
//        let label: String
//        @Binding var date: Date
//        @Binding var showDatePicker: Bool
//
//        var body: some View {
//            HStack {
//                Text(label)
//                    .font(.headline)
//                TextField("選擇\(label.lowercased())", text: Binding(get: { DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none) }, set: { _ in }))
//                    .disabled(true)
//                    .padding()
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 8)
//                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
//                    )
//                    .overlay(
//                        Button(action: {
//                            self.showDatePicker = true
//                        }) {
//                            Image(systemName: "calendar.badge.plus")
//                                .foregroundColor(.orange)
//                        }
//                            .padding(.trailing, 10),
//                        alignment: .trailing
//                    )
//            }
//            .padding(.horizontal)
//            .sheet(isPresented: $showDatePicker) {
//                DatePicker("選擇\(label.lowercased())", selection: $date, displayedComponents: .date)
//                    .datePickerStyle(GraphicalDatePickerStyle())
//                    .padding()
//                    .background(Color.white)
//            }
//        }
//    }
//
//
//extension DateFormatter {
//    static var shortDate: DateFormatter {
//        let formatter = DateFormatter()
//        formatter.dateStyle = .short
//        return formatter
//    }
//}
//
//#Preview {
//    MLIngredientView()
//}

//MARK:MVVM架構可以使用
//import SwiftUI
//
//struct MLIngredientView: View {
//    @StateObject var viewModel: MLIngredientViewModel
//    @Environment(\.dismiss) var dismiss
//
//    @State private var showPhotoOptions = false
//    @State private var photoSource: MLIngredientView.PhotoSource?
//
//    enum PhotoSource: Identifiable {
//        case photoLibrary
//        case camera
//
//        var id: Int { self.hashValue }
//    }
//
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                VStack(spacing: 10) {
//                    // 圖片選擇器
//                    ImageSelectorView(image: $viewModel.image)
//                        .onChange(of: viewModel.image) { newImage in
//                            if let newImage = newImage {
//                                viewModel.recognitionService.performTextRecognition(on: newImage) { result in
//                                    print("Recognized text: \(result)")
//                                }
//                                viewModel.recognitionService.recognizeFood(in: newImage) { foodResult in
//                                    print("Recognized food: \(foodResult)")
//                                }
//                            }
//                        }
//
//                    // 存儲方式選擇器
//                    Picker("選擇存儲方式", selection: $viewModel.storageMethod) {
//                        ForEach(viewModel.storageOptions, id: \.self) { option in
//                            Text(option)
//                        }
//                    }
//                    .pickerStyle(SegmentedPickerStyle())
//                    .padding()
//
//                    // 名稱、數量、到期日等輸入欄位
//                    VStack(alignment: .leading, spacing: 20) {
//                        HStack {
//                            Text("名稱")
//                                .font(.headline)
//
//                            TextField("辨識結果", text: $viewModel.recognitionService.recognizedText)
//                                .padding()
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 8)
//                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
//                                )
//                                .padding(.horizontal)
//
//                            // 使用封裝的 MicButtonView
//                            MicButtonView(recognitionService: viewModel.recognitionService)
//                                .padding(.trailing, 10)
//                        }
//
//                        HStack {
//                            Text("數量")
//                                .font(.headline)
//
//                            TextField("請輸入數量", text: $viewModel.quantity)
//                                .padding()
//                                .frame(width: 255)
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 8)
//                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
//                                )
//                                .keyboardType(.numberPad)
//                        }
//
//                        HStack {
//                            Text("到期日")
//                                .font(.headline)
//
//                            DatePickerTextField(date: $viewModel.expirationDate, label: "")
//                                .environment(\.locale, Locale(identifier: "zh-Hant"))
//                        }
//                    }
//                    .padding(.horizontal)
//
//                    // 儲存按鈕
//                    Button(action: {
//                        viewModel.saveIngredient()
//                    }) {
//                        Text("儲存")
//                            .font(.headline)
//                            .padding()
//                            .frame(maxWidth: .infinity)
//                            .background(Color.orange)
//                            .foregroundColor(.white)
//                            .cornerRadius(8)
//                    }
//                    .padding()
//                    .alert(isPresented: $viewModel.isSavedAlertPresented) {
//                        Alert(title: Text("成功"), message: Text("食材已儲存"), dismissButton: .default(Text("確定")))
//                    }
//                }
//                .padding()
//                .onAppear {
//                    viewModel.requestSpeechRecognitionAuthorization()
//                }
//            }
//            .navigationTitle("Add Ingredient")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: { dismiss() }) {
//                        Image(systemName: "xmark.circle.fill")
//                            .foregroundColor(.orange)
//                    }
//                }
//            }
//        }
//    }
//}

