# ClipVault — Architecture

## 技术栈
- **语言**: Swift 5.10+（启用 StrictConcurrency）
- **UI 框架**: SwiftUI（macOS 14+ / Sonoma）
- **App 类型**: Menu Bar App（MenuBarExtra + .window style）
- **数据持久化**: JSON 文件存储于 `~/Library/Application Support/ClipVault/`
- **系统集成**: NSPasteboard 监听、NSEvent 全局快捷键
- **依赖**: 无第三方依赖

## 项目结构

```
ClipVault/
├── Package.swift
├── Sources/
│   └── ClipVault/
│       ├── ClipVaultApp.swift              # @main 入口
│       ├── Models/
│       │   ├── AppState.swift              # @Observable 全局状态
│       │   └── ClipboardItem.swift         # 剪贴板条目数据模型
│       ├── Services/
│       │   ├── ClipboardMonitor.swift      # 系统剪贴板监听服务
│       │   ├── StorageService.swift        # JSON 持久化服务
│       │   └── HotkeyService.swift         # 全局快捷键服务
│       ├── Views/
│       │   ├── ClipboardListView.swift     # 主列表视图（搜索+历史）
│       │   ├── ClipboardRowView.swift      # 单条记录行视图
│       │   └── SettingsView.swift          # 设置视图
│       └── Resources/
│           └── Info.plist
├── Tests/
│   └── ClipVaultTests/
├── CLAUDE.md
├── ARCHITECTURE.md
├── phase1_concept.md
└── README.md
```

## 核心模块设计

### M1: ClipboardItem（数据模型）
剪贴板条目的数据结构。包含 id（UUID）、content（枚举：text/image）、timestamp、isPinned、preview（文本前 100 字符或图片缩略尺寸描述）。Codable 以支持 JSON 持久化。图片存为 Base64 编码的 Data。

### M2: AppState（全局状态）
@Observable 类，持有 items: [ClipboardItem]、searchText: String、filteredItems（计算属性，根据 searchText 过滤并将 pinned 置顶）。提供 add/delete/pin/unpin/clear/copyToClipboard 等方法。启动时从 StorageService 加载数据。

### M3: ClipboardMonitor（剪贴板监听）
用 Timer 定期轮询 NSPasteboard.general 的 changeCount。检测到变化时读取内容（文本优先，其次图片），创建 ClipboardItem 并通知 AppState。避免记录自身复制操作（通过标记位）。

### M4: StorageService（持久化）
JSON 文件读写。保存路径 ~/Library/Application Support/ClipVault/history.json。提供 save([ClipboardItem]) 和 load() -> [ClipboardItem] 方法。写入用 debounce 避免频繁 IO（变更后 2 秒内合并写入）。

### M5: HotkeyService（全局快捷键）
用 NSEvent.addGlobalMonitorForEvents 监听 ⌘+Shift+V。触发时通过回调通知 App 层切换 popover 可见性。强引用持有 monitor 返回值。

### M6: ClipboardListView（主列表视图）
搜索栏 + 列表。顶部搜索框绑定 AppState.searchText。列表显示 filteredItems。支持键盘导航。底部工具栏有"清空全部"按钮。

### M7: ClipboardRowView（行视图）
显示单条记录：图标（文本/图片）、内容预览（文本截断显示，图片显示缩略图）、时间戳。右侧有 pin 按钮和删除按钮。点击整行触发复制。hover 高亮效果。

### M8: SettingsView + App 入口
设置视图：历史记录上限（默认 500 条）、是否记录图片、清空历史按钮。App 入口组装 MenuBarExtra scene，注入 environment。

## 数据流

```
NSPasteboard → ClipboardMonitor(Timer 轮询)
    → AppState.add(item)
        → StorageService.save(items)  [debounced]
        → UI 自动更新（@Observable）

用户点击条目 → AppState.copyToClipboard(item)
    → NSPasteboard.general.setString/setData
    → ClipboardMonitor 忽略本次变更（skipNextChange 标记）
```

## 实现批次

### Batch 1: 核心基础（M1-M4）
- M1: ClipboardItem — 数据模型
- M2: AppState — 全局状态管理
- M3: ClipboardMonitor — 剪贴板监听
- M4: StorageService — 持久化存储

验证标准:
- 应用编译通过
- ClipboardItem 可正确编码/解码 JSON
- AppState 的 add/delete/pin/filter 逻辑正确

### Batch 2: UI 与交互（M5-M8）
- M5: HotkeyService — 全局快捷键
- M6: ClipboardListView — 主列表视图
- M7: ClipboardRowView — 行视图
- M8: SettingsView + App 入口 — 设置与入口组装

验证标准:
- 应用启动后 Menu Bar 图标出现
- 点击图标弹出历史面板
- 复制文本后历史中出现新条目
- 搜索可过滤条目
- 点击条目可复制回剪贴板
