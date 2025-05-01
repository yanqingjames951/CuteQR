import Foundation
import CloudKit

/// 管理 CloudKit 同步的类
class CloudKitManager: ObservableObject {
    /// 单例实例
    static let shared = CloudKitManager()
    
    #if !targetEnvironment(simulator)
    /// CloudKit 容器
    private let container: CKContainer
    /// 私有数据库
    private let privateDatabase: CKDatabase
    #endif
    
    /// 同步状态
    @Published var syncStatus: SyncStatus = .idle
    /// 上次同步时间
    @Published var lastSyncDate: Date?
    /// 是否已启用 iCloud
    @Published var isICloudAvailable = false
    
    /// 同步状态枚举
    enum SyncStatus {
        case idle
        case syncing
        case success
        case failed(Error)
    }
    
    private init() {
        #if targetEnvironment(simulator)
        // 模拟器环境下，跳过 CloudKit 配置
        print("模拟器环境：CloudKit 功能已禁用")
        isICloudAvailable = false
        #else
        // 真机环境下，正常初始化 CloudKit
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
        
        // 检查 iCloud 状态
        Task { [weak self] in
            await self?.checkICloudStatus()
        }
        #endif
    }
    
    /// 检查 iCloud 账户状态
    @MainActor
    func checkICloudStatus() async {
        #if targetEnvironment(simulator)
        // 模拟器环境下，直接返回不可用状态
        self.isICloudAvailable = false
        print("模拟器环境：iCloud 状态检查已跳过")
        #else
        // 将复杂表达式拆分为多个简单步骤，避免编译器超时
        do {
            // 步骤1：获取账户状态
            let status = try await container.accountStatus()
            
            // 步骤2：根据状态设置可用性和打印信息
            handleAccountStatus(status)
        } catch {
            // 步骤3：处理错误
            handleAccountError(error)
        }
        #endif
    }
    
    /// 处理账户状态 - 将复杂逻辑拆分为单独的方法
    private func handleAccountStatus(_ status: CKAccountStatus) {
        switch status {
        case .available:
            self.isICloudAvailable = true
            print("iCloud 状态: 可用")
        case .noAccount:
            self.isICloudAvailable = false
            print("iCloud 状态: 无账户")
        case .restricted:
            self.isICloudAvailable = false
            print("iCloud 状态: 受限制")
        case .couldNotDetermine:
            self.isICloudAvailable = false
            print("iCloud 状态: 无法确定")
        default:
            self.isICloudAvailable = false
            print("iCloud 状态: 未知状态 - \(status)")
        }
    }
    
    /// 处理账户错误 - 将错误处理逻辑拆分为单独的方法
    private func handleAccountError(_ error: Error) {
        print("iCloud 账户状态检查失败: \(error.localizedDescription)")
        self.isICloudAvailable = false
    }
    
    /// 同步历史记录到 iCloud
    @MainActor
    func syncHistoryToCloud(items: [QRCodeHistoryItem]) async throws {
        #if targetEnvironment(simulator)
        // 模拟器环境下，模拟成功状态
        print("模拟器环境：同步操作已跳过，数据仅保存在本地")
        syncStatus = .success
        lastSyncDate = Date()
        #else
        guard isICloudAvailable else {
            throw CloudKitError.iCloudNotAvailable
        }
        
        syncStatus = .syncing
        
        do {
            // 删除旧记录
            try await deleteAllHistoryRecords()
            
            // 添加新记录
            for item in items {
                let record = try createRecordFromHistoryItem(item)
                try await privateDatabase.save(record)
            }
            
            lastSyncDate = Date()
            syncStatus = .success
        } catch {
            syncStatus = .failed(error)
            throw error
        }
        #endif
    }
    
    /// 从 iCloud 获取历史记录
    @MainActor
    func fetchHistoryFromCloud() async throws -> [QRCodeHistoryItem] {
        #if targetEnvironment(simulator)
        // 模拟器环境下，返回空数组
        print("模拟器环境：获取操作已跳过，将使用本地数据")
        return []
        #else
        guard isICloudAvailable else {
            throw CloudKitError.iCloudNotAvailable
        }
        
        syncStatus = .syncing
        
        do {
            let query = CKQuery(recordType: "QRCodeHistoryItem", predicate: NSPredicate(value: true))
            let result = try await privateDatabase.records(matching: query)
            
            var historyItems: [QRCodeHistoryItem] = []
            
            for (_, result) in result.matchResults {
                switch result {
                case .success(let record):
                    if let item = try createHistoryItemFromRecord(record) {
                        historyItems.append(item)
                    }
                case .failure(let error):
                    print("获取记录失败: \(error.localizedDescription)")
                }
            }
            
            lastSyncDate = Date()
            syncStatus = .success
            return historyItems
        } catch {
            syncStatus = .failed(error)
            throw error
        }
        #endif
    }
    
    /// 删除所有历史记录
    private func deleteAllHistoryRecords() async throws {
        #if targetEnvironment(simulator)
        // 模拟器环境下，什么也不做
        return
        #else
        let query = CKQuery(recordType: "QRCodeHistoryItem", predicate: NSPredicate(value: true))
        let result = try await privateDatabase.records(matching: query)
        
        for (recordID, _) in result.matchResults {
            try await privateDatabase.deleteRecord(withID: recordID)
        }
        #endif
    }
    
    /// 从历史记录项创建 CloudKit 记录
    private func createRecordFromHistoryItem(_ item: QRCodeHistoryItem) throws -> CKRecord {
        #if targetEnvironment(simulator)
        // 模拟器环境下，什么也不做
        throw CloudKitError.recordCreationFailed
        #else
        let record = CKRecord(recordType: "QRCodeHistoryItem")
        
        record["id"] = item.id.uuidString
        record["content"] = item.content
        record["type"] = item.type.rawValue
        record["date"] = item.date
        record["isFavorite"] = item.isFavorite
        
        return record
        #endif
    }
    
    /// 从 CloudKit 记录创建历史记录项
    private func createHistoryItemFromRecord(_ record: CKRecord) throws -> QRCodeHistoryItem? {
        #if targetEnvironment(simulator)
        // 模拟器环境下，什么也不做
        return nil
        #else
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let content = record["content"] as? String,
              let typeRawValue = record["type"] as? String,
              let date = record["date"] as? Date,
              let isFavorite = record["isFavorite"] as? Bool,
              let type = QRCodeDataType(rawValue: typeRawValue) else {
            return nil
        }
        
        return QRCodeHistoryItem(id: id, type: type, content: content, date: date, isFavorite: isFavorite)
        #endif
    }
    
    /// 同步用户设置到 iCloud
    @MainActor
    func syncSettingsToCloud(settings: [String: Any]) async throws {
        #if targetEnvironment(simulator)
        // 模拟器环境下，什么也不做
        print("模拟器环境：同步设置已跳过")
        #else
        guard isICloudAvailable else {
            throw CloudKitError.iCloudNotAvailable
        }
        
        syncStatus = .syncing
        
        do {
            // 删除旧设置
            try await deleteAllSettingsRecords()
            
            // 创建新设置记录
            let record = CKRecord(recordType: "AppSettings")
            
            for (key, value) in settings {
                // CloudKit 只支持特定类型
                if value is String || value is Int || value is Double || value is Bool || value is Date {
                    record[key] = value as? CKRecordValue
                }
            }
            
            try await privateDatabase.save(record)
            
            lastSyncDate = Date()
            syncStatus = .success
        } catch {
            syncStatus = .failed(error)
            throw error
        }
        #endif
    }
    
    /// 从 iCloud 获取用户设置
    @MainActor
    func fetchSettingsFromCloud() async throws -> [String: Any] {
        #if targetEnvironment(simulator)
        // 模拟器环境下，什么也不做
        print("模拟器环境：获取设置已跳过")
        return [:]
        #else
        guard isICloudAvailable else {
            throw CloudKitError.iCloudNotAvailable
        }
        
        syncStatus = .syncing
        
        do {
            let query = CKQuery(recordType: "AppSettings", predicate: NSPredicate(value: true))
            let result = try await privateDatabase.records(matching: query)
            
            var settings: [String: Any] = [:]
            
            for (_, result) in result.matchResults {
                switch result {
                case .success(let record):
                    for key in record.allKeys() {
                        if let value = record[key] {
                            settings[key] = value
                        }
                    }
                case .failure(let error):
                    print("获取设置记录失败: \(error.localizedDescription)")
                }
            }
            
            lastSyncDate = Date()
            syncStatus = .success
            return settings
        } catch {
            syncStatus = .failed(error)
            throw error
        }
        #endif
    }
    
    /// 删除所有设置记录
    private func deleteAllSettingsRecords() async throws {
        #if targetEnvironment(simulator)
        // 模拟器环境下，什么也不做
        return
        #else
        let query = CKQuery(recordType: "AppSettings", predicate: NSPredicate(value: true))
        let result = try await privateDatabase.records(matching: query)
        
        for (recordID, _) in result.matchResults {
            try await privateDatabase.deleteRecord(withID: recordID)
        }
        #endif
    }
}

// MARK: - SyncStatus Equatable 实现
extension CloudKitManager.SyncStatus: Equatable {
    static func == (lhs: CloudKitManager.SyncStatus, rhs: CloudKitManager.SyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.syncing, .syncing), (.success, .success):
            return true
        case let (.failed(lhsError), .failed(rhsError)):
            return type(of: lhsError) == type(of: rhsError) &&
                   lhsError.localizedDescription == rhsError.localizedDescription
        case (.idle, _), (.syncing, _), (.success, _), (.failed, _):
            return false
        }
    }
}

/// CloudKit 错误类型
enum CloudKitError: Error {
    case iCloudNotAvailable
    case recordCreationFailed
    case syncFailed(String)
}

extension CloudKitError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud 不可用，请检查您的 iCloud 账户设置"
        case .recordCreationFailed:
            return "创建 CloudKit 记录失败"
        case .syncFailed(let message):
            return "同步失败: \(message)"
        }
    }
}
