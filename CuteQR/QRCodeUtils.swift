import UIKit

struct QRCodeUtils {
    static func addLogo(to qrCode: UIImage, logo: UIImage, size: CGFloat, cornerRadius: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: qrCode.size)
        
        return renderer.image { context in
            // 绘制二维码
            qrCode.draw(in: CGRect(origin: .zero, size: qrCode.size))
            
            // 计算 Logo 大小和位置
            let logoSize = CGSize(width: qrCode.size.width * size,
                                height: qrCode.size.height * size)
            let logoRect = CGRect(x: (qrCode.size.width - logoSize.width) / 2,
                                y: (qrCode.size.height - logoSize.height) / 2,
                                width: logoSize.width,
                                height: logoSize.height)
            
            // 创建圆角路径
            let path = UIBezierPath(roundedRect: logoRect,
                                  cornerRadius: cornerRadius)
            context.cgContext.addPath(path.cgPath)
            context.cgContext.clip()
            
            // 绘制 Logo
            logo.draw(in: logoRect)
        }
    }
}
