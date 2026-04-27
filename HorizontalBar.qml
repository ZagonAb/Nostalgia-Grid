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

        Component.onCompleted: {
            console.log("=== MAINBAR INIT ===")
            console.log("MainBar dimensions:", width, "x", height)
            console.log("MainBar opacity:", opacity)
            console.log("MainBar visible:", visible)
        }

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

            Component.onCompleted: {
                console.log("MainBarRow dimensions:", width, "x", height)
                console.log("MainBarRow children:", children.length)
            }

            Rectangle {
                id: exitButtonContainer
                width: exitRow.width
                height: parent.height
                color: "transparent"
                border.color: "transparent"
                border.width: 2
                anchors.verticalCenter: parent.verticalCenter

                Component.onCompleted: {
                    console.log("Exit button container:", width, "x", height, "at", x, y)
                }

                MouseArea {
                    id: exitMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onEntered: console.log("MOUSE ENTERED: Exit button")
                    onExited: console.log("MOUSE EXITED: Exit button")
                    onPressed: console.log("MOUSE PRESSED: Exit button at", mouse.x, mouse.y)
                    onClicked: {
                        console.log("=== EXIT CLICKED ===")
                        console.log("Sounds:", sounds ? "available" : "NULL")
                        if (sounds && sounds.infotogrid) {
                            console.log("Playing infotogrid sound")
                            sounds.infotogrid.play()
                        } else {
                            console.log("Cannot play sound - sounds or infotogrid not available")
                        }
                    }
                    onCanceled: console.log("MOUSE CANCELED: Exit button")
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

                Component.onCompleted: {
                    console.log("Details button container:", width, "x", height, "at", x, y)
                }

                MouseArea {
                    id: detailsMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onEntered: console.log("MOUSE ENTERED: Details button")
                    onExited: console.log("MOUSE EXITED: Details button")
                    onPressed: console.log("MOUSE PRESSED: Details button at", mouse.x, mouse.y)
                    onClicked: {
                        console.log("=== DETAILS CLICKED ===")
                        console.log("GameInfoRect:", gameInfoRect ? "available" : "NULL")
                        if (gameInfoRect) {
                            console.log("Current showGameInfo:", gameInfoRect.showGameInfo)
                            gameInfoRect.showGameInfo = !gameInfoRect.showGameInfo
                            console.log("New showGameInfo:", gameInfoRect.showGameInfo)
                            if (sounds && sounds.toDetails) {
                                sounds.toDetails.play()
                            }
                            if (gameInfoRect.showGameInfo) {
                                gameInfoRect.forceActiveFocus()
                                console.log("Focus set to gameInfoRect")
                            } else if (gameGridView) {
                                gameGridView.forceActiveFocus()
                                console.log("Focus set to gameGridView")
                            }
                        } else {
                            console.log("ERROR: gameInfoRect is null!")
                        }
                    }
                    onCanceled: console.log("MOUSE CANCELED: Details button")
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

                Component.onCompleted: {
                    console.log("Filter button container:", width, "x", height, "at", x, y)
                }

                MouseArea {
                    id: filterMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onEntered: console.log("MOUSE ENTERED: Filter button")
                    onExited: console.log("MOUSE EXITED: Filter button")
                    onPressed: console.log("MOUSE PRESSED: Filter button at", mouse.x, mouse.y)
                    onClicked: {
                        console.log("=== FILTER CLICKED ===")
                        console.log("hasFavorites:", root.hasFavorites)
                        console.log("hasHistory:", root.hasHistory)
                        console.log("GameGridView:", gameGridView ? "available" : "NULL")

                        if (!root.hasFavorites && !root.hasHistory) {
                            console.log("No filters available")
                            if (sounds && sounds.errorSound) {
                                sounds.errorSound.play()
                            }
                        } else if (gameGridView) {
                            console.log("Current filter:", gameGridView.currentFilter)
                            var nextFilter = (gameGridView.currentFilter + 1) % 3
                            console.log("Trying next filter:", nextFilter)
                            var originalFilter = gameGridView.currentFilter
                            while (true) {
                                if (nextFilter === 0 || (nextFilter === 1 && root.hasFavorites) || (nextFilter === 2 && root.hasHistory)) break
                                    nextFilter = (nextFilter + 1) % 3
                                    if (nextFilter === originalFilter) break
                            }

                            console.log("Setting filter to:", nextFilter)
                            gameGridView.currentFilter = nextFilter

                            if (sounds && sounds.naviSoundGrid) {
                                console.log("Playing filter change sound")
                                sounds.naviSoundGrid.play()
                            } else if (sounds && sounds.toDetails) {
                                console.log("Playing alternative filter sound")
                                sounds.toDetails.play()
                            }
                        } else {
                            console.log("ERROR: gameGridView is null!")
                        }
                    }
                    onCanceled: console.log("MOUSE CANCELED: Filter button")
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

                Component.onCompleted: {
                    console.log("Launch button container:", width, "x", height, "at", x, y)
                }

                MouseArea {
                    id: launchMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onEntered: console.log("MOUSE ENTERED: Launch button")
                    onExited: console.log("MOUSE EXITED: Launch button")
                    onPressed: console.log("MOUSE PRESSED: Launch button at", mouse.x, mouse.y)
                    onClicked: {
                        console.log("=== LAUNCH CLICKED ===")
                        console.log("GameGridView:", gameGridView ? "available" : "NULL")
                        if (gameGridView) {
                            console.log("currentGameData:", gameGridView.currentGameData ? "exists" : "NULL")
                            if (gameGridView.currentGameData) {
                                var gameToLaunch = gameGridView.currentGameData
                                console.log("Launching game:", gameToLaunch.title)
                                if (sounds && sounds.launchgame) {
                                    sounds.launchgame.play()
                                }
                                if (collectionListView) {
                                    console.log("Saving collection index:", collectionListView.currentIndex)
                                    api.memory.set('lastCollectionIndex', collectionListView.currentIndex)
                                }
                                gameToLaunch.launch()
                            } else {
                                console.log("ERROR: No currentGameData to launch!")
                            }
                        } else {
                            console.log("ERROR: gameGridView is null!")
                        }
                    }
                    onCanceled: console.log("MOUSE CANCELED: Launch button")
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

        Component.onCompleted: {
            console.log("=== INFOBAR INIT ===")
            console.log("InfoBar dimensions:", width, "x", height)
            console.log("InfoBar opacity:", opacity)
            console.log("InfoBar visible:", visible)
        }

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

                Component.onCompleted: {
                    console.log("Next page button container:", width, "x", height, "at", x, y, "visible:", visible)
                }

                MouseArea {
                    id: nextPageMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    visible: parent.visible

                    onEntered: console.log("MOUSE ENTERED: Next page button")
                    onExited: console.log("MOUSE EXITED: Next page button")
                    onPressed: console.log("MOUSE PRESSED: Next page button at", mouse.x, mouse.y)
                    onClicked: {
                        console.log("=== NEXT PAGE CLICKED ===")
                        console.log("GameInfoRect:", gameInfoRect ? "available" : "NULL")
                        if (gameInfoRect) {
                            console.log("Total pages:", gameInfoRect.totalPages)
                            if (gameInfoRect.totalPages <= 1) {
                                console.log("Only 1 page, playing error sound")
                                if (sounds && sounds.errorSound) sounds.errorSound.play()
                            } else {
                                console.log("Navigating to next page")
                                if (sounds && sounds.detailsNextSound) sounds.detailsNextSound.play()
                                    gameInfoRect.navigatePages()
                                    console.log("Current page after navigation:", gameInfoRect.currentPage)
                            }
                        } else {
                            console.log("ERROR: gameInfoRect is null!")
                        }
                    }
                    onCanceled: console.log("MOUSE CANCELED: Next page button")
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

                Component.onCompleted: {
                    console.log("Favorite button container:", width, "x", height, "at", x, y)
                }

                MouseArea {
                    id: favoriteMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onEntered: console.log("MOUSE ENTERED: Favorite button")
                    onExited: console.log("MOUSE EXITED: Favorite button")
                    onPressed: console.log("MOUSE PRESSED: Favorite button at", mouse.x, mouse.y)
                    onClicked: {
                        console.log("=== FAVORITE CLICKED ===")
                        console.log("GameInfoRect:", gameInfoRect ? "available" : "NULL")
                        if (gameInfoRect && gameInfoRect.currentGame) {
                            console.log("Current game:", gameInfoRect.currentGame.title)
                            console.log("Current favorite status:", gameInfoRect.currentGame.favorite)
                            var newFavoriteStatus = !gameInfoRect.currentGame.favorite
                            gameInfoRect.currentGame.favorite = newFavoriteStatus
                            console.log("New favorite status:", newFavoriteStatus)
                            if (sounds && sounds.naviSoundGrid) {
                                sounds.naviSoundGrid.play()
                            }
                            if (gameGridView && gameGridView.favoriteToggled) {
                                console.log("Emitting favoriteToggled signal")
                                gameGridView.favoriteToggled(gameInfoRect.currentGame, newFavoriteStatus)
                            }
                            gameInfoRect.favoriteStatusChanged()
                            console.log("Favorite toggled successfully")
                        } else {
                            console.log("ERROR: gameInfoRect or currentGame is null!")
                        }
                    }
                    onCanceled: console.log("MOUSE CANCELED: Favorite button")
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

                Component.onCompleted: {
                    console.log("Back button container:", width, "x", height, "at", x, y)
                }

                MouseArea {
                    id: backMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onEntered: console.log("MOUSE ENTERED: Back button")
                    onExited: console.log("MOUSE EXITED: Back button")
                    onPressed: console.log("MOUSE PRESSED: Back button at", mouse.x, mouse.y)
                    onClicked: {
                        console.log("=== BACK CLICKED ===")
                        console.log("GameInfoRect:", gameInfoRect ? "available" : "NULL")
                        console.log("GameGridView:", gameGridView ? "available" : "NULL")
                        if (gameInfoRect) {
                            console.log("Closing game info")
                            gameInfoRect.showGameInfo = false
                        }
                        if (gameGridView) {
                            console.log("Setting focus to gameGridView")
                            gameGridView.forceActiveFocus()
                        }
                        if (sounds && sounds.infotogrid) {
                            console.log("Playing infotogrid sound")
                            sounds.infotogrid.play()
                        }
                    }
                    onCanceled: console.log("MOUSE CANCELED: Back button")
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

        Component.onCompleted: {
            console.log("=== TOGGLE BTN INIT ===")
            console.log("Toggle button dimensions:", width, "x", height)
        }

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

            onEntered: console.log("MOUSE ENTERED: Toggle button")
            onExited: console.log("MOUSE EXITED: Toggle button")
            onPressed: console.log("MOUSE PRESSED: Toggle button")
            onClicked: {
                console.log("=== TOGGLE CLICKED ===")
                console.log("Current isCollapsed:", root.isCollapsed)
                root.isCollapsed = !root.isCollapsed;
                console.log("New isCollapsed:", root.isCollapsed)
                api.memory.set('horizontalBarCollapsed', root.isCollapsed);
            }
            onCanceled: console.log("MOUSE CANCELED: Toggle button")
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
            console.log("GameInfoRect totalPages changed:", gameInfoRect.totalPages)
            root.totalPages = gameInfoRect.totalPages;
        }
        function onVisibleChanged() {
            console.log("GameInfoRect visible changed:", gameInfoRect.visible)
            root.isGameInfoVisible = gameInfoRect.visible;
        }
        function onFavoriteStatusChanged() {
            console.log("GameInfoRect favorite status changed")
        }
        function onCurrentGameChanged() {
            console.log("GameInfoRect currentGame changed:", gameInfoRect.currentGame ? gameInfoRect.currentGame.title : "null")
        }
    }

    Connections {
        target: gameGridView
        function onFavoriteToggled(game, isFavorite) {
            console.log("GameGridView favorite toggled:", game ? game.title : "null", isFavorite)
            root.hasFavorites = gameGridView.hasFavorites
            root.hasHistory = gameGridView.hasHistory
        }
        function onFilterChanged(newFilter) {
            console.log("GameGridView filter changed to:", newFilter)
            root.currentFilter = newFilter
        }
    }

    Component.onCompleted: {
        console.log("=== HORIZONTALBAR COMPONENT ONCOMPLETED ===")
        console.log("Root dimensions:", root.width, "x", root.height)
        console.log("Root position:", root.x, root.y)
        console.log("Root visible:", root.visible)
        console.log("Root opacity:", root.opacity)
        console.log("Root z:", root.z)
        console.log("Root isCollapsed:", root.isCollapsed)
        console.log("Root isGameInfoVisible:", root.isGameInfoVisible)
        console.log("GameGridView:", gameGridView ? "available" : "NULL")
        console.log("GameInfoRect:", gameInfoRect ? "available" : "NULL")
        console.log("CollectionListView:", collectionListView ? "available" : "NULL")
        console.log("Sounds:", sounds ? "available" : "NULL")

        var saved = api.memory.get('horizontalBarCollapsed');
        console.log("Saved collapsed state:", saved)
        root.isCollapsed = (saved === true);

        Qt.callLater(function() {
            root.animationsReady = true;
            console.log("=== HORIZONTALBAR FULLY INITIALIZED ===")
            console.log("Animations ready set to true")
            console.log("MainBar opacity:", mainBar.opacity)
            console.log("MainBar visible:", mainBar.visible)
            console.log("InfoBar opacity:", infoBar.opacity)
            console.log("InfoBar visible:", infoBar.visible)
            console.log("Toggle button position:", toggleBtn.x, toggleBtn.y)
        });
    }
}
