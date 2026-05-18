import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: rotatePage
    property var pdfService
    property var feedbackDialog
    signal backRequested()
    signal pickInputRequested()
    signal pickOutputRequested()

    property var previewImages: []
    property var pageAngles: []
    property int selectedPageIndex: -1

    function pickInput(filePath) {
        inputField.text = filePath
        const previews = rotatePage.pdfService.generatePdfAllPagePreviews(filePath)
        if (previews && previews.length > 0) {
            previewImages = previews
            pageAngles = []
            for (let i = 0; i < previews.length; ++i) {
                pageAngles.push(0)
            }
            selectedPageIndex = 0
            resultArea.text = qsTr("已加载预览页：") + previews.length
        } else {
            previewImages = []
            pageAngles = []
            selectedPageIndex = -1
            resultArea.text = qsTr("预览图生成失败：") + rotatePage.pdfService.lastError
        }
    }

    function pickOutput(path) {
        outputField.text = path
    }

    function normalizeAngle(v) {
        let x = v % 360
        if (x < 0) x += 360
        return x
    }

    function rotateSelected(delta) {
        if (selectedPageIndex < 0 || selectedPageIndex >= pageAngles.length) {
            resultArea.text = qsTr("请先选择要旋转的页面")
            return
        }
        const arr = pageAngles.slice(0)
        arr[selectedPageIndex] = normalizeAngle(arr[selectedPageIndex] + delta)
        pageAngles = arr
        resultArea.text = qsTr("已旋转第 ") + (selectedPageIndex + 1) + qsTr(" 页")
    }

    function saveAll() {
        const inputPath = inputField.text.trim()
        let out = outputField.text.trim()
        if (inputPath.length === 0 || out.length === 0) {
            resultArea.text = qsTr("请先选择输入 PDF 和输出路径")
            if (rotatePage.feedbackDialog) { rotatePage.feedbackDialog.text = resultArea.text; rotatePage.feedbackDialog.open() }
            return
        }
        if (!out.toLowerCase().endsWith(".pdf")) {
            out = out.replace(/\/+$/g, "") + "/rotated.pdf"
        }
        if (!pageAngles || pageAngles.length === 0) {
            resultArea.text = qsTr("请先加载预览页")
            return
        }

        const ok = rotatePage.pdfService.rotatePdfByPageAngles(inputPath, out, pageAngles)
        if (ok) {
            resultArea.text = qsTr("保存完成\n输出文件：") + out
            const slash = out.lastIndexOf('/')
            if (slash > 0) {
                rotatePage.pdfService.openFolder(out.substring(0, slash))
            }
        } else {
            resultArea.text = qsTr("保存失败：") + rotatePage.pdfService.lastError
        }
        if (rotatePage.feedbackDialog) {
            rotatePage.feedbackDialog.text = resultArea.text
            rotatePage.feedbackDialog.open()
        }
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
                onClicked: rotatePage.backRequested()
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
                text: qsTr("PDF 旋转")
                font.pixelSize: 30
                font.bold: true
                color: "#0f172a"
                Layout.fillWidth: true
            }
        }

        Label {
            text: qsTr("显示全部页面预览（每行10个），点击页面后可左/右旋转，最后统一保存")
            color: "#64748b"
            font.pixelSize: 15
        }

        ScrollView {
            id: rotateScroll
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                width: rotateScroll.availableWidth
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
                            color: rotateDragArea.containsDrag ? "#dbeafe" : "#f8fafc"
                            border.width: 1
                            border.color: rotateDragArea.containsDrag ? "#3b82f6" : "#cbd5e1"
                            Label { anchors.centerIn: parent; text: qsTr("拖拽 PDF 到这里"); color: "#334155" }

                            DropArea {
                                id: rotateDragArea
                                anchors.fill: parent
                                onDropped: function(drop) {
                                    if (!drop.hasUrls || drop.urls.length === 0) return
                                    const first = String(drop.urls[0])
                                    if (!first.toLowerCase().endsWith(".pdf")) {
                                        resultArea.text = qsTr("仅支持拖入 .pdf 文件")
                                        return
                                    }
                                    rotatePage.pickInput(decodeURIComponent(first.replace("file://", "")))
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
                                onClicked: rotatePage.pickInputRequested()
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
                        Label { text: qsTr("页面预览"); font.bold: true; color: "#0f172a"; font.pixelSize: 16 }
                        ScrollView {
                            id: previewScroll
                            Layout.fillWidth: true
                            Layout.preferredHeight: 285
                            clip: true

                            Item {
                                width: Math.max(previewScroll.availableWidth, 1)
                                implicitHeight: previewGrid.implicitHeight

                                GridLayout {
                                id: previewGrid
                                width: parent.width
                                columns: Math.max(1, Math.floor(previewScroll.availableWidth / 128))
                                columnSpacing: 8
                                rowSpacing: 8

                                Repeater {
                                    model: rotatePage.previewImages
                                    delegate: Rectangle {
                                        required property int index
                                        required property string modelData
                                        width: 120
                                        height: 170
                                        radius: 10
                                        color: "#ffffff"
                                        border.width: 1
                                        border.color: rotatePage.selectedPageIndex === index ? "#3b82f6" : "#e2e8f0"

                                        Column {
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            spacing: 6

                                            Rectangle {
                                                width: parent.width
                                                height: 135
                                                radius: 6
                                                color: "#f8fafc"
                                                border.color: "#e2e8f0"
                                                clip: true

                                                Item {
                                                    id: imageWrap
                                                    anchors.centerIn: parent
                                                    width: parent.width - 10
                                                    height: parent.height - 10
                                                    transformOrigin: Item.Center
                                                    rotation: rotatePage.pageAngles[index] || 0
                                                    scale: ((rotatePage.pageAngles[index] || 0) % 180 === 0) ? 1.0 : 0.72

                                                    Image {
                                                        anchors.centerIn: parent
                                                        width: parent.width
                                                        height: parent.height
                                                        source: "file://" + modelData
                                                        fillMode: Image.PreserveAspectFit
                                                    }
                                                }
                                            }

                                            Label {
                                                width: parent.width
                                                horizontalAlignment: Text.AlignHCenter
                                                text: qsTr("第") + (index + 1) + qsTr("页") + "  " + (rotatePage.pageAngles[index] || 0) + "°"
                                                font.pixelSize: 11
                                                color: "#334155"
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: rotatePage.selectedPageIndex = index
                                        }
                                    }
                                }
                            }
                            }
                        }

                        Label {
                            color: "#64748b"
                            text: rotatePage.selectedPageIndex >= 0
                                  ? (qsTr("当前选中：第 ") + (rotatePage.selectedPageIndex + 1) + qsTr(" 页"))
                                  : qsTr("请点击一个页面")
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
                            TextField { id: outputField; Layout.fillWidth: true; placeholderText: qsTr("选择目录后默认文件名 rotated.pdf") }
                            Button {
                                id: chooseDirButton
                                text: qsTr("选择目录")
                                background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                                contentItem: Text { text: chooseDirButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16 }
                                onClicked: rotatePage.pickOutputRequested()
                            }
                        }

                        RowLayout {
                            spacing: 10
                            Button {
                                id: rotateLeftButton
                                text: "⟲ 90°"
                                background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                                contentItem: Text { text: rotateLeftButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16; font.bold: true }
                                onClicked: rotatePage.rotateSelected(-90)
                            }
                            Button {
                                id: rotateRightButton
                                text: "⟳ 90°"
                                background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                                contentItem: Text { text: rotateRightButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16; font.bold: true }
                                onClicked: rotatePage.rotateSelected(90)
                            }
                            Button {
                                id: saveButton
                                text: qsTr("保存")
                                background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                                contentItem: Text { text: saveButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16; font.bold: true }
                                onClicked: rotatePage.saveAll()
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
