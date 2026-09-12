import QtQuick 2.15
import QtGraphicalEffects 1.15

FocusScope {
    id: notification

    readonly property var _strings: ({
        updateTitle: "New update available",
        updateBody: "A new version is available: ",
        viewChanges: "View changes",
        openGithub: "Open in GitHub",
        close: "Close",
        updateHint: "\u2190\u2192 Navigate    A Select    B Close"
    })

    property string latestVersion: ""
    property string releaseUrl: ""
    property string releaseNotes: ""
    property bool expanded: false

    property var soundConfirm: null
    property var soundNav: null

    signal closed()

    visible: opacity > 0
    opacity: 0
    property real cardScale: 0.5

    readonly property color _accent: "#f2a541"
    readonly property color _accentDark: "#c97b1a"
    readonly property color _surface: "#1a1410"
    readonly property color _border: "#f2a541"
    readonly property color _textPrimary: "#f5e9da"
    readonly property color _textSoft: "#c9a97c"

    function show(version, url, notes) {
        latestVersion = version
        releaseUrl = url
        releaseNotes = notes || ""
        expanded = false
        cardScale = 0.5
        opacity = 0
        notification.forceActiveFocus()
        openAnim.restart()
        Qt.callLater(function() { btnView.forceActiveFocus() })
    }

    function hide() {
        closeAnim.restart()
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.78 * notification.opacity

        MouseArea {
            anchors.fill: parent
            onClicked: notification.hide()
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent

        width: notification.expanded
        ? Math.min(parent.width * 0.80, 820)
        : Math.min(parent.width * 0.52, 620)
        height: col.implicitHeight + pad * 2

        property real pad: vpx(22)

        radius: vpx(16)
        clip: true
        color: notification._surface
        border.color: notification._border
        border.width: vpx(2)
        opacity: notification.opacity
        scale: notification.cardScale

        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: vpx(4)
            radius: vpx(28)
            samples: 40
            color: "#88f2a541"
            transparentBorder: true
        }

        Column {
            id: col
            anchors {
                top: parent.top
                topMargin: card.pad
                horizontalCenter: parent.horizontalCenter
            }
            width: parent.width - card.pad * 2
            spacing: vpx(14)

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: vpx(8)

                Text {
                    text: "\u2B50"
                    font.pixelSize: vpx(22)
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: notification._strings.updateTitle
                    font.bold: true
                    font.pixelSize: vpx(20)
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: vpx(13)
                    color: notification._accent
                }

                Text {
                    text: "\u2B50"
                    font.pixelSize: vpx(22)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                width: parent.width
                text: notification._strings.updateBody + notification.latestVersion
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font.pixelSize: vpx(15)
                color: notification._textPrimary
            }

            Rectangle {
                width: parent.width * 0.6
                height: 1
                color: notification._border
                opacity: 0.35
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: vpx(10)

                Rectangle {
                    id: btnView
                    width: col.width * 0.30
                    height: vpx(36)
                    radius: vpx(8)
                    color: activeFocus ? notification._accent : "transparent"
                    border.color: notification._border
                    border.width: vpx(2)

                    Text {
                        anchors.centerIn: parent
                        width: parent.width * 0.9
                        text: notification._strings.viewChanges
                        font.bold: true
                        font.pixelSize: vpx(13)
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: vpx(9)
                        horizontalAlignment: Text.AlignHCenter
                        color: btnView.activeFocus
                        ? notification._surface
                        : notification._textPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            btnView.forceActiveFocus()
                            notification.expanded = !notification.expanded
                        }
                    }

                    Keys.onPressed: function(ev) {
                        if (ev.isAutoRepeat) return
                            if (api.keys.isAccept(ev)) {
                                ev.accepted = true
                                if (notification.soundConfirm) notification.soundConfirm.play()
                                    notification.expanded = !notification.expanded
                            } else if (api.keys.isCancel(ev)) {
                                ev.accepted = true
                                if (notification.soundConfirm) notification.soundConfirm.play()
                                    notification.hide()
                            } else if (ev.key === Qt.Key_Right) {
                                ev.accepted = true
                                if (notification.soundNav) notification.soundNav.play()
                                    btnOpen.forceActiveFocus()
                            }
                    }
                }

                Rectangle {
                    id: btnOpen
                    width: col.width * 0.36
                    height: vpx(36)
                    radius: vpx(8)
                    color: activeFocus ? notification._accent : "transparent"
                    border.color: notification._border
                    border.width: vpx(2)

                    Text {
                        anchors.centerIn: parent
                        width: parent.width * 0.9
                        text: notification._strings.openGithub
                        font.bold: true
                        font.pixelSize: vpx(13)
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: vpx(9)
                        horizontalAlignment: Text.AlignHCenter
                        color: btnOpen.activeFocus
                        ? notification._surface
                        : notification._textPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (notification.releaseUrl) Qt.openUrlExternally(notification.releaseUrl)
                                notification.hide()
                        }
                    }

                    Keys.onPressed: function(ev) {
                        if (ev.isAutoRepeat) return
                            if (api.keys.isAccept(ev)) {
                                ev.accepted = true
                                if (notification.soundConfirm) notification.soundConfirm.play()
                                    if (notification.releaseUrl) Qt.openUrlExternally(notification.releaseUrl)
                                        notification.hide()
                            } else if (api.keys.isCancel(ev)) {
                                ev.accepted = true
                                if (notification.soundConfirm) notification.soundConfirm.play()
                                    notification.hide()
                            } else if (ev.key === Qt.Key_Left) {
                                ev.accepted = true
                                if (notification.soundNav) notification.soundNav.play()
                                    btnView.forceActiveFocus()
                            } else if (ev.key === Qt.Key_Right) {
                                ev.accepted = true
                                if (notification.soundNav) notification.soundNav.play()
                                    btnClose.forceActiveFocus()
                            }
                    }
                }

                Rectangle {
                    id: btnClose
                    width: col.width * 0.22
                    height: vpx(36)
                    radius: vpx(8)
                    color: activeFocus ? notification._accent : "transparent"
                    border.color: notification._border
                    border.width: vpx(2)

                    Text {
                        anchors.centerIn: parent
                        width: parent.width * 0.9
                        text: notification._strings.close
                        font.bold: true
                        font.pixelSize: vpx(13)
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: vpx(9)
                        horizontalAlignment: Text.AlignHCenter
                        color: btnClose.activeFocus
                        ? notification._surface
                        : notification._textPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: notification.hide()
                    }

                    Keys.onPressed: function(ev) {
                        if (ev.isAutoRepeat) return
                            if (api.keys.isAccept(ev) || api.keys.isCancel(ev)) {
                                ev.accepted = true
                                if (notification.soundConfirm) notification.soundConfirm.play()
                                    notification.hide()
                            } else if (ev.key === Qt.Key_Left) {
                                ev.accepted = true
                                if (notification.soundNav) notification.soundNav.play()
                                    btnOpen.forceActiveFocus()
                            }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: notesText.implicitHeight + vpx(16)
                radius: vpx(8)
                color: "#22f2a541"
                visible: notification.expanded && notification.releaseNotes.length > 0

                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

                Text {
                    id: notesText
                    anchors {
                        top: parent.top
                        topMargin: vpx(8)
                        left: parent.left
                        leftMargin: vpx(12)
                        right: parent.right
                        rightMargin: vpx(12)
                    }
                    text: notification.releaseNotes
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignLeft
                    font.pixelSize: vpx(12)
                    color: notification._textSoft
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: notification._strings.updateHint
                font.pixelSize: vpx(11)
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: vpx(8)
                color: notification._textSoft
                opacity: 0.7
            }
        }
    }

    Keys.onPressed: function(ev) {
        if (!ev.isAutoRepeat && api.keys.isCancel(ev)) {
            ev.accepted = true
            if (notification.soundConfirm) notification.soundConfirm.play()
                notification.hide()
        }
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation {
            target: notification
            property: "opacity"
            from: 0
            to: 1
            duration: 260
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: notification
            property: "cardScale"
            from: 0.5
            to: 1.0
            duration: 400
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation {
            target: notification
            property: "opacity"
            from: 1
            to: 0
            duration: 200
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: notification
            property: "cardScale"
            from: 1.0
            to: 0.6
            duration: 200
            easing.type: Easing.InQuad
        }
        onStopped: notification.closed()
    }
}
