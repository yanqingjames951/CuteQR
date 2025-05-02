import UIKit

enum QRCodeUtils {
    static func addLogo(to qrCode: UIImage, logo: UIImage, size: CGFloat, cornerRadius: CGFloat) -> UIImage {
        let imageSize = qrCode.size
        let logoSize = CGSize(width: imageSize.width * size, height: imageSize.height * size)
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        qrCode.draw(in: CGRect(origin: .zero, size: imageSize))
        
        let logoRect = CGRect(
            x: (imageSize.width - logoSize.width) / 2,
            y: (imageSize.height - logoSize.height) / 2,
            width: logoSize.width,
            height: logoSize.height
        )
        
        let path = UIBezierPath(roundedRect: logoRect, cornerRadius: cornerRadius)
        path.addClip()
        
        logo.draw(in: logoRect)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? qrCode
    }
}
