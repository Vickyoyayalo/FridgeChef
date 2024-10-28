//
//  ImageSelectorView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/19.
//

import SwiftUI
import PhotosUI

struct ImageSelectorView: View {
    @Binding var image: UIImage?
    @State private var showPhotoOptions = false
    @State private var photoSource: PhotoSource?

    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    private let alertService = AlertService()

    enum PhotoSource: Identifiable {
        case photoLibrary
        case camera
        var id: Int { self.hashValue }
    }

    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                    .onTapGesture {
                        showPhotoOptions = true
                    }
            } else {
                Text("Choose your photos from")
                    .frame(height: 200)
                    .background(Color.gray.opacity(0.2))
                    .onTapGesture {
                        showPhotoOptions = true
                    }
            }
        }
        .confirmationDialog("Choose your photos from", isPresented: $showPhotoOptions) {
            Button("Camera") {
                checkCameraAuthorizationStatus()
            }
            Button("Photo Library") {
                checkPhotoLibraryAuthorizationStatus()
            }
        }
        .fullScreenCover(item: $photoSource) { source in
            switch source {
            case .camera:
                ImagePicker(image: $image, sourceType: .camera)
            case .photoLibrary:
                ImagePicker(image: $image, sourceType: .photoLibrary)
            }
        }
        .alert(isPresented: $showAlert) {
            alertService.showAlert(title: alertTitle, message: alertMessage)
        }
    }
    
    private func checkCameraAuthorizationStatus() {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthorizationStatus {
        case .authorized:
            photoSource = .camera
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    photoSource = .camera
                } else {
                    showCameraAccessDeniedAlert()
                }
            }
        case .denied, .restricted:
            showCameraAccessDeniedAlert()
        @unknown default:
            break
        }
    }
   
    private func checkPhotoLibraryAuthorizationStatus() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch photoAuthorizationStatus {
        case .authorized, .limited:
            photoSource = .photoLibrary
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    photoSource = .photoLibrary
                } else {
                    showPhotoLibraryAccessDeniedAlert()
                }
            }
        case .denied, .restricted:
            showPhotoLibraryAccessDeniedAlert()
        @unknown default:
            break
        }
    }

    private func showCameraAccessDeniedAlert() {
        alertTitle = "Cannot use your camera."
        alertMessage = "Please go to settings and allow the app to access your camera. "
        showAlert = true
    }

    private func showPhotoLibraryAccessDeniedAlert() {
        alertTitle = "Cannot use your photo album."
        alertMessage = "Please go to settings and allow the app to access your photo album."
        showAlert = true
    }
}
