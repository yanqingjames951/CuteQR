import SwiftUI

/// 管理应用的颜色主题
class ThemeManager: ObservableObject {
    /// 单例实例
    static let shared = ThemeManager()
    
    /// 当前主题模式
    @Published var colorScheme: ColorScheme?
    
    private init() {
        // 默认跟随系统
        colorScheme = nil
    }
    
    /// 设置主题模式
    /// - Parameter scheme: 颜色模式，nil 表示跟随系统
    func setColorScheme(_ scheme: ColorScheme?) {
        colorScheme = scheme
    }
}

/// 颜色主题修饰符
struct ThemeModifier: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.colorScheme)
    }
}

extension View {
    /// 应用主题设置
    func withTheme() -> some View {
        self.modifier(ThemeModifier())
    }
}
