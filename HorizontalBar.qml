import QtQuick 2.15

Item {
    id: root
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 10
    height: parent.height * 0.08
    width: isCollapsed ? toggleBtn.width : parent.width * 0.55
    z: 3
    clip: true

    property int totalPages: 0
    property int currentFilter: 0

    property bool showPagination: false
    property bool hasFavorites: false
    property bool hasHistory: false
    property bool filtersAvailable: hasFavorites || hasHistory
    property bool isCollapsed: false
    property bool isGameInfoVisible: false
    property bool animationsReady: false

    Behavior on width {
        enabled: root.animationsReady
        NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
    }

    Rectangle {
        id: mainBar
        anchors.fill: parent
        color: "black"
        opacity: !root.isGameInfoVisible ? 0.8 : 0
        radius: 8
        visible: opacity > 0

        Behavior on opacity {
            enabled: root.animationsReady
            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: parent.width * 0.01
            anchors.rightMargin: toggleBtn.width + parent.width * (
                root.currentFilter !== 0 ? 0.05 : 0.02
            )
            anchors.topMargin: parent.width * 0.02
            anchors.bottomMargin: parent.width * 0.02
            spacing: parent.width * 0.02

            Repeater {
                model: [
                    {icon: "assets/control/back.png",    text: "Exit"},
                    {icon: "assets/control/details.png", text: "Details"},
                    {icon: "assets/control/x.png",       text: root.currentFilter === 0 ? "Filter" :
                        root.currentFilter === 1 ? "Favorites" : "History"},
                        {icon: "assets/control/launch.png",  text: "Start"}
                ]

                delegate: Row {
                    spacing: parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: (modelData.text === "Filter" || modelData.text === "Favorites" || modelData.text === "History") ?
                    (root.filtersAvailable ? 1.0 : 0.6) : 1.0

                    Image {
                        source: modelData.icon
                        width: height
                        height: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        mipmap: true
                        opacity: parent.opacity
                    }

                    Text {
                        text: modelData.text
                        color: "white"
                        font.pixelSize: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: parent.opacity
                    }

                    Item {
                        width: parent.width * 0.05
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
        width: parent.width * 0.8
        color: "black"
        opacity: root.isGameInfoVisible ? 0.8 : 0
        radius: 8
        visible: opacity > 0

        Behavior on opacity {
            enabled: root.animationsReady
            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
        }

        Row {
            id: infoBarRow
            anchors.fill: parent
            anchors.leftMargin: parent.width * 0.1
            anchors.rightMargin: toggleBtn.width + parent.width * 0.02
            anchors.topMargin: parent.width * 0.02
            anchors.bottomMargin: parent.width * 0.02
            spacing: parent.width * 0.02

            property var buttonModel: {
                if (root.totalPages > 1) {
                    return [
                        {icon: "assets/control/launch.png", text: "Next"},
                        {icon: "assets/control/x.png", text: gameInfoRect.currentGame && gameInfoRect.currentGame.favorite ? "Favorite -" : "Favorite +"},
                        {icon: "assets/control/back.png", text: "Back"}
                    ];
                } else {
                    return [
                        {icon: "assets/control/x.png", text: gameInfoRect.currentGame && gameInfoRect.currentGame.favorite ? "Favorite -" : "Favorite +"},
                        {icon: "assets/control/back.png", text: "Back"}
                    ];
                }
            }

            Repeater {
                model: infoBarRow.buttonModel

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
                        width: parent.width * 0.05
                        height: 1
                    }
                }
            }

            function modelChanged() {
                buttonModel = Qt.binding(function() {
                    if (root.totalPages > 1) {
                        return [
                            {icon: "assets/control/launch.png", text: "Next"},
                            {icon: "assets/control/x.png", text: gameInfoRect.currentGame && gameInfoRect.currentGame.favorite ? "Favorite -" : "Favorite +"},
                            {icon: "assets/control/back.png", text: "Back"}
                        ];
                    } else {
                        return [
                            {icon: "assets/control/x.png", text: gameInfoRect.currentGame && gameInfoRect.currentGame.favorite ? "Favorite -" : "Favorite +"},
                            {icon: "assets/control/back.png", text: "Back"}
                        ];
                    }
                });
            }
        }
    }

    Rectangle {
        id: toggleBtn
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.verticalCenter: parent.verticalCenter
        width: root.height
        height: root.height
        color: "black"
        opacity: 0.95
        radius: 6
        z: 10

        Image {
            id: toggleIcon
            anchors.centerIn: parent
            source: root.isCollapsed ? "assets/icons/show.svg" : "assets/icons/hide.svg"
            width: parent.width * 0.65
            height: parent.height * 0.65
            mipmap: true
            fillMode: Image.PreserveAspectFit
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                root.isCollapsed = !root.isCollapsed;
                api.memory.set('horizontalBarCollapsed', root.isCollapsed);
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
        function onFavoriteStatusChanged() {
            infoBarRow.modelChanged();
        }
        function onCurrentGameChanged() {
            infoBarRow.modelChanged();
        }
    }

    Connections {
        target: gameGridView
        function onFavoriteToggled(game, isFavorite) {
            root.hasFavorites = gameGridView.hasFavorites
            root.hasHistory   = gameGridView.hasHistory
            infoBarRow.modelChanged()
        }
    }

    Component.onCompleted: {
        var saved = api.memory.get('horizontalBarCollapsed');
        root.isCollapsed = (saved === true);
        Qt.callLater(function() {
            root.animationsReady = true;
        });
    }
}
