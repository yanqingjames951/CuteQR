import Foundation

struct QRCodeHistoryItem: Identifiable, Codable, Hashable {
    let id: UUID
    let type: QRCodeDataType
    let content: String
    let date: Date
    var isFavorite: Bool
    
    init(id: UUID = UUID(), type: QRCodeDataType, content: String, date: Date = Date(), isFavorite: Bool = false) {
        self.id = id
        self.type = type
        self.content = content
        self.date = date
        self.isFavorite = isFavorite
    }
}
