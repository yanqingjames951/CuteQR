import SwiftUI

/// 应用主题辅助工具，提供统一的主题应用方法
struct AppTheme {
    /// 将主题应用到视图
    /// - Parameter content: 需要应用主题的视图
    /// - Returns: 应用了主题的视图
    static func applyTheme<T: View>(to content: T) -> some View {
        content.tint(Color.pastelPink)
    }
}
