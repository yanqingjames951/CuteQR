import SwiftUI

extension Color {
    // Define our pastel colors for the 'cute' theme
    static let pastelPink = Color(red: 255/255, green: 182/255, blue: 193/255)
    static let pastelBlue = Color(red: 173/255, green: 216/255, blue: 230/255)
    static let pastelGreen = Color(red: 152/255, green: 251/255, blue: 152/255)
    static let pastelYellow = Color(red: 255/255, green: 239/255, blue: 213/255)
    static let pastelPurple = Color(red: 221/255, green: 160/255, blue: 221/255)
    
    // 获取适合当前颜色的文本颜色（黑色或白色）
    func contrastingTextColor() -> Color {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 0]
        let brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000
        return brightness > 0.5 ? .black : .white
    }
}
