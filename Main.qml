import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window

ApplicationWindow {
    id: root
    width: 980
    height: 760
    visible: true
    title: qsTr("PDF Studio Toolbox")

    property bool splitting: false
    property int currentPage: 0 // 0: 功能区, 1: PDF拆分

    function toLocalPath(urlValue) {
        const s = String(urlValue)
        if (s.startsWith("file://")) {
            return decodeURIComponent(s.substring(7))
        }
        return s
    }

    FileDialog {
        id: inputPdfDialog
        title: qsTr("选择PDF文件")
        nameFilters: ["PDF files (*.pdf)"]
        fileMode: FileDialog.OpenFile
        onAccepted: inputPdfField.text = root.toLocalPath(selectedFile)
    }

    FolderDialog {
        id: outputFolderDialog
        title: qsTr("选择输出目录")
        onAccepted: outputDirField.text = root.toLocalPath(selectedFolder)
    }

    MessageDialog {
        id: feedbackDialog
        title: qsTr("提示")
        text: ""
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#eff6ff" }
            GradientStop { position: 1.0; color: "#f8fafc" }
        }
    }

    StackLayout {
        anchors.fill: parent
        currentIndex: root.currentPage

        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 20

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 130
                    radius: 20
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#2563eb" }
                        GradientStop { position: 1; color: "#1d4ed8" }
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Label { text: qsTr("PDF Studio Toolbox"); font.pixelSize: 34; font.bold: true; color: "white" }
                        Label { text: qsTr("高效处理 PDF：拆分、合并、更多工具持续增加"); color: "#dbeafe"; font.pixelSize: 15 }
                    }
                }

                Label {
                    text: qsTr("功能区")
                    font.pixelSize: 20
                    font.bold: true
                    color: "#0f172a"
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 16
                    rowSpacing: 16

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 170
                        radius: 16
                        color: "white"
                        border.color: splitHover.containsMouse ? "#3b82f6" : "#dbe3ef"
                        border.width: 1

                        Rectangle {
                            width: 44
                            height: 44
                            radius: 12
                            color: "#dbeafe"
                            anchors.left: parent.left
                            anchors.leftMargin: 18
                            anchors.top: parent.top
                            anchors.topMargin: 18
                            Label { anchors.centerIn: parent; text: "✂"; font.pixelSize: 22; color: "#1d4ed8" }
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 18
                            anchors.right: parent.right
                            anchors.rightMargin: 18
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 18
                            spacing: 8
                            Label { text: qsTr("拆分 PDF"); font.pixelSize: 24; font.bold: true; color: "#0f172a" }
                            Label { text: qsTr("支持按每 N 页拆分，或按页码表达式提取（如 1-3,5）"); color: "#64748b"; wrapMode: Text.WordWrap }
                        }

                        MouseArea {
                            id: splitHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentPage = 1
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 170
                        radius: 16
                        color: "white"
                        border.color: "#e2e8f0"
                        border.width: 1
                        opacity: 0.8

                        Rectangle {
                            width: 44
                            height: 44
                            radius: 12
                            color: "#f1f5f9"
                            anchors.left: parent.left
                            anchors.leftMargin: 18
                            anchors.top: parent.top
                            anchors.topMargin: 18
                            Label { anchors.centerIn: parent; text: "⇄"; font.pixelSize: 22; color: "#64748b" }
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 18
                            anchors.right: parent.right
                            anchors.rightMargin: 18
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 18
                            spacing: 8
                            Label { text: qsTr("合并 PDF"); font.pixelSize: 24; font.bold: true; color: "#64748b" }
                            Label { text: qsTr("即将上线"); color: "#94a3b8" }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        id: backButton
                        text: qsTr("← 返回")
                        onClicked: root.currentPage = 0
                        background: Rectangle {
                            radius: 10
                            color: backButton.down ? "#dbeafe" : (backButton.hovered ? "#eff6ff" : "white")
                            border.color: "#bfdbfe"
                        }
                        contentItem: Text {
                            text: backButton.text
                            color: "#111827"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }
                    Label {
                        text: qsTr("PDF 拆分")
                        font.pixelSize: 30
                        font.bold: true
                        color: "#0f172a"
                        Layout.fillWidth: true
                    }
                }

                Label {
                    text: qsTr("支持拖拽上传、按页数拆分、按页码提取")
                    color: "#64748b"
                    font.pixelSize: 15
                }

                ScrollView {
                    id: splitScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        width: splitScroll.availableWidth
                        spacing: 12

                        Frame {
                            Layout.fillWidth: true
                            background: Rectangle {
                                color: "white"
                                radius: 14
                                border.color: "#dbe3ef"
                                border.width: 1
                            }
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 10
                                Label { text: qsTr("输入 PDF"); font.bold: true; color: "#0f172a"; font.pixelSize: 16 }

                                Rectangle {
                                    id: dropZone
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 88
                                    radius: 10
                                    color: dragArea.containsDrag ? "#dbeafe" : "#f8fafc"
                                    border.width: 1
                                    border.color: dragArea.containsDrag ? "#3b82f6" : "#cbd5e1"
                                    Label { anchors.centerIn: parent; text: qsTr("拖拽 PDF 到这里"); color: "#334155" }

                                    DropArea {
                                        id: dragArea
                                        anchors.fill: parent
                                        onDropped: function(drop) {
                                            if (!drop.hasUrls || drop.urls.length === 0) return
                                            const first = String(drop.urls[0])
                                            if (!first.toLowerCase().endsWith(".pdf")) {
                                                resultArea.text = qsTr("仅支持拖入 .pdf 文件")
                                                return
                                            }
                                            inputPdfField.text = root.toLocalPath(first)
                                            resultArea.text = qsTr("已通过拖拽选择文件")
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    TextField {
                                        id: inputPdfField
                                        Layout.fillWidth: true
                                        placeholderText: qsTr("请选择或拖入 PDF 文件")
                                    }
                                    Button {
                                        id: chooseFileButton
                                        text: qsTr("选择文件")
                                        onClicked: inputPdfDialog.open()
                                        background: Rectangle {
                                            radius: 8
                                            color: "#ffffff"
                                            border.color: "#d1d5db"
                                        }
                                        contentItem: Text {
                                            text: chooseFileButton.text
                                            color: "#111827"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 16
                                        }
                                    }
                                }
                            }
                        }

                        Frame {
                            Layout.fillWidth: true
                            background: Rectangle {
                                color: "white"
                                radius: 14
                                border.color: "#dbe3ef"
                                border.width: 1
                            }
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 10
                                Label { text: qsTr("输出目录"); font.bold: true; color: "#0f172a"; font.pixelSize: 16 }
                                RowLayout {
                                    Layout.fillWidth: true
                                    TextField { id: outputDirField; Layout.fillWidth: true; placeholderText: qsTr("请选择输出目录") }
                                    Button {
                                        id: chooseDirButton
                                        text: qsTr("选择目录")
                                        onClicked: outputFolderDialog.open()
                                        background: Rectangle {
                                            radius: 8
                                            color: "#ffffff"
                                            border.color: "#d1d5db"
                                        }
                                        contentItem: Text {
                                            text: chooseDirButton.text
                                            color: "#111827"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 16
                                        }
                                    }
                                }
                            }
                        }

                        Frame {
                            Layout.fillWidth: true
                            background: Rectangle {
                                color: "white"
                                radius: 14
                                border.color: "#dbe3ef"
                                border.width: 1
                            }
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 10

                                Label { text: qsTr("拆分方式"); font.bold: true; color: "#0f172a"; font.pixelSize: 16 }
                                ComboBox {
                                    id: splitMode
                                    Layout.preferredWidth: 300
                                    model: [qsTr("全部拆分（按每N页）"), qsTr("按页码拆分（如 1-3,5）")]
                                }

                                RowLayout {
                                    visible: splitMode.currentIndex === 0
                                    Label { text: qsTr("每个文件页数") }
                                    SpinBox { id: pagesPerFileSpin; from: 1; to: 5000; value: 1; editable: true }
                                }

                                RowLayout {
                                    visible: splitMode.currentIndex === 1
                                    Layout.fillWidth: true
                                    Label { text: qsTr("页码") }
                                    TextField { id: pageExprField; Layout.fillWidth: true; placeholderText: qsTr("例如：1-3,5") }
                                }

                                Button {
                                    id: splitButton
                                    text: root.splitting ? qsTr("拆分中...") : qsTr("开始拆分")
                                    enabled: !root.splitting
                                    background: Rectangle {
                                        radius: 8
                                        color: "#ffffff"
                                        border.color: "#d1d5db"
                                    }
                                    contentItem: Text {
                                        text: splitButton.text
                                        color: "#111827"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 16
                                        font.bold: true
                                    }
                                    onClicked: {
                                        root.splitting = true
                                        resultArea.text = ""
                                        const inputPath = inputPdfField.text.trim()
                                        const outputPath = outputDirField.text.trim()
                                        if (inputPath.length === 0 || outputPath.length === 0) {
                                            resultArea.text = qsTr("请先选择输入 PDF 和输出目录")
                                            feedbackDialog.text = resultArea.text
                                            feedbackDialog.open()
                                            root.splitting = false
                                            return
                                        }

                                        resultArea.text = qsTr("正在拆分，请稍候...")
                                        let ok = false
                                        if (splitMode.currentIndex === 0) {
                                            ok = pdfSplitService.splitEveryNPages(inputPath, outputPath, pagesPerFileSpin.value)
                                        } else {
                                            const expr = pageExprField.text.trim()
                                            if (expr.length === 0) {
                                                resultArea.text = qsTr("请输入页码表达式，例如 1-3,5")
                                                feedbackDialog.text = resultArea.text
                                                feedbackDialog.open()
                                                root.splitting = false
                                                return
                                            }
                                            const outputFile = outputPath + "/selected_pages.pdf"
                                            ok = pdfSplitService.splitByPageExpression(inputPath, outputFile, expr)
                                        }

                                        if (ok) {
                                            if (splitMode.currentIndex === 0) {
                                                resultArea.text = qsTr("拆分完成\n输出目录：") + outputPath
                                            } else {
                                                resultArea.text = qsTr("拆分完成\n输出文件：") + outputPath + "/selected_pages.pdf"
                                            }
                                            pdfSplitService.openFolder(outputPath)
                                        } else {
                                            const errText = pdfSplitService.lastError
                                            resultArea.text = qsTr("拆分失败：") + (errText && errText.length > 0 ? errText : qsTr("未知错误"))
                                        }
                                        feedbackDialog.text = resultArea.text
                                        feedbackDialog.open()
                                        root.splitting = false
                                    }
                                }
                            }
                        }

                        Frame {
                            Layout.fillWidth: true
                            background: Rectangle {
                                color: "#ffffff"
                                radius: 14
                                border.color: "#dbe3ef"
                            }
                            TextArea {
                                id: resultArea
                                anchors.fill: parent
                                anchors.margins: 8
                                readOnly: true
                                color: "#0f172a"
                                wrapMode: Text.Wrap
                                placeholderText: qsTr("执行结果会显示在这里")
                                background: null
                            }
                        }
                    }
                }
            }
        }
    }
}
