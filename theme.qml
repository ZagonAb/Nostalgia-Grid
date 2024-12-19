import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.12
import SortFilterProxyModel 0.2
import QtMultimedia 5.15

FocusScope {
    id: root
    focus: true
    width: parent.width
    height: parent.height

    property bool gridViewFocused: false
    property bool showGameInfo: false
    property var game: null

    Timer {
        id: launchTimer
        interval: 500 
        repeat: false
        onTriggered: {
            game.launch();
        }
    }

    SoundEffect {
        id: toCollec
        source: "assets/sound/tocollec.wav"
        volume: 2.5
    }

    SoundEffect {
        id: toGames
        source: "assets/sound/togame.wav"
        volume: 2.5
    }

    SoundEffect {
        id: naviSoundLits
        source: "assets/sound/change-list.wav"
        volume: 2.5
    }

    SoundEffect {
        id: naviSoundGrid
        source: "assets/sound/change-grid.wav"
        volume: 2.5
    }

    SoundEffect {
        id: toDetails
        source: "assets/sound/details.wav"
        volume: 2.5
    }

    SoundEffect {
        id: infotogrid
        source: "assets/sound/infotogrid.wav"
        volume: 2.5
    }

    SoundEffect {
        id: launchgame
        source: "assets/sound/launch.wav"
        volume: 2.5
    }

    function formatPlayTime(seconds) {
        if (seconds <= 0) return "0 min";

        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);

        if (hours > 0) {
            return hours + " h " + (minutes > 0 ? minutes + " m" : ""); 
        } else {
            return minutes + " min";
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: collectionBar
            Layout.preferredWidth: parent.width * 0.15
            Layout.fillHeight: true
            color: "#FF0000"

            ListView {
                id: collectionListView
                anchors.fill: parent
                model: api.collections
                spacing: 20
                property int indexToPosition: -1
                property string currentShortName: ""
                property string cuerrntCollectionName: ""
                focus: !root.gridViewFocused

                delegate: Item {
                    width: parent.width
                    height: Math.min(parent.height * 0.12, 100)

                    Image {
                        id: collectionImage
                        source: "assets/systems/" + model.shortName + ".png"
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        width: Math.min(parent.width * 0.9, parent.height * 1.8)
                        height: width / (sourceSize.width / sourceSize.height)

                        opacity: index === collectionListView.currentIndex && !root.gridViewFocused ? 1 : 0.5

                        SequentialAnimation {
                            running: index === collectionListView.currentIndex
                            loops: Animation.Infinite

                            PropertyAnimation {
                                target: collectionImage
                                property: "scale"
                                to: 0.9
                                duration: 500
                                easing.type: Easing.InOutQuad
                            }
                            PropertyAnimation {
                                target: collectionImage
                                property: "scale"
                                to: 1.0
                                duration: 500
                                easing.type: Easing.InOutQuad
                            }
                        }

                        scale: index === collectionListView.currentIndex ? collectionImage.scale : 1.0
                    }

                    Image {
                        id: defaultImage
                        source: "assets/systems/default.png"
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                        width: Math.min(parent.width * 0.9, parent.height * 1.8)
                        height: width / (sourceSize.width / sourceSize.height)
                        visible: collectionImage.status === Image.Error
                        opacity: index === collectionListView.currentIndex && !root.gridViewFocused ? 1 : 0.5
                        mipmap: true
                        smooth: true

                        SequentialAnimation {
                            running: index === collectionListView.currentIndex
                            loops: Animation.Infinite

                            PropertyAnimation {
                                target: defaultImage
                                property: "scale"
                                to: 0.9
                                duration: 500
                                easing.type: Easing.InOutQuad
                            }
                            PropertyAnimation {
                                target: defaultImage
                                property: "scale"
                                to: 1.0
                                duration: 500
                                easing.type: Easing.InOutQuad
                            }
                        }

                        scale: index === collectionListView.currentIndex ? defaultImage.scale : 1.0
                    }
                }

                onIndexToPositionChanged: {
                    if (indexToPosition >= 0) {
                        positionViewAtIndex(indexToPosition, ListView.Center)
                    }
                }

                Behavior on indexToPosition {
                    NumberAnimation { duration: 200 }
                }

                onCurrentIndexChanged: {
                    const selectedCollection = api.collections.get(currentIndex)
                    gameGridView.model = selectedCollection.games
                    currentShortName = selectedCollection.shortName
                    cuerrntCollectionName = selectedCollection.name
                    indexToPosition = currentIndex
                    naviSoundLits.play();
                }

                Keys.onRightPressed: {
                    root.gridViewFocused = true
                    gameGridView.forceActiveFocus()
                    toGames.play();
                }
            }
        }

        Item {
            id: gameGridContainer
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                color: "#303030"
                width: parent.width
                height: parent.height

                GridView {
                    id: gameGridView
                    anchors.fill: parent
                    property bool isHorizontalMode: false
                    property int columns: isHorizontalMode ? 4 : 6
                    property int rows: isHorizontalMode ? 4 : 3
                    cellWidth: width / columns
                    cellHeight: height / rows
                    focus: root.gridViewFocused
                    property string currentGame: ""
                    clip: false
                    property real targetCellWidth: width / columns
                    property real targetCellHeight: height / rows

                    Behavior on cellWidth {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuad
                        }
                    }

                    Behavior on cellHeight {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuad
                        }
                    }

                    delegate: Item {
                        id: gameItem
                        width: gameGridView.cellWidth
                        height: gameGridView.cellHeight
                        z: gameGridView.currentIndex === index && root.gridViewFocused ? 100 : 1

                        Behavior on width {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutQuad
                            }
                        }

                        Behavior on height {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutQuad
                            }
                        }

                        Item {
                            id: imageContainer
                            property real zoomScale: gameGridView.currentIndex === index && root.gridViewFocused ?
                            (boxFront.sourceSize.width > boxFront.sourceSize.height ? 1.3 : 1.15) : 1.0

                            width: parent.width * zoomScale
                            height: parent.height * zoomScale

                            x: {
                                if (gameGridView.currentIndex === index && root.gridViewFocused) {
                                    var extraWidth = width - parent.width
                                    var column = index % gameGridView.columns

                                    if (column === 0) {
                                        return 0
                                    } else if (column === gameGridView.columns - 1) {
                                        return -extraWidth
                                    }
                                    return -extraWidth / 2
                                }
                                return 0
                            }

                            y: {
                                if (gameGridView.currentIndex === index && root.gridViewFocused) {
                                    var extraHeight = height - parent.height
                                    var row = Math.floor(index / gameGridView.columns)
                                    var totalRows = Math.ceil(gameGridView.count / gameGridView.columns)
                                    var visibleRows = Math.floor(gameGridView.height / gameGridView.cellHeight)
                                    var itemY = row * gameGridView.cellHeight
                                    var viewportTop = gameGridView.contentY
                                    var viewportBottom = viewportTop + gameGridView.height
                                    if (itemY - viewportTop < gameGridView.cellHeight) {
                                        return 0
                                    }
                                    else if (viewportBottom - itemY < gameGridView.cellHeight * 2) {
                                        return -extraHeight
                                    }
                                    return -extraHeight / 2
                                }
                                return 0
                            }

                            Behavior on x {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutQuad
                                }
                            }

                            Behavior on y {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutQuad
                                }
                            }

                            Behavior on width {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutQuad
                                }
                            }

                            Behavior on height {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutQuad
                                }
                            }

                            Image {
                                id: boxFront
                                anchors.fill: parent
                                source: model.assets.boxFront
                                fillMode: Image.Stretch
                                asynchronous: true

                                onStatusChanged: {
                                    if (status === Image.Ready && gameGridView.currentIndex === index) {
                                        gameGridView.isHorizontalMode = sourceSize.width > sourceSize.height
                                    }
                                }

                                layer.enabled: gameGridView.currentIndex === index && root.gridViewFocused
                                layer.effect: DropShadow {
                                    horizontalOffset: 5
                                    verticalOffset: 5
                                    radius: 80
                                    samples: 300
                                    color: "#FF000000"
                                }
                            }

                            Rectangle {
                                id: rectangleCurrentIndex
                                anchors.fill: parent
                                color: "transparent"
                                border.color: gameGridView.currentIndex === index && root.gridViewFocused ? "white" : "transparent"
                                border.width: 2

                                SequentialAnimation on border.color {
                                    running: gameGridView.currentIndex === index && root.gridViewFocused
                                    loops: Animation.Infinite
                                    ColorAnimation { to: "transparent"; duration: 500 }
                                    PauseAnimation { duration: 100 }
                                    ColorAnimation { to: "white"; duration: 500 }
                                    PauseAnimation { duration: 400 }
                                }
                            }

                            Image {
                                id: defaultImage
                                source: "assets/no-image/default.png"
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                mipmap: true
                                visible: boxFront.status === Image.Error
                            }
                        }
                    }

                    onCurrentIndexChanged: {
                        naviSoundGrid.play();
                        const selectedGame = gameGridView.model.get(currentIndex);
                        gameGridView.currentGame = selectedGame ? selectedGame.title : "";
                        const currentCollectionShortName = collectionListView.currentShortName;
                        game = gameGridView.model.get(currentIndex);
                        if (selectedGame && selectedGame.assets && selectedGame.assets.boxFront) {
                            var img = new Image();
                            img.source = selectedGame.assets.boxFront;
                            isHorizontalMode = img.sourceSize.width > img.sourceSize.height;
                        }
                    }

                    Keys.onLeftPressed: {
                        if (currentIndex % columns === 0) {
                            root.gridViewFocused = false
                            collectionListView.forceActiveFocus()
                            toCollec.play();
                        } else {
                            moveCurrentIndexLeft(naviSoundGrid.play())
                        }
                    }

                    Keys.onPressed: {
                        if (!event.isAutoRepeat) {
                            if (api.keys.isFilters(event)) {
                                showGameInfo = !showGameInfo;
                                toDetails.play();
                                gameInfoRect.forceActiveFocus();
                            } else if (api.keys.isAccept(event)) {
                                event.accepted = true;
                                launchTimer.start();
                                launchgame.play();
                            }
                        }
                    }
                }
            }
        }
    }

    FastBlur {
        anchors.fill: parent
        source: gameGridContainer
        radius: 62
        visible: showGameInfo
        z: 1
    }

    Rectangle {
        id: gameInfoRect
        anchors.centerIn: parent
        width: parent.width * 0.92
        height: parent.height * 0.92
        color: "#F0F0F0"
        radius: 10
        visible: showGameInfo
        z: 2

        Row {
            anchors.fill: parent
            anchors.margins: 10
            spacing: Math.max(10, parent.width * 0.02)

            Item {
                width: parent.width * 0.4
                height: parent.height

                Image {
                    id: gameScreenshot
                    source: game && game.assets.screenshots.length > 0 ? game.assets.screenshots[0] : ""
                    fillMode: Image.PreserveAspectFit
                    width: parent.width
                    height: parent.height
                    mipmap: true
                    smooth: true
                    visible: status === Image.Ready
                }

                Image {
                    id: defaultImage
                    source: "assets/no-image/default2.png"
                    fillMode: Image.PreserveAspectFit
                    width: parent.width
                    height: parent.height
                    mipmap: true
                    smooth: true
                    visible: gameScreenshot.status === Image.Error || gameScreenshot.source === ""
                }
            }

            Item {
                width: parent.width * 0.58
                height: parent.height

                Flickable {
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: infoColumn.height
                    clip: true
                    interactive: contentHeight > height

                    Column {
                        id: infoColumn
                        width: parent.width
                        spacing: Math.max(5, gameInfoRect.height * 0.01)

                        Text {
                            id: gameTitle
                            text: gameGridView.currentGame || ""
                            color: "black"
                            font.pixelSize: Math.max(16, gameInfoRect.width * 0.03)
                            font.bold: true
                            width: parent.width
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            text: "A different looking world!"
                            color: "black"
                            font.pixelSize: Math.max(14, gameInfoRect.width * 0.025)
                            width: parent.width
                            wrapMode: Text.WordWrap
                        }

                        Row {
                            spacing: 10
                            width: parent.width
                            Text {
                                text: game ? game.developer : ""
                                font.pixelSize: Math.max(12, gameInfoRect.width * 0.015)
                                color: "grey"
                            }
                            Text {
                                text: game ? "Published in " + game.releaseYear : ""
                                font.pixelSize: Math.max(12, gameInfoRect.width * 0.015)
                                color: "grey"
                            }
                        }

                        Row {
                            spacing: 10
                            width: parent.width
                            Text {
                                text: game ? "Number of players: " + game.players : ""
                                font.pixelSize: Math.max(12, gameInfoRect.width * 0.015)
                                color: "grey"
                            }
                            Text {
                                text: game ? "Playing time: " + formatPlayTime(game.playTime) : ""
                                font.pixelSize: Math.max(12, gameInfoRect.width * 0.015)
                                color: "grey"
                            }
                        }

                        Text {
                            text: "Discover the surprises that the special world has in store for you!"
                            font.pixelSize: Math.max(12, gameInfoRect.width * 0.015)
                            color: "black"
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }

                        Text {
                            text: {
                                if (game) {
                                    var firstDotIndex = game.description.indexOf(".");
                                    var secondDotIndex = game.description.indexOf(".", firstDotIndex + 1);
                                    if (secondDotIndex !== -1) {
                                        return game.description.substring(0, secondDotIndex + 1);
                                    } else {
                                        return game.description;
                                    }
                                } else {
                                    return "";
                                }
                            }
                            font.pixelSize: Math.max(20, gameInfoRect.width * 0.024)
                            color: "grey"
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                    }
                }
            }
        }

        Keys.onPressed: {
            if (!event.isAutoRepeat && api.keys.isCancel(event)) {
                event.accepted = true;
                showGameInfo = false;
                gameGridView.forceActiveFocus();
                infotogrid.play();
            }
        }
    }

    Rectangle {
        id: horizontalBar
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        width: parent.width * 0.45 
        height: parent.height * 0.08
        color: "black"
        opacity: 0.85
        radius: 5
        z: 3

        Row {
            id: barRow
            anchors.fill: parent
            anchors.margins: parent.width * 0.01
            spacing: parent.width * 0.02

            Repeater {
                model: {
                    if (gameInfoRect.activeFocus) {
                        return [{icon: "assets/control/back.png", text: "Back"}];
                    } else {
                        return [
                            {icon: "assets/control/right.png", text: "Games", visible: !gameGridView.activeFocus},
                            {icon: "assets/control/left.png", text: "Collections", visible: !collectionListView.activeFocus},
                            {icon: "assets/control/back.png", text: "Exit"},
                            {icon: "assets/control/details.png", text: "Details", visible: !collectionListView.activeFocus},
                            {icon: "assets/control/launch.png", text: "Start", visible: !collectionListView.activeFocus}
                        ];
                    }
                }
                
                delegate: Row {
                    spacing: parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    visible: modelData.visible !== undefined ? modelData.visible : true

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
                        font.pixelSize: horizontalBar.height * 0.3
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
