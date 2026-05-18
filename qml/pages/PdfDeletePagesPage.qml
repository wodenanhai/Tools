import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: deletePage
    property var pdfService
    property var feedbackDialog
    signal backRequested()
    signal pickInputRequested()
    signal pickOutputRequested()

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
                onClicked: deletePage.backRequested()
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
                text: qsTr("PDF 删除页")
                font.pixelSize: 30
                font.bold: true
                color: "#0f172a"
                Layout.fillWidth: true
            }
        }

        Label {
            text: qsTr("输入要删除的页码，例如：1,2,3 或 1-3")
            color: "#64748b"
            font.pixelSize: 15
        }

        ScrollView {
            id: deleteScroll
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                width: deleteScroll.availableWidth
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
                                    inputField.text = decodeURIComponent(first.replace("file://", ""))
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
                                onClicked: deletePage.pickInputRequested()
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
                            TextField { id: outputField; Layout.fillWidth: true; placeholderText: qsTr("选择目录后默认文件名 deleted_pages.pdf") }
                            Button {
                                id: chooseDirButton
                                text: qsTr("选择目录")
                                background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                                contentItem: Text { text: chooseDirButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16 }
                                onClicked: deletePage.pickOutputRequested()
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
                        Label { text: qsTr("删除设置"); font.bold: true; color: "#0f172a"; font.pixelSize: 16 }
                        TextField {
                            id: deleteExprField
                            Layout.fillWidth: true
                            placeholderText: qsTr("输入页码，例如 1,2,3 或 1-3")
                        }

                        Button {
                            id: deleteButton
                            text: qsTr("开始删除")
                            background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                            contentItem: Text { text: deleteButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16; font.bold: true }
                            onClicked: {
                                resultArea.text = ""
                                const inputPath = inputField.text.trim()
                                let out = outputField.text.trim()
                                const expr = deleteExprField.text.trim()

                                if (inputPath.length === 0 || out.length === 0) {
                                    resultArea.text = qsTr("请先选择输入 PDF 和输出路径")
                                    if (deletePage.feedbackDialog) { deletePage.feedbackDialog.text = resultArea.text; deletePage.feedbackDialog.open() }
                                    return
                                }
                                if (expr.length === 0) {
                                    resultArea.text = qsTr("请输入要删除的页码")
                                    if (deletePage.feedbackDialog) { deletePage.feedbackDialog.text = resultArea.text; deletePage.feedbackDialog.open() }
                                    return
                                }

                                if (!out.toLowerCase().endsWith(".pdf")) {
                                    out = out.replace(/\/+$/g, "") + "/deleted_pages.pdf"
                                }

                                const ok = deletePage.pdfService.deletePagesByExpression(inputPath, out, expr)
                                if (ok) {
                                    resultArea.text = qsTr("删除页完成\n输出文件：") + out
                                    const slash = out.lastIndexOf('/')
                                    if (slash > 0) {
                                        deletePage.pdfService.openFolder(out.substring(0, slash))
                                    }
                                } else {
                                    resultArea.text = qsTr("删除失败：") + deletePage.pdfService.lastError
                                }

                                if (deletePage.feedbackDialog) {
                                    deletePage.feedbackDialog.text = resultArea.text
                                    deletePage.feedbackDialog.open()
                                }
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
                        placeholderText: qsTr("执行结果会显示在这里")
                        background: null
                    }
                }
            }
        }
    }
}
