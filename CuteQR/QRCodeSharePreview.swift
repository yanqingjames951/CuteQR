import SwiftUI
import UIKit

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
                    Image(systemName: type.systemImage)
                        .foregroundColor(.pastelPink)
                    Text(title)
                        .font(.headline)
                }
                
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            .padding(.horizontal)
            
            Spacer()
            
            HStack(spacing: 30) {
                Button(action: {
                    UIPasteboard.general.string = content
                    withAnimation {
                        showCopiedFeedback = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            showCopiedFeedback = false
                        }
                    }
                }) {
                    VStack {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 24))
                        Text("复制")
                            .font(.caption)
                    }
                    .frame(width: 60, height: 60)
                }
                .foregroundColor(.pastelPink)
                
                Button(action: {
                    UIImageWriteToSavedPhotosAlbum(qrCodeImage, nil, nil, nil)
                    withAnimation {
                        showSavedFeedback = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            showSavedFeedback = false
                        }
                    }
                }) {
                    VStack {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 24))
                        Text("保存")
                            .font(.caption)
                    }
                    .frame(width: 60, height: 60)
                }
                .foregroundColor(.pastelPink)
                
                Button(action: {
                    showingShareSheet = true
                }) {
                    VStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 24))
                        Text("分享")
                            .font(.caption)
                    }
                    .frame(width: 60, height: 60)
                }
                .foregroundColor(.pastelPink)
            }
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [qrCodeImage, content])
        }
        .overlay(
            ZStack {
                if showCopiedFeedback {
                    feedbackToast(message: "已复制到剪贴板")
                }
                if showSavedFeedback {
                    feedbackToast(message: "已保存到相册")
                }
            }
        )
    }
    
    private func feedbackToast(message: String) -> some View {
        Text(message)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.pastelPink.opacity(0.8))
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
            .transition(.move(edge: .bottom).combined(with: .opacity))
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
