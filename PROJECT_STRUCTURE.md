# 项目目录说明

本项目按“功能隔离、页面隔离、实现隔离”组织，避免不同功能互相干扰。

## 根目录

- [`Main.qml`](Main.qml)
  - 仅负责页面路由与公共弹窗协调，不承载具体业务逻辑。
- [`main.cpp`](main.cpp)
  - 程序入口，初始化 Qt、注册服务到 QML。
- [`CMakeLists.txt`](CMakeLists.txt)
  - 构建配置与 QML 模块声明。

## `qml/pages/`

功能页面层，每个页面独立维护自己的 UI 与交互逻辑。

- [`qml/pages/HomePage.qml`](qml/pages/HomePage.qml)
  - 功能区首页，只发出功能跳转信号。
- [`qml/pages/PdfSplitPage.qml`](qml/pages/PdfSplitPage.qml)
  - PDF 拆分页，维护拆分相关交互与展示。
- [`qml/pages/PdfToImagePage.qml`](qml/pages/PdfToImagePage.qml)
  - PDF 转图片页面，维护转换参数与执行流程。

## `src/services/`

业务实现层（C++），供 QML 调用。

- [`src/services/PdfSplitService.h`](src/services/PdfSplitService.h)
  - 服务接口声明（拆分、转图片、打开目录等）。
- [`src/services/PdfSplitService.cpp`](src/services/PdfSplitService.cpp)
  - 服务实现（qpdf/pdftoppm 调用、参数校验、错误处理）。

## 设计原则

1. 页面只负责页面内交互，跨页面通过信号/入口协调。
2. 业务命令执行下沉到 `src/services/`，避免 UI 与实现耦合。
3. 新增功能时优先新增独立页面文件 + 独立服务函数。





export PATH="/Users/zhangcheng/Qt/6.11.1/macos/bin:$PATH"


# 1. 进入你的 Release 构建目录
# 2. 完整打包 Qt 依赖（关键）
# 3. 清除隔离属性
# 4. 强制签名
# 5. 重新制作 DMG（用之前的命令）


cd /Users/zhangcheng/Desktop/Tools/build/Qt_6_11_1_for_macOS-Release

macdeployqt appTools.app -always-overwrite -executable=$(pwd)/appTools.app/Contents/MacOS/appTools -verbose=3

xattr -cr appTools.app

codesign --force --deep --sign - appTools.app

create-dmg \
  --volname "PDF Tools" \
  --window-pos 200 200 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "appTools.app" 150 180 \
  --hide-extension "appTools.app" \
  --app-drop-link 450 180 \
  "PDF-Tools.dmg" \
  "appTools.app"