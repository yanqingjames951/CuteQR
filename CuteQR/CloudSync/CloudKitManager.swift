import Foundation
import CloudKit

/// 管理 CloudKit 同步的类
@MainActor
class CloudKitManager: ObservableObject {
    /// 单例实例
    static let shared = CloudKitManager()
    
    /// CloudKit 容器
    private let container: CKContainer
    /// 私有数据库
    private let privateDatabase: CKDatabase
    /// 容器ID
    private let containerID: String
    
    /// 同步状态
    @Published private(set) var syncStatus: SyncStatus = .idle {
        didSet {
            if case .success = syncStatus {
                lastSyncDate = Date()
            }
        }
    }
    /// 上次同步时间
    @Published private(set) var lastSyncDate: Date?
    /// 是否已启用 iCloud
    @Published private(set) var isICloudAvailable: Bool = false
    
    /// CloudKit 错误类型
    public enum CloudKitError: LocalizedError {
        case iCloudNotAvailable
        case networkError
        case quotaExceeded
        case unknown(Error)
        
        var errorDescription: String? {
            switch self {
            case .iCloudNotAvailable:
                return "iCloud 不可用，请检查账户设置"
            case .networkError:
                return "网络连接错误，请检查网络设置"
            case .quotaExceeded:
                return "iCloud 存储空间不足"
            case .unknown(let error):
                return error.localizedDescription
            }
        }
    }
    
    /// CloudKit 同步状态
    public enum SyncStatus: Equatable {
        case idle
        case syncing
        case success
        case failed(Error)
        
        static func == (lhs: SyncStatus, rhs: SyncStatus) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle),
                 (.syncing, .syncing),
                 (.success, .success):
                return true
            case (.failed(let lhsError), .failed(let rhsError)):
                return lhsError.localizedDescription == rhsError.localizedDescription
            default:
                return false
            }
        }
    }
    
    private init() {
        // 初始化 CloudKit 容器 - 使用应用程序的 bundle identifier
        guard let bundleID = Bundle.main.bundleIdentifier else {
            fatalError("无法获取应用程序的 Bundle Identifier")
        }
        containerID = "iCloud.\(bundleID)"
        print("初始化 CloudKit 容器: \(containerID)")
        
        container = CKContainer(identifier: containerID)
        privateDatabase = container.privateCloudDatabase
        
        // 异步检查 iCloud 状态
        Task { @MainActor in
            syncStatus = .syncing
            await checkICloudStatus()
        }
    }
    
    /// 检查 iCloud 账户状态
    @MainActor
    func checkICloudStatus() async {
        do {
            // 步骤1：检查 iCloud 账户状态
            let status = try await container.accountStatus()
            
            // 步骤2：处理账户状态
            await handleAccountStatus(status)
            
            // 步骤3：如果可用，设置同步状态
            if isICloudAvailable {
                syncStatus = .success
            }
        } catch {
            // 步骤4：处理错误
            handleAccountError(error)
        }
    }
    
    /// 处理账户状态 - 将复杂逻辑拆分为单独的方法
    @MainActor
    private func handleAccountStatus(_ status: CKAccountStatus) async {
        // 重置状态
        isICloudAvailable = false
        
        switch status {
        case .available:
            // 账户可用，可以尝试访问数据库
            isICloudAvailable = true
            print("✅ iCloud: 可用")
            // 注意：实际的数据库访问（如保存/获取）可能会因配额等问题失败
            // 此处仅确认账户状态可用
            
        case .restricted:
            print("⚠️ iCloud: 账户受限")
            syncStatus = .failed(CloudKitError.iCloudNotAvailable)
        case .noAccount:
            print("⚠️ iCloud: 未登录账户")
            syncStatus = .failed(CloudKitError.iCloudNotAvailable)
        case .couldNotDetermine:
            print("❌ iCloud: 状态无法确定")
            syncStatus = .failed(CloudKitError.networkError)
        case .temporarilyUnavailable:
            print("⏳ iCloud: 暂时不可用")
            syncStatus = .failed(CloudKitError.networkError)
        @unknown default:
            print("❌ iCloud: 未知状态")
            syncStatus = .failed(CloudKitError.unknown(NSError(domain: "CloudKitManager", 
                code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "未知的 iCloud 账户状态"])))
        }
    }
    
    /// 处理账户错误 - 将错误处理逻辑拆分为单独的方法
    private func handleAccountError(_ error: Error) {
        print("iCloud 账户状态检查失败: \(error.localizedDescription)")
        isICloudAvailable = false
        syncStatus = .failed(error)
    }
    
    /// 验证 CloudKit 权限
    private func validatePermissions() async throws {
        // 检查 CloudKit 权限状态
        let status = try await container.accountStatus()
        await handleAccountStatus(status)
        
        guard isICloudAvailable else {
            throw CloudKitError.iCloudNotAvailable
        }
    }
    
    /// 同步历史记录到 iCloud
    func syncHistoryToCloud(items: [QRCodeHistoryItem]) async throws {
        guard isICloudAvailable else {
            throw CloudKitError.iCloudNotAvailable
        }
        
        syncStatus = .syncing
        
        do {
            // 删除旧记录
            try await deleteAllHistoryRecords()
            
            // 批量保存新记录
            let records = try items.map { try createRecordFromHistoryItem($0) }
            
            // 使用异步API直接保存记录
            try await withThrowingTaskGroup(of: Void.self) { group in
                for record in records {
                    group.addTask {
                        try await self.privateDatabase.save(record)
                    }
                }
                
                // 等待所有任务完成
                try await group.waitForAll()
            }
            
            lastSyncDate = Date()
            syncStatus = .success
        } catch {
            print("同步到 iCloud 失败: \(error.localizedDescription)")
            syncStatus = .failed(error)
            throw CloudKitError.unknown(error)
        }
    }
    
    /// 从 iCloud 获取历史记录
    func fetchHistoryFromCloud() async throws -> [QRCodeHistoryItem] {
        guard isICloudAvailable else {
            throw CloudKitError.iCloudNotAvailable
        }
        
        syncStatus = .syncing
        
        do {
            let query = CKQuery(recordType: "QRCodeHistoryItem", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            // 使用更新的 API 调用方式，添加分页支持
            var historyItems: [QRCodeHistoryItem] = []
            var cursor: CKQueryOperation.Cursor?
            
            repeat {
                let (matchResults, newCursor) = try await privateDatabase.records(
                    matching: query,
                    inZoneWith: CKRecordZone.default().zoneID,
                    desiredKeys: ["id", "content", "type", "date", "isFavorite"],
                    resultsLimit: 50
                )
                cursor = newCursor
                
                // 处理结果
                for (_, result) in matchResults {
                    do {
                        let record = try result.get()
                        if let item = try createHistoryItemFromRecord(record) {
                            historyItems.append(item)
                        }
                    } catch {
                        print("处理记录失败: \(error.localizedDescription)")
                    }
                }
            } while cursor != nil
            
            lastSyncDate = Date()
            syncStatus = .success
            return historyItems
        } catch {
            print("从 iCloud 获取失败: \(error.localizedDescription)")
            syncStatus = .failed(error)
            throw CloudKitError.unknown(error)
        }
    }
    
    /// 删除所有历史记录
    private func deleteAllHistoryRecords() async throws {
        let query = CKQuery(recordType: "QRCodeHistoryItem", predicate: NSPredicate(value: true))
        
        // 使用更新的 API 调用方式
        let (matchResults, _) = try await privateDatabase.records(
            matching: query,
            inZoneWith: CKRecordZone.default().zoneID,
            resultsLimit: 100
        )
        
        // 使用任务组并行删除记录
        if !matchResults.isEmpty {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for (recordID, _) in matchResults {
                    group.addTask {
                        try await self.privateDatabase.deleteRecord(withID: recordID)
                    }
                }
                
                // 等待所有删除操作完成
                try await group.waitForAll()
            }
        }
    }
    
    /// 从 CKRecord 创建 QRCodeHistoryItem
    private func createHistoryItemFromRecord(_ record: CKRecord) throws -> QRCodeHistoryItem? {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let content = record["content"] as? String,
              let typeString = record["type"] as? String,
              let type = QRCodeDataType(rawValue: typeString),
              let date = record["date"] as? Date,
              let isFavorite = record["isFavorite"] as? Bool else {
            print("❌ 无法从 CKRecord 创建 QRCodeHistoryItem，缺少字段或类型不匹配")
            return nil
        }
        
        // 使用包含所有参数的初始化器
        return QRCodeHistoryItem(id: id, type: type, content: content, date: date, isFavorite: isFavorite)
    }
    
    /// 从历史记录项创建 CloudKit 记录
    private func createRecordFromHistoryItem(_ item: QRCodeHistoryItem) throws -> CKRecord {
        let record = CKRecord(recordType: "QRCodeHistoryItem")
        
        // 确保所有值都是有效的 CKRecordValue
        record["id"] = item.id.uuidString as CKRecordValue
        record["content"] = item.content as CKRecordValue
        record["type"] = item.type.rawValue as CKRecordValue
        record["date"] = item.date as CKRecordValue
        record["isFavorite"] = item.isFavorite as CKRecordValue
        
        return record
    }
    
    /// 同步用户设置到 iCloud
    func syncSettingsToCloud(settings: [String: Any]) async throws {
        guard isICloudAvailable else {
            throw CloudKitError.iCloudNotAvailable
        }
        
        syncStatus = .syncing
        
        do {
            // 删除旧设置
            try await deleteAllSettingsRecords()
            
            // 创建新设置记录
            let record = CKRecord(recordType: "AppSettings")
            
            // 过滤并转换设置值
            var validSettings = 0
            for (key, value) in settings {
                // CloudKit 只支持特定类型，确保值是 CKRecordValue
                if let recordValue = value as? CKRecordValue {
                    record[key] = recordValue
                    validSettings += 1
                } else {
                    print("警告：设置值 '\(key)' 不是有效的 CKRecordValue 类型，将被跳过")
                }
            }
            
            // 只有在有有效设置时才保存
            if validSettings > 0 {
                try await privateDatabase.save(record)
                print("成功保存 \(validSettings) 个设置项到 iCloud")
            } else {
                print("没有有效的设置项可保存")
            }
            
            lastSyncDate = Date()
            syncStatus = .success
        } catch {
            print("同步设置到 iCloud 失败: \(error.localizedDescription)")
            syncStatus = .failed(error)
            throw CloudKitError.unknown(error)
        }
    }
    
    /// 从 iCloud 获取用户设置
    func fetchSettingsFromCloud() async throws -> [String: Any] {
        guard isICloudAvailable else {
            throw CloudKitError.iCloudNotAvailable
        }
        
        syncStatus = .syncing
        
        do {
            let query = CKQuery(recordType: "AppSettings", predicate: NSPredicate(value: true))
            
            // 使用更新的 API 调用方式
            let (matchResults, _) = try await privateDatabase.records(matching: query, inZoneWith: CKRecordZone.default().zoneID)
            
            var settings: [String: Any] = [:]
            
            // 处理结果
            for (_, result) in matchResults {
                do {
                    let record = try result.get()
                    for key in record.allKeys() {
                        if let value = record[key] {
                            settings[key] = value
                        }
                    }
                } catch {
                    print("处理设置记录失败: \(error.localizedDescription)")
                }
            }
            
            lastSyncDate = Date()
            syncStatus = .success
            return settings
        } catch {
            print("从 iCloud 获取设置失败: \(error.localizedDescription)")
            syncStatus = .failed(error)
            throw CloudKitError.unknown(error)
        }
    }
    
    /// 删除所有设置记录
    private func deleteAllSettingsRecords() async throws {
        let query = CKQuery(recordType: "AppSettings", predicate: NSPredicate(value: true))
        
        // 使用更新的 API 调用方式
        let (matchResults, _) = try await privateDatabase.records(
            matching: query,
            inZoneWith: CKRecordZone.default().zoneID,
            resultsLimit: 50
        )
        
        // 使用任务组并行删除记录
        if !matchResults.isEmpty {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for (recordID, _) in matchResults {
                    group.addTask {
                        try await self.privateDatabase.deleteRecord(withID: recordID)
                    }
                }
                
                // 等待所有删除操作完成
                try await group.waitForAll()
            }
        }
    }
}
