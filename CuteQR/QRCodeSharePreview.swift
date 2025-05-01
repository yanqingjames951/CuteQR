import SwiftUI

struct QRCodeSharePreview: View {
    let qrCodeImage: UIImage
    let title: String
    let content: String
    let type: QRCodeDataType
    @State private var showingShareSheet = false
    @State private var showCopiedFeedback = false
    @State private var showSavedFeedback = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(UIColor.systemBackground).opacity(0.8))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text("分享预览")
                    .font(.headline)
                
                Spacer()
                
                // 平衡布局的占位视图
                Color.clear
                    .frame(width: 32, height: 32)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Image(uiImage: qrCodeImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .animation(.spring(), value: qrCodeImage)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(type.rawValue, systemImage: type.systemImage)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(Date().formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
            .padding(.horizontal)
            
            Spacer()
            
            HStack(spacing: 30) {
                Button(action: {
                    UIPasteboard.general.string = content
                    withAnimation {
                        showCopiedFeedback = true
                    }
                    // 2秒后自动隐藏反馈
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showCopiedFeedback = false
                        }
                    }
                }) {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }
                        
                        Text(showCopiedFeedback ? "已复制" : "复制")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
                
                Button(action: {
                    showingShareSheet = true
                }) {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                        }
                        
                        Text("分享")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
                
                Button(action: {
                    UIImageWriteToSavedPhotosAlbum(qrCodeImage, nil, nil, nil)
                    withAnimation {
                        showSavedFeedback = true
                    }
                    // 2秒后自动隐藏反馈
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showSavedFeedback = false
                        }
                    }
                }) {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(Color.purple.opacity(0.1))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: showSavedFeedback ? "checkmark" : "photo")
                                .font(.system(size: 20))
                                .foregroundColor(.purple)
                        }
                        
                        Text(showSavedFeedback ? "已保存" : "保存")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(
                items: [qrCodeImage, content],
                excludedActivityTypes: [.assignToContact, .addToReadingList],
                callback: nil
            )
        }
    }
}

#Preview {
    QRCodeSharePreview(
        qrCodeImage: UIImage(systemName: "qrcode")!,
        title: "分享二维码",
        content: "https://example.com",
        type: .url
    )
}
