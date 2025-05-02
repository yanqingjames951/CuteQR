import SwiftUI
import CoreImage.CIFilterBuiltins
import Photos

// MARK: - View Model
@MainActor
final class GenerateQRViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var generatedQRCode: UIImage?
    @Published var selectedLogo: UIImage?
    @Published var qrCodeColor = Color.black
    @Published var backgroundColor = Color.white
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var logoSize: CGFloat = 0.2
    @Published var logoCornerRadius: CGFloat = 0.0
    @Published var qrCodeStyle = QRCodeStyle.square
    @Published var showingSavedAlert = false
    @Published var selectedType: QRCodeDataType = .text
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    private let historyManager: QRCodeHistoryManager
    
    init(historyManager: QRCodeHistoryManager) {
        self.historyManager = historyManager
    }
    
    enum QRCodeStyle: String, CaseIterable {
        case square = "方形"
        case dot = "圆点"
        case round = "圆角"
    }
    
    func generateQRCode() {
        guard !inputText.isEmpty else {
            showError = true
            errorMessage = "请输入内容"
            return
        }
        
        guard let data = inputText.data(using: .utf8) else {
            showError = true
            errorMessage = "无法生成二维码"
            return
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else {
            showError = true
            errorMessage = "生成二维码失败"
            return
        }
        
        // 应用样式
        var styledQRCode = outputImage
        switch qrCodeStyle {
        case .dot:
            styledQRCode = applyDotStyle(to: outputImage)
        case .round:
            styledQRCode = applyRoundStyle(to: outputImage)
        default:
            break
        }
        
        let coloredQR = applyColors(to: styledQRCode)
        
        guard let cgImage = context.createCGImage(coloredQR, from: coloredQR.extent) else {
            showError = true
            errorMessage = "处理二维码图像失败"
            return
        }
        
        var finalImage = UIImage(cgImage: cgImage)
        
        if let logo = selectedLogo {
            finalImage = QRCodeUtils.addLogo(to: finalImage, logo: logo, size: logoSize, cornerRadius: logoCornerRadius)
        }
        
        generatedQRCode = finalImage
        saveToHistory()
    }
    
    private func applyDotStyle(to qrCode: CIImage) -> CIImage {
        let extent = qrCode.extent
        
        guard let cgImage = context.createCGImage(qrCode, from: extent) else {
            return qrCode
        }
        
        let scale = UIScreen.main.scale
        let size = CGSize(width: extent.width * scale, height: extent.height * scale)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return qrCode
        }
        
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        let width = cgImage.width
        let height = cgImage.height
        let dotSize = CGSize(width: size.width / CGFloat(width), height: size.height / CGFloat(height))
        
        if let pixelData = cgImage.dataProvider?.data {
            let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
            
            for y in 0..<height {
                for x in 0..<width {
                    let pixelInfo = ((width * y) + x) * 4
                    let r = CGFloat(data[pixelInfo]) / 255.0
                    
                    if r < 0.5 {
                        let pointX = CGFloat(x) * dotSize.width
                        let pointY = CGFloat(y) * dotSize.height
                        let dotRect = CGRect(x: pointX, y: pointY, width: dotSize.width, height: dotSize.height)
                        context.setFillColor(UIColor.black.cgColor)
                        context.fillEllipse(in: dotRect.insetBy(dx: dotSize.width * 0.1, dy: dotSize.height * 0.1))
                    }
                }
            }
        }
        
        guard let resultImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return qrCode
        }
        
        return CIImage(image: resultImage) ?? qrCode
    }
    
    private func applyRoundStyle(to qrCode: CIImage) -> CIImage {
        let extent = qrCode.extent
        
        guard let cgImage = context.createCGImage(qrCode, from: extent) else {
            return qrCode
        }
        
        let scale = UIScreen.main.scale
        let size = CGSize(width: extent.width * scale, height: extent.height * scale)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return qrCode
        }
        
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        let width = cgImage.width
        let height = cgImage.height
        let dotSize = CGSize(width: size.width / CGFloat(width), height: size.height / CGFloat(height))
        
        if let pixelData = cgImage.dataProvider?.data {
            let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
            
            for y in 0..<height {
                for x in 0..<width {
                    let pixelInfo = ((width * y) + x) * 4
                    let r = CGFloat(data[pixelInfo]) / 255.0
                    
                    if r < 0.5 {
                        let pointX = CGFloat(x) * dotSize.width
                        let pointY = CGFloat(y) * dotSize.height
                        let dotRect = CGRect(x: pointX, y: pointY, width: dotSize.width, height: dotSize.height)
                        let path = UIBezierPath(roundedRect: dotRect.insetBy(dx: dotSize.width * 0.05, dy: dotSize.height * 0.05),
                                              cornerRadius: dotSize.width * 0.3)
                        context.setFillColor(UIColor.black.cgColor)
                        path.fill()
                    }
                }
            }
        }
        
        guard let resultImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return qrCode
        }
        
        return CIImage(image: resultImage) ?? qrCode
    }
    
    private func applyColors(to qrCode: CIImage) -> CIImage {
        let parameters: [String: Any] = [
            "inputColor0": CIColor(color: UIColor(qrCodeColor)),
            "inputColor1": CIColor(color: UIColor(backgroundColor))
        ]
        
        let coloredQR = qrCode.applyingFilter("CIFalseColor", parameters: parameters)
        let extent = coloredQR.extent
        let transform = CGAffineTransform(scaleX: 200.0/extent.width, y: 200.0/extent.height)
        return coloredQR.transformed(by: transform)
    }
    
    func saveToHistory() {
        let historyItem = QRCodeHistoryItem(type: selectedType, content: inputText)
        historyManager.addItem(historyItem)
    }
    
    func saveToPhotos() {
        guard generatedQRCode != nil else { return }
        
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                self.showError = true
                self.errorMessage = "需要相册访问权限"
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: self.generatedQRCode!)
            }) { success, error in
                if success {
                    self.showingSavedAlert = true
                } else {
                    self.showError = true
                    self.errorMessage = "保存失败：\(error?.localizedDescription ?? "未知错误")"
                }
            }
        }
    }
}

// MARK: - Main View
struct GenerateQRView: View {
    @StateObject private var viewModel: GenerateQRViewModel
    @State private var showingImagePicker = false
    @State private var showingShareSheet = false
    @FocusState private var isInputFocused: Bool
    
    init(historyManager: QRCodeHistoryManager) {
        _viewModel = StateObject(wrappedValue: GenerateQRViewModel(historyManager: historyManager))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isInputFocused = false
                    }
                
                Form {
                    // QR Code Type Section
                    Section {
                        Picker("类型", selection: $viewModel.selectedType) {
                            ForEach(QRCodeDataType.allCases, id: \.self) { type in
                                Label(type.description, systemImage: type.systemImage)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                    
                    // Input Section
                    Section {
                        TextField("输入内容", text: $viewModel.inputText)
                            .textFieldStyle(.roundedBorder)
                            .focused($isInputFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                isInputFocused = false
                            }
                        
                        Button(action: {
                            isInputFocused = false
                            viewModel.generateQRCode()
                        }) {
                            HStack(spacing: 8) {
                                Spacer()
                                Image(systemName: "qrcode.viewfinder")
                                Text("生成二维码")
                                    .font(.body)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.pastelPink)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Style Section
                    Section("样式") {
                        ColorPicker("二维码颜色", selection: $viewModel.qrCodeColor)
                        ColorPicker("背景颜色", selection: $viewModel.backgroundColor)
                        
                        Picker("样式", selection: $viewModel.qrCodeStyle) {
                            ForEach(GenerateQRViewModel.QRCodeStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Logo Section
                    if let qrCode = viewModel.generatedQRCode {
                        Section("Logo") {
                            HStack {
                                if let logo = viewModel.selectedLogo {
                                    Image(uiImage: logo)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 44)
                                }
                                
                                Button(action: { showingImagePicker = true }) {
                                    Label(viewModel.selectedLogo == nil ? "添加 Logo" : "更换 Logo",
                                          systemImage: "photo")
                                }
                            }
                            
                            if viewModel.selectedLogo != nil {
                                Slider(value: $viewModel.logoSize, in: 0.1...0.3, step: 0.05) {
                                    Text("Logo 大小")
                                }
                                Slider(value: $viewModel.logoCornerRadius, in: 0...20, step: 2) {
                                    Text("Logo 圆角")
                                }
                            }
                        }
                        
                        // Preview Section
                        Section {
                            Image(uiImage: qrCode)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(12)
                            
                            HStack {
                                Button(action: { showingShareSheet = true }) {
                                    Label("分享", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(.bordered)
                                
                                Button(action: viewModel.saveToPhotos) {
                                    Label("保存到相册", systemImage: "square.and.arrow.down")
                                }
                                .buttonStyle(.bordered)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle("生成二维码")
            .alert("错误", isPresented: $viewModel.showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("已保存", isPresented: $viewModel.showingSavedAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text("二维码已保存到相册")
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $viewModel.selectedLogo, isPresented: $showingImagePicker)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let qrCode = viewModel.generatedQRCode {
                    ShareSheet(activityItems: [qrCode])
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        isInputFocused = false
                    }
                }
            }
        }
    }
}

struct GenerateQRView_Previews: PreviewProvider {
    static var previews: some View {
        GenerateQRView(historyManager: QRCodeHistoryManager())
    }
}