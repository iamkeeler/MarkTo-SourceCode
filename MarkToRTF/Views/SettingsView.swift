import SwiftUI

struct SettingsView: View {
    @AppStorage("fontSize") private var fontSize: Double = 14
    @AppStorage("showCharacterCount") private var showCharacterCount: Bool = true
    @AppStorage("autoLoadClipboard") private var autoLoadClipboard: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("MarkToRTF Settings")
                .font(.title2)
                .fontWeight(.medium)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Editor Settings")
                    .font(.headline)
                
                HStack {
                    Text("Font Size:")
                    Slider(value: $fontSize, in: 10...24, step: 1)
                    Text("\(Int(fontSize))pt")
                        .frame(width: 30)
                }
                
                Toggle("Show Character Count", isOn: $showCharacterCount)
                Toggle("Auto-load Clipboard Content", isOn: $autoLoadClipboard)
            }
            
            Spacer()
        }
        .padding(20)
        .frame(width: 350, height: 250)
    }
}
