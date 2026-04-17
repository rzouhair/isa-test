//
//  CameraCaptureView.swift
//  poke
//
//  Created by user on 25/3/2025.
//

import SwiftUI
import Inject

struct CameraCaptureView: View {
    @ObserveInjection var inject
    @State private var showChatSheet: Bool = false
    @State private var cameraIsActive: Bool = true
    @State private var showHistory: Bool = false

    @Environment(Router.self) private var router: Router

    var body: some View {
        ZStack(alignment: .topLeading) {
            CameraView(isActive: $cameraIsActive, onCaptureImage: { images in
                router.presentFullscreenCover(.detection(images: images))
            }, showHistory: $showHistory)

            // Close button
            if router.presentedSheet != .camera {
                Button {
                    router.dismissSheet()
                    router.dismissFullscreenCover()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                }
                .padding(.top, (UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first?.safeAreaInsets.top ?? 0) + 8)
                .padding(.leading, 16)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .background(Color.black)
        .enableInjection()
    }
}

#Preview {
    let router = Router()
    CameraCaptureView()
        .environment(router)
}
