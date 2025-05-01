import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeGenerator {
    private static let context = CIContext()
    private static let filter = CIFilter.qrCodeGenerator()
    
    // 从字符串生成基本二维码
    static func generateQRCode(from string: String, size: CGFloat = 300) -> UIImage? {
        guard !string.isEmpty else { return nil }
        
        // 设置二维码内容
        let data = string.data(using: .utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        // 获取输出图像
        guard let ciImage = filter.outputImage else { return nil }
        
        // 调整大小
        let scale = size / ciImage.extent.width
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledCIImage = ciImage.transformed(by: transform)
        
        // 转换为 UIImage
        guard let cgImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    // 从历史记录项生成二维码
    static func generateQRCode(from historyItem: QRCodeHistoryItem, size: CGFloat = 300) -> UIImage? {
        return generateQRCode(from: historyItem.content, size: size)
    }
    
    // 自定义二维码样式
    static func styleQRCode(qrCode: UIImage, foregroundColor: UIColor = .black, backgroundColor: UIColor = .white) -> UIImage? {
        guard let cgImage = qrCode.cgImage else { return nil }
        
        // 创建上下文
        let size = CGSize(width: qrCode.size.width, height: qrCode.size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 绘制背景
        context.setFillColor(backgroundColor.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // 绘制二维码
        context.saveGState()
        context.setBlendMode(.normal)
        
        // 设置前景色
        context.setFillColor(foregroundColor.cgColor)
        context.clip(to: CGRect(origin: .zero, size: size), mask: cgImage)
        context.fill(CGRect(origin: .zero, size: size))
        
        context.restoreGState()
        
        // 获取结果图像
        guard let resultImage = UIGraphicsGetImageFromCurrentImageContext() else { return qrCode }
        return resultImage
    }
    
    // 添加 Logo
    static func addLogo(to qrCode: UIImage, logo: UIImage, logoSize: CGFloat = 0.2, cornerRadius: CGFloat = 0) -> UIImage {
        let qrCodeSize = qrCode.size
        let logoWidth = qrCodeSize.width * logoSize
        let logoHeight = qrCodeSize.height * logoSize
        let logoX = (qrCodeSize.width - logoWidth) / 2
        let logoY = (qrCodeSize.height - logoHeight) / 2
        
        // 创建上下文
        UIGraphicsBeginImageContextWithOptions(qrCodeSize, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        // 绘制二维码
        qrCode.draw(in: CGRect(origin: .zero, size: qrCodeSize))
        
        // 绘制 Logo
        let logoRect = CGRect(x: logoX, y: logoY, width: logoWidth, height: logoHeight)
        
        if cornerRadius > 0 {
            // 创建圆角路径
            let path = UIBezierPath(roundedRect: logoRect, cornerRadius: cornerRadius * logoWidth)
            UIGraphicsGetCurrentContext()?.addPath(path.cgPath)
            UIGraphicsGetCurrentContext()?.clip()
        }
        
        logo.draw(in: logoRect)
        
        // 获取结果图像
        guard let resultImage = UIGraphicsGetImageFromCurrentImageContext() else { return qrCode }
        return resultImage
    }
}
