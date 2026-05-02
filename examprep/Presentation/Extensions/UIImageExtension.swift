// AI Wrapper SwiftUI
// Created by Adam Lyttle on 7/9/2024

// Make cool stuff and share your build with me:

//  --> x.com/adamlyttleapps
//  --> github.com/adamlyttleapps

import Foundation
import SwiftUI

func loadUIImage(_ imageName: String) -> UIImage? {
    if let uiImage = UIImage(named: imageName) {
        if let cgImage = uiImage.cgImage {
            return UIImage(cgImage: cgImage)
        }
    }
    return nil
}

extension UIImage {

    enum ImageFormat {
        case png
        case jpeg
    }

    func cropped(to rect: CGRect) -> UIImage? {
        guard let cgImage = cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    func aspectHeight(width: CGFloat) -> CGFloat {
        return (size.height / size.width) * width
    }
    func aspectWidth(height: CGFloat) -> CGFloat {
        return (size.width / size.height) * height
    }
    
    func getPixelColor(x: Int, y: Int) -> UIColor? {
        
        guard let cgImage = self.cgImage else { return nil }
    
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData: [UInt8] = [0, 0, 0, 0]
        
        if let context = CGContext(data: &pixelData,
                                   width: 1,
                                   height: 1,
                                   bitsPerComponent: 8,
                                   bytesPerRow: 4,
                                   space: colorSpace,
                                   bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
           let croppedImage = cgImage.cropping(to: CGRect(x: x, y: y, width: 1, height: 1)) {
            
            context.draw(croppedImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            let red = CGFloat(pixelData[0]) / 255.0
            let green = CGFloat(pixelData[1]) / 255.0
            let blue = CGFloat(pixelData[2]) / 255.0
            let alpha = CGFloat(pixelData[3]) / 255.0
            
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        }
        
        return nil
    }
    
    
    var height: CGFloat {
        guard let cgImage = self.cgImage else { return 0 }
        return CGFloat(cgImage.height)
    }
    
    var width: CGFloat {
        guard let cgImage = self.cgImage else { return 0 }
        return CGFloat(cgImage.width)
    }

    func resized(toHeight height: CGFloat) -> UIImage? {
        let scale = height / self.size.height
        let newWidth = self.size.width * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: height))
        self.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
    
    func toBase64(format: ImageFormat = .jpeg, quality: CGFloat = 0.8) -> String? {
        let imageData: Data?
        
        switch format {
        case .png:
            imageData = self.pngData()
        case .jpeg:
            imageData = self.jpegData(compressionQuality: quality)
        }
        
        guard let data = imageData else { return nil }
        let prefix = format == .png ? "data:image/png;base64," : "data:image/jpeg;base64,"
        return prefix + data.base64EncodedString()
    }
    
    static func testImage(color: UIColor, size: CGSize = CGSize(width: 300, height: 200), text: String? = nil) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            
            if let text = text {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 40),
                    .paragraphStyle: paragraphStyle,
                    .foregroundColor: UIColor.white
                ]
                
                let string = NSString(string: text)
                let stringSize = string.size(withAttributes: attrs)
                string.draw(at: CGPoint(x: (size.width - stringSize.width) / 2, y: (size.height - stringSize.height) / 2), withAttributes: attrs)
            }
        }
    }

}
