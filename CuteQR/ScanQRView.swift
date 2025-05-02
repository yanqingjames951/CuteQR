import SwiftUI
import AVFoundation

// MARK: - ViewModel
@MainActor
final class ScanQRViewModel: ObservableObject {
    @Published var scannedCode: String?
    @Published var isScanning: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var torchIsOn: Bool = false
    
    var historyManager: QRCodeHistoryManager
    var copiedMessageManager: CopiedMessageManager
    
    init(historyManager: QRCodeHistoryManager, copiedMessageManager: CopiedMessageManager) {
        self.historyManager = historyManager
        self.copiedMessageManager = copiedMessageManager
    }
    
    func handleScannedCode(_ code: String) {
        scannedCode = code
        isScanning = false
        
        // 尝试检测二维码类型
        let detectedType = detectCodeType(code)
        
        // 添加到历史记录
        let historyItem = QRCodeHistoryItem(type: detectedType, content: code)
        historyManager.addItem(historyItem)
    }
    
    func resetScan() {
        scannedCode = nil
        isScanning = true
    }
    
    func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        copiedMessageManager.showMessage()
    }
    
    private func detectCodeType(_ code: String) -> QRCodeDataType {
        let lowercasedCode = code.lowercased()
        
        if lowercasedCode.hasPrefix("http") || lowercasedCode.hasPrefix("www.") {
            return .url
        } else if lowercasedCode.hasPrefix("begin:vcard") {
            return .contact
        } else if lowercasedCode.hasPrefix("wifi:") {
            return .wifi
        } else if lowercasedCode.hasPrefix("geo:") {
            return .location
        } else {
            return .text
        }
    }
}

// MARK: - Scanner View
struct CodeScannerView: UIViewRepresentable {
    @Binding var isScanning: Bool
    let onCodeScanned: (String) -> Void
    @Binding var torchIsOn: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let captureSession = AVCaptureSession()
        
        context.coordinator.captureSession = captureSession
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return view
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return view
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return view
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr, .ean8, .ean13, .pdf417]
        } else {
            return view
        }
        
        context.coordinator.videoCaptureDevice = videoCaptureDevice
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if context.coordinator.previewLayer?.frame != uiView.layer.bounds {
            context.coordinator.previewLayer?.frame = uiView.layer.bounds
        }
        
        if isScanning != context.coordinator.isScanning {
            context.coordinator.isScanning = isScanning
            
            if isScanning {
                context.coordinator.captureSession?.startRunning()
            } else {
                context.coordinator.captureSession?.stopRunning()
            }
        }
        
        if torchIsOn != context.coordinator.torchIsOn {
            context.coordinator.torchIsOn = torchIsOn
            try? context.coordinator.videoCaptureDevice?.lockForConfiguration()
            context.coordinator.videoCaptureDevice?.torchMode = torchIsOn ? .on : .off
            context.coordinator.videoCaptureDevice?.unlockForConfiguration()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: CodeScannerView
        var captureSession: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        var isScanning: Bool = true
        var torchIsOn: Bool = false
        var videoCaptureDevice: AVCaptureDevice?
        
        init(_ parent: CodeScannerView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard isScanning else { return }
            
            if let metadataObject = metadataObjects.first,
               let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
               let stringValue = readableObject.stringValue {
                
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                parent.onCodeScanned(stringValue)
            }
        }
    }
}

// MARK: - Main View
struct ScanQRView: View {
    @ObservedObject var viewModel: ScanQRViewModel
    @EnvironmentObject private var historyManager: QRCodeHistoryManager
    @EnvironmentObject private var copiedMessageManager: CopiedMessageManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isScanning {
                    CodeScannerView(
                        isScanning: $viewModel.isScanning,
                        onCodeScanned: viewModel.handleScannedCode,
                        torchIsOn: $viewModel.torchIsOn
                    )
                    .edgesIgnoringSafeArea(.top) // 只忽略顶部安全区域，保留底部
                    
                    VStack {
                        Spacer()
                        
                        HStack {
                            Button(action: {
                                viewModel.torchIsOn.toggle()
                            }) {
                                Image(systemName: viewModel.torchIsOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(.bottom, 40)
                        }
                    }
                    .padding()
                    
                    // 扫描框
                    Rectangle()
                        .strokeBorder(Color.pastelPink, lineWidth: 3)
                        .frame(width: 250, height: 250)
                        .background(Color.clear)
                        .overlay(
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 80))
                                .foregroundColor(Color.pastelPink.opacity(0.3))
                        )
                } else if let code = viewModel.scannedCode {
                    // 扫描结果显示
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("扫描结果")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(code)
                                .font(.body)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                            
                            HStack {
                                Button(action: {
                                    viewModel.copyToClipboard(code)
                                }) {
                                    Label("复制", systemImage: "doc.on.doc")
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.pastelPink)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                
                                Button(action: {
                                    viewModel.resetScan()
                                }) {
                                    Label("继续扫描", systemImage: "qrcode.viewfinder")
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.pastelBlue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("扫描二维码")
            .navigationBarTitleDisplayMode(.inline)
            .alert("错误", isPresented: $viewModel.showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                viewModel.historyManager = historyManager
                viewModel.copiedMessageManager = copiedMessageManager
                viewModel.isScanning = true
            }
        }
    }
}
