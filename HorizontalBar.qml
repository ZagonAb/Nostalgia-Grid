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

    property var gameGridView: null
    property var gameInfoRect: null
    property var collectionListView: null
    property var sounds: null

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
            id: mainBarRow
            anchors.fill: parent
            anchors.leftMargin: parent.width * 0.01
            anchors.rightMargin: toggleBtn.width + parent.width * (
                root.currentFilter !== 0 ? 0.05 : 0.02
            )
            anchors.topMargin: parent.width * 0.02
            anchors.bottomMargin: parent.width * 0.02
            spacing: parent.width * 0.02

            Rectangle {
                id: exitButtonContainer
                width: exitRow.width
                height: parent.height
                color: "transparent"
                border.color: "transparent"
                border.width: 2
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    id: exitMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: {
                        if (sounds && sounds.infotogrid) {
                            sounds.infotogrid.play()
                        }
                    }
                }

                Row {
                    id: exitRow
                    spacing: 20
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        source: "assets/control/back.png"
                        width: height
                        height: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        mipmap: true
                    }

                    Text {
                        text: "Exit"
                        color: "white"
                        font.pixelSize: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                id: detailsButtonContainer
                width: detailsRow.width
                height: parent.height
                color: "transparent"
                border.color: "transparent"
                border.width: 2
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    id: detailsMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: {
                        if (gameInfoRect) {
                            gameInfoRect.showGameInfo = !gameInfoRect.showGameInfo
                            if (sounds && sounds.toDetails) {
                                sounds.toDetails.play()
                            }
                            if (gameInfoRect.showGameInfo) {
                                gameInfoRect.forceActiveFocus()
                            } else if (gameGridView) {
                                gameGridView.forceActiveFocus()
                            }
                        }
                    }
                }

                Row {
                    id: detailsRow
                    spacing: 20
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        source: "assets/control/details.png"
                        width: height
                        height: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        mipmap: true
                    }

                    Text {
                        text: "Details"
                        color: "white"
                        font.pixelSize: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                id: filterButtonContainer
                width: filterRow.width
                height: parent.height
                color: "transparent"
                border.color: "transparent"
                border.width: 2
                anchors.verticalCenter: parent.verticalCenter
                opacity: root.filtersAvailable ? 1.0 : 0.6

                MouseArea {
                    id: filterMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: {
                        if (!root.hasFavorites && !root.hasHistory) {
                            if (sounds && sounds.errorSound) {
                                sounds.errorSound.play()
                            }
                        } else if (gameGridView) {
                            var nextFilter = (gameGridView.currentFilter + 1) % 3
                            var originalFilter = gameGridView.currentFilter
                            while (true) {
                                if (nextFilter === 0 || (nextFilter === 1 && root.hasFavorites) || (nextFilter === 2 && root.hasHistory)) break
                                    nextFilter = (nextFilter + 1) % 3
                                    if (nextFilter === originalFilter) break
                            }

                            gameGridView.currentFilter = nextFilter

                            if (sounds && sounds.naviSoundGrid) {
                                sounds.naviSoundGrid.play()
                            } else if (sounds && sounds.toDetails) {
                                sounds.toDetails.play()
                            }
                        }
                    }
                }

                Row {
                    id: filterRow
                    spacing: 20
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        source: "assets/control/x.png"
                        width: height
                        height: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        mipmap: true
                        opacity: parent.parent.opacity
                    }

                    Text {
                        text: root.currentFilter === 0 ? "Filter" :
                        root.currentFilter === 1 ? "Favorites" : "History"
                        color: "white"
                        font.pixelSize: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: parent.parent.opacity
                    }
                }
            }

            Rectangle {
                id: launchButtonContainer
                width: launchRow.width
                height: parent.height
                color: "transparent"
                border.color: "transparent"
                border.width: 2
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    id: launchMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: {
                        if (gameGridView && gameGridView.currentGameData) {
                            var gameToLaunch = gameGridView.currentGameData
                            if (sounds && sounds.launchgame) {
                                sounds.launchgame.play()
                            }
                            if (collectionListView) {
                                api.memory.set('lastCollectionIndex', collectionListView.currentIndex)
                            }
                            gameToLaunch.launch()
                        }
                    }
                }

                Row {
                    id: launchRow
                    spacing: 20
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        source: "assets/control/launch.png"
                        width: height
                        height: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        mipmap: true
                    }

                    Text {
                        text: "Start"
                        color: "white"
                        font.pixelSize: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
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

            Rectangle {
                id: nextPageButtonContainer
                width: nextPageRow.width
                height: parent.height
                color: "transparent"
                border.color: "transparent"
                border.width: 2
                anchors.verticalCenter: parent.verticalCenter
                visible: root.totalPages > 1

                MouseArea {
                    id: nextPageMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    visible: parent.visible

                    onClicked: {
                        if (gameInfoRect) {
                            if (gameInfoRect.totalPages <= 1) {
                                if (sounds && sounds.errorSound) sounds.errorSound.play()
                            } else {
                                if (sounds && sounds.detailsNextSound) sounds.detailsNextSound.play()
                                    gameInfoRect.navigatePages()
                            }
                        }
                    }
                }

                Row {
                    id: nextPageRow
                    spacing: 20
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        source: "assets/control/launch.png"
                        width: height
                        height: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        mipmap: true
                    }

                    Text {
                        text: "Next"
                        color: "white"
                        font.pixelSize: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                id: favoriteButtonContainer
                width: favoriteRow.width
                height: parent.height
                color: "transparent"
                border.color: "transparent"
                border.width: 2
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    id: favoriteMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: {
                        if (gameInfoRect && gameInfoRect.currentGame) {
                            var newFavoriteStatus = !gameInfoRect.currentGame.favorite
                            gameInfoRect.currentGame.favorite = newFavoriteStatus
                            if (sounds && sounds.naviSoundGrid) {
                                sounds.naviSoundGrid.play()
                            }
                            if (gameGridView && gameGridView.favoriteToggled) {
                                gameGridView.favoriteToggled(gameInfoRect.currentGame, newFavoriteStatus)
                            }
                            gameInfoRect.favoriteStatusChanged()
                        }
                    }
                }

                Row {
                    id: favoriteRow
                    spacing: 20
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        source: "assets/control/x.png"
                        width: height
                        height: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        mipmap: true
                    }

                    Text {
                        text: gameInfoRect && gameInfoRect.currentGame && gameInfoRect.currentGame.favorite ? "Favorite -" : "Favorite +"
                        color: "white"
                        font.pixelSize: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                id: backButtonContainer
                width: backRow.width
                height: parent.height
                color: "transparent"
                border.color: "transparent"
                border.width: 2
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    id: backMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: {
                        if (gameInfoRect) {
                            gameInfoRect.showGameInfo = false
                        }
                        if (gameGridView) {
                            gameGridView.forceActiveFocus()
                        }
                        if (sounds && sounds.infotogrid) {
                            sounds.infotogrid.play()
                        }
                    }
                }

                Row {
                    id: backRow
                    spacing: 20
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        source: "assets/control/back.png"
                        width: height
                        height: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        mipmap: true
                    }

                    Text {
                        text: "Back"
                        color: "white"
                        font.pixelSize: horizontalBar.height * 0.5
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
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
            hoverEnabled: true

            onClicked: {
                root.isCollapsed = !root.isCollapsed;
                api.memory.set('horizontalBarCollapsed', root.isCollapsed);
                if (sounds && sounds.naviSoundGrid) {
                    sounds.naviSoundGrid.play();
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

    Connections {
        target: gameGridView
        function onFavoriteToggled(game, isFavorite) {
            root.hasFavorites = gameGridView.hasFavorites
            root.hasHistory = gameGridView.hasHistory
        }
        function onFilterChanged(newFilter) {
            root.currentFilter = newFilter
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
