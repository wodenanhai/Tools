import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: splitPage
    property var pdfService
    property var feedbackDialog
    signal backRequested()

    property bool splitting: false

    function pickInput(filePath) {
        inputPdfField.text = filePath
    }

    function pickOutput(folderPath) {
        outputDirField.text = folderPath
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            Button {
                id: backButton
                text: qsTr("← 返回")
                onClicked: splitPage.backRequested()
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
                    background: Rectangle { color: "white"; radius: 14; border.color: "#dbe3ef"; border.width: 1 }
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10
                        Label { text: qsTr("输入 PDF"); font.bold: true; color: "#0f172a"; font.pixelSize: 16 }

                        Rectangle {
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
                                    inputPdfField.text = decodeURIComponent(first.replace("file://", ""))
                                    resultArea.text = qsTr("已通过拖拽选择文件")
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            TextField { id: inputPdfField; Layout.fillWidth: true; placeholderText: qsTr("请选择或拖入 PDF 文件") }
                            Button {
                                id: chooseFileButton
                                text: qsTr("选择文件")
                                background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                                contentItem: Text { text: chooseFileButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16 }
                                onClicked: splitPage.pickInputRequested()
                            }
                        }
                    }
                }

                Frame {
                    Layout.fillWidth: true
                    background: Rectangle { color: "white"; radius: 14; border.color: "#dbe3ef"; border.width: 1 }
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
                                background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                                contentItem: Text { text: chooseDirButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16 }
                                onClicked: splitPage.pickOutputRequested()
                            }
                        }
                    }
                }

                Frame {
                    Layout.fillWidth: true
                    background: Rectangle { color: "white"; radius: 14; border.color: "#dbe3ef"; border.width: 1 }
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10
                        Label { text: qsTr("拆分方式"); font.bold: true; color: "#0f172a"; font.pixelSize: 16 }
                        ComboBox { id: splitMode; Layout.preferredWidth: 300; model: [qsTr("全部拆分（按每N页）"), qsTr("按页码拆分（如 1-3,5）")] }

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
                            text: splitPage.splitting ? qsTr("拆分中...") : qsTr("开始拆分")
                            enabled: !splitPage.splitting
                            background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                            contentItem: Text { text: splitButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16; font.bold: true }
                            onClicked: {
                                splitPage.splitting = true
                                resultArea.text = ""
                                const inputPath = inputPdfField.text.trim()
                                const outputPath = outputDirField.text.trim()
                                if (inputPath.length === 0 || outputPath.length === 0) {
                                    resultArea.text = qsTr("请先选择输入 PDF 和输出目录")
                                    if (splitPage.feedbackDialog) { splitPage.feedbackDialog.text = resultArea.text; splitPage.feedbackDialog.open() }
                                    splitPage.splitting = false
                                    return
                                }

                                resultArea.text = qsTr("正在拆分，请稍候...")
                                progressBar.visible = true
                                progressLabel.visible = true
                                let started = false
                                if (splitMode.currentIndex === 0) {
                                    started = splitPage.pdfService.startSplitEveryNPages(inputPath, outputPath, pagesPerFileSpin.value)
                                } else {
                                    const expr = pageExprField.text.trim()
                                    if (expr.length === 0) {
                                        resultArea.text = qsTr("请输入页码表达式，例如 1-3,5")
                                        if (splitPage.feedbackDialog) { splitPage.feedbackDialog.text = resultArea.text; splitPage.feedbackDialog.open() }
                                        splitPage.splitting = false
                                        progressBar.visible = false
                                        progressLabel.visible = false
                                        return
                                    }
                                    started = splitPage.pdfService.startSplitByPageExpression(inputPath, outputPath, expr)
                                }

                                if (!started) {
                                    const errText = splitPage.pdfService.lastError
                                    resultArea.text = qsTr("拆分失败：") + (errText && errText.length > 0 ? errText : qsTr("未知错误"))
                                    splitPage.splitting = false
                                    progressBar.visible = false
                                    progressLabel.visible = false
                                    if (splitPage.feedbackDialog) { splitPage.feedbackDialog.text = resultArea.text; splitPage.feedbackDialog.open() }
                                }
                            }
                        }

                        ProgressBar {
                            id: progressBar
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            value: splitPage.pdfService ? splitPage.pdfService.splitProgress : 0
                            visible: false
                        }

                        Label {
                            id: progressLabel
                            visible: false
                            color: "#64748b"
                            text: qsTr("拆分进度：") + Math.round(progressBar.value) + "%"
                        }
                    }
                }

                Frame {
                    Layout.fillWidth: true
                    background: Rectangle { color: "#ffffff"; radius: 14; border.color: "#dbe3ef" }
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

    signal pickInputRequested()
    signal pickOutputRequested()

    Connections {
        target: splitPage.pdfService
        function onSplitCompleted(success, message, outputPath) {
            splitPage.splitting = false
            progressBar.visible = false
            progressLabel.visible = false
            progressBar.value = 0

            if (success) {
                resultArea.text = qsTr("拆分完成\n输出目录：") + outputPath
                splitPage.pdfService.openFolder(outputPath)
            } else {
                resultArea.text = qsTr("拆分失败：") + message
            }

            if (splitPage.feedbackDialog) {
                splitPage.feedbackDialog.text = resultArea.text
                splitPage.feedbackDialog.open()
            }
        }
    }
}
