import Foundation

struct QRCodeStringParser {
    static func parseVCard(_ string: String) -> QRCodeDataType.Contact? {
        var contact = QRCodeDataType.Contact(firstName: "", lastName: "", phone: "", email: "", organization: "")
        
        let lines = string.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("N:") {
                let parts = line.dropFirst(2).components(separatedBy: ";")
                if parts.count >= 2 {
                    contact.lastName = parts[0]
                    contact.firstName = parts[1]
                }
            } else if line.hasPrefix("ORG:") {
                contact.organization = String(line.dropFirst(4))
            } else if line.hasPrefix("TEL:") {
                contact.phone = String(line.dropFirst(4))
            } else if line.hasPrefix("EMAIL:") {
                contact.email = String(line.dropFirst(6))
            }
        }
        
        return contact
    }
    
    static func parseWiFi(_ string: String) -> QRCodeDataType.WiFi? {
        guard string.hasPrefix("WIFI:") else { return nil }
        
        var wifi = QRCodeDataType.WiFi(ssid: "", password: "", security: .none, isHidden: false)
        let content = string.dropFirst(5)
        
        let components = content.components(separatedBy: ";")
        for component in components {
            let parts = component.components(separatedBy: ":")
            guard parts.count == 2 else { continue }
            
            let key = parts[0]
            let value = parts[1]
            
            switch key {
            case "S":
                wifi.ssid = value
            case "P":
                wifi.password = value
            case "T":
                switch value.lowercased() {
                case "wpa", "wpa2":
                    wifi.security = .wpa
                case "wep":
                    wifi.security = .wep
                default:
                    wifi.security = .none
                }
            case "H":
                wifi.isHidden = value == "true"
            default:
                break
            }
        }
        
        return wifi
    }
    
    static func parseSMS(_ string: String) -> QRCodeDataType.SMS? {
        guard string.hasPrefix("SMSTO:") else { return nil }
        
        let content = string.dropFirst(6)
        let parts = content.components(separatedBy: ":")
        
        if parts.count >= 2 {
            return QRCodeDataType.SMS(phone: parts[0], message: parts[1])
        } else if parts.count == 1 {
            return QRCodeDataType.SMS(phone: parts[0], message: "")
        }
        
        return nil
    }
    
    static func parseEmail(_ string: String) -> QRCodeDataType.Email? {
        guard string.hasPrefix("mailto:") else { return nil }
        
        var email = QRCodeDataType.Email(address: "", subject: "", body: "")
        
        let components = string.components(separatedBy: "?")
        if components.count > 0 {
            email.address = String(components[0].dropFirst(7))
            
            if components.count > 1 {
                let params = components[1].components(separatedBy: "&")
                for param in params {
                    let parts = param.components(separatedBy: "=")
                    if parts.count == 2 {
                        let key = parts[0]
                        let value = parts[1].removingPercentEncoding ?? parts[1]
                        
                        switch key {
                        case "subject":
                            email.subject = value
                        case "body":
                            email.body = value
                        default:
                            break
                        }
                    }
                }
            }
        }
        
        return email
    }
    
    static func parseCalendar(_ string: String) -> QRCodeDataType.Calendar? {
        var calendar = QRCodeDataType.Calendar(
            title: "",
            startDate: Date(),
            endDate: Date(),
            description: "",
            location: ""
        )
        
        let lines = string.components(separatedBy: .newlines)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss"
        
        for line in lines {
            if line.hasPrefix("SUMMARY:") {
                calendar.title = String(line.dropFirst(8))
            } else if line.hasPrefix("DTSTART:") {
                if let date = dateFormatter.date(from: String(line.dropFirst(8))) {
                    calendar.startDate = date
                }
            } else if line.hasPrefix("DTEND:") {
                if let date = dateFormatter.date(from: String(line.dropFirst(6))) {
                    calendar.endDate = date
                }
            } else if line.hasPrefix("LOCATION:") {
                calendar.location = String(line.dropFirst(9))
            } else if line.hasPrefix("DESCRIPTION:") {
                calendar.description = String(line.dropFirst(12))
            }
        }
        
        return calendar
    }
}
