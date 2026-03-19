# Electron 脚手架模板

## 项目结构

```
[AppName]/
├── package.json
├── src/
│   ├── main.js              # Electron 主进程
│   ├── preload.js            # 预加载脚本（安全桥接）
│   ├── renderer/
│   │   ├── index.html        # 主页面
│   │   ├── styles.css        # 样式
│   │   ├── app.js            # 渲染进程逻辑
│   │   └── components/       # UI 组件
│   └── services/             # 业务逻辑（主进程侧）
├── assets/
│   ├── icon.png              # 1024x1024 App 图标
│   └── dmg-background.png    # DMG 背景图（可选）
├── CLAUDE.md
├── ARCHITECTURE.md
└── README.md
```

## package.json 模板

```json
{
  "name": "[appname]",
  "version": "1.0.0",
  "description": "[一句话描述]",
  "main": "src/main.js",
  "scripts": {
    "start": "electron .",
    "build": "electron-builder --mac dmg",
    "dev": "electron . --enable-logging"
  },
  "build": {
    "appId": "com.local.[appname]",
    "productName": "[AppName]",
    "mac": {
      "category": "public.app-category.utilities",
      "target": ["dmg"],
      "icon": "assets/icon.png",
      "identity": null
    },
    "dmg": {
      "title": "[AppName]",
      "contents": [
        { "x": 130, "y": 220 },
        { "x": 410, "y": 220, "type": "link", "path": "/Applications" }
      ]
    }
  },
  "devDependencies": {
    "electron": "^33.0.0",
    "electron-builder": "^25.0.0"
  }
}
```

## main.js 模板

```javascript
const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 900,
    height: 600,
    titleBarStyle: 'hiddenInset',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  mainWindow.loadFile(path.join(__dirname, 'renderer', 'index.html'));
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) createWindow();
});
```

## preload.js 模板

```javascript
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('api', {
  // 暴露安全的 API 给渲染进程
  // send: (channel, data) => ipcRenderer.send(channel, data),
  // on: (channel, callback) => ipcRenderer.on(channel, (event, ...args) => callback(...args)),
});
```

## 项目级 CLAUDE.md 模板

```markdown
# [AppName] — CLAUDE.md

## 项目概述
[一句话描述]

## 技术栈
- Electron 33+
- 原生 HTML/CSS/JS（不使用框架，保持简单）
- electron-builder 打包

## 编码规则
- **安全第一**: 始终使用 contextIsolation + preload，不要开启 nodeIntegration
- **主进程 vs 渲染进程**: 业务逻辑放主进程，UI 放渲染进程，通过 IPC 通信
- **样式**: 使用系统字体 `-apple-system, BlinkMacSystemFont`，深色/浅色主题跟随系统
- **文件操作**: 通过 IPC 在主进程中执行，不要在渲染进程直接操作文件
- **错误处理**: 所有 async 操作用 try-catch，向用户展示友好错误信息

## 构建
- 开发: `npm start`
- 打包: `npm run build`
- 产物: `dist/[AppName].dmg`

## 常见陷阱
- ⚠️ 不要在渲染进程中 require('fs') 或其他 Node 模块
- ⚠️ 不要使用 remote 模块（已废弃）
- ⚠️ CSP（内容安全策略）可能阻止内联脚本，用外部文件
```
