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
    property string collectionOrientation: "vertical"
    property bool orientationResolved: false
    property var _orientationCache: ({})
    property int currentFilter: 0
    property bool hasFavorites: false
    property bool hasHistory: false

    signal favoriteToggled(var game, bool isFavorite)
    signal filterChanged(int newFilter)
    signal restoreFinished()


    property var sourceModel: null
    property int lastClickedIndex: -1
    property var lastClickTime: 0

    Timer {
        id: doubleClickTimer
        interval: 300
        repeat: false
        onTriggered: {
            gameGridView.lastClickedIndex = -1
        }
    }

    function updateFilterAvailability() {
        if (!model || !model.count) {
            hasFavorites = false;
            hasHistory = false;
            return;
        }

        var favFound = false;
        var histFound = false;

        for (var i = 0; i < model.count && (!favFound || !histFound); i++) {
            var game = model.get(i);
            if (game) {
                if (!favFound && game.favorite) favFound = true;
                if (!histFound && game.lastPlayed && game.lastPlayed.getTime() > 0) histFound = true;
            }
        }

        hasFavorites = favFound;
        hasHistory = histFound;

        filterChanged(currentFilter);
    }

    function handleFavoriteToggle(game, isFavorite) {
        if (!sourceModel) return;

        for (var i = 0; i < sourceModel.count; i++) {
            var sourceGame = sourceModel.get(i);
            if (sourceGame && sourceGame.title === game.title) {
                sourceGame.favorite = isFavorite;

                if (sourceModel.dataChanged) {
                    sourceModel.dataChanged(sourceModel.index(i, 0), sourceModel.index(i, 0));
                }
                break;
            }
        }

        if (currentFilter === 1) {
            filterProxyModel.invalidate();
        }

        updateFilterAvailability();

        if (currentIndex >= model.count && model.count > 0) {
            currentIndex = model.count - 1;
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
        if (!sourceModel) return;
        console.log("[PT][GameGridView] onCurrentFilterChanged ->", currentFilter,
                    "sourceModel.count:", sourceModel.count,
                    "filterProxyModel.count (antes):", filterProxyModel.count);
        model = currentFilter === 0 ? sourceModel : filterProxyModel;
        currentIndex = 0;
        positionViewAtIndex(0, GridView.Contain);
        updateFilterAvailability();
        console.log("[PT][GameGridView] onCurrentFilterChanged (fin) -> model.count:", model ? model.count : -1);
    }

    property string _pendingRestoreTitle: ""
    property int _restoreSettleAttempts: 0
    property bool _isInitialRestore: false

    function restoreState(filter, gameTitle) {
        var safeFilter = filter;
        if (safeFilter === 1 && !hasFavorites) safeFilter = 0;
        if (safeFilter === 2 && !hasHistory) safeFilter = 0;

        console.log("[PT][GameGridView] restoreState -> filter pedido:", filter,
                    "safeFilter:", safeFilter,
                    "hasFavorites:", hasFavorites,
                    "hasHistory:", hasHistory,
                    "gameTitle:", gameTitle);

        _isInitialRestore = true;
        _beginSettledChange(safeFilter, gameTitle || "");
    }

    function applyFilter(newFilter) {
        if (!sourceModel) return;
        console.log("[PT][GameGridView] applyFilter ->", currentFilter, "->", newFilter);
        _isInitialRestore = false;
        _beginSettledChange(newFilter, "");
    }

    function _beginSettledChange(targetFilter, pendingTitle) {
        _pendingRestoreTitle = pendingTitle;
        _restoreSettleAttempts = 0;
        restoreSettleTimer.lastCount = -1;

        if (currentFilter === targetFilter) {
            restoreSettleTimer.restart();
        } else {
            currentFilter = targetFilter;
            restoreSettleTimer.restart();
        }
    }

    function _ensureGridVisible() {
        console.log("[PT][GameGridView] _ensureGridVisible -> opacity:", gridTransitionOpacity,
                    "scale:", gridTransitionScale);
        if (gridTransitionOpacity < 1.0 || gridTransitionScale < 1.0) {
            console.log("[PT][GameGridView] _ensureGridVisible -> forzando reveal");
            revealAnimation.restart();
        }
    }

    function _applyPendingRestore() {
        var title = _pendingRestoreTitle;
        _pendingRestoreTitle = "";

        console.log("[PT][GameGridView] _applyPendingRestore -> title:", title,
                    "model.count:", model ? model.count : -1,
                    "currentFilter:", currentFilter);

        if (title !== "" && model && model.count > 0) {
            for (var i = 0; i < model.count; i++) {
                var g = model.get(i);
                if (g && g.title === title) {
                    console.log("[PT][GameGridView] _applyPendingRestore -> encontrado en index:", i);
                    currentIndex = -1;
                    currentIndex = i;
                    positionViewAtIndex(i, GridView.Contain);
                    _ensureGridVisible();
                    _finishPendingRestore();
                    return;
                }
            }
            console.log("[PT][GameGridView] _applyPendingRestore -> NO encontrado, cae a index 0");
        }

        currentIndex = -1;
        currentIndex = 0;
        positionViewAtIndex(0, GridView.Contain);

        if (model && model.get && model.count > 0) {
            currentGameData = model.get(0);
            gameChanged(currentGameData);
        }

        _ensureGridVisible();
        _finishPendingRestore();
    }

    function _finishPendingRestore() {
        if (_isInitialRestore) {
            _isInitialRestore = false;
            console.log("[PT][GameGridView] restoreFinished()");
            restoreFinished();
        }
    }

    Timer {
        id: restoreSettleTimer
        interval: 80
        repeat: true
        property int lastCount: -1
        onTriggered: {
            var count = gameGridView.model ? gameGridView.model.count : 0;
            gameGridView._restoreSettleAttempts++;

            console.log("[PT][GameGridView] restoreSettleTimer tick", gameGridView._restoreSettleAttempts,
                        "-> count:", count, "lastCount:", lastCount);

            if (count === lastCount || gameGridView._restoreSettleAttempts > 15) {
                stop();
                console.log("[PT][GameGridView] restoreSettleTimer -> asentado, aplicando cambio");
                gameGridView._applyPendingRestore();
                return;
            }
            lastCount = count;
        }
    }

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

    readonly property var orientationProfiles: ({
        vertical:   { columns: 6, rows: 3, zoomScale: 1.20 },
        square:     { columns: 4, rows: 3, zoomScale: 1.30 },
        horizontal: { columns: 4, rows: 4, zoomScale: 1.40 },
        panoramic:  { columns: 3, rows: 5, zoomScale: 1.15 }
    })

    property string displayOrientation: "vertical"
    readonly property var activeProfile: orientationProfiles[displayOrientation] || orientationProfiles.vertical

    property int columns: activeProfile.columns
    property int rows: activeProfile.rows

    property string currentGame: ""
    property string spinnerSource: "assets/icons/spinner.svg"
    property real gridTransitionOpacity: 1.0
    property real gridTransitionScale: 1.0

    function hideGridInstantly() {
        revealAnimation.stop();
        gameGridView.gridTransitionOpacity = 0.0;
        gameGridView.gridTransitionScale = 0.92;
    }

    function revealWithOrientation(orientation) {
        gameGridView.displayOrientation = orientation;
        revealAnimation.restart();
    }

    ParallelAnimation {
        id: revealAnimation
        NumberAnimation {
            target: gameGridView
            property: "gridTransitionOpacity"
            to: 1.0
            duration: 220
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: gameGridView
            property: "gridTransitionScale"
            to: 1.0
            duration: 280
            easing.type: Easing.OutBack
            easing.overshoot: 1.4
        }
    }

    function orientationCacheKey() {
        var collIdx = collectionListView ? collectionListView.currentIndex : -1;
        return "col:" + collIdx + ":filt:" + currentFilter;
    }

    function updateOrientation() {
        var key = gameGridView.orientationCacheKey();

        console.log("[PT][GameGridView] updateOrientation -> key:", key,
                    "opacity actual:", gameGridView.gridTransitionOpacity,
                    "en caché:", gameGridView._orientationCache.hasOwnProperty(key));

        if (gameGridView._orientationCache.hasOwnProperty(key)) {
            var resolved = gameGridView._orientationCache[key];
            gameGridView.collectionOrientation = resolved;
            gameGridView.orientationResolved = true;
            aspectProbe.source = "";

            if (resolved === gameGridView.displayOrientation && gameGridView.gridTransitionOpacity >= 1.0) {
                console.log("[PT][GameGridView] updateOrientation -> ya visible, nada que hacer");
                return;
            }

            gameGridView.hideGridInstantly();
            gameGridView.revealWithOrientation(resolved);
            return;
        }

        gameGridView.orientationResolved = false;
        gameGridView.hideGridInstantly();

        var firstGame = (gameGridView.model && gameGridView.model.count > 0) ? gameGridView.model.get(0) : null;
        var src = (firstGame && firstGame.assets && firstGame.assets.boxFront) ? firstGame.assets.boxFront : "";

        if (src === "") {
            gameGridView._orientationCache[key] = "vertical";
            gameGridView.collectionOrientation = "vertical";
            gameGridView.orientationResolved = true;
            aspectProbe.source = "";
            gameGridView.revealWithOrientation("vertical");
            return;
        }

        aspectProbe.pendingKey = key;
        aspectProbe.source = src;
    }

    AspectProbe {
        id: aspectProbe
        property string pendingKey: ""
        onResolved: {
            var currentKey = gameGridView.orientationCacheKey();
            gameGridView._orientationCache[pendingKey] = orientation;

            console.log("[PT][GameGridView] aspectProbe.onResolved -> pendingKey:", pendingKey,
                        "currentKey:", currentKey,
                        "orientation:", orientation,
                        "match:", currentKey === pendingKey);

            if (currentKey === pendingKey) {
                gameGridView.collectionOrientation = orientation;
                gameGridView.orientationResolved = true;
                gameGridView.revealWithOrientation(orientation);
            }
        }
    }

    signal gameChanged(var selectedGame)
    clip: false
    focus: true

    cellWidth: width / columns
    cellHeight: height / rows

    onModelChanged: {
        currentIndex = 0
        gameGridView.lastClickedIndex = -1
        gameGridView.updateOrientation();

        console.log("[PT][GameGridView] onModelChanged -> model.count:", model ? model.count : -1,
                    "currentFilter:", currentFilter);

        if (model && model.count > 0) {
            var lastGameTitle = api.memory.get('lastGameTitle') || "";
            if (lastGameTitle !== "") {
                var found = false;
                for (var i = 0; i < Math.min(model.count, 100); i++) {
                    var game = model.get(i);
                    if (game && game.title === lastGameTitle) {
                        currentIndex = i;
                        positionViewAtIndex(i, GridView.Contain);
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    currentIndex = 0;
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

        opacity: gameGridView.gridTransitionOpacity
        scale: gameGridView.gridTransitionScale
        transformOrigin: Item.Center

        readonly property bool isCurrent: gameGridView.currentIndex === index
        readonly property bool artVisible: boxFront.visible || defaultBoxArt.visible

        Item {
            id: imageContainer

            readonly property int column: index % gameGridView.columns
            readonly property int row: Math.floor(index / gameGridView.columns)

            property real zoomScale: (gameItem.isCurrent && gameItem.artVisible)
            ? gameGridView.activeProfile.zoomScale
            : 1.0

            width: parent ? parent.width * zoomScale : 0
            height: parent ? parent.height * zoomScale : 0

            x: {
                if (!gameItem.isCurrent || !parent) return 0;
                var extraWidth = width - parent.width;
                if (column === 0) return 0;
                if (column === gameGridView.columns - 1) return -extraWidth;
                return -extraWidth / 2;
            }

            y: {
                if (!gameItem.isCurrent || !parent) return 0;
                var extraHeight = height - parent.height;
                var itemY = row * gameGridView.cellHeight;
                var viewportTop = gameGridView.contentY;
                var viewportBottom = viewportTop + gameGridView.height;

                if (itemY - viewportTop < gameGridView.cellHeight) return 0;
                if (viewportBottom - itemY < gameGridView.cellHeight * 2) return -extraHeight;
                return -extraHeight / 2;
            }

            Behavior on x {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutQuad
                }
            }

            Behavior on y {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutQuad
                }
            }

            MouseArea {
                id: gameMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                property bool longPressTriggered: false
                property bool isClick: false
                property real pressX: 0
                property real pressY: 0

                onPressed: {
                    longPressTriggered = false
                    isClick = true
                    pressX = mouse.x
                    pressY = mouse.y
                    longPressTimer.restart()
                }

                onReleased: {
                    longPressTimer.stop()

                    if (longPressTriggered) {
                        return
                    }

                    if (!isClick) {
                        return
                    }

                    handleGameClick()
                }

                onPositionChanged: {
                    if (Math.abs(mouse.x - pressX) > 10 || Math.abs(mouse.y - pressY) > 10) {
                        isClick = false
                        longPressTimer.stop()
                    }
                }

                onCanceled: {
                    longPressTimer.stop()
                    longPressTriggered = false
                    isClick = false
                }

                Timer {
                    id: longPressTimer
                    interval: 500
                    repeat: false
                    onTriggered: {
                        parent.longPressTriggered = true
                        parent.isClick = false

                        if (gameGridView.currentIndex !== index) {
                            gameGridView.currentIndex = index
                            gameGridView.positionViewAtIndex(index, GridView.Contain)
                        }

                        if (gameGridView.gameInfoRect) {
                            gameGridView.gameInfoRect.currentGame = gameGridView.currentGameData
                            gameGridView.gameInfoRect.showGameInfo = true
                            gameGridView.gameInfoRect.forceActiveFocus()

                            if (sounds && sounds.toDetails) {
                                sounds.toDetails.play()
                            }
                        }
                    }
                }

                function handleGameClick() {
                    var currentTime = Date.now()

                    if (gameGridView.lastClickedIndex === index &&
                        (currentTime - gameGridView.lastClickTime) < 300) {
                        doubleClickTimer.stop()
                        gameGridView.lastClickedIndex = -1

                        if (gameGridView.currentIndex === index && gameGridView.currentGameData) {
                            var gameToLaunch = gameGridView.currentGameData
                            if (sounds && sounds.launchgame) {
                                sounds.launchgame.play()
                            }
                            if (collectionListView) {
                                api.memory.set('lastCollectionIndex', collectionListView.currentIndex)
                            }
                            api.memory.set('lastFilter', gameGridView.currentFilter)
                            api.memory.set('lastGameTitle', gameToLaunch.title)
                            gameToLaunch.launch()
                        }
                        } else {
                            gameGridView.lastClickedIndex = index
                            gameGridView.lastClickTime = currentTime
                            doubleClickTimer.restart()

                            if (gameGridView.currentIndex !== index) {
                                gameGridView.currentIndex = index
                                positionViewAtIndex(index, GridView.Contain)
                                if (sounds && sounds.naviSoundGrid) {
                                    sounds.naviSoundGrid.play()
                                }
                            }
                        }
                }
            }

            Image {
                id: boxFront
                anchors.fill: parent
                source: (model && model.assets && model.assets.boxFront) ? model.assets.boxFront : ""
                fillMode: Image.Stretch
                visible: status === Image.Ready
                asynchronous: true
                cache: true
                mipmap: true
            }

            DefaultBoxArt {
                id: defaultBoxArt
                anchors.fill: parent
                visible: boxFront.status === Image.Null || boxFront.status === Image.Error
            }

            Rectangle {
                id: boxFrontGradient
                anchors.fill: parent
                visible: gameItem.isCurrent && gameItem.artVisible
                gradient: Gradient {
                    GradientStop { position: 0.6; color: "transparent" }
                    GradientStop { position: 1.0; color: "black" }
                }
            }

            Item {
                id: infoBar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.02
                height: parent.height * 0.15
                visible: gameItem.isCurrent && gameItem.artVisible
                z: 1

                Row {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: parent.height * 0.15
                        rightMargin: parent.height * 0.15
                    }
                    spacing: 8

                    Image {
                        id: favoriteIcon
                        source: "assets/icons/fav.svg"
                        width: parent.parent.height * 0.7
                        height: width
                        visible: model && model.favorite
                        mipmap: true
                        fillMode: Image.PreserveAspectFit
                        cache: true
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        id: gameTitle
                        width: parent.width - (favoriteIcon.visible ? favoriteIcon.width + parent.spacing : 0)
                        text: model ? model.title : ""
                        color: "white"
                        font.pixelSize: parent.parent.height * 0.35
                        font.bold: true
                        wrapMode: Text.WordWrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                id: rectangleCurrentIndex
                anchors.fill: parent
                color: "transparent"
                border.color: "white"
                border.width: 3
                visible: gameItem.isCurrent
                opacity: gameItem.isCurrent ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                }

                SequentialAnimation on border.color {
                    running: gameItem.isCurrent
                    loops: Animation.Infinite
                    ColorAnimation { to: "transparent"; duration: 500 }
                    PauseAnimation { duration: 100 }
                    ColorAnimation { to: "white"; duration: 500 }
                    PauseAnimation { duration: 400 }
                }
            }

            Rectangle {
                id: dimOverlay
                anchors.fill: parent
                color: "black"
                opacity: gameItem.isCurrent ? 0.0 : 0.45
                visible: gameItem.artVisible || titleBackground.visible

                Behavior on opacity {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }
            }

            Rectangle {
                id: titleBackground
                anchors.fill: parent
                color: "#1a1a1a"
                visible: !gameItem.artVisible

                Text {
                    id: titleText
                    text: model ? model.title : ""
                    anchors.centerIn: parent
                    width: parent.width * 0.9
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    color: "white"
                    font.pixelSize: Math.max(12, parent.height * 0.06)
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
                cache: true

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
            return currentRow === 0 ? model.count - 1 : Math.max(0, currentIdx - columns);
        }
        return currentRow >= totalRows - 1 ? 0 : Math.min(model.count - 1, currentIdx + columns);
    }

    onCurrentIndexChanged: {
        if (model && model.get && currentIndex >= 0 && currentIndex < count) {
            var gameData = model.get(currentIndex);
            if (gameData !== currentGameData) {
                currentGameData = gameData;
                currentGame = gameData ? gameData.title || "" : "";

                if (gameData) {
                    gameChanged(gameData);
                }
            }
        }
    }

    Component.onCompleted: {
        favoriteToggled.connect(handleFavoriteToggle);

        if (collectionListView && collectionListView.model) {
            sourceModel = collectionListView.model.get(collectionListView.currentIndex).games;
        }
    }

    Keys.onPressed: {
        if (!event.isAutoRepeat) {
            if (api.keys.isUp(event)) {
                var newIndex = getCircularVerticalIndex(currentIndex, "up");
                if (newIndex !== currentIndex) {
                    currentIndex = newIndex;
                    positionViewAtIndex(currentIndex, GridView.Contain);
                    if (sounds && sounds.naviSoundGrid) sounds.naviSoundGrid.play();
                }
                event.accepted = true;
            }
            else if (api.keys.isDown(event)) {
                var newIndex = getCircularVerticalIndex(currentIndex, "down");
                if (newIndex !== currentIndex) {
                    currentIndex = newIndex;
                    positionViewAtIndex(currentIndex, GridView.Contain);
                    if (sounds && sounds.naviSoundGrid) sounds.naviSoundGrid.play();
                }
                event.accepted = true;
            }
            else if (api.keys.isLeft(event)) {
                if (currentIndex > 0) {
                    currentIndex--;
                    positionViewAtIndex(currentIndex, GridView.Contain);
                    if (sounds && sounds.naviSoundGrid) sounds.naviSoundGrid.play();
                }
                event.accepted = true;
            }
            else if (api.keys.isRight(event)) {
                if (currentIndex < count - 1) {
                    currentIndex++;
                    positionViewAtIndex(currentIndex, GridView.Contain);
                    if (sounds && sounds.naviSoundGrid) sounds.naviSoundGrid.play();
                }
                event.accepted = true;
            }
            else if (api.keys.isCancel(event)) {
                sounds.infotogrid.play();
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

                if (sounds && sounds.naviSoundGrid) sounds.naviSoundGrid.play();
                applyFilter(nextFilter);
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
