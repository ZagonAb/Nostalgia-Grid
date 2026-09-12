import QtQuick 2.15
import QtGraphicalEffects 1.12
import "utils.js" as Utils

Rectangle {
    id: splash
    anchors.fill: parent
    z: 1000

    property var themeColors: ({})
    property string titleText: "NOSTALGIA GRID"
    property string subtitleText: "Restoring your collection..."
    property string iconSource: "assets/systems/icon_0.png"
    property int minSplashDuration: 2000
    property bool interfaceReady: false
    property bool _minTimeElapsed: false
    readonly property bool hidden: interfaceReady && _minTimeElapsed

    signal splashFinished()

    color: themeColors.background || "#000000"
    opacity: hidden ? 0 : 1
    visible: opacity > 0

    Behavior on color {
        ColorAnimation { duration: 600; easing.type: Easing.OutCubic }
    }

    onHiddenChanged: {
        if (hidden) splash.splashFinished();
    }

    Behavior on opacity {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    Timer {
        interval: splash.minSplashDuration
        running: true
        repeat: false
        onTriggered: splash._minTimeElapsed = true
    }

    MouseArea {
        anchors.fill: parent
        enabled: splash.visible
    }

    Column {
        anchors.centerIn: parent
        spacing: vpx(24)

        Item {
            id: iconWrap
            anchors.horizontalCenter: parent.horizontalCenter
            width: vpx(130)
            height: vpx(130)

            opacity: 0
            scale: 0.5

            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }

            Component.onCompleted: {
                opacity = 1;
                scale = 1;
            }

            Image {
                id: iconImage
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                source: splash.iconSource
                fillMode: Image.PreserveAspectFit
                mipmap: true
                asynchronous: true

                transform: [
                    Rotation {
                        id: iconRotate
                        origin.x: iconImage.width / 2
                        origin.y: iconImage.height / 2
                        angle: 0
                        SequentialAnimation on angle {
                            loops: Animation.Infinite
                            running: splash.visible
                            NumberAnimation { from: -6; to: 6; duration: 1900; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 6; to: -6; duration: 1900; easing.type: Easing.InOutSine }
                        }
                    },
                    Translate {
                        id: iconFloat
                        y: 0
                        SequentialAnimation on y {
                            loops: Animation.Infinite
                            running: splash.visible
                            NumberAnimation { from: 0; to: -vpx(10); duration: 1500; easing.type: Easing.InOutSine }
                            NumberAnimation { from: -vpx(10); to: 0; duration: 1500; easing.type: Easing.InOutSine }
                        }
                    }
                ]

                layer.enabled: true
                layer.effect: Glow {
                    radius: vpx(16)
                    samples: 26
                    spread: 0.3
                    color: splash.themeColors.primary || "#f2a541"
                    transparentBorder: true
                }
            }
        }

        Row {
            id: titleRow
            anchors.horizontalCenter: parent.horizontalCenter

            property real glowPulse: 0.7
            SequentialAnimation on glowPulse {
                loops: Animation.Infinite
                running: splash.visible
                NumberAnimation { from: 0.7; to: 1.3; duration: 1400; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.3; to: 0.7; duration: 1400; easing.type: Easing.InOutSine }
            }

            layer.enabled: true
            layer.effect: Glow {
                radius: vpx(16) * titleRow.glowPulse
                samples: 24
                spread: 0.3
                color: "#80FFFFFF"
                transparentBorder: true
            }

            Repeater {
                model: splash.titleText.length

                Text {
                    id: letterText
                    text: splash.titleText.charAt(index) === " " ? "\u00A0" : splash.titleText.charAt(index)
                    color: splash.themeColors.text || "#ffffff"
                    font.pixelSize: vpx(42)
                    font.bold: true
                    font.letterSpacing: vpx(1)

                    opacity: 0
                    scale: 0.3

                    transform: Translate {
                        id: letterTranslate
                        y: vpx(22)
                        Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutBack } }
                    }

                    Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.OutBack } }

                    SequentialAnimation {
                        running: true
                        PauseAnimation { duration: 250 + index * 45 }
                        ScriptAction {
                            script: {
                                letterText.opacity = 1;
                                letterText.scale = 1;
                                letterTranslate.y = 0;
                            }
                        }
                    }
                }
            }
        }

        Grid {
            id: gridLoader
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 3
            rows: 3
            spacing: vpx(7)

            opacity: 0
            scale: 0.6

            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

            SequentialAnimation {
                running: true
                PauseAnimation { duration: 900 }
                ScriptAction {
                    script: {
                        gridLoader.opacity = 1;
                        gridLoader.scale = 1;
                    }
                }
            }

            Repeater {
                model: 9
                Rectangle {
                    width: vpx(13)
                    height: vpx(13)
                    radius: vpx(3)
                    color: splash.themeColors.primary || "#2d5c8f"
                    opacity: 0.25

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: splash.visible
                        PauseAnimation { duration: index * 85 }
                        NumberAnimation { from: 0.25; to: 1.0; duration: 260; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.0; to: 0.25; duration: 260; easing.type: Easing.InOutQuad }
                        PauseAnimation { duration: (8 - index) * 85 }
                    }

                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: splash.visible
                        PauseAnimation { duration: index * 85 }
                        NumberAnimation { from: 0.8; to: 1.15; duration: 260; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.15; to: 0.8; duration: 260; easing.type: Easing.InOutQuad }
                        PauseAnimation { duration: (8 - index) * 85 }
                    }
                }
            }
        }

        Text {
            id: loadingText
            anchors.horizontalCenter: parent.horizontalCenter
            text: splash.subtitleText
            color: splash.themeColors.textSecondary || "#b0b0b0"
            font.pixelSize: vpx(22)

            opacity: 0

            transform: Translate {
                id: loadingTranslate
                y: vpx(10)
                Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            }

            Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

            SequentialAnimation {
                running: true
                PauseAnimation { duration: 550 }
                ScriptAction {
                    script: {
                        loadingText.text = Utils.getRandomSplashMessage(loadingText.text);
                        loadingText.opacity = 1;
                        loadingTranslate.y = 0;
                    }
                }
            }

            Timer {
                id: messageRotateTimer
                interval: 1300
                repeat: true
                running: splash.visible
                onTriggered: {
                    loadingText.opacity = 0;
                    messageSwapTimer.restart();
                }
            }

            Timer {
                id: messageSwapTimer
                interval: 300
                repeat: false
                onTriggered: {
                    loadingText.text = Utils.getRandomSplashMessage(loadingText.text);
                    loadingText.opacity = 1;
                }
            }
        }
    }
}
