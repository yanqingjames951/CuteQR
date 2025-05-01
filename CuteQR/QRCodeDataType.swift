import Foundation
import SwiftUI

enum QRCodeDataType: String, Codable, CaseIterable, Identifiable {
    case text = "文本"
    case url = "网址"
    case email = "邮箱"
    case phone = "电话"
    case sms = "短信"
    case contact = "联系人"
    case wifi = "Wi-Fi"
    case calendar = "日历"
    case location = "位置"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .text:
            return "text.alignleft"
        case .url:
            return "link"
        case .email:
            return "envelope"
        case .phone:
            return "phone"
        case .sms:
            return "message"
        case .contact:
            return "person.fill"
        case .wifi:
            return "wifi"
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
        case .email:
            return "请输入邮箱地址"
        case .phone:
            return "请输入电话号码"
        case .sms:
            return "请输入短信内容"
        case .contact:
            return "请输入联系人信息"
        case .wifi:
            return "请输入 Wi-Fi 信息"
        case .calendar:
            return "请输入日历事件"
        case .location:
            return "请输入位置信息"
        }
    }
}

// 数据模型
extension QRCodeDataType {
    struct URL: Equatable, Hashable {
        var url: String
    }
    
    struct Contact: Equatable, Hashable {
        var firstName: String
        var lastName: String
        var phone: String
        var email: String
        var organization: String
        
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
    
    struct WiFi: Equatable, Hashable {
        enum SecurityType: String, CaseIterable, Equatable, Hashable {
            case none = "None"
            case wep = "WEP"
            case wpa = "WPA/WPA2"
        }
        
        var ssid: String
        var password: String
        var security: SecurityType
        var isHidden: Bool
        
        var wifiString: String {
            let securityStr = security == .none ? "nopass" : security.rawValue.lowercased()
            return "WIFI:T:\(securityStr);S:\(ssid);P:\(password);H:\(isHidden);"
        }
    }
    
    struct SMS: Equatable, Hashable {
        var phone: String
        var message: String
        
        var smsString: String {
            "SMSTO:\(phone):\(message)"
        }
    }
    
    struct Phone: Equatable, Hashable {
        var number: String
        
        var phoneString: String {
            "tel:\(number)"
        }
    }
    
    struct Email: Equatable, Hashable {
        var address: String
        var subject: String
        var body: String
        
        var emailString: String {
            "mailto:\(address)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
    }
    
    struct Calendar: Equatable, Hashable {
        var title: String
        var startDate: Date
        var endDate: Date
        var description: String
        var location: String
        
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
}
