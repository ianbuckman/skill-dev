# 打包指南：从构建产物到 .dmg

## Swift/SwiftUI 路线

Swift 编译出的是一个可执行文件，需要手动组装成 .app bundle，再打包为 .dmg。

### Step 1: Release 构建

```bash
swift build -c release --arch arm64
```

产物位置: `.build/release/[AppName]`

### Step 2: 组装 .app Bundle

.app 本质是一个特定结构的文件夹：

```
[AppName].app/
├── Contents/
│   ├── Info.plist
│   ├── MacOS/
│   │   └── [AppName]          # 可执行文件
│   ├── Resources/
│   │   ├── AppIcon.icns       # 应用图标
│   │   └── [其他资源]
│   └── PkgInfo                # 内容: "APPL????"
```

组装脚本（在项目根目录执行）：

```bash
#!/bin/bash
set -e

APP_NAME="[AppName]"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"

# 清理旧产物
rm -rf "${APP_BUNDLE}"

# 创建 bundle 结构
mkdir -p "${CONTENTS}/MacOS"
mkdir -p "${CONTENTS}/Resources"

# 复制可执行文件
cp "${BUILD_DIR}/${APP_NAME}" "${CONTENTS}/MacOS/${APP_NAME}"

# 复制 Info.plist
cp "Sources/${APP_NAME}/Resources/Info.plist" "${CONTENTS}/Info.plist"

# 复制图标（如果存在）
if [ -f "assets/AppIcon.icns" ]; then
    cp "assets/AppIcon.icns" "${CONTENTS}/Resources/AppIcon.icns"
fi

# 创建 PkgInfo
echo -n "APPL????" > "${CONTENTS}/PkgInfo"

# 设置可执行权限
chmod +x "${CONTENTS}/MacOS/${APP_NAME}"

echo "✅ ${APP_BUNDLE} 创建完成"
```

### Step 3: 生成 .dmg

#### 方案 A: create-dmg（推荐，美观）

```bash
# 安装: brew install create-dmg
create-dmg \
  --volname "[AppName]" \
  --volicon "assets/AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "[AppName].app" 175 190 \
  --hide-extension "[AppName].app" \
  --app-drop-link 425 190 \
  --no-internet-enable \
  "dist/${APP_NAME}.dmg" \
  "${APP_NAME}.app"
```

#### 方案 B: hdiutil（系统自带，基础）

```bash
mkdir -p dist
TEMP_DMG="dist/${APP_NAME}_temp.dmg"
FINAL_DMG="dist/${APP_NAME}.dmg"

# 创建临时可读写 DMG
hdiutil create -srcfolder "${APP_NAME}.app" \
  -volname "${APP_NAME}" \
  -fs HFS+ \
  -format UDRW \
  "${TEMP_DMG}"

# 挂载
MOUNT_DIR=$(hdiutil attach "${TEMP_DMG}" | grep "Volumes" | awk '{print $3}')

# 创建 Applications 符号链接
ln -s /Applications "${MOUNT_DIR}/Applications"

# 卸载
hdiutil detach "${MOUNT_DIR}"

# 转换为压缩只读 DMG
hdiutil convert "${TEMP_DMG}" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "${FINAL_DMG}"

# 清理
rm -f "${TEMP_DMG}"

echo "✅ ${FINAL_DMG} 创建完成"
```

### Step 4: 验证

```bash
# 检查 DMG 是否可以挂载
hdiutil attach "dist/${APP_NAME}.dmg" -noverify
ls -la "/Volumes/${APP_NAME}/"
hdiutil detach "/Volumes/${APP_NAME}"

# 检查文件大小
du -sh "dist/${APP_NAME}.dmg"
```

---

## Electron 路线

Electron 使用 electron-builder，一条命令搞定。

### 打包命令

```bash
npx electron-builder --mac dmg
```

产物位置: `dist/[AppName].dmg`

### 常见问题

1. **签名错误** — 在 package.json 中设置 `"mac": { "identity": null }` 跳过签名
2. **icon 格式错误** — electron-builder 需要 1024x1024 PNG，会自动生成 icns
3. **包体过大** — 检查是否意外打包了 `node_modules` 中不需要的包
4. **构建失败** — 确保 `main` 字段指向正确的入口文件

---

## 通用: 打包前检查清单

- [ ] Release 模式构建成功
- [ ] Info.plist / package.json 中的 app 名称、版本号正确
- [ ] 图标文件存在且格式正确
- [ ] 目标架构: arm64（Apple Silicon）
- [ ] dist/ 目录已创建
- [ ] 旧的 .dmg 已清理
