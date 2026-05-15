import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: convertPage
    property var pdfService
    property var feedbackDialog
    signal backRequested()
    signal pickInputRequested()
    signal pickOutputRequested()

    property bool converting: false
    property var formatLabels: ({"png":"PNG（无损）", "jpg":"JPG（体积小）", "tiff":"TIFF（高质量）", "ppm":"PPM（原始）"})

    function pickInput(filePath) {
        inputField.text = filePath
    }

    function pickOutput(folderPath) {
        outputField.text = folderPath
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
                onClicked: convertPage.backRequested()
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
                text: qsTr("PDF 转图片")
                font.pixelSize: 30
                font.bold: true
                color: "#0f172a"
                Layout.fillWidth: true
            }
        }

        Label {
            text: qsTr("将 PDF 每页导出为图片，可选 PNG/JPG 与 DPI")
            color: "#64748b"
            font.pixelSize: 15
        }

        ScrollView {
            id: convertScroll
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                width: convertScroll.availableWidth
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
                            Layout.preferredHeight: 84
                            radius: 10
                            color: dragArea.containsDrag ? "#e0f2fe" : "#f8fafc"
                            border.width: 1
                            border.color: dragArea.containsDrag ? "#0ea5e9" : "#cbd5e1"

                            Label {
                                anchors.centerIn: parent
                                text: qsTr("拖拽 PDF 到这里")
                                color: "#334155"
                            }

                            DropArea {
                                id: dragArea
                                anchors.fill: parent
                                onDropped: function(drop) {
                                    if (!drop.hasUrls || drop.urls.length === 0)
                                        return
                                    const first = String(drop.urls[0])
                                    if (!first.toLowerCase().endsWith(".pdf")) {
                                        resultArea.text = qsTr("仅支持拖入 .pdf 文件")
                                        return
                                    }
                                    convertPage.pickInput(decodeURIComponent(first.replace("file://", "")))
                                    resultArea.text = qsTr("已通过拖拽选择文件")
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            TextField { id: inputField; Layout.fillWidth: true; placeholderText: qsTr("请选择 PDF 文件") }
                            Button {
                                id: chooseFileButton
                                text: qsTr("选择文件")
                                background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                                contentItem: Text { text: chooseFileButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16 }
                                onClicked: convertPage.pickInputRequested()
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
                            TextField { id: outputField; Layout.fillWidth: true; placeholderText: qsTr("请选择输出目录") }
                            Button {
                                id: chooseDirButton
                                text: qsTr("选择目录")
                                background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                                contentItem: Text { text: chooseDirButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16 }
                                onClicked: convertPage.pickOutputRequested()
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
                        Label { text: qsTr("导出设置"); font.bold: true; color: "#0f172a"; font.pixelSize: 16 }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: settingColumn.implicitHeight + 20
                            radius: 10
                            color: "#f8fafc"
                            border.color: "#e2e8f0"

                            ColumnLayout {
                                id: settingColumn
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    Label {
                                        text: qsTr("输出格式")
                                        color: "#334155"
                                        Layout.preferredWidth: 88
                                    }
                                    ComboBox {
                                        id: imageFormatBox
                                        Layout.fillWidth: true
                                        model: ["png", "jpg", "tiff", "ppm"]
                                        delegate: ItemDelegate {
                                            width: ListView.view.width
                                            text: convertPage.formatLabels[modelData] + " (" + modelData + ")"
                                        }
                                        contentItem: Text {
                                            leftPadding: 8
                                            rightPadding: 8
                                            text: convertPage.formatLabels[imageFormatBox.currentText] + " (" + imageFormatBox.currentText + ")"
                                            color: "#0f172a"
                                            verticalAlignment: Text.AlignVCenter
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Label {
                                        text: qsTr("分辨率 DPI")
                                        color: "#334155"
                                        Layout.preferredWidth: 88
                                    }
                                    SpinBox { id: dpiSpin; from: 72; to: 600; value: 150; editable: true }
                                    Label { text: qsTr("推荐：150-300"); color: "#64748b" }
                                    Item { Layout.fillWidth: true }
                                }
                            }
                        }

                        Button {
                            id: convertButton
                            text: convertPage.converting ? qsTr("转换中...") : qsTr("开始转换")
                            enabled: !convertPage.converting
                            background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                            contentItem: Text { text: convertButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16; font.bold: true }
                            onClicked: {
                                convertPage.converting = true
                                resultArea.text = ""

                                const inputPath = inputField.text.trim()
                                const outputPath = outputField.text.trim()
                                if (inputPath.length === 0 || outputPath.length === 0) {
                                    resultArea.text = qsTr("请先选择输入 PDF 和输出目录")
                                    if (convertPage.feedbackDialog) { convertPage.feedbackDialog.text = resultArea.text; convertPage.feedbackDialog.open() }
                                    convertPage.converting = false
                                    return
                                }

                                resultArea.text = qsTr("正在转换，请稍候...")
                                const ok = convertPage.pdfService.convertPdfToImages(inputPath, outputPath, imageFormatBox.currentText, dpiSpin.value)
                                if (ok) {
                                    resultArea.text = qsTr("转换完成\n输出目录：") + outputPath
                                    convertPage.pdfService.openFolder(outputPath)
                                } else {
                                    const errText = convertPage.pdfService.lastError
                                    resultArea.text = qsTr("转换失败：") + (errText && errText.length > 0 ? errText : qsTr("未知错误"))
                                }

                                if (convertPage.feedbackDialog) { convertPage.feedbackDialog.text = resultArea.text; convertPage.feedbackDialog.open() }
                                convertPage.converting = false
                            }
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
                        placeholderText: qsTr("转换结果会显示在这里")
                        background: null
                    }
                }
            }
        }
    }
}
