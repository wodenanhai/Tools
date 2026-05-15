import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: mergePage
    property var pdfService
    property var feedbackDialog
    signal backRequested()
    signal pickInputRequested()
    signal pickOutputRequested()

    property var selectedPdfs: []

    function addInputFiles(filePaths) {
        if (!filePaths || filePaths.length === 0) return
        let appended = 0
        for (let i = 0; i < filePaths.length; ++i) {
            const p = String(filePaths[i]).trim()
            if (p.length > 0 && selectedPdfs.indexOf(p) === -1) {
                selectedPdfs.push(p)
                appended++
            }
        }
        // 触发 QML 绑定刷新，确保 ListView 立即显示
        selectedPdfs = selectedPdfs.slice(0)
        if (appended > 0) {
            resultArea.text = qsTr("已添加 ") + appended + qsTr(" 个 PDF，当前共 ") + selectedPdfs.length + qsTr(" 个")
        } else {
            resultArea.text = qsTr("未添加新文件（可能已存在于列表）")
        }
    }

    function pickOutput(path) {
        outputField.text = path
    }

    function moveUp(index) {
        if (index <= 0 || index >= selectedPdfs.length)
            return
        const arr = selectedPdfs.slice(0)
        const tmp = arr[index - 1]
        arr[index - 1] = arr[index]
        arr[index] = tmp
        selectedPdfs = arr
        resultArea.text = qsTr("已上移第 ") + (index + 1) + qsTr(" 个文件")
    }

    function moveDown(index) {
        if (index < 0 || index >= selectedPdfs.length - 1)
            return
        const arr = selectedPdfs.slice(0)
        const tmp = arr[index + 1]
        arr[index + 1] = arr[index]
        arr[index] = tmp
        selectedPdfs = arr
        resultArea.text = qsTr("已下移第 ") + (index + 1) + qsTr(" 个文件")
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
                onClicked: mergePage.backRequested()
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
                text: qsTr("PDF 合并")
                font.pixelSize: 30
                font.bold: true
                color: "#0f172a"
                Layout.fillWidth: true
            }
        }

        Label {
            text: qsTr("选择多个 PDF 按列表顺序合并为一个文件")
            color: "#64748b"
            font.pixelSize: 15
        }

        Frame {
            Layout.fillWidth: true
            background: Rectangle { color: "white"; radius: 14; border.color: "#dbe3ef"; border.width: 1 }
            ColumnLayout {
                anchors.fill: parent
                spacing: 8
                Label { text: qsTr("输入 PDF 列表"); font.bold: true; color: "#0f172a"; font.pixelSize: 16 }
                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        id: chooseFilesButton
                        text: qsTr("选择多个 PDF")
                        onClicked: mergePage.pickInputRequested()
                        background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                        contentItem: Text { text: chooseFilesButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16 }
                    }
                    Button {
                        id: clearButton
                        text: qsTr("清空列表")
                        background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                        contentItem: Text { text: clearButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16 }
                        onClicked: {
                            mergePage.selectedPdfs = []
                            resultArea.text = qsTr("已清空文件列表")
                        }
                    }
                    Item { Layout.fillWidth: true }
                }

                Label {
                    text: qsTr("已选择：") + mergePage.selectedPdfs.length + qsTr(" 个文件")
                    color: "#64748b"
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 230
                    clip: true
                    model: mergePage.selectedPdfs
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 42
                        color: index % 2 === 0 ? "#f8fafc" : "#ffffff"
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            Label { text: (index + 1) + "."; color: "#64748b" }
                            Label { text: modelData; elide: Text.ElideMiddle; Layout.fillWidth: true; color: "#0f172a" }
                            Button {
                                id: upBtn
                                text: qsTr("上移")
                                enabled: index > 0
                                onClicked: mergePage.moveUp(index)
                                background: Rectangle { radius: 6; color: "#ffffff"; border.color: "#d1d5db" }
                                contentItem: Text { text: upBtn.text; color: upBtn.enabled ? "#111827" : "#9ca3af"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 13 }
                            }
                            Button {
                                id: downBtn
                                text: qsTr("下移")
                                enabled: index < (mergePage.selectedPdfs.length - 1)
                                onClicked: mergePage.moveDown(index)
                                background: Rectangle { radius: 6; color: "#ffffff"; border.color: "#d1d5db" }
                                contentItem: Text { text: downBtn.text; color: downBtn.enabled ? "#111827" : "#9ca3af"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 13 }
                            }
                        }
                    }
                }
            }
        }

        Frame {
            Layout.fillWidth: true
            background: Rectangle { color: "white"; radius: 14; border.color: "#dbe3ef"; border.width: 1 }
            ColumnLayout {
                anchors.fill: parent
                spacing: 8
                Label { text: qsTr("输出文件"); font.bold: true; color: "#0f172a"; font.pixelSize: 16 }
                RowLayout {
                    Layout.fillWidth: true
                    TextField { id: outputField; Layout.fillWidth: true; placeholderText: qsTr("选择输出目录后默认文件名 merged.pdf") }
                    Button {
                        id: chooseOutButton
                        text: qsTr("选择目录")
                        onClicked: mergePage.pickOutputRequested()
                        background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                        contentItem: Text { text: chooseOutButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16 }
                    }
                }
                Button {
                    id: mergeButton
                    text: qsTr("开始合并")
                    background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                    contentItem: Text { text: mergeButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16; font.bold: true }
                    onClicked: {
                        if (mergePage.selectedPdfs.length < 2) {
                            resultArea.text = qsTr("至少选择两个 PDF 文件")
                            if (mergePage.feedbackDialog) { mergePage.feedbackDialog.text = resultArea.text; mergePage.feedbackDialog.open() }
                            return
                        }
                        let out = outputField.text.trim()
                        if (out.length === 0) {
                            resultArea.text = qsTr("请先选择输出目录")
                            if (mergePage.feedbackDialog) { mergePage.feedbackDialog.text = resultArea.text; mergePage.feedbackDialog.open() }
                            return
                        }
                        if (!out.toLowerCase().endsWith(".pdf")) {
                            out = out.replace(/\/+$/g, "") + "/merged.pdf"
                        }
                        const ok = mergePage.pdfService.mergePdfs(mergePage.selectedPdfs, out)
                        if (ok) {
                            resultArea.text = qsTr("合并完成\n输出文件：") + out
                            mergePage.pdfService.openFolder(out.substring(0, out.lastIndexOf('/')))
                        } else {
                            resultArea.text = qsTr("合并失败：") + mergePage.pdfService.lastError
                        }
                        if (mergePage.feedbackDialog) { mergePage.feedbackDialog.text = resultArea.text; mergePage.feedbackDialog.open() }
                    }
                }
            }
        }

        Frame {
            Layout.fillWidth: true
            background: Rectangle { color: "#fff"; radius: 14; border.color: "#dbe3ef" }
            TextArea {
                id: resultArea
                anchors.fill: parent
                anchors.margins: 8
                readOnly: true
                wrapMode: Text.Wrap
                placeholderText: qsTr("执行结果会显示在这里")
                background: null
            }
        }
    }
}
