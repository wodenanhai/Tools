import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: homePage
    signal openSplitRequested()
    signal openConvertRequested()
    signal openMergeRequested()
    signal openCompressRequested()

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
                Label { text: qsTr("高效处理 PDF：拆分、转图片、更多工具持续增加"); color: "#dbeafe"; font.pixelSize: 15 }
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
            columns: 3
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
                    Label { text: qsTr("按页数拆分或页码提取"); color: "#64748b"; wrapMode: Text.WordWrap }
                }

                MouseArea {
                    id: splitHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: homePage.openSplitRequested()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 170
                radius: 16
                color: "white"
                border.color: convertHover.containsMouse ? "#3b82f6" : "#dbe3ef"
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
                    Label { anchors.centerIn: parent; text: "🖼"; font.pixelSize: 22; color: "#1d4ed8" }
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 18
                    spacing: 8
                    Label { text: qsTr("PDF 转图片"); font.pixelSize: 24; font.bold: true; color: "#0f172a" }
                    Label { text: qsTr("导出 PNG/JPG，多页批量转换"); color: "#64748b"; wrapMode: Text.WordWrap }
                }

                MouseArea {
                    id: convertHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: homePage.openConvertRequested()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 170
                radius: 16
                color: "white"
                border.color: mergeHover.containsMouse ? "#3b82f6" : "#e2e8f0"
                border.width: 1

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
                    Label { text: qsTr("合并 PDF"); font.pixelSize: 24; font.bold: true; color: "#0f172a" }
                    Label { text: qsTr("多个 PDF 按顺序合并为一个"); color: "#64748b" }
                }

                MouseArea {
                    id: mergeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: homePage.openMergeRequested()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 170
                radius: 16
                color: "white"
                border.color: compressHover.containsMouse ? "#3b82f6" : "#e2e8f0"
                border.width: 1

                Rectangle {
                    width: 44
                    height: 44
                    radius: 12
                    color: "#f1f5f9"
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.top: parent.top
                    anchors.topMargin: 18
                    Label { anchors.centerIn: parent; text: "🗜"; font.pixelSize: 22; color: "#64748b" }
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 18
                    spacing: 8
                    Label { text: qsTr("压缩 PDF"); font.pixelSize: 24; font.bold: true; color: "#0f172a" }
                    Label { text: qsTr("使用 Ghostscript 减小文件体积"); color: "#64748b"; wrapMode: Text.WordWrap }
                }

                MouseArea {
                    id: compressHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: homePage.openCompressRequested()
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
