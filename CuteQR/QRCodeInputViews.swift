import SwiftUI

// MARK: - URL Input View
struct URLInputView: View {
    @Binding var url: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("请输入网址", text: $url)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.URL)
                .textContentType(.URL)
                .textInputAutocapitalization(.none)
                .autocorrectionDisabled()
        }
    }
}

// MARK: - Contact Input View
struct ContactInputView: View {
    @Binding var contact: QRCodeDataType.Contact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("姓", text: $contact.lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.familyName)
            
            TextField("名", text: $contact.firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.givenName)
            
            TextField("电话", text: $contact.phone)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
            
            TextField("邮箱", text: $contact.email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.none)
            
            TextField("组织", text: $contact.organization)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.organizationName)
        }
    }
}

// MARK: - WiFi Input View
struct WiFiInputView: View {
    @Binding var wifi: QRCodeDataType.WiFi
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("网络名称 (SSID)", text: $wifi.ssid)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.none)
            
            SecureField("密码", text: $wifi.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.password)
            
            Picker("安全类型", selection: $wifi.security) {
                ForEach(QRCodeDataType.WiFi.SecurityType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Toggle("隐藏网络", isOn: $wifi.isHidden)
        }
    }
}

// MARK: - SMS Input View
struct SMSInputView: View {
    @Binding var sms: QRCodeDataType.SMS
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("电话号码", text: $sms.phone)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
            
            TextField("短信内容", text: $sms.message)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.none)
        }
    }
}

// MARK: - Phone Input View
struct PhoneInputView: View {
    @Binding var phone: QRCodeDataType.Phone
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("电话号码", text: $phone.number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
        }
    }
}

// MARK: - Email Input View
struct EmailInputView: View {
    @Binding var email: QRCodeDataType.Email
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("邮箱地址", text: $email.address)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.none)
            
            TextField("主题", text: $email.subject)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.none)
            
            TextField("正文", text: $email.body)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.none)
        }
    }
}

// MARK: - Location Input View
struct LocationInputView: View {
    @Binding var location: QRCodeDataType.Location
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("名称", text: $location.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.location)
            
            TextField("纬度", value: $location.latitude, format: .number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
            
            TextField("经度", value: $location.longitude, format: .number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
        }
    }
}

// MARK: - Calendar Input View
struct CalendarInputView: View {
    @Binding var calendar: QRCodeDataType.Calendar
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("标题", text: $calendar.title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.none)
            
            DatePicker("开始时间", selection: $calendar.startDate)
                .datePickerStyle(.compact)
            
            DatePicker("结束时间", selection: $calendar.endDate)
                .datePickerStyle(.compact)
            
            TextField("地点", text: $calendar.location)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.location)
            
            TextField("描述", text: $calendar.description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.none)
        }
    }
}

// MARK: - Previews
struct QRCodeInputViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            URLInputView(url: .constant("https://example.com"))
                .previewDisplayName("URL Input")
            
            ContactInputView(contact: .constant(QRCodeDataType.Contact()))
                .previewDisplayName("Contact Input")
            
            WiFiInputView(wifi: .constant(QRCodeDataType.WiFi()))
                .previewDisplayName("WiFi Input")
            
            LocationInputView(location: .constant(QRCodeDataType.Location()))
                .previewDisplayName("Location Input")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
