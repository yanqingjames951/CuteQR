import Foundation

struct QRCodeHistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    let type: QRCodeDataType
    let content: String
    let date: Date
    var isFavorite: Bool
    
    init(type: QRCodeDataType, content: String, isFavorite: Bool = false) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.date = Date()
        self.isFavorite = isFavorite
    }
    
    init(id: UUID, type: QRCodeDataType, content: String, date: Date, isFavorite: Bool) {
        self.id = id
        self.type = type
        self.content = content
        self.date = date
        self.isFavorite = isFavorite
    }
}
