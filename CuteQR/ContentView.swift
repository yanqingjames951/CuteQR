import SwiftUI
import CoreImage.CIFilterBuiltins
import AVFoundation

struct ContentView: View {
    @StateObject private var historyManager = QRCodeHistoryManager()
    @StateObject private var copiedMessageManager = CopiedMessageManager()
    @AppStorage("selectedTab") private var selectedTab = 0
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                GenerateQRView(historyManager: historyManager)
                    .tabItem {
                        Label("生成", systemImage: "qrcode.viewfinder")
                    }
                    .tag(0)
                
                ScanQRView(viewModel: ScanQRViewModel(historyManager: historyManager, copiedMessageManager: copiedMessageManager))
                    .tabItem {
                        Label("扫描", systemImage: "camera.viewfinder")
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
            
            // Copied Message Overlay
            if copiedMessageManager.showCopiedMessage {
                VStack {
                    Spacer()
                    Text("已复制到剪贴板")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.pastelPink.opacity(0.9))
                                .shadow(radius: 5)
                        )
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                        .padding(.bottom, 80)
                }
                .animation(.spring(), value: copiedMessageManager.showCopiedMessage)
                .zIndex(1)
            }
        }
        .environmentObject(historyManager)
        .environmentObject(copiedMessageManager)
        .tint(.pastelPink)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
