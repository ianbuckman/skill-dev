import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @State private var showClearAlert = false

    private let maxHistoryOptions = [100, 200, 500, 1000]

    var body: some View {
        @Bindable var appState = appState

        Form {
            Section("通用") {
                Picker("历史记录上限", selection: $appState.maxHistoryCount) {
                    ForEach(maxHistoryOptions, id: \.self) { count in
                        Text("\(count)").tag(count)
                    }
                }

                Toggle("记录图片", isOn: $appState.recordImages)

                Toggle("启动时自动运行", isOn: $launchAtLogin)
            }

            Section("快捷键") {
                LabeledContent("粘贴面板") {
                    Text("⌘+Shift+V")
                        .font(.system(.body, design: .monospaced))
                }

                Text("需要在 系统设置 → 隐私与安全 → 辅助功能 中授权")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("数据管理") {
                LabeledContent("当前历史条目") {
                    Text("\(appState.items.count)")
                }

                Button("清空所有历史", role: .destructive) {
                    showClearAlert = true
                }
            }

            Section("关于") {
                LabeledContent("版本") {
                    Text("1.0.0")
                }

                Text("ClipVault — 简洁优美的 macOS 剪贴板管理工具")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 350)
        .alert("确认清空", isPresented: $showClearAlert) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                appState.clearAll()
            }
        } message: {
            Text("将删除所有未固定的历史记录，此操作不可撤销。")
        }
    }
}
