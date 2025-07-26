import QtQuick 2.15

Item {
    id: root
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 10
    height: parent.height * 0.08
    width: parent.width * 0.45
    z: 3

    property bool isGameInfoVisible: false
    property int totalPages: 0
    property bool showPagination: false

    Rectangle {
        id: mainBar
        anchors.fill: parent
        color: "black"
        opacity: !root.isGameInfoVisible ? 0.8 : 0
        radius: 8
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: parent.width * 0.1
            anchors.rightMargin: parent.width * 0.02
            anchors.topMargin: parent.width * 0.02
            anchors.bottomMargin: parent.width * 0.02
            spacing: parent.width * 0.02

            Repeater {
                model: [
                    {icon: "assets/control/back.png", text: "Exit"},
                    {icon: "assets/control/details.png", text: "Details"},
                    {icon: "assets/control/launch.png", text: "Start"}
                ]

                delegate: Row {
                    spacing: parent.spacing
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        source: modelData.icon
                        width: height
                        height: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        mipmap: true
                    }

                    Text {
                        text: modelData.text
                        color: "white"
                        font.pixelSize: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        width: parent.width * 0.25
                        height: 1
                    }
                }
            }
        }
    }

    Rectangle {
        id: infoBar
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height
        width: parent.width * 0.6
        color: "black"
        opacity: root.isGameInfoVisible ? 0.8 : 0
        radius: 8
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: parent.width * 0.1
            anchors.rightMargin: parent.width * 0.02
            anchors.topMargin: parent.width * 0.02
            anchors.bottomMargin: parent.width * 0.02
            spacing: parent.width * 0.02

            Repeater {
                model: root.totalPages > 1 ? [
                    {icon: "assets/control/launch.png", text: "Next"},
                    {icon: "assets/control/back.png", text: "Back"}
                ] : [
                    {icon: "assets/control/back.png", text: "Back"}
                ]

                delegate: Row {
                    spacing: parent.spacing
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        source: modelData.icon
                        width: height
                        height: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        mipmap: true
                    }

                    Text {
                        text: modelData.text
                        color: "white"
                        font.pixelSize: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        width: parent.width * 0.25
                        height: 1
                    }
                }
            }
        }
    }

    SequentialAnimation {
        id: hideMainAnimation
        running: root.isGameInfoVisible
        NumberAnimation {
            target: mainBar
            property: "anchors.bottomMargin"
            to: -mainBar.height
            duration: 300
            easing.type: Easing.OutQuad
        }
        ScriptAction { script: mainBar.visible = false }
    }

    SequentialAnimation {
        id: showMainAnimation
        running: !root.isGameInfoVisible
        ScriptAction { script: mainBar.visible = true }
        NumberAnimation {
            target: mainBar
            property: "anchors.bottomMargin"
            to: 0
            duration: 300
            easing.type: Easing.OutQuad
        }
    }

    SequentialAnimation {
        id: hideInfoAnimation
        running: !root.isGameInfoVisible
        NumberAnimation {
            target: infoBar
            property: "anchors.bottomMargin"
            to: -infoBar.height
            duration: 300
            easing.type: Easing.OutQuad
        }
        ScriptAction { script: infoBar.visible = false }
    }

    SequentialAnimation {
        id: showInfoAnimation
        running: root.isGameInfoVisible
        ScriptAction { script: infoBar.visible = true }
        NumberAnimation {
            target: infoBar
            property: "anchors.bottomMargin"
            to: 0
            duration: 300
            easing.type: Easing.OutQuad
        }
    }

    Connections {
        target: gameInfoRect
        function onTotalPagesChanged() {
            root.totalPages = gameInfoRect.totalPages;
        }
        function onVisibleChanged() {
            root.isGameInfoVisible = gameInfoRect.visible;
        }
    }
}
