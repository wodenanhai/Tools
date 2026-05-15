import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: compressPage
    property var pdfService
    property var feedbackDialog
    signal backRequested()
    signal pickInputRequested()
    signal pickOutputRequested()

    property bool compressing: false

    function pickInput(filePath) {
        inputField.text = filePath
    }

    function pickOutput(path) {
        outputField.text = path
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
                onClicked: compressPage.backRequested()
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
                text: qsTr("PDF 压缩")
                font.pixelSize: 30
                font.bold: true
                color: "#0f172a"
                Layout.fillWidth: true
            }
        }

        Label {
            text: qsTr("使用 Ghostscript 压缩 PDF，平衡体积与清晰度")
            color: "#64748b"
            font.pixelSize: 15
        }

        ScrollView {
            id: compressScroll
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                width: compressScroll.availableWidth
                spacing: 12

                Frame {
                    Layout.fillWidth: true
                    background: Rectangle { color: "white"; radius: 14; border.color: "#dbe3ef"; border.width: 1 }
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10
                        Label { text: qsTr("输入 PDF"); font.bold: true; color: "#0f172a"; font.pixelSize: 16 }
                        RowLayout {
                            Layout.fillWidth: true
                            TextField { id: inputField; Layout.fillWidth: true; placeholderText: qsTr("请选择 PDF 文件") }
                            Button {
                                id: chooseFileButton
                                text: qsTr("选择文件")
                                background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                                contentItem: Text { text: chooseFileButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16 }
                                onClicked: compressPage.pickInputRequested()
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
                        Label { text: qsTr("输出文件"); font.bold: true; color: "#0f172a"; font.pixelSize: 16 }
                        RowLayout {
                            Layout.fillWidth: true
                            TextField { id: outputField; Layout.fillWidth: true; placeholderText: qsTr("选择目录后默认 compressed.pdf") }
                            Button {
                                id: chooseDirButton
                                text: qsTr("选择目录")
                                background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                                contentItem: Text { text: chooseDirButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16 }
                                onClicked: compressPage.pickOutputRequested()
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
                        Label { text: qsTr("压缩设置"); font.bold: true; color: "#0f172a"; font.pixelSize: 16 }

                        ComboBox {
                            id: qualityBox
                            Layout.preferredWidth: 320
                            model: ["screen", "ebook", "printer", "prepress"]
                        }

                        Label {
                            color: "#64748b"
                            text: qsTr("screen体积最小；ebook平衡；printer/prepress质量更高")
                        }

                        RowLayout {
                            spacing: 10
                            Button {
                                id: compressButton
                                text: compressPage.compressing ? qsTr("压缩中...") : qsTr("开始压缩")
                                enabled: !compressPage.compressing
                                background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                                contentItem: Text { text: compressButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16; font.bold: true }
                                onClicked: {
                                    compressPage.compressing = true
                                    resultArea.text = ""
                                    const inputPath = inputField.text.trim()
                                    let out = outputField.text.trim()
                                    if (inputPath.length === 0 || out.length === 0) {
                                        resultArea.text = qsTr("请先选择输入 PDF 和输出路径")
                                        if (compressPage.feedbackDialog) { compressPage.feedbackDialog.text = resultArea.text; compressPage.feedbackDialog.open() }
                                        compressPage.compressing = false
                                        return
                                    }
                                    if (!out.toLowerCase().endsWith(".pdf")) {
                                        out = out.replace(/\/+$/g, "") + "/compressed.pdf"
                                    }

                                    progressBar.visible = true
                                    progressLabel.visible = true
                                    resultArea.text = qsTr("正在压缩，请稍候...")
                                    const started = compressPage.pdfService.startCompressPdf(inputPath, out, "/" + qualityBox.currentText)
                                    if (!started) {
                                        const errText = compressPage.pdfService.lastError
                                        resultArea.text = qsTr("压缩失败：") + (errText && errText.length > 0 ? errText : qsTr("未知错误"))
                                        if (compressPage.feedbackDialog) { compressPage.feedbackDialog.text = resultArea.text; compressPage.feedbackDialog.open() }
                                        compressPage.compressing = false
                                        progressBar.visible = false
                                        progressLabel.visible = false
                                    }
                                }
                            }

                            Button {
                                id: cancelButton
                                text: qsTr("中断压缩")
                                enabled: compressPage.compressing
                                background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                                contentItem: Text { text: cancelButton.text; color: cancelButton.enabled ? "#111827" : "#9ca3af"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16; font.bold: true }
                                onClicked: {
                                    const ok = compressPage.pdfService.cancelCompressPdf()
                                    if (!ok) {
                                        resultArea.text = qsTr("中断失败：") + compressPage.pdfService.lastError
                                        if (compressPage.feedbackDialog) { compressPage.feedbackDialog.text = resultArea.text; compressPage.feedbackDialog.open() }
                                    }
                                }
                            }
                        }

                        ProgressBar {
                            id: progressBar
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            value: compressPage.pdfService ? compressPage.pdfService.compressProgress : 0
                            visible: false
                        }

                        Label {
                            id: progressLabel
                            visible: false
                            color: "#64748b"
                            text: qsTr("压缩进度：") + Math.round(progressBar.value) + "%"
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
                        placeholderText: qsTr("压缩结果会显示在这里")
                        background: null
                    }
                }
            }
        }
    }

    Connections {
        target: compressPage.pdfService
        function onCompressCompleted(success, message, outputPdf) {
            compressPage.compressing = false
            progressBar.visible = false
            progressLabel.visible = false
            progressBar.value = 0

            if (success) {
                resultArea.text = qsTr("压缩完成\n输出文件：") + outputPdf
                const slash = outputPdf.lastIndexOf('/')
                if (slash > 0) {
                    compressPage.pdfService.openFolder(outputPdf.substring(0, slash))
                }
            } else {
                resultArea.text = qsTr("压缩失败：") + message
            }

            if (compressPage.feedbackDialog) {
                compressPage.feedbackDialog.text = resultArea.text
                compressPage.feedbackDialog.open()
            }
        }
    }
}
