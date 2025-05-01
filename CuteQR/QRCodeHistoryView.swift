import SwiftUI

struct QRCodeHistoryView: View {
    // MARK: - Environment
    @EnvironmentObject private var historyManager: QRCodeHistoryManager
    
    // MARK: - State
    @State private var searchText = ""
    @State private var showingFavoriteOnly = false
    @State private var selectedType: QRCodeDataType?
    @State private var selectedItem: QRCodeHistoryItem?
    @State private var showingActionSheet = false
    @State private var showingShareSheet = false
    @State private var showingSharePreview = false
    @State private var itemToShare: QRCodeHistoryItem?
    @State private var shareImage: UIImage?
    
    // MARK: - Computed Properties
    private var filteredItems: [QRCodeHistoryItem] {
        historyManager.items.filter { item in
            let matchesFavorite = !showingFavoriteOnly || item.isFavorite
            let matchesType = selectedType == nil || item.type == selectedType
            let matchesSearch = searchText.isEmpty || item.content.localizedCaseInsensitiveContains(searchText)
            return matchesFavorite && matchesType && matchesSearch
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Group {
                if historyManager.isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .searchable(text: $searchText, prompt: "搜索历史记录")
            .navigationTitle("历史记录")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    filterMenu
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !filteredItems.isEmpty {
                        EditButton()
                    }
                }
            }
            .confirmationDialog("操作", isPresented: $showingActionSheet, presenting: selectedItem) { item in
                actionButtons(for: item)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = shareImage {
                    ShareSheet(
                        items: [image],
                        excludedActivityTypes: [.assignToContact, .addToReadingList],
                        callback: nil
                    )
                }
            }
            .sheet(isPresented: $showingSharePreview) {
                if let item = itemToShare, let image = shareImage {
                    QRCodeSharePreview(
                        qrCodeImage: image,
                        title: "分享二维码",
                        content: item.content,
                        type: item.type
                    )
                }
            }
            .alert("错误", isPresented: .constant(historyManager.error != nil)) {
                Button("确定", role: .cancel) {}
            } message: {
                if let error = historyManager.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Views
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("暂无历史记录", systemImage: "doc.text.magnifyingglass")
        } description: {
            if !searchText.isEmpty {
                Text("没有找到匹配的记录")
            } else if showingFavoriteOnly {
                Text("暂无收藏记录")
            } else {
                Text("生成或扫描二维码后会自动保存在这里")
            }
        }
    }
    
    private var historyListView: some View {
        List {
            ForEach(filteredItems) { item in
                Button(action: {
                    selectedItem = item
                    showingActionSheet = true
                }) {
                    QRCodeHistoryItemView(item: item)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    contextMenuItems(for: item)
                }
                .swipeActions(edge: .trailing) {
                    swipeActions(for: item)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .listStyle(.plain)
        .animation(.default, value: filteredItems)
    }
    
    private var filterMenu: some View {
        Menu {
            Toggle(isOn: $showingFavoriteOnly) {
                Label("仅显示收藏", systemImage: "star.fill")
            }
            
            Menu("类型筛选") {
                Button(action: { selectedType = nil }) {
                    Label("全部类型", systemImage: selectedType == nil ? "checkmark" : "")
                }
                
                ForEach(QRCodeDataType.allCases) { type in
                    Button(action: { selectedType = type }) {
                        Label(type.rawValue, systemImage: selectedType == type ? "checkmark" : "")
                    }
                }
            }
        } label: {
            Label("筛选", systemImage: "line.3.horizontal.decrease.circle")
        }
    }
    
    // MARK: - Actions
    @ViewBuilder
    private func actionButtons(for item: QRCodeHistoryItem) -> some View {
        Button("分享预览") {
            shareItemWithPreview(item)
        }
        
        Button("快速分享") {
            shareItem(item)
        }
        
        Button(item.isFavorite ? "取消收藏" : "收藏") {
            historyManager.toggleFavorite(item)
        }
        
        Button("删除", role: .destructive) {
            if let index = historyManager.items.firstIndex(where: { $0.id == item.id }) {
                deleteItems(at: IndexSet([index]))
            }
        }
    }
    
    @ViewBuilder
    private func contextMenuItems(for item: QRCodeHistoryItem) -> some View {
        Button(action: {
            shareItemWithPreview(item)
        }) {
            Label("分享预览", systemImage: "square.and.arrow.up.on.square")
        }
        
        Button(action: {
            shareItem(item)
        }) {
            Label("快速分享", systemImage: "square.and.arrow.up")
        }
        
        Button(action: {
            UIPasteboard.general.string = item.content
        }) {
            Label("复制内容", systemImage: "doc.on.doc")
        }
        
        Button(action: {
            historyManager.toggleFavorite(item)
        }) {
            Label(item.isFavorite ? "取消收藏" : "收藏", systemImage: item.isFavorite ? "star.slash" : "star")
        }
        
        Button(role: .destructive, action: {
            if let index = historyManager.items.firstIndex(where: { $0.id == item.id }) {
                deleteItems(at: IndexSet([index]))
            }
        }) {
            Label("删除", systemImage: "trash")
        }
    }
    
    @ViewBuilder
    private func swipeActions(for item: QRCodeHistoryItem) -> some View {
        Button(role: .destructive) {
            if let index = historyManager.items.firstIndex(where: { $0.id == item.id }) {
                deleteItems(at: IndexSet([index]))
            }
        } label: {
            Label("删除", systemImage: "trash")
        }
        
        Button {
            historyManager.toggleFavorite(item)
        } label: {
            Label(item.isFavorite ? "取消收藏" : "收藏", systemImage: item.isFavorite ? "star.slash" : "star")
        }
        .tint(item.isFavorite ? .gray : .yellow)
        
        Button {
            shareItem(item)
        } label: {
            Label("分享", systemImage: "square.and.arrow.up")
        }
        .tint(.blue)
    }
    
    private func deleteItems(at offsets: IndexSet) {
        historyManager.removeItems(at: offsets)
    }
    
    private func shareItem(_ item: QRCodeHistoryItem) {
        itemToShare = item
        if let qrImage = QRCodeGenerator.generateQRCode(from: item) {
            shareImage = qrImage
            showingShareSheet = true
        }
    }
    
    private func shareItemWithPreview(_ item: QRCodeHistoryItem) {
        itemToShare = item
        if let qrImage = QRCodeGenerator.generateQRCode(from: item) {
            shareImage = qrImage
            showingSharePreview = true
        }
    }
}

// MARK: - History Item View
struct QRCodeHistoryItemView: View {
    let item: QRCodeHistoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(item.type.rawValue, systemImage: item.type.systemImage)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                if item.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            Text(item.content)
                .lineLimit(2)
            
            Text(item.date.formatted())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    QRCodeHistoryView()
        .environmentObject(QRCodeHistoryManager.preview)
}
