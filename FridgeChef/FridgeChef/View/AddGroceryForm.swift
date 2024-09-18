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
                        Image("newphoto")  // Provide a placeholder
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
                    }

                    FormTextField(label: "NAME", placeholder: "Fill in the grocery name", value: $viewModel.name)
                    FormTextField(label: "TYPE", placeholder: "Fill in the grocery type", value: $viewModel.type)
//                    FormTextField(label: "ADDRESS", placeholder: "Fill in the grocery address", value: $viewModel.location)
//                    FormTextField(label: "PHONE", placeholder: "Fill in the grocery phone", value: $viewModel.phone)
                    FormTextView(label: "DESCRIPTION", value: $viewModel.description, height: 100)
                }
                .padding()
            }
            .navigationTitle("Add Grocery Item")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { save() }) {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(Color("NavigationBarTitle"))
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
        .confirmationDialog("Choose your photo source", isPresented: $showPhotoOptions, titleVisibility: .visible) {
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
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .padding(.vertical, 10)
            
        }
    }
}

struct FormTextView: View {
    
    let label: String
    
    @Binding var value: String
    
    var height: CGFloat = 200.0
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label.uppercased())
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Color(.darkGray))
            
            TextEditor(text: $value)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .padding(.top, 10)
            
        }
    }
}

#Preview("FormTextField", traits: .fixedLayout(width: 300, height: 200)) {
    FormTextField(label: "NAME", placeholder: "Fill in the restaurant name", value: .constant(""))
}

#Preview("FormTextView", traits: .sizeThatFitsLayout) {
    FormTextView(label: "Description", value: .constant(""))
}

