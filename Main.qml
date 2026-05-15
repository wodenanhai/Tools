import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 980
    height: 760
    visible: true
    title: qsTr("PDF Studio Toolbox")

    property int currentPage: 0 // 0: Home, 1: Split, 2: Convert, 3: Merge, 4: Compress

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
        fileMode: root.currentPage === 3 ? FileDialog.OpenFiles : FileDialog.OpenFile
        onAccepted: {
            if (root.currentPage === 1) {
                const p = root.toLocalPath(selectedFile)
                splitPage.pickInput(p)
            } else if (root.currentPage === 2) {
                const p = root.toLocalPath(selectedFile)
                convertPage.pickInput(p)
            } else if (root.currentPage === 3) {
                let paths = []
                if (selectedFiles && selectedFiles.length > 0) {
                    for (let i = 0; i < selectedFiles.length; ++i) {
                        paths.push(root.toLocalPath(selectedFiles[i]))
                    }
                }

                // 兼容部分平台/样式下多选对话框仅返回单文件字段的情况
                if (paths.length === 0 && selectedFile) {
                    paths.push(root.toLocalPath(selectedFile))
                }

                mergePage.addInputFiles(paths)
            } else if (root.currentPage === 4) {
                const p = root.toLocalPath(selectedFile)
                compressPage.pickInput(p)
            }
        }
    }

    FolderDialog {
        id: outputFolderDialog
        title: qsTr("选择输出目录")
        onAccepted: {
            const p = root.toLocalPath(selectedFolder)
            if (root.currentPage === 1) {
                splitPage.pickOutput(p)
            } else if (root.currentPage === 2) {
                convertPage.pickOutput(p)
            } else if (root.currentPage === 3) {
                mergePage.pickOutput(p)
            } else if (root.currentPage === 4) {
                compressPage.pickOutput(p)
            }
        }
    }

    Popup {
        id: feedbackDialog
        modal: true
        focus: true
        anchors.centerIn: parent
        width: Math.min(root.width * 0.62, 560)
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        property string text: ""

        background: Rectangle {
            radius: 16
            color: "#ffffff"
            border.color: "#dbe3ef"
            border.width: 1
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            Label {
                text: qsTr("提示")
                font.pixelSize: 20
                font.bold: true
                color: "#0f172a"
            }

            TextArea {
                text: feedbackDialog.text
                readOnly: true
                wrapMode: Text.Wrap
                selectByMouse: true
                color: "#1e293b"
                background: Rectangle {
                    color: "#f8fafc"
                    border.color: "#e2e8f0"
                    radius: 10
                }
                Layout.fillWidth: true
                Layout.preferredHeight: 140
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button {
                    id: popupOkButton
                    text: qsTr("确定")
                    onClicked: feedbackDialog.close()
                    background: Rectangle {
                        radius: 8
                        color: "#ffffff"
                        border.color: "#d1d5db"
                    }
                    contentItem: Text {
                        text: popupOkButton.text
                        color: "#111827"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 16
                        font.bold: true
                    }
                }
            }
        }
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

        HomePage {
            onOpenSplitRequested: root.currentPage = 1
            onOpenConvertRequested: root.currentPage = 2
            onOpenMergeRequested: root.currentPage = 3
            onOpenCompressRequested: root.currentPage = 4
        }

        PdfSplitPage {
            id: splitPage
            pdfService: pdfSplitService
            feedbackDialog: feedbackDialog
            onBackRequested: root.currentPage = 0
            onPickInputRequested: inputPdfDialog.open()
            onPickOutputRequested: outputFolderDialog.open()
        }

        PdfToImagePage {
            id: convertPage
            pdfService: pdfSplitService
            feedbackDialog: feedbackDialog
            onBackRequested: root.currentPage = 0
            onPickInputRequested: inputPdfDialog.open()
            onPickOutputRequested: outputFolderDialog.open()
        }

        PdfMergePage {
            id: mergePage
            pdfService: pdfSplitService
            feedbackDialog: feedbackDialog
            onBackRequested: root.currentPage = 0
            onPickInputRequested: inputPdfDialog.open()
            onPickOutputRequested: outputFolderDialog.open()
        }

        PdfCompressPage {
            id: compressPage
            pdfService: pdfSplitService
            feedbackDialog: feedbackDialog
            onBackRequested: root.currentPage = 0
            onPickInputRequested: inputPdfDialog.open()
            onPickOutputRequested: outputFolderDialog.open()
        }
    }
}
