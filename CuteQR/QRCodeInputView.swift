import SwiftUI

struct QRCodeInputView: View {
    let type: QRCodeDataType
    @Binding var qrContent: String
    
    // 状态变量
    @State private var urlInput = ""
    @State private var contact = QRCodeDataType.Contact(firstName: "", lastName: "", phone: "", email: "", organization: "")
    @State private var wifi = QRCodeDataType.WiFi(ssid: "", password: "", security: .wpa, isHidden: false)
    @State private var sms = QRCodeDataType.SMS(phone: "", message: "")
    @State private var phone = QRCodeDataType.Phone(number: "")
    @State private var email = QRCodeDataType.Email(address: "", subject: "", body: "")
    @State private var calendar = QRCodeDataType.Calendar(title: "", startDate: Date(), endDate: Date(), description: "", location: "")
    
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
                        qrContent = newValue
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
                TextField("请输入位置内容", text: $qrContent)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.default)
                    .textContentType(.none)
                    .textInputAutocapitalization(.sentences)
            }
        }
    }
    
    private func initializeContent() {
        switch type {
        case .text:
            break // 文本类型直接使用 qrContent
        case .url:
            urlInput = qrContent
        case .contact:
            if let parsedContact = QRCodeStringParser.parseVCard(qrContent) {
                contact = parsedContact
            }
        case .wifi:
            if let parsedWiFi = QRCodeStringParser.parseWiFi(qrContent) {
                wifi = parsedWiFi
            }
        case .sms:
            if let parsedSMS = QRCodeStringParser.parseSMS(qrContent) {
                sms = parsedSMS
            }
        case .phone:
            phone = QRCodeDataType.Phone(number: qrContent.replacingOccurrences(of: "tel:", with: ""))
        case .email:
            if let parsedEmail = QRCodeStringParser.parseEmail(qrContent) {
                email = parsedEmail
            }
        case .calendar:
            if let parsedCalendar = QRCodeStringParser.parseCalendar(qrContent) {
                calendar = parsedCalendar
            }
        case .location:
            break // 位置类型直接使用 qrContent
        }
    }
}

#Preview {
    QRCodeInputView(type: .text, qrContent: .constant(""))
}
