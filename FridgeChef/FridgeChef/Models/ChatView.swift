//
//  ChatView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/22.
//

import SwiftUI
import PhotosUI
import Vision
import CoreML

struct ChatView: View {
    @State private var api = ChatGPTAPI(
        apiKey: "sk-8VrzLltl-TexufDVK8RWN-GVvWLusdkCjGi9lKNSSkT3BlbkFJMryR2KSLUPFRKb5VCzGPXJGI8s-8bUt9URrmdfq0gA", // 请替换为您的 API 密钥
        systemPrompt: "你是一個專業的廚師助手，能夠根據用戶提供的食材、圖片和描述，提供詳細的食譜和烹飪步驟。請用繁體中文回答，並盡可能提供完整的食譜，包括材料、步驟和提示。"
    )
    @State private var inputText = ""
    @State private var messages: [Message] = []
    @State private var showPhotoOptions = false
    @State private var photoSource: PhotoSource?
    @State private var image: UIImage?
    @State private var showChangePhotoDialog = false
    @State private var errorMessage: String?
    
    enum PhotoSource: Identifiable {
        case photoLibrary
        case camera
        var id: Int { self.hashValue }
    }
    
    var body: some View {
        VStack {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Image("LogoFridgeChef")
                .resizable()
                .scaledToFill()
                .frame(width: 300, height: 80)
                .padding(.top, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(messages) { message in
                        messageView(for: message)
                    }
                }
            }
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .cornerRadius(15)
                    .shadow(radius: 3)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
            }
            
            HStack {
                Button(action: { showPhotoOptions = true }) {
                    Image(systemName: "camera.fill")
                        .font(.title)
                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                }
                .padding(.leading)
                .padding(.bottom , 30)
                .confirmationDialog("選擇你的相片來源", isPresented: $showPhotoOptions, titleVisibility: .visible) {
                    Button("相機") { photoSource = .camera }
                    Button("相冊") { photoSource = .photoLibrary }
                }
                
                TextField("今天想來點 🥙🍍 ...", text: $inputText)
                    .padding(.horizontal)
                    .padding(5)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 3)
                    .padding(.bottom , 30)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                }
                .padding(.trailing)
                .padding(.bottom , 30)
            }
            .padding(.horizontal, 10)
        }
        .fullScreenCover(item: $photoSource) { source in
            ImagePicker(image: $image, sourceType: source == .photoLibrary ? .photoLibrary : .camera)
                .ignoresSafeArea()
                .onDisappear {
                    if let image = image {
                        // 将照片作为一条消息添加到聊天记录中
                        let imageMessage = Message(role: .user, content: nil, image: image)
                        self.messages.append(imageMessage)
                        
                        // 识别食材并将结果添加到输入框
                        recognizeFood(in: image) { recognizedText in
                            inputText += "\n識別的食材：\(recognizedText)"
                        }
                    }
                }
        }
    }
    
    func recognizeFood(in image: UIImage, completion: @escaping (String) -> Void) {
        // 请确保您在项目中包含了 Food.mlmodel 和 TranslationDictionary
        guard let model = try? VNCoreMLModel(for: Food().model) else {
            print("Failed to load model")
            completion("未知食材")
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                print("No results: \(error?.localizedDescription ?? "Unknown error")")
                completion("未知食材")
                return
            }
            
            DispatchQueue.main.async {
                let label = topResult.identifier
                // 使用您的翻译字典
                let translatedLabel = TranslationDictionary.foodNames[label] ?? "未知食材"
                completion(translatedLabel)
            }
        }
        
        guard let ciImage = CIImage(image: image) else {
            print("Unable to create \(CIImage.self) from \(image).")
            completion("未知食材")
            return
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
                completion("未知食材")
            }
        }
    }
    
    private func messageView(for message: Message) -> some View {
        HStack {
            if message.role == .user {
                Spacer()
                VStack(alignment: .trailing) {
                    if let image = message.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .cornerRadius(10)
                    }
                    if let content = message.content {
                        Text(content)
                            .padding()
                            .background(Color.customColor(named: "NavigationBarTitle"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            } else {
                VStack(alignment: .leading) {
                    if let content = message.content {
                        Text(content)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal)
    }
    
    func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        let userMessage = Message(role: .user, content: inputText, image: image)
        self.messages.append(userMessage)
        
        Task {
            do {
                let responseText = try await api.sendMessage(inputText)
                let responseMessage = Message(role: .assistant, content: responseText, image: nil)
                self.messages.append(responseMessage)
                self.errorMessage = nil
            } catch {
                print("Error sending message: \(error)")
                self.errorMessage = "发送消息时出错：\(error.localizedDescription)"
            }
        }
        // 清空输入框和图像
        inputText = ""
        image = nil
    }
}

extension Color {
    static func customColor(named name: String) -> Color {
        return Color(UIColor(named: name) ?? .systemRed)
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}




//MARK: UI is good
//import SwiftUI
//import Foundation
//
//struct Message: Identifiable {
//    let id = UUID()
//    let content: String
//    let isFromUser: Bool
//    let imageData: Data?  // Optional, used if the message is a photo
//
//    init(content: String, isFromUser: Bool, imageData: Data? = nil) {
//        self.content = content
//        self.isFromUser = isFromUser
//        self.imageData = imageData
//    }
//}
//
//
//import SwiftUI
//import PhotosUI  // For photo library access
//
//struct ChatView: View {
//    @State private var api = ChatGPTAPI(apiKey: "sk-8VrzLltl-TexufDVK8RWN-GVvWLusdkCjGi9lKNSSkT3BlbkFJMryR2KSLUPFRKb5VCzGPXJGI8s-8bUt9URrmdfq0gA")
//    @State private var inputText = ""
//    @State private var messages: [Message] = []
//    @State private var showPhotoOptions = false
//    @State private var photoSource: PhotoSource?
//    @State private var image: UIImage?
//    @State private var showChangePhotoDialog = false
//
//    init(messages: [Message] = []) {
//        _messages = State(initialValue: messages)
//    }
//
//    enum PhotoSource: Identifiable {
//        case photoLibrary
//        case camera
//        var id: Int { self.hashValue }
//    }
//
//    var body: some View {
//        VStack {
//            Image("LogoFridgeChef")
//                .resizable()
//                .scaledToFill()
//                .frame(width: 300, height: 80)
//                .padding(.top, 20)
//
//            ScrollView {
//                VStack(alignment: .leading, spacing: 10) { // 可以在这里调整间距
//                    ForEach(messages) { message in
//                        messageView(for: message)
//                            .padding(.horizontal, 10) // 为每个消息添加水平边距
//                    }
//                }
//            }
//            .padding(.top, 10) // ScrollView 顶部的边距
//
//            // Image Preview Area with interactive options
//            if let image = image {
//                Button(action: {
//                    showChangePhotoDialog = true
//                }) {
//                    Image(uiImage: image)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(height: 100)
//                        .cornerRadius(15)
//                        .shadow(radius: 3)
//                        .padding(.horizontal, 10) // 图片的水平边距
//                        .padding(.vertical, 5)
//                }
//                .confirmationDialog("想換張照片嗎？", isPresented: $showChangePhotoDialog, titleVisibility: .visible) {
//                    Button("換一張") {
//                        showPhotoOptions = true
//                    }
//                    Button("移除照片", role: .destructive) {
//                        self.image = nil
//                    }
//                    Button("取消", role: .cancel) {}
//                }
//            }
//
//            HStack {
//                Button(action: { showPhotoOptions = true }) {
//                    Image(systemName: "camera.fill")
//                        .font(.title)
//                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                }
//                .padding(.leading)
//                .padding(.bottom , 30)
//                .confirmationDialog("選擇你的相片來源", isPresented: $showPhotoOptions, titleVisibility: .visible) {
//                    Button("相機") { photoSource = .camera }
//                    Button("相冊") { photoSource = .photoLibrary }
//                }
//
//                TextField("今天想來點 🥙🍍 ...", text: $inputText)
//                    .padding(.horizontal)
//                    .padding(5)
//                    .background(Color.white)  // 背景色
//                    .cornerRadius(10)  // 圆角
//                    .shadow(radius: 3)
//                    .padding(.bottom , 30)// 阴影
//
//                Button(action: sendMessage) {
//                    Image(systemName: "paperplane.fill")
//                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                }
//                .padding(.trailing)
//                .padding(.bottom , 30)
//            }
//            .padding(.horizontal, 10) // 底部输入区的水平边距
//        }
//            .fullScreenCover(item: $photoSource) { source in
//                ImagePicker(image: $image, sourceType: source == .photoLibrary ? .photoLibrary : .camera)
//                    .ignoresSafeArea()
//            }
//    }
//
//    private func messageView(for message: Message) -> some View {
//        HStack {
//            if message.isFromUser {
//                Spacer() // 把内容推到右边
//                VStack(alignment: .trailing) {
//                    if let imageData = message.imageData, let uiImage = UIImage(data: imageData) {
//                        Image(uiImage: uiImage)
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 200, height: 200)
//                            .cornerRadius(15)
//                            .clipped()
//                    } else {
//                        Text(message.content)
//                            .padding()
//                            .background(Color.customColor(named: "NavigationBarTitle"))
//                            .foregroundColor(.white) // 文本颜色
//                            .cornerRadius(10)
//                            .frame(minWidth: 100)
//                    }
//                }
//            } else {
//                VStack(alignment: .leading) {
//                    if let imageData = message.imageData, let uiImage = UIImage(data: imageData) {
//                        Image(uiImage: uiImage)
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 200, height: 200)
//                            .cornerRadius(15)
//                            .clipped()
//                    } else {
//                        Text(message.content)
//                            .padding() // 内边距
//                            .background(Color.gray.opacity(0.2))
//                            .cornerRadius(10)
//                            .frame(minWidth: 100)
//                    }
//                }
//                Spacer() // 把内容推到左边
//            }
//        }
//        .padding(.horizontal) // 水平边距
//    }
//
//    func sendMessage() {
//        if let image = image, let imageData = image.jpegData(compressionQuality: 0.5) {
//            let newMessage = Message(content: "📷 Photo", isFromUser: true, imageData: imageData)
//            messages.append(newMessage)
//            self.image = nil
//        }
//
//        if !inputText.isEmpty {
//            let newMessage = Message(content: inputText, isFromUser: true)
//            messages.append(newMessage)
//            sendMessageToChatGPT(message: inputText) { response in
//                let responseMessage = Message(content: response, isFromUser: false)
//                DispatchQueue.main.async {
//                    messages.append(responseMessage)
//                }
//            }
//            inputText = ""  // 清空输入框
//        }
//    }
//}
//
//extension Color {
//    static func customColor(named name: String) -> Color {
//        return Color(UIColor(named: name) ?? .systemRed) //
//    }
//}
//
//struct ChatView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatView(messages: [Message(content: "Hello, this is a test message.", isFromUser: false)])
//    }
//}
//
