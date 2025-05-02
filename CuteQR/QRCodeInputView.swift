import SwiftUI

struct QRCodeInputView: View {
    let type: QRCodeDataType
    @Binding var qrContent: String
    
    // 状态变量
    @State private var urlInput = ""
    @State private var contact = QRCodeDataType.Contact()
    @State private var wifi = QRCodeDataType.WiFi()
    @State private var sms = QRCodeDataType.SMS()
    @State private var phone = QRCodeDataType.Phone()
    @State private var email = QRCodeDataType.Email()
    @State private var calendar = QRCodeDataType.Calendar()
    @State private var location = QRCodeDataType.Location()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("请输入\(type.rawValue)内容")
                .font(.headline)
                .padding(.horizontal)
            
            inputView
        }
        .padding(.horizontal)
        .onAppear {
            initializeContent()
        }
    }
    
    @ViewBuilder
    private var inputView: some View {
        Group {
            switch type {
            case .text:
                TextField("请输入文本内容", text: $qrContent)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.default)
                    .textContentType(.none)
                    .textInputAutocapitalization(.sentences)
            case .url:
                URLInputView(url: $urlInput)
                    .onChange(of: urlInput) { _, newValue in
                        qrContent = type.formatContent(newValue)
                    }
            case .contact:
                ContactInputView(contact: $contact)
                    .onChange(of: contact) { _, newValue in
                        qrContent = newValue.vCardString
                    }
            case .wifi:
                WiFiInputView(wifi: $wifi)
                    .onChange(of: wifi) { _, newValue in
                        qrContent = newValue.wifiString
                    }
            case .sms:
                SMSInputView(sms: $sms)
                    .onChange(of: sms) { _, newValue in
                        qrContent = newValue.smsString
                    }
            case .phone:
                PhoneInputView(phone: $phone)
                    .onChange(of: phone) { _, newValue in
                        qrContent = newValue.phoneString
                    }
            case .email:
                EmailInputView(email: $email)
                    .onChange(of: email) { _, newValue in
                        qrContent = newValue.emailString
                    }
            case .calendar:
                CalendarInputView(calendar: $calendar)
                    .onChange(of: calendar) { _, newValue in
                        qrContent = newValue.eventString
                    }
            case .location:
                LocationInputView(location: $location)
                    .onChange(of: location) { _, newValue in
                        qrContent = newValue.geoString
                    }
            }
        }
    }
    
    private func initializeContent() {
        // 这里采用直接的赋值而不是使用外部解析器，遵循Context7架构
        switch type {
        case .text:
            break // 文本类型直接使用 qrContent
        case .url:
            urlInput = qrContent.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "")
        case .contact:
            // vCard格式简单处理，实际项目中可能需要更复杂的解析
            let vCardString = qrContent
            contact.firstName = vCardString.contains("FN:") ? String(vCardString.split(separator: "FN:")[1].split(separator: "\n")[0]) : ""
        case .wifi:
            // WiFi格式简单处理
            let wifiString = qrContent
            if wifiString.contains("S:") && wifiString.contains(";") {
                let ssidRange = wifiString.range(of: "S:")?.upperBound
                if let ssidRange = ssidRange,
                   let endRange = wifiString[ssidRange...].firstIndex(where: { $0 == ";" }) {
                    wifi.ssid = String(wifiString[ssidRange..<endRange])
                }
            }
        case .sms:
            // SMS格式简单处理
            let smsString = qrContent.replacingOccurrences(of: "sms:", with: "").replacingOccurrences(of: "SMSTO:", with: "")
            sms.phone = smsString
        case .phone:
            phone.number = qrContent.replacingOccurrences(of: "tel:", with: "")
        case .email:
            // Email格式简单处理
            let emailString = qrContent.replacingOccurrences(of: "mailto:", with: "")
            email.address = emailString.split(separator: "?").first.map(String.init) ?? emailString
        case .calendar:
            // 日历格式简单处理
            if qrContent.contains("SUMMARY:") {
                calendar.title = qrContent.components(separatedBy: "SUMMARY:")[1].components(separatedBy: "\n")[0]
            }
        case .location:
            // 位置格式简单处理
            let locationString = qrContent.replacingOccurrences(of: "geo:", with: "")
            let parts = locationString.split(separator: ",")
            if parts.count >= 2, 
               let lat = Double(parts[0]), 
               let lon = Double(parts[1]) {
                location.latitude = lat
                location.longitude = lon
            }
        }
    }
}

#Preview {
    QRCodeInputView(type: .text, qrContent: .constant(""))
}
