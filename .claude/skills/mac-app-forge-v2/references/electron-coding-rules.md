# Electron 编码规则

## 安全
1. **始终开启 `contextIsolation: true`**
2. **始终关闭 `nodeIntegration: false`**
3. 所有 Node.js API 通过 `preload.js` + `contextBridge` 暴露
4. 不要使用 `remote` 模块（已废弃且不安全）
5. 设置 Content Security Policy (CSP) header

## 架构
1. **主进程**: 文件操作、系统 API、窗口管理、菜单
2. **渲染进程**: UI 渲染、用户交互
3. **IPC 通信**: `ipcMain.handle()` + `ipcRenderer.invoke()` 模式
4. 不要在渲染进程中 `require()` Node 模块

## UI 规则
1. 使用系统字体: `font-family: -apple-system, BlinkMacSystemFont, system-ui`
2. 支持 Dark Mode: `@media (prefers-color-scheme: dark) { }`
3. 使用 `titleBarStyle: 'hiddenInset'` 获得原生感
4. 窗口圆角和毛玻璃效果用 `vibrancy` 和 `visualEffectState`
5. 不要引入 React/Vue 等大框架（除非功能确实需要），原生 DOM 操作足够

## 数据存储
1. 用户设置: `electron-store` 包
2. 结构化数据: `better-sqlite3`
3. 路径获取: `app.getPath('userData')`

## 打包
1. 使用 `electron-builder`（而非 electron-forge，兼容性更好）
2. `package.json` 的 `build` 字段配置打包选项
3. 设置 `"identity": null` 跳过签名
4. DMG 布局在 `build.dmg.contents` 中配置

## 性能
1. 窗口创建使用 `show: false` + `ready-to-show` 事件避免白屏
2. 大文件操作用 stream 而非一次读入内存
3. 避免同步 IPC（`ipcRenderer.sendSync`），始终用异步
