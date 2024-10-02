//
//  LoginView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//

import SwiftUI
import AVKit

struct LoginView: View {
    @State private var isShowingLoginDetail = false
    @State private var isShowingSignUp = false
    
    var body: some View {
        CustomNavigationBarView(title: "Welcome") {
            ZStack(alignment: .bottom) {
//                GeometryReader {
//                    let size = $0.size
//                    Image(.loginView)
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                        .offset(y: -60)
//                        .frame(width: size.width, height: size.height)
//                }
//                 背景影片
                VideoPlayerView(videoName: "LoginVideo")
                    .ignoresSafeArea()
//                
                    .mask {
                        Rectangle()
                            .fill(.linearGradient(
                                colors:[
                                    .white,
                                    .white,
                                    .white,
                                    .white,
                                    .white,
                                    .white.opacity(0.6),
                                    .white.opacity(0.2),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                    }
                    .ignoresSafeArea()
                
                VStack {
                    
                    Spacer()
                    
                    Button("Sign In") {
                        self.isShowingLoginDetail = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange, Color.yellow]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .opacity(0.8)  // 应用50%透明度到整个LinearGradient
                    )
                    .cornerRadius(25)
                    .shadow(radius: 25)
                    .padding(.horizontal)
                    
                    // 注册按钮
                    Button("Sign Up") {
                        self.isShowingSignUp = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                    .cornerRadius(25)
                    .shadow(radius: 25)
                    .padding(.horizontal)
                    
                    //                    Spacer()
                }
            }
            .sheet(isPresented: $isShowingLoginDetail) {
                LoginDetailView()
            }
            .sheet(isPresented: $isShowingSignUp) {
                SignUpView()
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
