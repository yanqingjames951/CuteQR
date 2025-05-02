import Foundation

// MARK: - QR Code String Parser
/// 二维码字符串解析器，支持多种二维码格式的解析
struct QRCodeStringParser {
    /// 解析二维码内容
    /// - Parameter content: 二维码内容
    /// - Returns: 解析结果（类型和内容）
    static func parse(content: String) -> (type: QRCodeDataType, parsedContent: String) {
        let lowercasedContent = content.lowercased()
        
        // URL
        if lowercasedContent.hasPrefix("http") || lowercasedContent.hasPrefix("https") {
            return (.url, content)
        }
        
        // Phone
        if lowercasedContent.hasPrefix("tel:") {
            let phoneNumber = String(content.dropFirst(4))
            return (.phone, phoneNumber)
        }
        
        // Email
        if lowercasedContent.hasPrefix("mailto:") {
            let email = String(content.dropFirst(7))
            return (.email, email)
        }
        
        // SMS
        if lowercasedContent.hasPrefix("sms:") || lowercasedContent.hasPrefix("smsto:") {
            let prefix = lowercasedContent.hasPrefix("sms:") ? 4 : 6
            let sms = String(content.dropFirst(prefix))
            return (.sms, sms)
        }
        
        // WiFi
        if lowercasedContent.hasPrefix("wifi:") {
            return (.wifi, parseWiFi(content))
        }
        
        // vCard (Contact)
        if lowercasedContent.hasPrefix("begin:vcard") {
            return (.contact, content)
        }
        
        // Calendar
        if lowercasedContent.hasPrefix("begin:vevent") {
            return (.calendar, content)
        }
        
        // Location
        if lowercasedContent.hasPrefix("geo:") {
            let location = String(content.dropFirst(4))
            return (.location, location)
        }
        
        // Default to text
        return (.text, content)
    }
    
    /// WiFi解析：从二维码内容中提取WiFi信息
    /// - Parameter wifiString: WiFi字符串
    /// - Returns: WiFi信息字符串
    static func parseWiFi(_ wifiString: String) -> String {
        // Extract SSID from WIFI:S:<ssid>;T:<type>;P:<password>;H:<hidden>;
        if let ssidRange = wifiString.range(of: "S:") {
            let ssidStart = ssidRange.upperBound
            if let ssidEnd = wifiString[ssidStart...].firstIndex(where: { $0 == ";" }) {
                let ssid = String(wifiString[ssidStart..<ssidEnd])
                return ssid
            }
        }
        return wifiString
    }
    
    /// vCard解析：从二维码内容中提取联系人信息
    /// - Parameter vCardString: vCard字符串
    /// - Returns: 联系人信息字符串
    static func parseVCard(_ vCardString: String) -> String {
        // Extract name from vCard
        if let fnRange = vCardString.range(of: "FN:") {
            let fnStart = fnRange.upperBound
            if let fnEnd = vCardString[fnStart...].firstIndex(where: { $0.isNewline }) {
                let name = String(vCardString[fnStart..<fnEnd])
                return name
            }
        }
        return vCardString
    }
    
    // MARK: - 对象解析方法
    
    /// 将WiFi字符串解析为WiFi对象
    /// - Parameter wifiString: WiFi字符串
    /// - Returns: WiFi对象
    static func parseWiFiToObject(_ wifiString: String) -> QRCodeDataType.WiFi {
        var wifi = QRCodeDataType.WiFi()
        
        // Extract SSID
        if let ssidRange = wifiString.range(of: "S:") {
            let ssidStart = ssidRange.upperBound
            if let ssidEnd = wifiString[ssidStart...].firstIndex(where: { $0 == ";" }) {
                wifi.ssid = String(wifiString[ssidStart..<ssidEnd])
            }
        }
        
        // Extract password
        if let pwdRange = wifiString.range(of: "P:") {
            let pwdStart = pwdRange.upperBound
            if let pwdEnd = wifiString[pwdStart...].firstIndex(where: { $0 == ";" }) {
                wifi.password = String(wifiString[pwdStart..<pwdEnd])
            }
        }
        
        // Extract security type
        if let typeRange = wifiString.range(of: "T:") {
            let typeStart = typeRange.upperBound
            if let typeEnd = wifiString[typeStart...].firstIndex(where: { $0 == ";" }) {
                let securityStr = String(wifiString[typeStart..<typeEnd]).lowercased()
                if securityStr == "wep" {
                    wifi.security = .wep
                } else if securityStr == "wpa" || securityStr == "wpa2" {
                    wifi.security = .wpa
                } else if securityStr == "nopass" {
                    wifi.security = .none
                }
            }
        }
        
        // Extract hidden
        if let hiddenRange = wifiString.range(of: "H:") {
            let hiddenStart = hiddenRange.upperBound
            if let hiddenEnd = wifiString[hiddenStart...].firstIndex(where: { $0 == ";" }) {
                let hiddenStr = String(wifiString[hiddenStart..<hiddenEnd]).lowercased()
                wifi.isHidden = hiddenStr == "true"
            }
        }
        
        return wifi
    }
    
    /// 将vCard字符串解析为Contact对象
    /// - Parameter vCardString: vCard字符串
    /// - Returns: Contact对象
    static func parseVCardToObject(_ vCardString: String) -> QRCodeDataType.Contact {
        var contact = QRCodeDataType.Contact()
        
        // Extract FN (Full Name)
        if let fnRange = vCardString.range(of: "FN:") {
            let fnStart = fnRange.upperBound
            if let fnEnd = vCardString[fnStart...].firstIndex(where: { $0.isNewline }) {
                let name = String(vCardString[fnStart..<fnEnd])
                let nameParts = name.split(separator: " ")
                if nameParts.count > 1 {
                    contact.firstName = String(nameParts[0])
                    contact.lastName = String(nameParts[1])
                } else if nameParts.count == 1 {
                    contact.firstName = String(nameParts[0])
                }
            }
        }
        
        // Extract TEL
        if let telRange = vCardString.range(of: "TEL:") {
            let telStart = telRange.upperBound
            if let telEnd = vCardString[telStart...].firstIndex(where: { $0.isNewline }) {
                contact.phone = String(vCardString[telStart..<telEnd])
            }
        }
        
        // Extract EMAIL
        if let emailRange = vCardString.range(of: "EMAIL:") {
            let emailStart = emailRange.upperBound
            if let emailEnd = vCardString[emailStart...].firstIndex(where: { $0.isNewline }) {
                contact.email = String(vCardString[emailStart..<emailEnd])
            }
        }
        
        // Extract ORG
        if let orgRange = vCardString.range(of: "ORG:") {
            let orgStart = orgRange.upperBound
            if let orgEnd = vCardString[orgStart...].firstIndex(where: { $0.isNewline }) {
                contact.organization = String(vCardString[orgStart..<orgEnd])
            }
        }
        
        return contact
    }
    
    /// 将SMS字符串解析为SMS对象
    /// - Parameter smsString: SMS字符串
    /// - Returns: SMS对象
    static func parseSMSToObject(_ smsString: String) -> QRCodeDataType.SMS {
        var sms = QRCodeDataType.SMS()
        
        // Handle SMSTO:phone:message format
        if smsString.hasPrefix("SMSTO:") || smsString.hasPrefix("smsto:") {
            let cleanString = smsString.replacingOccurrences(of: "SMSTO:", with: "").replacingOccurrences(of: "smsto:", with: "")
            let components = cleanString.split(separator: ":", maxSplits: 1)
            if components.count > 0 {
                sms.phone = String(components[0])
            }
            if components.count > 1 {
                sms.message = String(components[1])
            }
        } 
        // Handle SMS:phone format
        else if smsString.hasPrefix("SMS:") || smsString.hasPrefix("sms:") {
            let cleanString = smsString.replacingOccurrences(of: "SMS:", with: "").replacingOccurrences(of: "sms:", with: "")
            sms.phone = cleanString
        }
        
        return sms
    }
    
    /// 将Email字符串解析为Email对象
    /// - Parameter emailString: Email字符串
    /// - Returns: Email对象
    static func parseEmailToObject(_ emailString: String) -> QRCodeDataType.Email {
        var email = QRCodeDataType.Email()
        
        // Handle mailto:address?subject=Subject&body=Body format
        if emailString.hasPrefix("mailto:") {
            let cleanString = emailString.replacingOccurrences(of: "mailto:", with: "")
            let components = cleanString.split(separator: "?", maxSplits: 1)
            
            if components.count > 0 {
                email.address = String(components[0])
            }
            
            if components.count > 1 {
                let params = String(components[1])
                
                // Extract subject
                if let subjectRange = params.range(of: "subject=") {
                    let subjectStart = subjectRange.upperBound
                    let endRange: Range<String.Index>
                    
                    if let bodyRange = params[subjectStart...].range(of: "&body=") {
                        endRange = subjectStart..<bodyRange.lowerBound
                    } else {
                        endRange = subjectStart..<params.endIndex
                    }
                    
                    email.subject = String(params[endRange])
                        .removingPercentEncoding ?? ""
                }
                
                // Extract body
                if let bodyRange = params.range(of: "body=") {
                    let bodyStart = bodyRange.upperBound
                    email.body = String(params[bodyStart...])
                        .removingPercentEncoding ?? ""
                }
            }
        } else {
            // Simple email address
            email.address = emailString
        }
        
        return email
    }
    
    /// 将Calendar字符串解析为Calendar对象
    /// - Parameter calendarString: Calendar字符串
    /// - Returns: Calendar对象
    static func parseCalendarToObject(_ calendarString: String) -> QRCodeDataType.Calendar {
        var calendar = QRCodeDataType.Calendar()
        
        // Extract SUMMARY (Title)
        if let summaryRange = calendarString.range(of: "SUMMARY:") {
            let summaryStart = summaryRange.upperBound
            if let summaryEnd = calendarString[summaryStart...].firstIndex(where: { $0.isNewline }) {
                calendar.title = String(calendarString[summaryStart..<summaryEnd])
            }
        }
        
        // Extract DTSTART (Start Date)
        if let startRange = calendarString.range(of: "DTSTART:") {
            let startStart = startRange.upperBound
            if let startEnd = calendarString[startStart...].firstIndex(where: { $0.isNewline }) {
                let dateString = String(calendarString[startStart..<startEnd])
                if let date = parseDate(dateString) {
                    calendar.startDate = date
                }
            }
        }
        
        // Extract DTEND (End Date)
        if let endRange = calendarString.range(of: "DTEND:") {
            let endStart = endRange.upperBound
            if let endEnd = calendarString[endStart...].firstIndex(where: { $0.isNewline }) {
                let dateString = String(calendarString[endStart..<endEnd])
                if let date = parseDate(dateString) {
                    calendar.endDate = date
                }
            }
        }
        
        // Extract LOCATION
        if let locationRange = calendarString.range(of: "LOCATION:") {
            let locationStart = locationRange.upperBound
            if let locationEnd = calendarString[locationStart...].firstIndex(where: { $0.isNewline }) {
                calendar.location = String(calendarString[locationStart..<locationEnd])
            }
        }
        
        // Extract DESCRIPTION
        if let descRange = calendarString.range(of: "DESCRIPTION:") {
            let descStart = descRange.upperBound
            if let descEnd = calendarString[descStart...].firstIndex(where: { $0.isNewline }) {
                calendar.description = String(calendarString[descStart..<descEnd])
            }
        }
        
        return calendar
    }
    
    // MARK: - 辅助方法
    
    /// 解析日期字符串
    /// - Parameter dateString: 日期字符串
    /// - Returns: 日期对象
    private static func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        
        return formatter.date(from: dateString)
    }
}
