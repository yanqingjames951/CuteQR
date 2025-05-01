import SwiftUI
import CoreImage.CIFilterBuiltins
import AVFoundation

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var copiedMessageManager = CopiedMessageManager()
    @StateObject private var historyManager = QRCodeHistoryManager()

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                GenerateQRView()
                    .tabItem {
                        Label("生成", systemImage: "qrcode.viewfinder")
                    }
                    .tag(0)
                
                ScanQRView()
                    .tabItem {
                        Label("扫描", systemImage: "viewfinder")
                    }
                    .tag(1)
                
                QRCodeHistoryView()
                    .tabItem {
                        Label("历史", systemImage: "clock.arrow.circlepath")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Label("设置", systemImage: "gear")
                    }
                    .tag(3)
            }
            .tint(.pink) // 使用粉色作为主题色，符合 CuteQR 的可爱风格
            
            if copiedMessageManager.showCopiedMessage {
                VStack {
                    Spacer()
                    Text("已复制到剪贴板")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.pink.opacity(0.8))
                                .shadow(color: Color.black.opacity(0.2), radius: 5)
                        )
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                        .padding(.bottom, 80)
                }
                .animation(.spring(), value: copiedMessageManager.showCopiedMessage)
                .zIndex(1) // 确保提示消息显示在最上层
            }
        }
        .environmentObject(copiedMessageManager)
        .environmentObject(historyManager)
        .accentColor(.pink)
        .withTheme()
    }
}

class CopiedMessageManager: ObservableObject {
    @Published var showCopiedMessage = false
    
    func showMessage() {
        showCopiedMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showCopiedMessage = false
        }
    }
}

struct ScanQRView: View {
    @State private var scannedText = ""
    @State private var isShowingScanner = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @EnvironmentObject private var copiedMessageManager: CopiedMessageManager
    
    var body: some View {
        NavigationView {
            VStack {
                if !scannedText.isEmpty {
                    Text(scannedText)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding()
                        .onTapGesture {
                            UIPasteboard.general.string = scannedText
                            copiedMessageManager.showMessage()
                        }
                }
                
                Button(action: {
                    isShowingScanner = true
                }) {
                    Label("开始扫描", systemImage: "qrcode.viewfinder")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.pink)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("扫描二维码")
            .sheet(isPresented: $isShowingScanner) {
                QRCodeScannerView(scannedText: $scannedText, isShowingScanner: $isShowingScanner, errorMessage: $errorMessage)
            }
            .alert("错误", isPresented: $showingErrorAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
