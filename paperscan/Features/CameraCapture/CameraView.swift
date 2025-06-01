// AI Wrapper SwiftUI
// Created by Adam Lyttle on 7/9/2024

// Make cool stuff and share your build with me:
//  --> x.com/adamlyttleapps
//  --> github.com/adamlyttleapps

import AVFoundation
import Inject
import SwiftUI

struct CameraView: View {
  @ObserveInjection var inject

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
  private let photoCaptureDelegate = PhotoCaptureDelegate()

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
  @State private var showAlert: Bool = false
  @State private var showPermissionDeniedMessage: Bool = false

  @Binding var showHistory: Bool

  @State private var flashOn: Bool = false

  @Environment(\.colorScheme) var colorScheme  //colorScheme == .dark ? Color.white : Color.black

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
    } else {
      return 0
    }
  }

  private var screenHeight: CGFloat {
    if let screen = screen {
      return screen.size.width
    } else {
      return 0
    }
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      ZStack {
        VStack {
          if let captureSession = captureSession, let photoOutput = photoOutput {
            GeometryReader { geometry in
              CameraPreviewView(
                captureSession: captureSession, photoOutput: photoOutput,
                photoCaptureDelegate: photoCaptureDelegate
              )
              .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
              .scaleEffect(1.0)
              .onAppear {
                checkCameraPermission()
                previewSize = geometry.size
              }

            }
          }
        }
        .opacity(isActive ? 1 : (1 - 0.66))

        ResizableCropFrameView(cropRect: $cropRect, parentSize: UIScreen.main.bounds.size)

      }
      .blur(radius: showPermissionDeniedMessage ? 3 : 0)

      if showPermissionDeniedMessage {
        VStack {
          Spacer()
          Text("Camera access is required.")
            .font(.headline)
            .padding()
          Text("Please grant camera access in Settings to use the banknote capture feature")
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
          Button("Open Settings") {
            if let url = URL(string: UIApplication.openSettingsURLString) {
              UIApplication.shared.open(url)
            }
          }
          .padding()
          .buttonStyle(.borderedProminent)
          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.75))
        .foregroundColor(.white)
        .edgesIgnoringSafeArea(.all)
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

      } else {

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
            } else {
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
              ForEach(0..<(twoSidedCapture ? 2 : 1), id: \.self) { index in
                Group {
                  if selectedImages.count > index {
                    Image(uiImage: selectedImages[index])
                      .resizable()
                      .scaledToFit()
                      .frame(width: 100, height: 50)
                      .clipped()
                      .opacity(0.8)
                      .clipShape(RoundedRectangle(cornerRadius: 8))
                  } else if twoSidedCapture && index == 1 && selectedImages.count == 1 {
                    // Show 'Done (1 Side)' button if two-sided capture is enabled,
                    // it's the second slot, and one image is already captured.
                    Button("Click for\n1 side only") {
                      // Trigger capture completion with the single image
                      onCaptureImage([self.selectedImages[0]])
                    }
                    .font(.caption)
                    .multilineTextAlignment(.center)

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
              PhotoPicker(
                isPresented: $showImagePicker, selectedImage: $selectedImage, filename: $filename
              )
              .accentColor(.blue)
            }

            Spacer()
            Button(action: {
              switch AVCaptureDevice.authorizationStatus(for: .video) {
              case .authorized:
                if let photoOutput = photoOutput {
                  print("==> capturePhoto")
                  isProcessing = true
                  let settings = AVCapturePhotoSettings()
                  photoOutput.capturePhoto(with: settings, delegate: photoCaptureDelegate)
                }
              case .denied, .restricted:
                showAlert = true
              default:
                showAlert = true
              }
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
    .alert(isPresented: $showAlert) {
      Alert(
        title: Text("Camera Access Denied"),
        message: Text("Camera access is required to use this feature."),
        primaryButton: .default(Text("Settings"), action: {
          if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
          }
        }),
        secondaryButton: .cancel()
      )
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
      } else {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          isActive = true
        }
      }
    }
    .onChange(of: isActive) { value in
      if isActive {
        self.startCameraSession()
      } else {
        self.stopCameraSession()
      }
    }
    .onChange(of: selectedImage) { selectedImage in
      DispatchQueue.main.async {
        print("Captured from picker")
        if let selectedImage = selectedImage {
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isProcessing = false
          }
          let maxImages = twoSidedCapture ? 2 : 1
          if self.selectedImages.count < maxImages {
            self.selectedImages.append(selectedImage)
          }

          // Trigger completion if we have the required number of images
          if self.selectedImages.count == maxImages {
            onCaptureImage(self.selectedImages)
          }
        }
      }
    }
    .edgesIgnoringSafeArea(.all)
    .enableInjection()
  }

  private func stopCameraSession() {
    if let captureSession = captureSession, captureSession.isRunning {
      DispatchQueue.global(qos: .userInitiated).async {
        print("==> captureSession.stopRunning()")
        captureSession.stopRunning()
        self.captureSession = nil
        self.photoOutput = nil
      }
    }
  }

  private func startCameraSession() {
    print("==> startCameraSession")
    if captureSession != nil {
    } else {
      captureSession = AVCaptureSession()
    }
    if photoOutput != nil {
    } else {
      photoOutput = AVCapturePhotoOutput()
    }
    print("==> 1")
    if let captureSession = captureSession, !captureSession.isRunning {
      print("==> 2")
      DispatchQueue.global(qos: .userInitiated).async {
        print("==> captureSession.startRunning()")
        captureSession.startRunning()
      }
    }
  }

  private func setupCamera() {
    // Initialize and configure the capture session
    photoCaptureDelegate.onPhotoCapture = { image in
      let fixedImage = image.resized(toHeight: image.height) ?? image

      if let croppedImage = cropImage(fixedImage, to: cropRect) {
        print("Setup camera - photo captured")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          isProcessing = false
        }

        let maxImages = twoSidedCapture ? 2 : 1
        if self.selectedImages.count < maxImages {
          self.selectedImages.append(croppedImage)
        }

        // Trigger completion if we have the required number of images
        if self.selectedImages.count == maxImages {
          onCaptureImage(self.selectedImages)
        }
      } else {
        // Handle cropping failure if necessary
        DispatchQueue.main.async {
          isProcessing = false
        }
        print("Error: Could not crop image.")
      }
    }
  }

  func checkCameraPermission() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      // Already authorized
      showPermissionDeniedMessage = false
      setupCamera()
    case .notDetermined:
      // Request permission
      AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async {
          if granted {
            showPermissionDeniedMessage = false
            setupCamera()
          } else {
            // Handle if not granted
            showPermissionDeniedMessage = true
          }
        }
      }
    case .denied, .restricted:
      // Permission denied or restricted, handle accordingly
      showPermissionDeniedMessage = true
      break
    @unknown default:
      break
    }
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
    let frameWidth = screenWidth * 0.8  // Example: 80% of screen width
    let frameHeight = frameWidth * 0.5  // Example: Aspect ratio of 2:1
    let framePosition = CGPoint(
      x: (screenWidth - frameWidth) / 2, y: (screenHeight - frameHeight) / 2)

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

struct CameraPreviewView: UIViewRepresentable {
  var captureSession: AVCaptureSession
  var photoOutput: AVCapturePhotoOutput
  var photoCaptureDelegate: AVCapturePhotoCaptureDelegate

  func makeUIView(context: Context) -> UIView {
    let view = UIView(frame: UIScreen.main.bounds)

    captureSession.sessionPreset = .photo

    if let videoDevice = AVCaptureDevice.default(
      .builtInWideAngleCamera, for: .video, position: .back)
    {
      guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
        captureSession.canAddInput(videoDeviceInput)
      else { return view }
      captureSession.addInput(videoDeviceInput)

      guard captureSession.canAddOutput(photoOutput) else { return view }
      captureSession.addOutput(photoOutput)

      let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
      previewLayer.frame = view.bounds

      previewLayer.videoGravity = .resizeAspectFill

      previewLayer.connection?.videoOrientation = .portrait
      view.layer.addSublayer(previewLayer)

      DispatchQueue.global(qos: .userInitiated).async {
        self.captureSession.startRunning()
      }
    }

    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {}
}

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
  var onPhotoCapture: ((UIImage) -> Void)?

  func photoOutput(
    _ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?
  ) {
    guard let imageData = photo.fileDataRepresentation() else { return }
    if let image = UIImage(data: imageData) {
      onPhotoCapture?(image)
    }
  }
}

#Preview {
  @Previewable
  @State var showChatSheet: Bool = false
  @Previewable
  @State var cameraIsActive: Bool = true
  @Previewable
  @State var showHistory: Bool = false

  ZStack(alignment: .top) {
    CameraView(
      isActive: $cameraIsActive,
      onCaptureImage: { images in

        showChatSheet = true

      }, showHistory: $showHistory)
  }
  .edgesIgnoringSafeArea(.all)
  .background(Color.black)
}
