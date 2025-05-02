import SwiftUI

struct QRCodeHistoryView: View {
    @EnvironmentObject private var historyManager: QRCodeHistoryManager
    @EnvironmentObject private var copiedMessageManager: CopiedMessageManager
    @State private var searchText = ""
    @State private var selectedFilter: QRCodeDataType? = nil
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: QRCodeHistoryItem? = nil
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Section
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterButton(title: "全部", systemImage: "list.bullet", isSelected: selectedFilter == nil) {
                            selectedFilter = nil
                        }
                        
                        ForEach(QRCodeDataType.allCases, id: \.self) { type in
                            FilterButton(
                                title: type.description,
                                systemImage: type.systemImage,
                                isSelected: selectedFilter == type
                            ) {
                                selectedFilter = type
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(UIColor.secondarySystemBackground))
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("搜索", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                if filteredItems.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text(historyManager.items.isEmpty ? "暂无历史记录" : "没有找到匹配的记录")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if !historyManager.items.isEmpty {
                            Button(action: {
                                searchText = ""
                                selectedFilter = nil
                            }) {
                                Text("清除筛选")
                                    .foregroundColor(.pastelPink)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemBackground))
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            HistoryItemRow(item: item, onCopy: {
                                UIPasteboard.general.string = item.content
                                copiedMessageManager.showMessage()
                            }, onFavorite: {
                                historyManager.toggleFavorite(item)
                            }, onDelete: {
                                itemToDelete = item
                                showingDeleteAlert = true
                            })
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("历史记录")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingClearAlert = true
                    }) {
                        Text("清空")
                            .foregroundColor(.red)
                    }
                    .disabled(historyManager.items.isEmpty)
                }
            }
            .alert("删除记录", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    if let item = itemToDelete {
                        historyManager.removeItem(item)
                    }
                }
            } message: {
                Text("确定要删除这条记录吗？")
            }
            .alert("清空历史", isPresented: $showingClearAlert) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) {
                    historyManager.clearHistory()
                }
            } message: {
                Text("确定要清空所有历史记录吗？此操作无法撤销。")
            }
        }
    }
    
    private var filteredItems: [QRCodeHistoryItem] {
        historyManager.items.filter { item in
            let matchesFilter = selectedFilter == nil || item.type == selectedFilter
            let matchesSearch = searchText.isEmpty || 
                item.content.localizedCaseInsensitiveContains(searchText) ||
                item.type.description.localizedCaseInsensitiveContains(searchText)
            return matchesFilter && matchesSearch
        }
    }
}

struct FilterButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.pastelPink : Color(UIColor.tertiarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct HistoryItemRow: View {
    let item: QRCodeHistoryItem
    let onCopy: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: item.type.systemImage)
                    .foregroundColor(.pastelPink)
                
                Text(item.type.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(item.content)
                .lineLimit(2)
                .font(.body)
            
            HStack {
                Button(action: onCopy) {
                    Label("复制", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                Button(action: onFavorite) {
                    Image(systemName: item.isFavorite ? "star.fill" : "star")
                        .foregroundColor(item.isFavorite ? .yellow : .gray)
                }
                .buttonStyle(.plain)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: item.date)
    }
}

#Preview {
    QRCodeHistoryView()
        .environmentObject(QRCodeHistoryManager.preview)
        .environmentObject(CopiedMessageManager())
}
