//
//  CameraCaptureView.swift
//  paperscan
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
        NavigationStack {
            ZStack(alignment: .top) {
                CameraView(isActive: $cameraIsActive, onCaptureImage: { images in
                    router.presentFullscreenCover(.detection(images: images))
                }, showHistory: $showHistory)
            }
            .edgesIgnoringSafeArea(.all)
            .background(Color.black)
            .toolbar {
                if router.presentedSheet != .camera {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            router.dismissSheet()
                            router.dismissFullscreenCover()
                        } label: {
                            Image(systemName: "xmark")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .padding(.top, 18)
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
        }
        .enableInjection()
    }
}

#Preview {
    let router = Router()
    CameraCaptureView()
        .environment(router)
}
