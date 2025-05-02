import Foundation
import SwiftUI

@MainActor
final class QRCodeHistoryManager: ObservableObject {
    @Published private(set) var items: [QRCodeHistoryItem] = []
    @Published private(set) var isLoading = false
    
    private let maxItems: Int
    private let userDefaults = UserDefaults.standard
    private let itemsKey = "qrCodeHistoryItems"
    
    init(maxItems: Int = 100) {
        self.maxItems = maxItems
        loadItems()
    }
    
    func addItem(_ item: QRCodeHistoryItem) {
        if !items.contains(where: { $0.id == item.id }) {
            items.insert(item, at: 0)
            if items.count > maxItems {
                items.removeLast()
            }
            saveItems()
        }
    }
    
    func removeItem(_ item: QRCodeHistoryItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    func removeItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        saveItems()
    }
    
    func toggleFavorite(_ item: QRCodeHistoryItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isFavorite.toggle()
            saveItems()
        }
    }
    
    func clearHistory() {
        items.removeAll()
        saveItems()
    }
    
    private func loadItems() {
        isLoading = true
        defer { isLoading = false }
        
        guard let data = userDefaults.data(forKey: itemsKey) else { return }
        
        do {
            items = try JSONDecoder().decode([QRCodeHistoryItem].self, from: data)
        } catch {
            print("Error loading history items: \(error)")
        }
    }
    
    private func saveItems() {
        do {
            let data = try JSONEncoder().encode(items)
            userDefaults.set(data, forKey: itemsKey)
        } catch {
            print("Error saving history items: \(error)")
        }
    }
    
    static var preview: QRCodeHistoryManager {
        let manager = QRCodeHistoryManager()
        manager.items = [
            QRCodeHistoryItem(type: .text, content: "Hello, World!"),
            QRCodeHistoryItem(type: .url, content: "https://example.com", isFavorite: true),
            QRCodeHistoryItem(type: .wifi, content: "MyWiFi")
        ]
        return manager
    }
}
