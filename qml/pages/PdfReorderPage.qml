import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: reorderPage
    property var pdfService
    property var feedbackDialog
    signal backRequested()
    signal pickInputRequested()
    signal pickOutputRequested()

    property var previewImages: []
    property var pageOrder: []

    function moveUp(index) {
        if (index <= 0 || index >= pageOrder.length) return
        movePage(index, index - 1)
    }

    function moveDown(index) {
        if (index < 0 || index >= pageOrder.length - 1) return
        movePage(index, index + 1)
    }

    function moveTop(index) {
        if (index <= 0 || index >= pageOrder.length) return
        movePage(index, 0)
    }

    function moveBottom(index) {
        if (index < 0 || index >= pageOrder.length - 1) return
        movePage(index, pageOrder.length - 1)
    }

    function pickInput(filePath) {
        inputField.text = filePath
        const previews = reorderPage.pdfService.generatePdfAllPagePreviews(filePath)
        if (previews && previews.length > 0) {
            previewImages = previews
            pageOrder = []
            for (let i = 0; i < previews.length; ++i) {
                pageOrder.push(i + 1)
            }
            resultArea.text = qsTr("已加载页面：") + previews.length
        } else {
            previewImages = []
            pageOrder = []
            resultArea.text = qsTr("预览图生成失败：") + reorderPage.pdfService.lastError
        }
    }

    function pickOutput(path) {
        outputField.text = path
    }

    function movePage(fromIndex, toIndex) {
        if (fromIndex < 0 || toIndex < 0 || fromIndex >= pageOrder.length || toIndex >= pageOrder.length || fromIndex === toIndex)
            return
        const arrOrder = pageOrder.slice(0)
        const arrPreview = previewImages.slice(0)
        const p = arrOrder.splice(fromIndex, 1)[0]
        const img = arrPreview.splice(fromIndex, 1)[0]
        arrOrder.splice(toIndex, 0, p)
        arrPreview.splice(toIndex, 0, img)
        pageOrder = arrOrder
        previewImages = arrPreview
    }

    function saveOrder() {
        const inputPath = inputField.text.trim()
        let out = outputField.text.trim()
        if (inputPath.length === 0 || out.length === 0) {
            resultArea.text = qsTr("请先选择输入 PDF 和输出路径")
            if (reorderPage.feedbackDialog) { reorderPage.feedbackDialog.text = resultArea.text; reorderPage.feedbackDialog.open() }
            return
        }
        if (!out.toLowerCase().endsWith(".pdf")) {
            out = out.replace(/\/+$/g, "") + "/reordered.pdf"
        }
        if (!pageOrder || pageOrder.length === 0) {
            resultArea.text = qsTr("请先加载页面")
            return
        }

        const ok = reorderPage.pdfService.reorderPdfPages(inputPath, out, pageOrder)
        if (ok) {
            resultArea.text = qsTr("保存完成\n输出文件：") + out
            const slash = out.lastIndexOf('/')
            if (slash > 0) {
                reorderPage.pdfService.openFolder(out.substring(0, slash))
            }
        } else {
            resultArea.text = qsTr("保存失败：") + reorderPage.pdfService.lastError
        }
        if (reorderPage.feedbackDialog) {
            reorderPage.feedbackDialog.text = resultArea.text
            reorderPage.feedbackDialog.open()
        }
    }

    function resetInitialOrder() {
        if (!previewImages || previewImages.length === 0 || !pageOrder || pageOrder.length === 0) {
            resultArea.text = qsTr("请先加载页面")
            return
        }

        const originPairs = []
        for (let i = 0; i < pageOrder.length; ++i) {
            originPairs.push({
                page: pageOrder[i],
                img: previewImages[i]
            })
        }
        originPairs.sort(function(a, b) { return a.page - b.page })

        const newOrder = []
        const newImgs = []
        for (let i = 0; i < originPairs.length; ++i) {
            newOrder.push(originPairs[i].page)
            newImgs.push(originPairs[i].img)
        }

        pageOrder = newOrder
        previewImages = newImgs
        resultArea.text = qsTr("已恢复初始排序")
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
                onClicked: reorderPage.backRequested()
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
                text: qsTr("PDF 排序")
                font.pixelSize: 30
                font.bold: true
                color: "#0f172a"
                Layout.fillWidth: true
            }
        }

        Label {
            text: qsTr("通过上移/下移/置顶/置底对页面重排，页面下方显示原始位置与当前位置")
            color: "#64748b"
            font.pixelSize: 15
        }

        ScrollView {
            id: reorderScroll
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                width: reorderScroll.availableWidth
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
                            color: reorderDragArea.containsDrag ? "#dbeafe" : "#f8fafc"
                            border.width: 1
                            border.color: reorderDragArea.containsDrag ? "#3b82f6" : "#cbd5e1"
                            Label { anchors.centerIn: parent; text: qsTr("拖拽 PDF 到这里"); color: "#334155" }

                            DropArea {
                                id: reorderDragArea
                                anchors.fill: parent
                                onDropped: function(drop) {
                                    if (!drop.hasUrls || drop.urls.length === 0) return
                                    const first = String(drop.urls[0])
                                    if (!first.toLowerCase().endsWith(".pdf")) {
                                        resultArea.text = qsTr("仅支持拖入 .pdf 文件")
                                        return
                                    }
                                    reorderPage.pickInput(decodeURIComponent(first.replace("file://", "")))
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
                                onClicked: reorderPage.pickInputRequested()
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
                        Label { text: qsTr("页面预览（按钮重排）"); font.bold: true; color: "#0f172a"; font.pixelSize: 16 }

                        ScrollView {
                            id: previewScroll
                            Layout.fillWidth: true
                            Layout.preferredHeight: 340
                            clip: true

                            Item {
                                width: Math.max(previewScroll.availableWidth, 1)
                                implicitHeight: previewGrid.implicitHeight

                                GridLayout {
                                    id: previewGrid
                                    width: parent.width
                                    columns: Math.max(1, Math.floor(previewScroll.availableWidth / 140))
                                    columnSpacing: 10
                                    rowSpacing: 10

                                    Repeater {
                                        model: reorderPage.previewImages
                                        delegate: Rectangle {
                                            required property int index
                                            required property string modelData
                                            width: 130
                                            height: 200
                                            radius: 10
                                            color: "#ffffff"
                                            border.width: 1
                                            border.color: "#e2e8f0"

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

                                                    Image {
                                                        anchors.centerIn: parent
                                                        width: parent.width - 10
                                                        height: parent.height - 10
                                                        source: "file://" + modelData
                                                        fillMode: Image.PreserveAspectFit
                                                    }
                                                }

                                                Label {
                                                    width: parent.width
                                                    horizontalAlignment: Text.AlignHCenter
                                                    text: qsTr("原：") + (reorderPage.pageOrder[index] || (index + 1)) + qsTr("页，现：") + (index + 1) + qsTr("页")
                                                    font.pixelSize: 11
                                                    color: "#334155"
                                                }

                                                RowLayout {
                                                    width: parent.width
                                                    spacing: 4
                                                    Button {
                                                        id: upButton
                                                        text: qsTr("↑")
                                                        enabled: reorderPage.previewImages.length > 1
                                                        Layout.fillWidth: true
                                                        Layout.preferredWidth: 0
                                                        onClicked: reorderPage.moveUp(index)
                                                        background: Rectangle { radius: 6; color: "#ffffff"; border.color: "#d1d5db" }
                                                        contentItem: Text { text: upButton.text; color: upButton.enabled ? "#111827" : "#9ca3af"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 12; font.bold: true }
                                                    }
                                                    Button {
                                                        id: downButton
                                                        text: qsTr("↓")
                                                        enabled: reorderPage.previewImages.length > 1
                                                        Layout.fillWidth: true
                                                        Layout.preferredWidth: 0
                                                        onClicked: reorderPage.moveDown(index)
                                                        background: Rectangle { radius: 6; color: "#ffffff"; border.color: "#d1d5db" }
                                                        contentItem: Text { text: downButton.text; color: downButton.enabled ? "#111827" : "#9ca3af"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 12; font.bold: true }
                                                    }
                                                    Button {
                                                        id: topButton
                                                        text: qsTr("顶")
                                                        enabled: reorderPage.previewImages.length > 1
                                                        Layout.fillWidth: true
                                                        Layout.preferredWidth: 0
                                                        onClicked: reorderPage.moveTop(index)
                                                        background: Rectangle { radius: 6; color: "#ffffff"; border.color: "#d1d5db" }
                                                        contentItem: Text { text: topButton.text; color: topButton.enabled ? "#111827" : "#9ca3af"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 12; font.bold: true }
                                                    }
                                                    Button {
                                                        id: bottomButton
                                                        text: qsTr("底")
                                                        enabled: reorderPage.previewImages.length > 1
                                                        Layout.fillWidth: true
                                                        Layout.preferredWidth: 0
                                                        onClicked: reorderPage.moveBottom(index)
                                                        background: Rectangle { radius: 6; color: "#ffffff"; border.color: "#d1d5db" }
                                                        contentItem: Text { text: bottomButton.text; color: bottomButton.enabled ? "#111827" : "#9ca3af"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 12; font.bold: true }
                                                    }
                                                }
                                        }
                                        }
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
                        spacing: 10
                        Label { text: qsTr("输出文件"); font.bold: true; color: "#0f172a"; font.pixelSize: 16 }
                        RowLayout {
                            Layout.fillWidth: true
                            TextField { id: outputField; Layout.fillWidth: true; placeholderText: qsTr("选择目录后默认文件名 reordered.pdf") }
                            Button {
                                id: chooseDirButton
                                text: qsTr("选择目录")
                                background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                                contentItem: Text { text: chooseDirButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 16 }
                                onClicked: reorderPage.pickOutputRequested()
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Button {
                                id: resetOrderButton
                                text: qsTr("恢复初始排序")
                                Layout.fillWidth: true
                                background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                                contentItem: Text { text: resetOrderButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 15; font.bold: true }
                                onClicked: reorderPage.resetInitialOrder()
                            }
                            Button {
                                id: saveButton
                                text: qsTr("保存排序")
                                Layout.fillWidth: true
                                background: Rectangle { radius: 8; color: "#ffffff"; border.color: "#d1d5db" }
                                contentItem: Text { text: saveButton.text; color: "#111827"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 15; font.bold: true }
                                onClicked: reorderPage.saveOrder()
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

