import SwiftUI
import CoreImage.CIFilterBuiltins
import Photos
import UIKit

struct GenerateQRView: View {
    @State private var inputText = ""
    @State private var generatedQRCode: UIImage? = nil
    @State private var showingImagePicker = false
    @State private var selectedLogo: UIImage? = nil
    @State private var qrCodeColor = Color.black
    @State private var backgroundColor = Color.white
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var logoSize: CGFloat = 0.2
    @State private var logoCornerRadius: CGFloat = 0.0
    @State private var qrCodeStyle = QRCodeStyle.square
    @State private var showingSavedAlert = false
    @State private var selectedType: QRCodeDataType = .text
    @State private var showingHistory = false
    @State private var showingShareSheet = false
    @EnvironmentObject private var historyManager: QRCodeHistoryManager

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    enum QRCodeStyle: String, CaseIterable {
        case square = "方形"
        case dot = "圆点"
        case round = "圆角"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    typePickerSection
                    inputSection
                    qrCodeDisplaySection
                    styleSettingsSection
                    historyButton
                }
            }
            .navigationTitle("生成二维码")
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedLogo, isPresented: $showingImagePicker)
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("已保存", isPresented: $showingSavedAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("二维码已保存到相册")
        }
        .sheet(isPresented: $showingHistory) {
            QRCodeHistoryView()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = generatedQRCode {
                ShareSheet(
                    items: [image],
                    excludedActivityTypes: [
                        .assignToContact,
                        .addToReadingList
                    ],
                    callback: { activity, completed, items, error in
                        if completed {
                            // 可以在这里添加分享成功后的操作
                        }
                    }
                )
            }
        }
    }
    
    private var typePickerSection: some View {
        Picker("二维码类型", selection: $selectedType) {
            ForEach(QRCodeDataType.allCases) { type in
                Label(type.rawValue, systemImage: type.systemImage)
                    .tag(type)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .padding()
        .onChange(of: selectedType) { _, _ in
            generateQRCode()
        }
    }
    
    private var inputSection: some View {
        QRCodeInputView(type: selectedType, qrContent: $inputText)
            .padding()
            .onChange(of: inputText) { newValue, _ in
                if !newValue.isEmpty {
                    generateQRCode()
                }
            }
    }
    
    private var qrCodeDisplaySection: some View {
        Group {
            if generatedQRCode != nil {
                Image(uiImage: generatedQRCode!)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .contextMenu {
                        Button(action: saveToPhotos) {
                            Label("保存到相册", systemImage: "square.and.arrow.down")
                        }
                        Button(action: shareQRCode) {
                            Label("分享", systemImage: "square.and.arrow.up")
                        }
                    }
            }
        }
    }
    
    private var styleSettingsSection: some View {
        VStack(spacing: 20) {
            qrCodeStylePicker
            colorPickers
            logoSettings
        }
        .padding()
    }
    
    private var qrCodeStylePicker: some View {
        Picker("二维码样式", selection: $qrCodeStyle) {
            ForEach(QRCodeStyle.allCases, id: \.self) { style in
                Text(style.rawValue).tag(style)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: qrCodeStyle) { oldValue, newValue in
            generateQRCode()
        }
    }
    
    private var colorPickers: some View {
        VStack {
            ColorPicker("二维码颜色", selection: $qrCodeColor)
                .onChange(of: qrCodeColor) { oldValue, newValue in
                    generateQRCode()
                }
            ColorPicker("背景颜色", selection: $backgroundColor)
                .onChange(of: backgroundColor) { oldValue, newValue in
                    generateQRCode()
                }
        }
    }
    
    private var logoSettings: some View {
        VStack(alignment: .leading) {
            Button(action: { showingImagePicker = true }) {
                Label(selectedLogo == nil ? "添加Logo" : "更换Logo", systemImage: "photo")
                    .foregroundColor(.blue)
            }
            
            if selectedLogo != nil {
                logoSliders
            }
        }
        .onChange(of: selectedLogo) { oldValue, newValue in
            generateQRCode()
        }
    }
    
    private var logoSliders: some View {
        VStack {
            Slider(value: $logoSize, in: 0.1...0.3) {
                Text("Logo 大小: \(Int(logoSize * 100))%")
            }
            .onChange(of: logoSize) { oldValue, newValue in
                generateQRCode()
            }
            
            Slider(value: $logoCornerRadius, in: 0...20) {
                Text("Logo 圆角: \(Int(logoCornerRadius))px")
            }
            .onChange(of: logoCornerRadius) { oldValue, newValue in
                generateQRCode()
            }
        }
    }
    
    private var historyButton: some View {
        Button(action: { showingHistory = true }) {
            Image(systemName: "clock")
        }
        .padding()
    }
    
    private func generateQRCode() {
        guard !inputText.isEmpty else { return }
        
        // 设置二维码内容
        let data = inputText.data(using: .utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        // 获取输出图像
        guard let qrCodeImage = filter.outputImage else {
            showErrorMessage("生成二维码失败")
            return
        }
        
        // 应用样式
        var styledQRCode = qrCodeImage
        switch qrCodeStyle {
        case .dot:
            styledQRCode = applyDotStyle(to: qrCodeImage)
        case .round:
            styledQRCode = applyRoundStyle(to: qrCodeImage)
        default:
            break
        }
        
        let coloredQR = applyColors(to: styledQRCode)
        
        guard let cgImage = context.createCGImage(coloredQR, from: coloredQR.extent) else {
            showErrorMessage("处理二维码图像失败")
            return
        }
        
        var finalImage = UIImage(cgImage: cgImage)
        
        if let logo = selectedLogo {
            finalImage = QRCodeUtils.addLogo(to: finalImage, logo: logo, size: logoSize, cornerRadius: logoCornerRadius)
        }
        
        generatedQRCode = finalImage
        
        // 保存到历史记录
        saveToHistory()
    }
    
    private func saveToHistory() {
        let historyItem = QRCodeHistoryItem(type: selectedType, content: inputText)
        historyManager.addItem(historyItem)
    }
    
    private func applyDotStyle(to qrCode: CIImage) -> CIImage {
        let extent = qrCode.extent
        
        // 创建一个 CGImage
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(qrCode, from: extent) else {
            return qrCode
        }
        
        // 创建一个位图上下文
        let scale = UIScreen.main.scale
        let size = CGSize(width: extent.width * scale, height: extent.height * scale)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return qrCode
        }
        
        // 设置背景为白色
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // 获取二维码像素数据
        let width = cgImage.width
        let height = cgImage.height
        
        // 计算每个点的大小
        let dotSize = CGSize(width: size.width / CGFloat(width), height: size.height / CGFloat(height))
        
        // 遍历二维码像素
        for y in 0..<height {
            for x in 0..<width {
                // 获取像素颜色
                let pixelData = cgImage.dataProvider?.data
                let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
                let pixelInfo = ((width * y) + x) * 4
                
                let r = CGFloat(data[pixelInfo]) / 255.0
                let g = CGFloat(data[pixelInfo + 1]) / 255.0
                let b = CGFloat(data[pixelInfo + 2]) / 255.0
                
                // 如果是黑色像素，绘制一个圆点
                if r < 0.5 && g < 0.5 && b < 0.5 {
                    let pointX = CGFloat(x) * dotSize.width
                    let pointY = CGFloat(y) * dotSize.height
                    let dotRect = CGRect(x: pointX, y: pointY, width: dotSize.width, height: dotSize.height)
                    
                    // 绘制圆点
                    context.setFillColor(UIColor.black.cgColor)
                    context.fillEllipse(in: dotRect.insetBy(dx: dotSize.width * 0.1, dy: dotSize.height * 0.1))
                }
            }
        }
        
        // 获取结果图像
        guard let resultImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return qrCode
        }
        
        // 转换回 CIImage
        let resultCIImage = CIImage(image: resultImage) ?? qrCode
        return resultCIImage
    }
    
    private func applyRoundStyle(to qrCode: CIImage) -> CIImage {
        let extent = qrCode.extent
        
        // 创建一个 CGImage
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(qrCode, from: extent) else {
            return qrCode
        }
        
        // 创建一个位图上下文
        let scale = UIScreen.main.scale
        let size = CGSize(width: extent.width * scale, height: extent.height * scale)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return qrCode
        }
        
        // 设置背景为白色
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // 获取二维码像素数据
        let width = cgImage.width
        let height = cgImage.height
        
        // 计算每个点的大小
        let dotSize = CGSize(width: size.width / CGFloat(width), height: size.height / CGFloat(height))
        
        // 遍历二维码像素
        for y in 0..<height {
            for x in 0..<width {
                // 获取像素颜色
                let pixelData = cgImage.dataProvider?.data
                let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
                let pixelInfo = ((width * y) + x) * 4
                
                let r = CGFloat(data[pixelInfo]) / 255.0
                let g = CGFloat(data[pixelInfo + 1]) / 255.0
                let b = CGFloat(data[pixelInfo + 2]) / 255.0
                
                // 如果是黑色像素，绘制一个圆角矩形
                if r < 0.5 && g < 0.5 && b < 0.5 {
                    let pointX = CGFloat(x) * dotSize.width
                    let pointY = CGFloat(y) * dotSize.height
                    let dotRect = CGRect(x: pointX, y: pointY, width: dotSize.width, height: dotSize.height)
                    
                    // 绘制圆角矩形
                    let path = UIBezierPath(roundedRect: dotRect.insetBy(dx: dotSize.width * 0.05, dy: dotSize.height * 0.05), 
                                           cornerRadius: dotSize.width * 0.3)
                    context.setFillColor(UIColor.black.cgColor)
                    path.fill()
                }
            }
        }
        
        // 获取结果图像
        guard let resultImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return qrCode
        }
        
        // 转换回 CIImage
        let resultCIImage = CIImage(image: resultImage) ?? qrCode
        return resultCIImage
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
    
    private func saveToPhotos() {
        guard generatedQRCode != nil else { return }
        
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                showErrorMessage("需要相册访问权限")
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: self.generatedQRCode!)
            }) { success, error in
                if success {
                    showingSavedAlert = true
                } else {
                    showErrorMessage("保存失败：\(error?.localizedDescription ?? "未知错误")")
                }
            }
        }
    }
    
    private func shareQRCode() {
        if generatedQRCode != nil {
            showingShareSheet = true
        } else {
            showErrorMessage("请先生成二维码")
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

struct GenerateQRView_Previews: PreviewProvider {
    static var previews: some View {
        GenerateQRView()
    }
}