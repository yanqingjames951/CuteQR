import SwiftUI

@MainActor
final class QRCodeHistoryManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var items: [QRCodeHistoryItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    
    // MARK: - Constants
    @AppStorage("maxHistoryItems") private var maxHistoryItems = 100
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = true
    private let userDefaults: UserDefaults
    private let historyKey: String
    private let cloudKitManager: CloudKitManager
    
    // MARK: - Initialization
    init(userDefaults: UserDefaults = .standard, historyKey: String = "qrcode_history", cloudKitManager: CloudKitManager = .shared) {
        self.userDefaults = userDefaults
        self.historyKey = historyKey
        self.cloudKitManager = cloudKitManager
        loadHistoryIfNeeded()
    }
    
    // MARK: - Public Methods
    func addItem(_ item: QRCodeHistoryItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
        }
        
        items.insert(item, at: 0)
        
        if items.count > maxHistoryItems {
            items.removeLast()
        }
        
        Task { 
            await saveHistory() 
            if iCloudSyncEnabled && cloudKitManager.isICloudAvailable {
                await syncToCloud()
            }
        }
    }
    
    func removeItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        Task { 
            await saveHistory() 
            if iCloudSyncEnabled && cloudKitManager.isICloudAvailable {
                await syncToCloud()
            }
        }
    }
    
    func toggleFavorite(_ item: QRCodeHistoryItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        
        var updatedItem = items[index]
        updatedItem.isFavorite.toggle()
        items[index] = updatedItem
        Task { 
            await saveHistory() 
            if iCloudSyncEnabled && cloudKitManager.isICloudAvailable {
                await syncToCloud()
            }
        }
    }
    
    func clearHistory() {
        items.removeAll()
        Task { 
            await saveHistory() 
            if iCloudSyncEnabled && cloudKitManager.isICloudAvailable {
                await syncToCloud()
            }
        }
    }
    
    // MARK: - iCloud Sync Methods
    
    /// 同步历史记录到 iCloud
    func syncToCloud() async {
        guard iCloudSyncEnabled && cloudKitManager.isICloudAvailable else { return }
        
        isSyncing = true
        error = nil
        
        do {
            try await cloudKitManager.syncHistoryToCloud(items: items)
            lastSyncDate = Date()
        } catch {
            print("同步到 iCloud 失败: \(error.localizedDescription)")
            self.error = error
        }
        
        isSyncing = false
    }
    
    /// 从 iCloud 同步历史记录
    func syncFromCloud() async {
        guard iCloudSyncEnabled && cloudKitManager.isICloudAvailable else { return }
        
        isSyncing = true
        error = nil
        
        do {
            let cloudItems = try await cloudKitManager.fetchHistoryFromCloud()
            
            // 合并本地和云端数据
            mergeCloudItems(cloudItems)
            
            // 保存合并后的数据
            await saveHistory()
            
            lastSyncDate = Date()
        } catch {
            print("从 iCloud 同步失败: \(error.localizedDescription)")
            self.error = error
        }
        
        isSyncing = false
    }
    
    /// 双向同步 - 合并本地和云端数据
    func syncWithCloud() async {
        guard iCloudSyncEnabled && cloudKitManager.isICloudAvailable else { return }
        
        isSyncing = true
        error = nil
        
        do {
            // 先从云端获取数据并合并
            let cloudItems = try await cloudKitManager.fetchHistoryFromCloud()
            mergeCloudItems(cloudItems)
            
            // 然后将合并后的数据同步回云端
            try await cloudKitManager.syncHistoryToCloud(items: items)
            
            // 保存合并后的数据到本地
            await saveHistory()
            
            lastSyncDate = Date()
        } catch {
            print("与 iCloud 同步失败: \(error.localizedDescription)")
            self.error = error
        }
        
        isSyncing = false
    }
    
    /// 合并云端和本地数据
    private func mergeCloudItems(_ cloudItems: [QRCodeHistoryItem]) {
        // 创建本地项目的 ID 集合，用于快速查找
        let localItemIds = Set(items.map { $0.id })
        
        // 添加云端独有的项目
        for cloudItem in cloudItems {
            if !localItemIds.contains(cloudItem.id) {
                items.append(cloudItem)
            }
        }
        
        // 按日期排序
        items.sort { $0.date > $1.date }
        
        // 如果超出最大数量，移除最旧的项目
        if items.count > maxHistoryItems {
            items = Array(items.prefix(maxHistoryItems))
        }
    }
    
    /// 设置 iCloud 同步状态
    func setICloudSyncEnabled(_ enabled: Bool) {
        iCloudSyncEnabled = enabled
        if enabled {
            // 如果启用同步，立即进行一次同步
            Task { await syncFromCloud() }
        }
    }
    
    // MARK: - Private Methods
    private func loadHistoryIfNeeded() {
        Task { 
            await loadHistory() 
            // 如果启用了 iCloud 同步，尝试从云端加载数据
            if iCloudSyncEnabled && cloudKitManager.isICloudAvailable {
                await syncFromCloud()
            }
        }
    }
    
    private func loadHistory() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            guard let data = userDefaults.data(forKey: historyKey) else {
                isLoading = false
                return
            }
            
            let decoder = JSONDecoder()
            items = try decoder.decode([QRCodeHistoryItem].self, from: data)
        } catch {
            print("Error loading history: \(error.localizedDescription)")
            self.error = error
            items = []
            userDefaults.removeObject(forKey: historyKey)
        }
        
        isLoading = false
    }
    
    private func saveHistory() async {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(items)
            userDefaults.set(data, forKey: historyKey)
            error = nil
        } catch {
            print("Error saving history: \(error.localizedDescription)")
            self.error = error
        }
    }
}

#if DEBUG
extension QRCodeHistoryManager {
    static var preview: QRCodeHistoryManager {
        let manager = QRCodeHistoryManager()
        manager.addItem(QRCodeHistoryItem(type: .text, content: "Sample Text"))
        manager.addItem(QRCodeHistoryItem(type: .url, content: "https://example.com"))
        manager.addItem(QRCodeHistoryItem(type: .contact, content: "John Doe"))
        return manager
    }
}
#endif
