//
//  LoginView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//

import SwiftUI
import AVKit

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景影片
                VideoPlayerView(videoName: "LoginVideo")
                    .ignoresSafeArea()
                //                    .overlay(Color.white.opacity(0.1)) // 影片加上透明黑色遮罩，讓文字更易閱讀
                
                VStack {
                    Spacer()
                    
                    // 登入按鈕
                    Button(action: {
                        // 登入動作
                    }) {
                        NavigationLink(destination: LoginDetailView()) {
                            Text("登入")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 25).stroke(Color.orange, lineWidth: 2))
                                .background(RoundedRectangle(cornerRadius: 25).fill(Color.clear))
                        }
                        .padding(.horizontal)
                        
                        // 註冊按鈕
                        Button(action: {
                            // 註冊動作
                        }) {
                            NavigationLink(destination: SignUpView()) {
                                Text("註冊")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(25)
                            }
//                            .padding(.horizontal)
                            
                        }
                        .padding()
                        .navigationBarHidden(true)
                    }
                }
            }
        }
    }
}

// 背景影片播放
struct VideoPlayerView: UIViewRepresentable {
    var videoName: String
    
    func makeUIView(context: Context) -> UIView {
        return LoopingPlayerUIView(videoName: videoName)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 更新邏輯
    }
}

class LoopingPlayerUIView: UIView {
    private var playerLayer = AVPlayerLayer()
    
    init(videoName: String) {
        super.init(frame: .zero)
        let player = AVPlayer(url: Bundle.main.url(forResource: videoName, withExtension: "mp4")!)
        player.isMuted = true
        player.actionAtItemEnd = .none
        player.play()
        
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main) { _ in
                player.seek(to: .zero)
                player.play()
            }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
