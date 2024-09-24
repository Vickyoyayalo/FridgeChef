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

    // 管理 Alert 的狀態
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    // AlertService 實例
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
                Text("選擇圖片")
                    .frame(height: 200)
                    .background(Color.gray.opacity(0.2))
                    .onTapGesture {
                        showPhotoOptions = true
                    }
            }
        }
        .confirmationDialog("選擇來源", isPresented: $showPhotoOptions) {
            Button("相機") {
                checkCameraAuthorizationStatus()
            }
            Button("相冊") {
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
        // 顯示授權相關的 Alert
        .alert(isPresented: $showAlert) {
            alertService.showAlert(title: alertTitle, message: alertMessage)
        }
    }
    
    // 檢查相機授權狀態
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
    
    // 檢查相冊授權狀態
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

    // 相機訪問被拒時顯示的警告
    private func showCameraAccessDeniedAlert() {
        alertTitle = "相機無法使用"
        alertMessage = "請到設定中允許應用訪問相機。"
        showAlert = true
    }

    // 相冊訪問被拒時顯示的警告
    private func showPhotoLibraryAccessDeniedAlert() {
        alertTitle = "相冊無法使用"
        alertMessage = "請到設定中允許應用訪問相冊。"
        showAlert = true
    }
}
