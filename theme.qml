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
    property bool interfaceReady: false

    readonly property color splashBackgroundColor: Utils.interpolateColors("#101014", root.cachedColor, 0.4)

    ColorMapping {
        id: colorMapping
    }

    Timer {
        id: launchTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (game) {
                console.log("[PT][theme] launchTimer -> guardando lastCollectionIndex:", collectionListView.currentIndex,
                            "lastFilter:", gameGridView.currentFilter,
                            "lastGameTitle:", game.title);
                api.memory.set('lastCollectionIndex', collectionListView.currentIndex);
                api.memory.set('lastFilter', gameGridView.currentFilter);
                api.memory.set('lastGameTitle', game.title);
                game.launch();
            }
        }
    }

    function clearRestoreMemory() {
        console.log("[PT][theme] clearRestoreMemory -> reseteando memoria de restauración");
        api.memory.set('lastCollectionIndex', 0);
        api.memory.set('lastFilter', 0);
        api.memory.set('lastGameTitle', '');
    }

    Sounds {
        id: sounds
    }

    RowLayout {
        id: mainContent
        anchors.fill: parent
        spacing: 0
        enabled: root.interfaceReady

        Rectangle {
            id: collectionBar
            Layout.preferredWidth: parent.width * 0.20
            Layout.fillHeight: true

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: - 0.2
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

            CollectionListView {
                id: collectionListView
                anchors.fill: parent
                anchors.margins: 20
                sounds: root.sounds
                gameGridView: gameGridView

                onShortNameChanged: {
                    var newColor = colorMapping.getColor(shortName);
                    if (root.cachedColor !== newColor) {
                        root.cachedColor = newColor;
                        gradientStop.color = newColor;
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

                GameGridView {
                    id: gameGridView
                    anchors.fill: parent
                    sounds: root.sounds
                    collectionListView: collectionListView
                    gameInfoRect: gameInfoRect

                    onGameChanged: {
                        if (selectedGame && selectedGame !== root.currentGame) {
                            root.game = selectedGame;
                            root.currentGame = selectedGame;
                            gameInfoRect.currentGame = selectedGame;
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

    GameInfoRect {
        id: gameInfoRect
        visible: showGameInfo
        currentGame: root.currentGame
        sounds: root.sounds

        onShowGameInfoChanged: {
            root.showGameInfo = showGameInfo;
        }
    }

    HorizontalBar {
        id: horizontalBar
        isGameInfoVisible: gameInfoRect.visible
        showPagination: gameInfoRect.totalPages > 1
        totalPages: gameInfoRect.totalPages
        currentFilter: gameGridView.currentFilter
        hasFavorites: gameGridView.hasFavorites
        hasHistory: gameGridView.hasHistory
        gameGridView: gameGridView
        gameInfoRect: gameInfoRect
        collectionListView: collectionListView
        sounds: root.sounds
    }

    Connections {
        target: gameGridView
        function onFilterChanged(newFilter) {
            horizontalBar.currentFilter = newFilter;
        }
        function onRestoreFinished() {
            console.log("[PT][theme] restoreFinished -> interfaceReady = true");
            root.interfaceReady = true;
            root.clearRestoreMemory();
        }
    }

    SplashScreen {
        id: splashScreen
        anchors.fill: parent
        titleText: "NOSTALGIA GRID"
        subtitleText: "Restoring your collection..."
        minSplashDuration: 2600
        interfaceReady: root.interfaceReady
        themeColors: ({
            background: root.splashBackgroundColor,
            primary: "#f2a541",
            text: "#f5e9da",
            textSecondary: "#c9a97c"
        })
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            if (!root.initialized) {
                if (!api.collections || api.collections.count === 0) {
                    console.log("[PT][theme] onCompleted -> sin colecciones, nada que restaurar");
                    root.interfaceReady = true;
                    root.initialized = true;
                    return;
                }

                var lastCollectionIndex = api.memory.get('lastCollectionIndex') || 0;
                var targetIndex = Math.min(lastCollectionIndex, api.collections.count - 1);
                var lastFilter = api.memory.get('lastFilter') || 0;
                var lastGameTitle = api.memory.get('lastGameTitle') || "";

                console.log("[PT][theme] onCompleted -> lastCollectionIndex:", lastCollectionIndex,
                            "targetIndex:", targetIndex,
                            "lastFilter:", lastFilter,
                            "lastGameTitle:", lastGameTitle);

                collectionListView.currentIndex = -1;
                collectionListView.currentIndex = targetIndex;

                console.log("[PT][theme] tras fijar collectionListView.currentIndex ->",
                            "gameGridView.model.count:", gameGridView.model ? gameGridView.model.count : -1,
                            "hasFavorites:", gameGridView.hasFavorites,
                            "hasHistory:", gameGridView.hasHistory);

                if (gameGridView.model) {
                    console.log("[PT][theme] llamando gameGridView.restoreState(", lastFilter, ",", lastGameTitle, ")");
                    gameGridView.restoreState(lastFilter, lastGameTitle);
                } else {
                    root.interfaceReady = true;
                }

                if (collectionListView.currentShortName) {
                    root.cachedColor = colorMapping.getColor(collectionListView.currentShortName);
                    gradientStop.color = root.cachedColor;
                }

                root.initialized = true;
            }
        });
    }
}
