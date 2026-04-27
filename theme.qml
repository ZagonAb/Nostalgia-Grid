import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.12
import SortFilterProxyModel 0.2
import QtMultimedia 5.15
import "utils.js" as Utils

FocusScope {
    id: root
    focus: true

    width: parent.width
    height: parent.height

    property bool showGameInfo: false
    property var currentGame: null
    property var game: null
    property alias sounds: sounds

    property string cachedColor: "#f62507"
    property bool initialized: false

    ColorMapping {
        id: colorMapping
    }

    Timer {
        id: launchTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (game) {
                api.memory.set('lastCollectionIndex', collectionLoader.item.currentIndex);
                game.launch();
            }
        }
    }

    Sounds {
        id: sounds
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: collectionBar
            Layout.preferredWidth: parent.width * 0.20
            Layout.fillHeight: true

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: -0.2
                    color: "#CC000000"
                }
                GradientStop {
                    id: gradientStop
                    position: 1.0
                    color: root.cachedColor

                    Behavior on color {
                        ColorAnimation {
                            duration: 300
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }

            Loader {
                id: collectionLoader
                anchors.fill: parent
                anchors.margins: 20
                source: "CollectionListView.qml"
                asynchronous: true

                onLoaded: {
                    console.log("CollectionListView loaded successfully")
                    collectionLoader.item.sounds = Qt.binding(function() { return root.sounds })
                    collectionLoader.item.gameGridView = Qt.binding(function() { return gameGridLoader.item })

                    collectionLoader.item.shortNameChanged.connect(function(shortName) {
                        var newColor = colorMapping.getColor(shortName);
                        if (root.cachedColor !== newColor) {
                            root.cachedColor = newColor;
                            gradientStop.color = newColor;
                        }
                    })
                }

                onStatusChanged: {
                    if (status === Loader.Error) {
                        console.error("Failed to load CollectionListView.qml")
                    }
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

                Loader {
                    id: gameGridLoader
                    anchors.fill: parent
                    source: "GameGridView.qml"
                    asynchronous: true

                    onLoaded: {
                        console.log("GameGridView loaded successfully")
                        gameGridLoader.item.sounds = Qt.binding(function() { return root.sounds })
                        gameGridLoader.item.collectionListView = Qt.binding(function() { return collectionLoader.item })
                        gameGridLoader.item.gameInfoRect = Qt.binding(function() { return gameInfoLoader.item })

                        gameGridLoader.item.gameChanged.connect(function(selectedGame) {
                            if (selectedGame && selectedGame !== root.currentGame) {
                                root.game = selectedGame;
                                root.currentGame = selectedGame;
                                if (gameInfoLoader.item) {
                                    gameInfoLoader.item.currentGame = selectedGame;
                                }
                            }
                        })

                        gameGridLoader.item.filterChanged.connect(function(newFilter) {
                            if (horizontalBar) {
                                horizontalBar.currentFilter = newFilter;
                            }
                        })
                    }

                    onStatusChanged: {
                        if (status === Loader.Error) {
                            console.error("Failed to load GameGridView.qml")
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
        cached: !showGameInfo
    }

    Loader {
        id: gameInfoLoader
        source: "GameInfoRect.qml"
        asynchronous: true
        active: root.showGameInfo

        onLoaded: {
            console.log("GameInfoRect loaded successfully")
            gameInfoLoader.item.currentGame = Qt.binding(function() { return root.currentGame })
            gameInfoLoader.item.sounds = Qt.binding(function() { return root.sounds })
            gameInfoLoader.item.showGameInfo = Qt.binding(function() { return root.showGameInfo })
            gameInfoLoader.item.visible = Qt.binding(function() { return root.showGameInfo })

            gameInfoLoader.item.onShowGameInfoChanged.connect(function() {
                root.showGameInfo = gameInfoLoader.item.showGameInfo;
            })
        }

        onStatusChanged: {
            if (status === Loader.Error) {
                console.error("Failed to load GameInfoRect.qml")
            }
        }
    }

    HorizontalBar {
        id: horizontalBar
        isGameInfoVisible: gameInfoLoader.item ? gameInfoLoader.item.visible : false
        showPagination: gameInfoLoader.item ? gameInfoLoader.item.totalPages > 1 : false
        totalPages: gameInfoLoader.item ? gameInfoLoader.item.totalPages : 0
        currentFilter: gameGridLoader.item ? gameGridLoader.item.currentFilter : 0
        hasFavorites: gameGridLoader.item ? gameGridLoader.item.hasFavorites : false
        hasHistory: gameGridLoader.item ? gameGridLoader.item.hasHistory : false
        gameGridView: gameGridLoader.item
        gameInfoRect: gameInfoLoader.item
        collectionListView: collectionLoader.item
        sounds: root.sounds
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            if (!root.initialized && api.collections && api.collections.count > 0) {
                var lastCollectionIndex = api.memory.get('lastCollectionIndex') || 0;
                var targetIndex = Math.min(lastCollectionIndex, api.collections.count - 1);

                if (collectionLoader.item) {
                    collectionLoader.item.currentIndex = -1;
                    collectionLoader.item.currentIndex = targetIndex;
                }

                if (gameGridLoader.item && gameGridLoader.item.model && gameGridLoader.item.model.count > 0) {
                    gameGridLoader.item.currentIndex = 0;
                    gameGridLoader.item.positionViewAtIndex(0, GridView.Contain);
                }

                if (collectionLoader.item && collectionLoader.item.currentShortName) {
                    root.cachedColor = colorMapping.getColor(collectionLoader.item.currentShortName);
                    gradientStop.color = root.cachedColor;
                }

                root.initialized = true;
            }
        });
    }
}
