import Foundation
import SwiftUI

enum QRCodeDataType: String, Codable, CaseIterable, Identifiable, Hashable {
    case text = "文本"
    case url = "网址"
    case contact = "联系人"
    case wifi = "Wi-Fi"
    case phone = "电话"
    case email = "邮箱"
    case sms = "短信"
    case calendar = "日历"
    case location = "位置"
    
    var id: String { rawValue }
    
    var description: String {
        return self.rawValue
    }
    
    var systemImage: String {
        switch self {
        case .text:
            return "text.alignleft"
        case .url:
            return "link"
        case .contact:
            return "person.fill"
        case .wifi:
            return "wifi"
        case .phone:
            return "phone"
        case .email:
            return "envelope"
        case .sms:
            return "message"
        case .calendar:
            return "calendar"
        case .location:
            return "location.fill"
        }
    }
    
    var placeholder: String {
        switch self {
        case .text:
            return "请输入文本内容"
        case .url:
            return "请输入网址"
        case .contact:
            return "请输入联系人信息"
        case .wifi:
            return "请输入Wi-Fi信息"
        case .phone:
            return "请输入电话号码"
        case .email:
            return "请输入邮箱地址"
        case .sms:
            return "请输入短信内容"
        case .calendar:
            return "请输入日历事件"
        case .location:
            return "请输入位置信息"
        }
    }
    
    func formatContent(_ content: String) -> String {
        switch self {
        case .text:
            return content
        case .url:
            if !content.lowercased().hasPrefix("http") {
                return "https://" + content
            }
            return content
        case .contact:
            // vCard format
            return """
                BEGIN:VCARD
                VERSION:3.0
                FN:\(content)
                END:VCARD
                """
        case .wifi:
            // WiFi format
            return "WIFI:T:WPA;S:\(content);;"
        case .phone:
            return "tel:\(content)"
        case .email:
            return "mailto:\(content)"
        case .sms:
            return "sms:\(content)"
        case .calendar:
            return content
        case .location:
            // Geo format
            let coordinates = content.split(separator: ",")
            if coordinates.count == 2,
               let lat = Double(coordinates[0]),
               let lon = Double(coordinates[1]) {
                return "geo:\(lat),\(lon)"
            }
            return content
        }
    }
}

// MARK: - Data Models
extension QRCodeDataType {
    struct Contact: Identifiable, Hashable {
        var id = UUID()
        var firstName: String = ""
        var lastName: String = ""
        var phone: String = ""
        var email: String = ""
        var organization: String = ""
        
        var vCardString: String {
            """
            BEGIN:VCARD
            VERSION:3.0
            N:\(lastName);\(firstName);;;
            FN:\(firstName) \(lastName)
            ORG:\(organization)
            TEL:\(phone)
            EMAIL:\(email)
            END:VCARD
            """
        }
    }
    
    struct WiFi: Identifiable, Hashable {
        var id = UUID()
        var ssid: String = ""
        var password: String = ""
        var isHidden: Bool = false
        
        enum SecurityType: String, CaseIterable, Identifiable, Hashable {
            case none = "None"
            case wep = "WEP"
            case wpa = "WPA/WPA2"
            
            var id: String { rawValue }
        }
        
        var security: SecurityType = .wpa
        
        var wifiString: String {
            let securityStr = security == .none ? "nopass" : security.rawValue.lowercased()
            return "WIFI:T:\(securityStr);S:\(ssid);P:\(password);H:\(isHidden ? "true" : "false");"
        }
    }
    
    struct Email: Identifiable, Hashable {
        var id = UUID()
        var address: String = ""
        var subject: String = ""
        var body: String = ""
        
        var emailString: String {
            let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return "mailto:\(address)?subject=\(encodedSubject)&body=\(encodedBody)"
        }
    }
    
    struct Phone: Identifiable, Hashable {
        var id = UUID()
        var number: String = ""
        
        var phoneString: String {
            "tel:\(number)"
        }
    }
    
    struct SMS: Identifiable, Hashable {
        var id = UUID()
        var phone: String = ""
        var message: String = ""
        
        var smsString: String {
            "SMSTO:\(phone):\(message)"
        }
    }
    
    struct Calendar: Identifiable, Hashable {
        var id = UUID()
        var title: String = ""
        var startDate: Date = Date()
        var endDate: Date = Date().addingTimeInterval(3600)
        var description: String = ""
        var location: String = ""
        
        var eventString: String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss"
            
            return """
            BEGIN:VEVENT
            SUMMARY:\(title)
            DTSTART:\(dateFormatter.string(from: startDate))
            DTEND:\(dateFormatter.string(from: endDate))
            LOCATION:\(location)
            DESCRIPTION:\(description)
            END:VEVENT
            """
        }
    }
    
    struct Location: Identifiable, Hashable {
        var id = UUID()
        var latitude: Double = 0.0
        var longitude: Double = 0.0
        var name: String = ""
        
        var geoString: String {
            "geo:\(latitude),\(longitude)"
        }
        
        var mapUrl: String {
            "https://maps.apple.com/?q=\(latitude),\(longitude)"
        }
    }
}
