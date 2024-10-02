//
//  AddGroceryForm.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//

import SwiftUI

struct AddGroceryForm: View {
    @ObservedObject var viewModel: AddGroceryFormViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showPhotoOptions = false
    @State private var photoSource: PhotoSource?
    @State private var selectedImage: UIImage?

    enum PhotoSource: Identifiable {
        case photoLibrary
        case camera
        
        var id: Int { self.hashValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 渐层背景
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 20.0))
                            .padding(.bottom)
                    } else {
                        Image("RecipeFood")  // Provide a placeholder
                            .resizable()
                            .scaledToFit()  // 保持比例並完整顯示圖片
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color.white.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 20.0))
                            .padding(.bottom)
                            .onTapGesture {
                                showPhotoOptions = true
                            }
                    }
                    FormTextField(label: "Name", placeholder: "Recipe Name", value: $viewModel.name)
                    FormTextField(label: "Type", placeholder: "Recipe Type", value: $viewModel.type)
                    FormTextField(label: "Notes", placeholder: "Anything to be keep in here ~", value: $viewModel.description)
                }
                .padding()
            }
            .navigationTitle("Add Recipe")
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
        .onDisappear {
            // Handle the image saving here
            if let selectedImage = selectedImage {
                let imageName = saveImageToFileSystem(selectedImage)
                viewModel.image = imageName
            }
        }
        .confirmationDialog("Choose your photos from", isPresented: $showPhotoOptions, titleVisibility: .visible) {
            Button("Camera") { photoSource = .camera }
            Button("Photo Library") { photoSource = .photoLibrary }
        }
        .fullScreenCover(item: $photoSource) { source in
            switch source {
            case .photoLibrary:
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary).ignoresSafeArea()
            case .camera:
                ImagePicker(image: $selectedImage, sourceType: .camera).ignoresSafeArea()
            }
        }
        .tint(.primary)
    }

    private func save() {
        let recommendRecipe = RecommendRecipe(
            name: viewModel.name,
            type: viewModel.type,
            location: viewModel.location,
            phone: viewModel.phone,
            description: viewModel.description,
            image: viewModel.image ?? "default_image"
        )
        // Save recommendRecipe somewhere
    }

    private func saveImageToFileSystem(_ image: UIImage) -> String {
        let imageData = image.jpegData(compressionQuality: 1.0) ?? Data()
        let uniqueID = UUID().uuidString
        let filePath = NSTemporaryDirectory() + uniqueID + ".jpg"
        let fileURL = URL(fileURLWithPath: filePath)

        do {
            try imageData.write(to: fileURL)
            return filePath
        } catch {
            print("Error saving image: \(error)")
            return "default_image"
        }
    }
}

#Preview{
    AddGroceryForm(
        viewModel: AddGroceryFormViewModel()
    )
}

struct FormTextField: View {
    let label: String
    var placeholder: String = ""
    
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label.uppercased())
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Color(.darkGray))
            
            TextField(placeholder, text: $value)
                .font(.system(.body, design: .rounded))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(10)
                .background(Color.white.opacity(0.3)) // 添加淡色背景
                .cornerRadius(8) // 圓角設定
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 2) // 修改框線顏色和寬度
                )
                .padding(.vertical, 10)
        }
    }
}



#Preview("FormTextField", traits: .fixedLayout(width: 300, height: 200)) {
    FormTextField(label: "NAME", placeholder: "Fill in the restaurant name", value: .constant(""))
}

