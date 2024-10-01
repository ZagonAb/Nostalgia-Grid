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
                        source: "assets/systems/" + model.shortName + ".png"
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        width: Math.min(parent.width * 0.9, parent.height * 1.8)
                        height: width / (sourceSize.width / sourceSize.height)
                        
                        opacity: index === collectionListView.currentIndex && !root.gridViewFocused ? 1 : 0.5
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
                    property int columns: 4
                    property int rows: 2
                    cellWidth: width / columns
                    cellHeight: height / rows
                    focus: root.gridViewFocused
                    property string currentGame: ""
                    
                    delegate: Item {
                        id: gameItem
                        width: gameGridView.cellWidth
                        height: gameGridView.cellHeight
                        z: gameGridView.currentIndex === index && root.gridViewFocused ? 2 : 1

                        Image {
                            id: boxFront
                            source: model.assets.boxFront
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop                            
                            asynchronous: true
                            scale: gameGridView.currentIndex === index && root.gridViewFocused ? 1.15 : 1.0
                            
                            Behavior on scale { 
                                NumberAnimation { 
                                    duration: 250 
                                    easing.type: Easing.OutQuad
                                } 
                            }
                        }

                        Rectangle {
                            anchors.fill: boxFront
                            color: "transparent"
                            border.color: gameGridView.currentIndex === index && root.gridViewFocused ? "white" : "transparent"
                            border.width: 2
                            scale: boxFront.scale
                        }

                        Rectangle {
                            anchors.fill: boxFront
                            color: "black"
                            opacity: 0.5
                            visible: gameGridView.currentIndex === index && root.gridViewFocused
                            scale: boxFront.scale
                        }
                    }

                    onCurrentIndexChanged: {
                        naviSoundGrid.play();
                        const selectedGame = gameGridView.model.get(currentIndex);
                        gameGridView.currentGame = selectedGame ? selectedGame.title : "";
                        const currentCollectionShortName = collectionListView.currentShortName;
                        game = gameGridView.model.get(currentIndex);
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

            Image {
                id: gameScreenshot
                source: game ? game.assets.screenshots[0] : ""
                fillMode: Image.PreserveAspectFit
                width: parent.width * 0.4
                height: parent.height
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
