import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

PathView {
    id: collectionPathView

    anchors {
        fill: parent
        leftMargin: 30
        rightMargin: 10
    }

    model: api.collections
    property int indexToPosition: -1
    property string currentShortName: ""
    property string currentCollectionName: ""
    property var sounds
    property var gameGridView
    focus: false

    signal shortNameChanged(string shortName)

    pathItemCount: 7
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5

    property real swipeStartY: 0
    property real swipeStartX: 0
    property real swipeThreshold: 50
    property bool isSwiping: false
    property bool isTouching: false

    path: Path {
        startX: 30; startY: 0

        PathQuad {
            x: 30; y: collectionPathView.height
            controlX: collectionPathView.width * 0.8 + 30;
            controlY: collectionPathView.height * 0.5
        }
    }

    MouseArea {
        id: pathViewMouseArea
        anchors.fill: parent
        z: -1

        onPressed: {
            collectionPathView.swipeStartY = mouse.y
            collectionPathView.swipeStartX = mouse.x
            collectionPathView.isSwiping = false
            collectionPathView.isTouching = true
        }

        onPositionChanged: {
            if (!collectionPathView.isTouching) return

                var deltaY = mouse.y - collectionPathView.swipeStartY
                var deltaX = mouse.x - collectionPathView.swipeStartX

                if (Math.abs(deltaY) > Math.abs(deltaX) && Math.abs(deltaY) > 10) {
                    collectionPathView.isSwiping = true
                }
        }

        onReleased: {
            if (collectionPathView.isSwiping) {
                var deltaY = mouse.y - collectionPathView.swipeStartY

                if (Math.abs(deltaY) > collectionPathView.swipeThreshold) {
                    if (deltaY > 0) {
                        if (collectionPathView.currentIndex > 0) {
                            collectionPathView.currentIndex--
                        }
                    } else {
                        if (collectionPathView.currentIndex < collectionPathView.count - 1) {
                            collectionPathView.currentIndex++
                        }
                    }
                }
            }

            collectionPathView.isSwiping = false
            collectionPathView.isTouching = false
        }

        onCanceled: {
            collectionPathView.isSwiping = false
            collectionPathView.isTouching = false
        }
    }

    delegate: Item {
        width: Math.min(collectionPathView.width * 0.65, 200)
        height: Math.min(collectionPathView.height * 0.12, 100)
        scale: {
            if (PathView.isCurrentItem) return 1.2;
            var distanceFromCenter = Math.abs(index - PathView.view.currentIndex);
            return distanceFromCenter > 2 ? 0.6 : 0.8;
        }
        opacity: PathView.isCurrentItem ? 1.0 : 0.5

        property bool isSelected: PathView.isCurrentItem ? true : false

        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }

        MouseArea {
            id: collectionMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            property bool isLongPress: false
            property bool isClick: false
            property real pressX: 0
            property real pressY: 0

            onPressed: {
                isLongPress = false
                isClick = true
                pressX = mouse.x
                pressY = mouse.y

                collectionLongPressTimer.restart()
            }

            onPositionChanged: {
                if (Math.abs(mouse.x - pressX) > 10 || Math.abs(mouse.y - pressY) > 10) {
                    isClick = false
                    collectionLongPressTimer.stop()

                    if (!collectionPathView.isSwiping) {
                        collectionPathView.swipeStartY = mouse.y
                        collectionPathView.swipeStartX = mouse.x
                        collectionPathView.isSwiping = true
                    }
                }
            }

            onReleased: {
                collectionLongPressTimer.stop()

                if (isLongPress) {
                    return
                }

                if (!isClick) {
                    return
                }

                if (collectionPathView.currentIndex !== index) {
                    collectionPathView.currentIndex = index

                    if (sounds && sounds.naviSoundLits) {
                        sounds.naviSoundLits.play()
                    }
                }
            }

            onCanceled: {
                collectionLongPressTimer.stop()
                isLongPress = false
                isClick = false
            }

            Timer {
                id: collectionLongPressTimer
                interval: 500
                repeat: false
                onTriggered: {
                    parent.isLongPress = true
                    parent.isClick = false
                }
            }
        }

        Image {
            id: collectionImage
            source: "assets/systems/" + model.shortName + ".png"
            anchors.centerIn: parent
            fillMode: Image.PreserveAspectFit
            mipmap: true
            width: Math.min(collectionPathView.width * 0.75, collectionPathView.height * 1.8)
            height: width / (sourceSize.width / sourceSize.height)
            visible: status !== Image.Error

            sourceSize.width: 512
            sourceSize.height: 512

            transform: Translate {
                id: collectionImageReveal
                y: vpx(14)
            }

            layer.enabled: parent.isSelected
            layer.effect: DropShadow {
                horizontalOffset: 5
                verticalOffset: 5
                radius: 60
                samples: 100
                color: "#FF000000"
            }

            states: [
                State {
                    name: "selected"
                    when: parent.isSelected === true
                    PropertyChanges { target: collectionImage; opacity: 1.0; scale: 1.0 }
                    PropertyChanges { target: collectionImageReveal; y: 0 }
                },
                State {
                    name: "idle"
                    when: parent.isSelected !== true
                    PropertyChanges { target: collectionImage; opacity: 0.55; scale: 0.88 }
                    PropertyChanges { target: collectionImageReveal; y: vpx(14) }
                }
            ]

            transitions: [
                Transition {
                    to: "selected"
                    ParallelAnimation {
                        NumberAnimation { target: collectionImage; property: "opacity"; duration: 360; easing.type: Easing.OutCubic }
                        NumberAnimation { target: collectionImage; property: "scale"; duration: 520; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                        NumberAnimation { target: collectionImageReveal; property: "y"; duration: 420; easing.type: Easing.OutCubic }
                    }
                },
                Transition {
                    to: "idle"
                    ParallelAnimation {
                        NumberAnimation { target: collectionImage; property: "opacity"; duration: 260; easing.type: Easing.OutCubic }
                        NumberAnimation { target: collectionImage; property: "scale"; duration: 260; easing.type: Easing.OutCubic }
                        NumberAnimation { target: collectionImageReveal; property: "y"; duration: 260; easing.type: Easing.OutCubic }
                    }
                }
            ]
        }

        Image {
            id: defaultImage
            source: "assets/systems/default.png"
            anchors.centerIn: parent
            fillMode: Image.PreserveAspectFit
            width: Math.min(parent.width * 0.9, parent.height * 1.8)
            height: width / (sourceSize.width / sourceSize.height)
            visible: collectionImage.status === Image.Error
            mipmap: true
            sourceSize.width: 512
            sourceSize.height: 512

            transform: Translate {
                id: defaultImageReveal
                y: vpx(14)
            }

            layer.enabled: parent.isSelected
            layer.effect: DropShadow {
                horizontalOffset: 5
                verticalOffset: 5
                radius: 60
                samples: 100
                color: "#FF000000"
            }

            states: [
                State {
                    name: "selected"
                    when: parent.isSelected === true
                    PropertyChanges { target: defaultImage; opacity: 1.0; scale: 1.0 }
                    PropertyChanges { target: defaultImageReveal; y: 0 }
                },
                State {
                    name: "idle"
                    when: parent.isSelected !== true
                    PropertyChanges { target: defaultImage; opacity: 0.55; scale: 0.88 }
                    PropertyChanges { target: defaultImageReveal; y: vpx(14) }
                }
            ]

            transitions: [
                Transition {
                    to: "selected"
                    ParallelAnimation {
                        NumberAnimation { target: defaultImage; property: "opacity"; duration: 360; easing.type: Easing.OutCubic }
                        NumberAnimation { target: defaultImage; property: "scale"; duration: 520; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                        NumberAnimation { target: defaultImageReveal; property: "y"; duration: 420; easing.type: Easing.OutCubic }
                    }
                },
                Transition {
                    to: "idle"
                    ParallelAnimation {
                        NumberAnimation { target: defaultImage; property: "opacity"; duration: 260; easing.type: Easing.OutCubic }
                        NumberAnimation { target: defaultImage; property: "scale"; duration: 260; easing.type: Easing.OutCubic }
                        NumberAnimation { target: defaultImageReveal; property: "y"; duration: 260; easing.type: Easing.OutCubic }
                    }
                }
            ]
        }
    }

    function updateCurrentCollection() {
        if (model && model.count > 0 && currentIndex >= 0) {
            const selectedCollection = api.collections.get(currentIndex)
            if (selectedCollection) {
                currentShortName = selectedCollection.shortName
                currentCollectionName = selectedCollection.name
                indexToPosition = currentIndex

                console.log("[PT][CollectionListView] updateCurrentCollection -> index:", currentIndex,
                            "shortName:", currentShortName,
                            "games.count:", selectedCollection.games ? selectedCollection.games.count : -1);

                shortNameChanged(currentShortName)

                if (gameGridView) {
                    gameGridView.sourceModel = selectedCollection.games
                    gameGridView.model = selectedCollection.games
                }
            }
        }
    }

    Component.onCompleted: {
        if (model && model.count > 0) {
            currentIndex = 0
            updateCurrentCollection()
        }
    }

    onModelChanged: {
        if (model && model.count > 0) {
            Qt.callLater(function() {
                currentIndex = 0
                updateCurrentCollection()
            })
        }
    }

    Behavior on indexToPosition {
        NumberAnimation { duration: 200 }
    }

    onCurrentIndexChanged: {
        const selectedCollection = api.collections.get(currentIndex);
        if (selectedCollection && gameGridView) {
            currentShortName = selectedCollection.shortName;
            currentCollectionName = selectedCollection.name;
            indexToPosition = currentIndex;

            console.log("[PT][CollectionListView] onCurrentIndexChanged -> index:", currentIndex,
                        "shortName:", currentShortName,
                        "-> forzando gameGridView.currentFilter = 0");

            gameGridView.currentFilter = 0;
            gameGridView.sourceModel = selectedCollection.games;
            gameGridView.model = selectedCollection.games;

            if (sounds && sounds.naviSoundLits) {
                sounds.naviSoundLits.play();
            }
            gameGridView.currentIndex = 0;
            gameGridView.positionViewAtIndex(0, GridView.Contain);

            shortNameChanged(currentShortName);
        }
    }
}
