import SwiftUI

struct SettingsView: View {
    // MARK: - 环境和状态
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var cloudKitManager = CloudKitManager.shared
    @EnvironmentObject private var historyManager: QRCodeHistoryManager
    
    // MARK: - 用户设置
    @AppStorage("maxHistoryItems") private var maxHistoryItems = 100
    @AppStorage("saveToHistoryAutomatically") private var saveToHistoryAutomatically = true
    @AppStorage("defaultQRCodeStyle") private var defaultQRCodeStyle = "方形"
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = true
    
    // MARK: - 本地状态
    @State private var showingClearHistoryAlert = false
    @State private var showingSyncAlert = false
    
    // MARK: - 辅助计算属性和方法
    
    // 主题选择器的索引值 - 拆分复杂表达式
    private var themeSelectionIndex: Int {
        if themeManager.colorScheme == nil {
            return 0
        } else if themeManager.colorScheme == .dark {
            return 2
        } else {
            return 1
        }
    }
    
    // 设置主题的方法 - 拆分复杂表达式
    private func setTheme(_ index: Int) {
        switch index {
        case 0:
            themeManager.setColorScheme(nil)
        case 1:
            themeManager.setColorScheme(.light)
        case 2:
            themeManager.setColorScheme(.dark)
        default:
            break
        }
    }
    
    // iCloud 同步设置相关方法 - 拆分复杂表达式
    private func setICloudSync(_ enabled: Bool) {
        iCloudSyncEnabled = enabled
        historyManager.setICloudSyncEnabled(enabled)
    }
    
    // 历史记录数量滑块值转换 - 拆分复杂表达式
    private var historyCountSliderValue: Double {
        return Double(maxHistoryItems)
    }
    
    private func setHistoryCount(_ value: Double) {
        maxHistoryItems = Int(value)
    }
    
    private let qrCodeStyles = ["方形", "圆点", "圆角"]
    
    // MARK: - 视图构建
    var body: some View {
        NavigationStack {
            List {
                // 外观设置
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("主题模式")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // 使用拆分后的计算属性和方法，避免复杂表达式
                        Picker("主题模式", selection: Binding(
                            get: { self.themeSelectionIndex },
                            set: { self.setTheme($0) }
                        )) {
                            HStack {
                                Image(systemName: "circle.lefthalf.filled")
                                Text("跟随系统")
                            }.tag(0)
                            
                            HStack {
                                Image(systemName: "sun.max.fill")
                                Text("浅色模式")
                            }.tag(1)
                            
                            HStack {
                                Image(systemName: "moon.fill")
                                Text("深色模式")
                            }.tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.vertical, 5)
                    }
                    .padding(.vertical, 5)
                } header: {
                    SectionHeader(title: "外观", icon: "paintbrush.fill")
                }
                
                // 二维码生成设置
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("默认样式")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("默认样式", selection: $defaultQRCodeStyle) {
                            ForEach(qrCodeStyles, id: \.self) { style in
                                Text(style).tag(style)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.vertical, 5)
                    }
                    .padding(.vertical, 5)
                    
                    SettingToggleRow(
                        title: "自动保存到历史记录",
                        icon: "square.and.arrow.down.fill",
                        isOn: $saveToHistoryAutomatically
                    )
                } header: {
                    SectionHeader(title: "二维码生成", icon: "qrcode")
                }
                
                // 历史记录设置
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("最大历史记录数量")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text("\(maxHistoryItems)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.pink)
                                .frame(width: 60)
                                .padding(.trailing, 10)
                            
                            Slider(value: Binding(
                                get: { historyCountSliderValue },
                                set: { setHistoryCount($0) }
                            ), in: 10...500, step: 10)
                            .tint(.pink)
                        }
                    }
                    .padding(.vertical, 5)
                    
                    Button(action: {
                        showingClearHistoryAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 18))
                            Text("清空历史记录")
                                .foregroundColor(.red)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    SectionHeader(title: "历史记录", icon: "clock.arrow.circlepath")
                }
                
                // iCloud 同步设置
                Section {
                    if cloudKitManager.isICloudAvailable {
                        SettingToggleRow(
                            title: "启用 iCloud 同步",
                            icon: "cloud.fill",
                            isOn: Binding(
                                get: { iCloudSyncEnabled },
                                set: { setICloudSync($0) }
                            )
                        )
                        
                        if iCloudSyncEnabled {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.secondary)
                                    .frame(width: 25)
                                Text("上次同步")
                                Spacer()
                                Text(historyManager.lastSyncDate?.formatted(date: .abbreviated, time: .shortened) ?? "从未同步")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            
                            Button(action: {
                                showingSyncAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .foregroundColor(.pink)
                                        .font(.system(size: 18))
                                    Text("立即同步")
                                        .foregroundColor(.pink)
                                        .fontWeight(.medium)
                                    Spacer()
                                    
                                    if historyManager.isSyncing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .disabled(historyManager.isSyncing)
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.cloud.fill")
                                .foregroundColor(.orange)
                                .frame(width: 25)
                            Text("iCloud 不可用")
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    SectionHeader(title: "iCloud 同步", icon: "cloud")
                } footer: {
                    Text("启用后，您的历史记录将在所有使用相同 Apple ID 的设备上同步。")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                }
                
                // 关于
                Section {
                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.pink)
                                .frame(width: 25)
                            Text("关于 CuteQR")
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.secondary)
                            .frame(width: 25)
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } header: {
                    SectionHeader(title: "关于", icon: "info.circle")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("设置")
            .alert("确认清空历史记录", isPresented: $showingClearHistoryAlert) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) {
                    historyManager.clearHistory()
                }
            } message: {
                Text("此操作将永久删除所有历史记录，且无法恢复。")
            }
            .alert("确认同步", isPresented: $showingSyncAlert) {
                Button("取消", role: .cancel) {}
                Button("同步", role: .none) {
                    Task {
                        await historyManager.syncWithCloud()
                    }
                }
            } message: {
                Text("此操作将使用 iCloud 中的数据覆盖本地数据，或将本地数据上传到 iCloud。")
            }
        }
        .withTheme()
    }
}

// MARK: - 辅助视图组件

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.pink)
                .font(.system(size: 14))
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.pink)
        }
        .padding(.bottom, 5)
    }
}

struct SettingToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isOn ? .pink : .secondary)
                .frame(width: 25)
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.pink)
        }
        .padding(.vertical, 8)
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 20) {
                    // 使用应用图标作为 logo
                    if let iconImage = UIImage(named: "AppIcon") {
                        Image(uiImage: iconImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color.pink.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .pink.opacity(0.2), radius: 10, x: 0, y: 5)
                    } else {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.pink)
                    }
                    
                    Text("CuteQR")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    
                    Text("一款简洁、美观的二维码生成与扫描工具")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Text(" 2025 CuteQR Team")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }
            
            Section(header: Text("开发者")) {
                Link(destination: URL(string: "https://github.com")!) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.pink)
                        Text("开发者主页")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("反馈")) {
                Link(destination: URL(string: "mailto:feedback@cuteqr.app")!) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.pink)
                        Text("发送反馈")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("关于")
    }
}

#Preview {
    SettingsView()
        .environmentObject(QRCodeHistoryManager.preview)
}
