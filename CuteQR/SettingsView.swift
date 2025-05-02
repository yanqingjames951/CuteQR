import SwiftUI

struct SettingsView: View {
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @AppStorage("defaultQRStyle") private var defaultQRStyle: String = "square"
    @AppStorage("iCloudSync") private var iCloudSync: Bool = false
    @AppStorage("maxHistoryItems") private var maxHistoryItems: Int = 100
    @EnvironmentObject private var historyManager: QRCodeHistoryManager
    
    var body: some View {
        NavigationStack {
            Form {
                // Appearance Section
                Section {
                    Picker("主题", selection: $colorScheme) {
                        Text("跟随系统").tag("system")
                        Text("浅色").tag("light")
                        Text("深色").tag("dark")
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("外观设置")
                }
                
                // QR Code Generation Section
                Section {
                    Picker("默认样式", selection: $defaultQRStyle) {
                        Text("方形").tag("square")
                        Text("圆点").tag("dot")
                        Text("圆角").tag("round")
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("二维码生成")
                }
                
                // History Management Section
                Section {
                    Stepper("最大历史记录数: \(maxHistoryItems)", value: $maxHistoryItems, in: 50...500, step: 50)
                    
                    Toggle("iCloud 同步", isOn: $iCloudSync)
                        .onChange(of: iCloudSync) { oldValue, newValue in
                            // 这里可以添加同步逻辑
                        }
                    
                    Button(action: {
                        historyManager.clearHistory()
                    }) {
                        Text("清空历史记录")
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("历史记录管理")
                }
                
                // About Section
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/yanqingjames951/CuteQR.git")!) {
                        HStack {
                            Text("隐私政策")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://github.com/yanqingjames951/CuteQR.git")!) {
                        HStack {
                            Text("使用条款")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://github.com/yanqingjames951/CuteQR.git")!) {
                        HStack {
                            Text("源代码仓库")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(QRCodeHistoryManager.preview)
}
