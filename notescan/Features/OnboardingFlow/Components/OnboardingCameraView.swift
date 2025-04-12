// AI Wrapper SwiftUI
// Created by Adam Lyttle on 7/9/2024

// Make cool stuff and share your build with me:
//  --> x.com/adamlyttleapps
//  --> github.com/adamlyttleapps

import SwiftUI
import AVFoundation

struct OnboardingCameraView: View {
    
    @Binding var isActive: Bool
    var twoSidedCapture: Bool = true
    
    @State var screen: GeometryProxy?
    
    @State private var cropRect = CGRect(
        x: (UIScreen.main.bounds.width / 2) - UIScreen.main.bounds.width * 0.425,
        y: (UIScreen.main.bounds.height / 2) - 150,
        width: UIScreen.main.bounds.width * 0.85,
        height: 200
    )
        
    @State private var captureSession: AVCaptureSession? = AVCaptureSession()
    @State private var photoOutput: AVCapturePhotoOutput? = AVCapturePhotoOutput()
    
    @State private var isProcessing: Bool = false
    @State private var shutterFlash: Bool = false
    //let onShutterFlash: () -> Void
    
    let onCaptureImage: ([UIImage]) -> Void
    
    //image picker stuff
    @State private var showImagePicker: Bool = false
    //@State private var imagePickerOpacity: CGFloat = 0
    @State private var selectedImage: UIImage? = nil
    @State private var selectedImages: [UIImage] = []
    
    @State private var filename: String? = nil
    
    @Binding var showHistory: Bool
    
    @State private var flashOn: Bool = false
    
    @Environment(\.colorScheme) var colorScheme //colorScheme == .dark ? Color.white : Color.black
    
    @State private var previewSize: CGSize = .zero
    
    func toggleFlashlight() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        
        flashOn = !flashOn
        
        do {
            try device.lockForConfiguration()
            device.torchMode = flashOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Flashlight could not be used")
        }
    }
    
    //let processedImage: (UIImage, String) -> Void
    
    private var screenWidth: CGFloat {
        if let screen = screen {
            return screen.size.width
        }
        else {
            return 0
        }
    }
    
    private var screenHeight: CGFloat {
        if let screen = screen {
            return screen.size.width
        }
        else {
            return 0
        }
    }
    
    
    var body: some View {
        ZStack (alignment: .topLeading) {
            ZStack {
                VStack {
                    Color.orange.ignoresSafeArea()
                }
                .opacity(isActive ? 1 : (1 - 0.66))
                
                ResizableCropFrameView(cropRect: $cropRect, parentSize: UIScreen.main.bounds.size)

            }
            
            if isProcessing {
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.bottom, 80)
                        Spacer()
                    }
                    Spacer()
                }
                .background(shutterFlash ? Color.white : Color.black.opacity(0.66))
                .onAppear {
                    withAnimation {
                        shutterFlash = false
                    }
                }
                
            }
            else {
                
                HStack {
                    Spacer()
                    Button(action: {
                        //show image selection
                        self.toggleFlashlight()
                    }) {
                        if flashOn {
                            Image(systemName: "bolt")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 22, height: 22, alignment: .center)
                                .clipped()
                                .padding(.top)
                        }
                        else {
                            Image(systemName: "bolt.slash")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 22, height: 22, alignment: .center)
                                .clipped()
                                .padding(.top)
                        }
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, (UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0))
                
                
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        HStack(spacing: 10) {
                            ForEach(0..<2, id: \.self) { index in
                                Group {
                                    if selectedImages.count > index {
                                        Image(uiImage: selectedImages[index])
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 100, height: 50)
                                            .clipped()
                                            .opacity(0.8)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        Text("Side \(index + 1)")
                                    }
                                }
                                .foregroundStyle(.white)
                                .frame(width: 120, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedImages.count > index ? .green.opacity(0.3) : .white.opacity(0.3))
                                        .stroke(selectedImages.count > index ? .green : .white, lineWidth: 2)
                                )
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 120 + (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0))
                
                VStack {
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            //show image selection
                            showImagePicker = true
                        }) {
                            Image(systemName: "photo.on.rectangle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30, alignment: .center)
                                .clipped()
                                .padding(25)
                        }
                        .foregroundColor(.white)
                        .sheet(isPresented: $showImagePicker) {
                            PhotoPicker(isPresented: $showImagePicker, selectedImage: $selectedImage, filename: $filename)
                                .accentColor(.blue)
                        }
                        
                        Spacer()
                        Button(action: {
                            // Capture photo
                        }) {
                            Image(systemName: "camera.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 35, alignment: .center)
                                .clipped()
                                .padding(25)
                                .background(
                                    Circle()
                                        .fill(Color.appPrimary.gradient)
                                )
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        Spacer()
                        //
                        
                        
                        
                        Button(action: {
                            showHistory.toggle()
                        }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, alignment: .center)
                                .clipped()
                                .padding(25)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 2.5)
                        
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20 + (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0))
                
                //white flash shows that the photo has been taken but also hides the transition from live to still
                
                
                //}
                
            }
            
        }
        .onChange(of: isProcessing) { value in
            if value {
                shutterFlash = true
            }
        }
        .onChange(of: showHistory) { value in
            if value {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isActive = false
                }
            }
            else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isActive = true
                }
            }
        }
        .onChange(of: selectedImage) { selectedImage in
            DispatchQueue.main.async {
                print("Captured")
                if let selectedImage = selectedImage {
                 DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                 isProcessing = false
                 }
                 if (self.selectedImages.count != 2) {
                 self.selectedImages.append(selectedImage)
                 }
                 
                 if (self.selectedImages.count == 2) {
                 onCaptureImage(self.selectedImages)
                 }
                 }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    func cropImage(_ image: UIImage, to rect: CGRect) -> UIImage? {
        let imageSize = image.size
        let previewRatio = previewSize.width / previewSize.height
        let imageRatio = imageSize.width / imageSize.height
        
        var adjustedCropRect = cropRect
        
        if previewRatio > imageRatio {
            let scaledHeight = imageSize.width / previewRatio
            let yOffset = (imageSize.height - scaledHeight) / 2
            let scale = imageSize.width / previewSize.width
            
            adjustedCropRect.origin.x *= scale
            adjustedCropRect.origin.y = (adjustedCropRect.origin.y * scale) + yOffset
            adjustedCropRect.size.width *= scale
            adjustedCropRect.size.height *= scale
        } else {
            let scaledWidth = imageSize.height * previewRatio
            let xOffset = (imageSize.width - scaledWidth) / 2
            let scale = imageSize.height / previewSize.height
            
            adjustedCropRect.origin.x = (adjustedCropRect.origin.x * scale) + xOffset
            adjustedCropRect.origin.y *= scale
            adjustedCropRect.size.width *= scale
            adjustedCropRect.size.height *= scale
        }
        
        guard let cgImage = image.cgImage?.cropping(to: adjustedCropRect.integral) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    func cropCapturedImage(capturedImage: UIImage) -> UIImage? {
        guard let cgImage = capturedImage.cgImage else { return nil }
        
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // Assume the cropping frame is centered and based on a percentage of screen width
        let frameWidth = screenWidth * 0.8 // Example: 80% of screen width
        let frameHeight = frameWidth * 0.5 // Example: Aspect ratio of 2:1
        let framePosition = CGPoint(x: (screenWidth - frameWidth) / 2, y: (screenHeight - frameHeight) / 2)
        
        // Scale factors between captured image and screen size
        let scaleX = imageWidth / screenWidth
        let scaleY = imageHeight / screenHeight
        
        // Calculate cropping rectangle in image coordinates
        let cropX = framePosition.x * scaleX
        let cropY = framePosition.y * scaleY
        let cropWidth = frameWidth * scaleX
        let cropHeight = frameHeight * scaleY
        
        let cropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
        
        // Perform cropping
        guard let croppedCgImage = cgImage.cropping(to: cropRect) else { return nil }
        
        return UIImage(cgImage: croppedCgImage)
    }
}

#Preview {
    @Previewable
    @State var showChatSheet: Bool = false
    @Previewable
    @State var cameraIsActive: Bool = true
    @Previewable
    @State var showHistory: Bool = false

    ZStack (alignment: .top) {
        CameraView(isActive: $cameraIsActive, onCaptureImage: { images in
            
            showChatSheet = true
            
        }, showHistory: $showHistory)
    }
    .edgesIgnoringSafeArea(.all)
    .background(Color.black)
}
