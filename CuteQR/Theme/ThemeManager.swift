import SwiftUI

/// 管理应用的颜色主题
final class ThemeManager {
    /// 单例实例
    static let shared = ThemeManager()
    
    @AppStorage("colorScheme") private var colorSchemeString: String = "system"
    
    private init() {}
    
    /// 获取当前主题模式
    func getColorScheme() -> ColorScheme? {
        switch colorSchemeString {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
    
    /// 设置主题模式
    /// - Parameter scheme: 颜色模式，nil 表示跟随系统
    func setColorScheme(_ scheme: ColorScheme?) {
        switch scheme {
        case .some(.light):
            colorSchemeString = "light"
        case .some(.dark):
            colorSchemeString = "dark"
        default:
            colorSchemeString = "system"
        }
    }
}
