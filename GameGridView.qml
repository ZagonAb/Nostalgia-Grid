import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.12
import SortFilterProxyModel 0.2
import "utils.js" as Utils

GridView {
    id: gameGridView
    anchors.fill: parent

    property var sounds
    property var collectionListView
    property var gameInfoRect
    property var currentGameData: null
    property bool initialLayoutSet: false
    property bool firstImageIsHorizontal: false
    property int imageAspectRatio: 0
    property int currentFilter: 0
    property bool hasFavorites: false
    property bool hasHistory: false

    signal favoriteToggled(var game, bool isFavorite)

    property var sourceModel: collectionListView.model.get(collectionListView.currentIndex).games

    function updateFilterAvailability() {
        if (!model || !model.count) {
            hasFavorites = false;
            hasHistory = false;
            return;
        }

        hasFavorites = false;
        for (var i = 0; i < model.count; i++) {
            var game = model.get(i);
            if (game && game.favorite) {
                hasFavorites = true;
                break;
            }
        }

        hasHistory = false;
        for (var j = 0; j < model.count; j++) {
            game = model.get(j);
            if (game && game.lastPlayed && game.lastPlayed.getTime() > 0) {
                hasHistory = true;
                break;
            }
        }

        filterChanged(currentFilter);
    }

    function handleFavoriteToggle(game, isFavorite) {
        var sourceUpdated = false;
        for (var i = 0; i < sourceModel.count; i++) {
            var sourceGame = sourceModel.get(i);
            if (sourceGame && sourceGame.title === game.title) {
                sourceGame.favorite = isFavorite;
                sourceUpdated = true;

                if (sourceModel.dataChanged) {
                    sourceModel.dataChanged(sourceModel.index(i, 0), sourceModel.index(i, 0));
                }
                break;
            }
        }

        if (currentFilter === 1) {
            filterProxyModel.invalidate();

            var hasFavs = false;
            for (var j = 0; j < filterProxyModel.count; j++) {
                if (filterProxyModel.get(j).favorite) {
                    hasFavs = true;
                    break;
                }
            }

            if (!hasFavs) {
                currentFilter = 0;
                model = sourceModel;
            }
        }

        updateFilterAvailability();

        if (currentIndex >= model.count) {
            currentIndex = model.count > 0 ? model.count - 1 : 0;
        }

        if (model.count > 0) {
            currentGameData = model.get(currentIndex);
            gameChanged(currentGameData);
        } else {
            currentGameData = null;
            gameChanged(null);
        }
    }

    onCurrentFilterChanged: {
        if (currentFilter === 0) {
            model = sourceModel;
        } else {
            filterProxyModel.sourceModel = sourceModel;
            model = filterProxyModel;
        }
        currentIndex = 0;
        positionViewAtIndex(0, GridView.Contain);
        updateFilterAvailability();
    }

    property alias proxyModel: filterProxyModel

    signal filterChanged(int newFilter)

    SortFilterProxyModel {
        id: filterProxyModel
        sourceModel: gameGridView.sourceModel
        filters: [
            ValueFilter {
                id: favoriteFilter
                enabled: currentFilter === 1
                roleName: "favorite"
                value: true
            },
            ExpressionFilter {
                id: lastPlayedFilter
                enabled: currentFilter === 2
                expression: {
                    if (!modelData) return false;
                    return modelData.lastPlayed && modelData.lastPlayed.getTime() > 0;
                }
            }
        ]
        sorters: [
            RoleSorter {
                enabled: currentFilter === 2
                roleName: "lastPlayed"
                sortOrder: Qt.DescendingOrder
            }
        ]
    }

    property int columns: {
        if (imageAspectRatio === 1) return 4;
        else if (imageAspectRatio === 2) return 6;
        else return 4;
    }

    property int rows: {
        if (imageAspectRatio === 1) return 4;
        else if (imageAspectRatio === 2) return 3;
        else return 3;
    }

    property string currentGame: ""
    property real targetCellWidth: width / columns
    property real targetCellHeight: height / rows
    property string spinnerSource: "assets/icons/spinner.svg"
    property real squareThreshold: 0.15

    signal gameChanged(var selectedGame)
    clip: false
    focus: true

    cellWidth: width / columns
    cellHeight: height / rows

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

    onModelChanged: {
        currentIndex = 0
        initialLayoutSet = false
        firstImageIsHorizontal = false

        if (model && model.count > 0) {
            var lastGameTitle = api.memory.get('lastGameTitle') || "";
            if (lastGameTitle !== "") {
                for (var i = 0; i < model.count; i++) {
                    var game = model.get(i);
                    if (game.title === lastGameTitle) {
                        currentIndex = i;
                        positionViewAtIndex(i, GridView.Contain);
                        break;
                    }
                }
            }
        }

        updateFilterAvailability();
    }


    delegate: Item {
        id: gameItem
        width: gameGridView.cellWidth
        height: gameGridView.cellHeight
        z: gameGridView.currentIndex === index ? 100 : 1

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

            property real zoomScale: {
                if (gameGridView.currentIndex === index && boxFront && boxFront.sourceSize) {
                    if (gameGridView.imageAspectRatio === 1) {
                        return 1.2;
                    } else if (gameGridView.imageAspectRatio === 2) {
                        return 1.10;
                    } else {
                        return 1.15;
                    }
                }
                return 1.0
            }

            width: parent ? parent.width * zoomScale : 0
            height: parent ? parent.height * zoomScale : 0

            x: {
                if (!parent || !gameGridView) return 0

                    if (gameGridView.currentIndex === index) {
                        var extraWidth = width - parent.width
                        var column = index % (gameGridView.columns || 1)

                        if (column === 0) {
                            return 0
                        } else if (column === (gameGridView.columns - 1)) {
                            return -extraWidth
                        }
                        return -extraWidth / 2
                    }
                    return 0
            }

            y: {
                if (!parent || !gameGridView) return 0

                    if (gameGridView.currentIndex === index) {
                        var extraHeight = height - parent.height
                        var row = Math.floor(index / (gameGridView.columns || 1))
                        var totalRows = Math.ceil((gameGridView.count || 0) / (gameGridView.columns || 1))
                        var visibleRows = Math.floor((gameGridView.height || 0) / (gameGridView.cellHeight || 1))
                        var itemY = row * (gameGridView.cellHeight || 0)
                        var viewportTop = gameGridView.contentY || 0
                        var viewportBottom = viewportTop + (gameGridView.height || 0)

                        if (itemY - viewportTop < (gameGridView.cellHeight || 0)) {
                            return 0
                        }
                        else if (viewportBottom - itemY < (gameGridView.cellHeight || 0) * 2) {
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
                source: model.assets.boxFront || ""
                fillMode: Image.Stretch
                visible: status === Image.Ready
                asynchronous: true
                cache: true

                Component.onDestruction: {
                    if (source != "") {
                        source = ""
                    }
                }

                onStatusChanged: {
                    if (status === Image.Ready && sourceSize) {
                        var ratio = sourceSize.width / sourceSize.height;
                        var isSquare = Math.abs(1 - ratio) < gameGridView.squareThreshold;
                        var isHorizontal = ratio > 1 + gameGridView.squareThreshold;
                        var isVertical = ratio < 1 - gameGridView.squareThreshold;

                        if (!gameGridView.initialLayoutSet && index === 0) {
                            if (isHorizontal) {
                                gameGridView.imageAspectRatio = 1;
                            } else if (isVertical) {
                                gameGridView.imageAspectRatio = 2;
                            } else {
                                gameGridView.imageAspectRatio = 3;
                            }
                            gameGridView.initialLayoutSet = true;
                        }

                        if (sourceSize) {
                            if (isHorizontal) {
                                sourceSize.width = 680;
                                sourceSize.height = 500;
                            } else if (isVertical) {
                                sourceSize.width = 498;
                                sourceSize.height = 680;
                            } else {
                                sourceSize.width = 700;
                                sourceSize.height = 700;
                            }
                        }
                    }
                }

                layer.enabled: gameGridView.currentIndex === index && status === Image.Ready
                layer.effect: DropShadow {
                    horizontalOffset: 5
                    verticalOffset: 5
                    radius: 80
                    samples: 300
                    color: "#FF000000"
                }
            }

            Item {
                id: favoriteBadge
                width: parent.width * 0.34
                height: width
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                visible: Boolean(model && model.favorite) && boxFront.visible

                Image {
                    id: favoriteIcon
                    source: Boolean(model && model.favorite) ? "assets/icons/fav.png" : ""
                    width: parent.width
                    height: parent.height
                    anchors.centerIn: parent
                    visible: Boolean(model && model.favorite)
                    mipmap: true
                    fillMode: Image.PreserveAspectFit
                }
            }

            Rectangle {
                id: rectangleCurrentIndex
                anchors.fill: parent
                color: "transparent"
                border.color: gameGridView.currentIndex === index ? "white" : "transparent"
                border.width: 2

                SequentialAnimation on border.color {
                    running: gameGridView.currentIndex === index
                    loops: Animation.Infinite
                    ColorAnimation { to: "transparent"; duration: 500 }
                    PauseAnimation { duration: 100 }
                    ColorAnimation { to: "white"; duration: 500 }
                    PauseAnimation { duration: 400 }
                }
            }

            Rectangle {
                id: titleBackground
                anchors.fill: parent
                color: "#1a1a1a"
                visible: !boxFront.visible && !loadingSpinner.visible

                Text {
                    id: titleText
                    text: model.title
                    anchors.centerIn: parent
                    width: parent.width * 0.9
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    color: "white"
                    font.pixelSize: parent.height * 0.08
                    elide: Text.ElideRight
                    maximumLineCount: 3
                }
            }

            Image {
                id: loadingSpinner
                anchors.centerIn: parent
                source: gameGridView.spinnerSource
                width: parent.width * 0.3
                height: width
                visible: boxFront.status === Image.Loading
                fillMode: Image.PreserveAspectFit

                RotationAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                    running: loadingSpinner.visible
                }
            }
        }
    }

    function getCircularVerticalIndex(currentIdx, direction) {
        if (!model || model.count === 0) return currentIdx;

        var currentRow = Math.floor(currentIdx / columns);
        var totalRows = Math.ceil(model.count / columns);

        if (direction === "up") {
            if (currentRow === 0) {
                return model.count - 1;
            } else {
                var newIndex = currentIdx - columns;
                return newIndex >= 0 ? newIndex : currentIdx;
            }
        } else if (direction === "down") {
            if (currentRow === totalRows - 1) {
                return 0;
            } else {
                var newIndex = currentIdx + columns;
                return newIndex < model.count ? newIndex : currentIdx;
            }
        }

        return currentIdx;
    }

    onCurrentIndexChanged: {
        if (model && model.get && currentIndex >= 0 && currentIndex < count) {
            sounds.naviSoundGrid.play();
            currentGameData = model.get(currentIndex);

            if (currentGameData && currentGameData.hasOwnProperty("title")) {
                currentGame = currentGameData.title;
            } else {
                currentGame = "";
            }

            if (currentGameData) {
                gameChanged(currentGameData);
            }
        }
    }

    Component.onCompleted: {
        initialLayoutSet = false
        favoriteToggled.connect(handleFavoriteToggle)
    }

    Keys.onPressed: {
        if (!event.isAutoRepeat) {
            if (api.keys.isUp(event)) {
                var newIndex = getCircularVerticalIndex(currentIndex, "up");
                if (newIndex !== currentIndex) {
                    currentIndex = newIndex;
                    positionViewAtIndex(currentIndex, GridView.Contain);
                }
                event.accepted = true;
            }
            else if (api.keys.isDown(event)) {
                var newIndex = getCircularVerticalIndex(currentIndex, "down");
                if (newIndex !== currentIndex) {
                    currentIndex = newIndex;
                    positionViewAtIndex(currentIndex, GridView.Contain);
                }
                event.accepted = true;
            }
            else if (api.keys.isLeft(event)) {
                if (currentIndex > 0) {
                    currentIndex--;
                    positionViewAtIndex(currentIndex, GridView.Contain);
                }
                event.accepted = true;
            }
            else if (api.keys.isRight(event)) {
                if (currentIndex < count - 1) {
                    currentIndex++;
                    positionViewAtIndex(currentIndex, GridView.Contain);
                }
                event.accepted = true;
            }

            else if (api.keys.isNextPage(event)) {
                if (collectionListView.count > 0) {
                    currentFilter = 0;
                    collectionListView.currentIndex = (collectionListView.currentIndex + 1) % collectionListView.count;
                    sounds.toCollec.play();
                }
                event.accepted = true;
            }
            else if (api.keys.isPrevPage(event)) {
                if (collectionListView.count > 0) {
                    currentFilter = 0;
                    collectionListView.currentIndex = (collectionListView.currentIndex - 1 + collectionListView.count) % collectionListView.count;
                    sounds.toCollec.play();
                }
                event.accepted = true;
            }
            else if (api.keys.isFilters(event)) {
                gameInfoRect.showGameInfo = !gameInfoRect.showGameInfo;
                sounds.toDetails.play();
                gameInfoRect.forceActiveFocus();
                event.accepted = true;
            }

            else if (api.keys.isDetails(event)) {
                if (!hasFavorites && !hasHistory) {
                    sounds.errorSound.play();
                    event.accepted = true;
                    return;
                }

                var nextFilter = (currentFilter + 1) % 3;

                while (true) {
                    if (nextFilter === 0) break;
                    if (nextFilter === 1 && hasFavorites) break;
                    if (nextFilter === 2 && hasHistory) break;
                    nextFilter = (nextFilter + 1) % 3;
                }

                currentFilter = nextFilter;
                sounds.naviSoundGrid.play();

                if (currentFilter === 0) {
                    model = collectionListView.model.get(collectionListView.currentIndex).games;
                } else {
                    filterProxyModel.sourceModel = collectionListView.model.get(collectionListView.currentIndex).games;
                    model = filterProxyModel;
                }

                currentIndex = -1;
                currentIndex = 0;
                if (model && model.get && model.count > 0) {
                    currentGameData = model.get(0);
                    gameChanged(currentGameData);
                }
                positionViewAtIndex(0, GridView.Contain);
                event.accepted = true;
            }

            else if (api.keys.isAccept(event)) {
                event.accepted = true;
                if (currentGameData) {
                    var gameToLaunch = currentGameData;
                    if (currentFilter !== 0) {
                        var sourceIndex = filterProxyModel.mapToSource(filterProxyModel.index(currentIndex, 0));
                        gameToLaunch = collectionListView.model.get(collectionListView.currentIndex).games.get(sourceIndex.row);
                    }
                    game = gameToLaunch;
                    launchTimer.start();
                    sounds.launchgame.play();
                }
            }
        }
    }
}
