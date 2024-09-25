import SwiftUI
import PhotosUI
import Vision
import CoreML
import IQKeyboardManagerSwift

struct Message: Identifiable {
    var id: UUID = UUID()
    let role: ChatGPTRole
    let content: String?
    let image: UIImage?
}

// 聊天角色枚举
enum ChatGPTRole: String {
    case system
    case user
    case assistant
}

struct PlaceholderTextEditor: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        ZStack(alignment: .leading) {
            TextEditor(text: $text)
                .padding(8)
                .frame(minHeight: 44)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 3)

            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)  // Allows touches to pass through to TextEditor
            }
        }
    }
}


struct ChatView: View {
    @State private var api = ChatGPTAPI(
        apiKey: "sk-8VrzLltl-TexufDVK8RWN-GVvWLusdkCjGi9lKNSSkT3BlbkFJMryR2KSLUPFRKb5VCzGPXJGI8s-8bUt9URrmdfq0gA",
        systemPrompt: """
        你是一個專業的廚師助手，能夠根據用戶提供的食材、圖片和描述，提供詳細的食譜和烹飪步驟。請用繁體中文回答，並盡可能提供完整的食譜，包括材料、步驟和提示。請按照以下格式回覆：
        
        📝 食譜名稱
        
        🥬【食材】
        • 食材1
        • 食材2
        • ...
        
        🍳【烹飪步驟】
        1. 步驟一
        2. 步驟二
        3. ...
        
        👩🏻‍🍳【貼心提醒】
        ...Bon appetit 🍽️
        """
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
                .frame(width: 300, height: 0)
                .padding(.top, 30)
            
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
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                    .onTapGesture {
                        self.showChangePhotoDialog = true
                    }
                    .confirmationDialog("想換張照片嗎？", isPresented: $showChangePhotoDialog, titleVisibility: .visible) {
                        Button("換一張") {
                            showPhotoOptions = true
                        }
                        Button("移除照片", role: .destructive) {
                            self.image = nil
                        }
                        Button("取消", role: .cancel) {}
                    }
            }
            HStack {
                Button(action: { showPhotoOptions = true }) {
                    Image(systemName: "camera.fill")
                        .resizable()
                        .scaledToFit() // Ensure the image scales properly within the frame
                        .frame(width: 40, height: 40)
                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                }
                .padding(.leading, 10)
                .fixedSize() // Prevent the button from being compressed
                .confirmationDialog("選擇你的相片來源", isPresented: $showPhotoOptions, titleVisibility: .visible) {
                    Button("相機") { photoSource = .camera }
                    Button("相冊") { photoSource = .photoLibrary }
                }
                
                Spacer(minLength: 20) // Ensures space distribution
                
                PlaceholderTextEditor(text: $inputText, placeholder: "今天想來點 🥙🍍 ...")
                    .frame(height: 44) // Consistent height with buttons
                
                Spacer(minLength: 20) // Ensures space distribution
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35, height: 35)
                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                }
                .padding(.trailing, 10)
                .fixedSize() // Prevent the button from being compressed
            }
            .padding(.horizontal)
        }
        .fullScreenCover(item: $photoSource) { source in
            ImagePicker(image: $image, sourceType: source == .photoLibrary ? .photoLibrary : .camera)
                .ignoresSafeArea()
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
        // 检查输入文本和图片是否为空
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || image != nil else { return }
        
        let messageText = inputText
        let messageImage = image
        
        // 清空输入框和图像
        inputText = ""
        image = nil
        
        // 将用户的消息添加到本地显示
        if let messageImage = messageImage {
            // 将照片作为一条消息添加到聊天记录中
            let imageMessage = Message(role: .user, content: nil, image: messageImage)
            self.messages.append(imageMessage)
        }
        
        if !messageText.isEmpty {
            let userMessage = Message(role: .user, content: messageText, image: nil)
            self.messages.append(userMessage)
        }
        
        Task {
            do {
                var finalMessageText = messageText
                
                if let messageImage = messageImage {
                    // 进行食材识别
                    recognizeFood(in: messageImage) { recognizedText in
                        DispatchQueue.main.async {
                            // 将识别结果添加到消息文本
                            if !finalMessageText.isEmpty {
                                finalMessageText += "\n識別的食材：\(recognizedText)。請提供詳細的食譜和烹飪步驟。"
                            } else {
                                finalMessageText = "識別的食材：\(recognizedText)。請提供詳細的食譜和烹飪步驟。"
                            }
                            
                            // 更新用户消息
                            if !finalMessageText.isEmpty {
                                let updatedUserMessage = Message(role: .user, content: finalMessageText, image: nil)
                                self.messages.append(updatedUserMessage)
                            }
                            
                            // 发送消息给 API
                            Task {
                                do {
                                    let responseText = try await api.sendMessage(finalMessageText)
                                    let responseMessage = Message(role: .assistant, content: responseText, image: nil)
                                    self.messages.append(responseMessage)
                                    self.errorMessage = nil
                                } catch {
                                    print("发送消息时出错：\(error)")
                                    self.errorMessage = "发送消息时出错：\(error.localizedDescription)"
                                }
                            }
                        }
                    }
                } else {
                    // 没有图片，直接发送消息
                    if !finalMessageText.isEmpty {
                        let responseText = try await api.sendMessage(finalMessageText)
                        let responseMessage = Message(role: .assistant, content: responseText, image: nil)
                        DispatchQueue.main.async {
                            self.messages.append(responseMessage)
                            self.errorMessage = nil
                        }
                    }
                }
            } catch {
                print("发送消息时出错：\(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "发送消息时出错：\(error.localizedDescription)"
                }
            }
        }
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

//import SwiftUI
//import PhotosUI
//import Vision
//import CoreML
//
//struct Message: Identifiable {
//    var id: UUID = UUID()
//    let role: ChatGPTRole
//    let content: String?
//    let image: UIImage?
//}
//
//// 聊天角色枚举
//enum ChatGPTRole: String {
//    case system
//    case user
//    case assistant
//}
//
//struct ChatView: View {
//    @State private var api = ChatGPTAPI(
//        apiKey: "sk-8VrzLltl-TexufDVK8RWN-GVvWLusdkCjGi9lKNSSkT3BlbkFJMryR2KSLUPFRKb5VCzGPXJGI8s-8bUt9URrmdfq0gA",
//        systemPrompt: """
//        你是一個專業的廚師助手，能夠根據用戶提供的食材、圖片和描述，提供詳細的食譜和烹飪步驟。請用繁體中文回答，並盡可能提供完整的食譜，包括材料、步驟和提示。請按照以下格式回覆：
//
//        📝 食譜名稱
//
//        🥬【食材】
//        - 食材1
//        - 食材2
//        - ...
//
//        🍳【烹飪步驟】
//        1. 步驟一
//        2. 步驟二
//        3. ...
//
//        ⚠️【貼心提醒】
//
//        FridgeChef 祝您 Bon appetit 🍽️
//        """
//    )
//    @State private var inputText = ""
//    @State private var messages: [Message] = []
//    @State private var showPhotoOptions = false
//    @State private var photoSource: PhotoSource?
//    @State private var image: UIImage?
//    @State private var showChangePhotoDialog = false
//    @State private var errorMessage: String?
//
//    enum PhotoSource: Identifiable {
//        case photoLibrary
//        case camera
//        var id: Int { self.hashValue }
//    }
//
//    var body: some View {
//        VStack {
//            if let errorMessage = errorMessage {
//                Text(errorMessage)
//                    .foregroundColor(.red)
//                    .padding()
//            }
//
//            Image("LogoFridgeChef")
//                .resizable()
//                .scaledToFill()
//                .frame(width: 300, height: 80)
//                .padding(.top, 20)
//
//            ScrollView {
//                VStack(alignment: .leading, spacing: 10) {
//                    ForEach(messages) { message in
//                        messageView(for: message)
//                    }
//                }
//            }
//
//            if let image = image {
//                Image(uiImage: image)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(height: 100)
//                    .cornerRadius(15)
//                    .shadow(radius: 3)
//                    .padding(.horizontal, 10)
//                    .padding(.vertical, 5)
//                    .onTapGesture {
//                                self.showChangePhotoDialog = true
//                            }
//                            .confirmationDialog("想換張照片嗎？", isPresented: $showChangePhotoDialog, titleVisibility: .visible) {
//                                Button("換一張") {
//                                    showPhotoOptions = true
//                                }
//                                Button("移除照片", role: .destructive) {
//                                    self.image = nil
//                                }
//                                Button("取消", role: .cancel) {}
//                            }
//            }
//            HStack {
//                Button(action: { showPhotoOptions = true }) {
//                    Image(systemName: "camera.fill")
//                        .resizable()
//                        .frame(width: 30, height: 30) // Set a specific size
//                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                }
//                .padding(.leading)
//
//                .confirmationDialog("選擇你的相片來源", isPresented: $showPhotoOptions, titleVisibility: .visible) {
//                    Button("相機") { photoSource = .camera }
//                    Button("相冊") { photoSource = .photoLibrary }
//                }
//
//                Spacer()
//
//                TextField("今天想來點 🥙🍍 ...", text: $inputText)
//                    .padding(.horizontal)
//                    .padding(5)
//                    .background(Color.white)
//                    .cornerRadius(10)
//                    .shadow(radius: 3)
//                    .padding(.bottom, 30)
//
//                Spacer()
//
//                Button(action: sendMessage) {
//                    Image(systemName: "paperplane.fill")
//                        .resizable()
//                        .frame(width: 30, height: 30) // Match the size to the camera button
//                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                }
//                .padding(.trailing)
//            }
//            .padding(.horizontal)
//        }
//        .fullScreenCover(item: $photoSource) { source in
//            ImagePicker(image: $image, sourceType: source == .photoLibrary ? .photoLibrary : .camera)
//                .ignoresSafeArea()
//        }
//    }
//
//    func recognizeFood(in image: UIImage, completion: @escaping (String) -> Void) {
//        // 请确保您在项目中包含了 Food.mlmodel 和 TranslationDictionary
//        guard let model = try? VNCoreMLModel(for: Food().model) else {
//            print("Failed to load model")
//            completion("未知食材")
//            return
//        }
//
//        let request = VNCoreMLRequest(model: model) { request, error in
//            guard let results = request.results as? [VNClassificationObservation],
//                  let topResult = results.first else {
//                print("No results: \(error?.localizedDescription ?? "Unknown error")")
//                completion("未知食材")
//                return
//            }
//
//            DispatchQueue.main.async {
//                let label = topResult.identifier
//                // 使用您的翻译字典
//                let translatedLabel = TranslationDictionary.foodNames[label] ?? "未知食材"
//                completion(translatedLabel)
//            }
//        }
//
//        guard let ciImage = CIImage(image: image) else {
//            print("Unable to create \(CIImage.self) from \(image).")
//            completion("未知食材")
//            return
//        }
//
//        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                try handler.perform([request])
//            } catch {
//                print("Failed to perform classification.\n\(error.localizedDescription)")
//                completion("未知食材")
//            }
//        }
//    }
//
//    private func messageView(for message: Message) -> some View {
//        HStack {
//            if message.role == .user {
//                Spacer()
//                VStack(alignment: .trailing) {
//                    if let image = message.image {
//                        Image(uiImage: image)
//                            .resizable()
//                            .scaledToFit()
//                            .frame(height: 150)
//                            .cornerRadius(10)
//                    }
//                    if let content = message.content {
//                        Text(content)
//                            .padding()
//                            .background(Color.customColor(named: "NavigationBarTitle"))
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                    }
//                }
//            } else {
//                VStack(alignment: .leading) {
//                    if let content = message.content {
//                        Text(content)
//                            .padding()
//                            .background(Color.gray.opacity(0.2))
//                            .cornerRadius(10)
//                    }
//                }
//                Spacer()
//            }
//        }
//        .padding(.horizontal)
//    }
//
//    func sendMessage() {
//        // 检查输入文本和图片是否为空
//        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || image != nil else { return }
//
//        let messageText = inputText
//        let messageImage = image
//
//        // 清空输入框和图像
//        inputText = ""
//        image = nil
//
//        // 将用户的消息添加到本地显示
//        if let messageImage = messageImage {
//            // 将照片作为一条消息添加到聊天记录中
//            let imageMessage = Message(role: .user, content: nil, image: messageImage)
//            self.messages.append(imageMessage)
//        }
//
//        if !messageText.isEmpty {
//            let userMessage = Message(role: .user, content: messageText, image: nil)
//            self.messages.append(userMessage)
//        }
//
//        Task {
//            do {
//                var finalMessageText = messageText
//
//                if let messageImage = messageImage {
//                    // 进行食材识别
//                    recognizeFood(in: messageImage) { recognizedText in
//                        DispatchQueue.main.async {
//                            // 将识别结果添加到消息文本
//                            if !finalMessageText.isEmpty {
//                                finalMessageText += "\n識別的食材：\(recognizedText)。請提供詳細的食譜和烹飪步驟。"
//                            } else {
//                                finalMessageText = "識別的食材：\(recognizedText)。請提供詳細的食譜和烹飪步驟。"
//                            }
//
//                            // 更新用户消息
//                            if !finalMessageText.isEmpty {
//                                let updatedUserMessage = Message(role: .user, content: finalMessageText, image: nil)
//                                self.messages.append(updatedUserMessage)
//                            }
//
//                            // 发送消息给 API
//                            Task {
//                                do {
//                                    let responseText = try await api.sendMessage(finalMessageText)
//                                    let responseMessage = Message(role: .assistant, content: responseText, image: nil)
//                                    self.messages.append(responseMessage)
//                                    self.errorMessage = nil
//                                } catch {
//                                    print("发送消息时出错：\(error)")
//                                    self.errorMessage = "发送消息时出错：\(error.localizedDescription)"
//                                }
//                            }
//                        }
//                    }
//                } else {
//                    // 没有图片，直接发送消息
//                    if !finalMessageText.isEmpty {
//                        let responseText = try await api.sendMessage(finalMessageText)
//                        let responseMessage = Message(role: .assistant, content: responseText, image: nil)
//                        DispatchQueue.main.async {
//                            self.messages.append(responseMessage)
//                            self.errorMessage = nil
//                        }
//                    }
//                }
//            } catch {
//                print("发送消息时出错：\(error)")
//                DispatchQueue.main.async {
//                    self.errorMessage = "发送消息时出错：\(error.localizedDescription)"
//                }
//            }
//        }
//    }
//}
//
//extension Color {
//    static func customColor(named name: String) -> Color {
//        return Color(UIColor(named: name) ?? .systemRed)
//    }
//}
//
//struct ChatView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatView()
//    }
//}