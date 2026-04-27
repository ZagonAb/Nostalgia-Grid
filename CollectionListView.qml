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
            console.log("=== PATHVIEW PRESSED ===")
            collectionPathView.swipeStartY = mouse.y
            collectionPathView.swipeStartX = mouse.x
            collectionPathView.isSwiping = false
            collectionPathView.isTouching = true
            console.log("Swipe start at:", mouse.x, mouse.y)
        }

        onPositionChanged: {
            if (!collectionPathView.isTouching) return

                var deltaY = mouse.y - collectionPathView.swipeStartY
                var deltaX = mouse.x - collectionPathView.swipeStartX

                if (Math.abs(deltaY) > Math.abs(deltaX) && Math.abs(deltaY) > 10) {
                    collectionPathView.isSwiping = true
                    console.log("Swiping - deltaY:", deltaY)
                }
        }

        onReleased: {
            console.log("=== PATHVIEW RELEASED ===")
            console.log("isSwiping:", collectionPathView.isSwiping)

            if (collectionPathView.isSwiping) {
                var deltaY = mouse.y - collectionPathView.swipeStartY
                console.log("Swipe deltaY:", deltaY, "threshold:", collectionPathView.swipeThreshold)

                if (Math.abs(deltaY) > collectionPathView.swipeThreshold) {
                    if (deltaY > 0) {
                        console.log("SWIPE DOWN - Previous collection")
                        if (collectionPathView.currentIndex > 0) {
                            collectionPathView.currentIndex--
                            console.log("New index:", collectionPathView.currentIndex)
                        }
                    } else {
                        console.log("SWIPE UP - Next collection")
                        if (collectionPathView.currentIndex < collectionPathView.count - 1) {
                            collectionPathView.currentIndex++
                            console.log("New index:", collectionPathView.currentIndex)
                        }
                    }
                } else {
                    console.log("Swipe too short, ignoring")
                }
            }

            collectionPathView.isSwiping = false
            collectionPathView.isTouching = false
        }

        onCanceled: {
            console.log("PathView mouse area canceled")
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

        property bool isSelected: PathView.isCurrentItem

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
                console.log("=== COLLECTION ITEM PRESSED ===")
                console.log("Index:", index)
                console.log("Collection:", model ? model.shortName : "unknown")
                console.log("Current index:", collectionPathView.currentIndex)

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
                console.log("=== COLLECTION ITEM RELEASED ===")
                console.log("isClick:", isClick)
                console.log("isLongPress:", isLongPress)

                collectionLongPressTimer.stop()

                if (isLongPress) {
                    console.log("Long press was handled, ignoring release")
                    return
                }

                if (!isClick) {
                    console.log("Not a click (probably swipe), ignoring")
                    return
                }

                if (collectionPathView.currentIndex !== index) {
                    console.log("Selecting collection:", model.shortName)
                    collectionPathView.currentIndex = index

                    if (sounds && sounds.naviSoundLits) {
                        sounds.naviSoundLits.play()
                    }
                } else {
                    console.log("Collection already selected")
                }
            }

            onCanceled: {
                console.log("Collection mouse area canceled")
                collectionLongPressTimer.stop()
                isLongPress = false
                isClick = false
            }

            Timer {
                id: collectionLongPressTimer
                interval: 500
                repeat: false
                onTriggered: {
                    console.log("Collection long press detected")
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
            opacity: 1.0
            visible: status !== Image.Error

            sourceSize.width: 512
            sourceSize.height: 512

            layer.enabled: parent.isSelected
            layer.effect: DropShadow {
                horizontalOffset: 5
                verticalOffset: 5
                radius: 60
                samples: 100
                color: "#FF000000"
            }

            SequentialAnimation on scale {
                running: PathView.isCurrentItem
                loops: Animation.Infinite
                PropertyAnimation { to: 0.95; duration: 700; easing.type: Easing.InOutQuad }
                PropertyAnimation { to: 1.05; duration: 700; easing.type: Easing.InOutQuad }
            }
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
            opacity: 1.0

            layer.enabled: parent.isSelected
            layer.effect: DropShadow {
                horizontalOffset: 5
                verticalOffset: 5
                radius: 60
                samples: 100
                color: "#FF000000"
            }

            SequentialAnimation on scale {
                running: PathView.isCurrentItem
                loops: Animation.Infinite
                PropertyAnimation { to: 0.95; duration: 500; easing.type: Easing.InOutQuad }
                PropertyAnimation { to: 1.05; duration: 500; easing.type: Easing.InOutQuad }
            }
        }
    }

    function updateCurrentCollection() {
        if (model && model.count > 0 && currentIndex >= 0) {
            const selectedCollection = api.collections.get(currentIndex)
            if (selectedCollection) {
                currentShortName = selectedCollection.shortName
                currentCollectionName = selectedCollection.name
                indexToPosition = currentIndex

                shortNameChanged(currentShortName)

                if (gameGridView) {
                    gameGridView.sourceModel = selectedCollection.games
                    gameGridView.model = selectedCollection.games
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("=== COLLECTIONLISTVIEW INIT ===")
        console.log("Model count:", model ? model.count : 0)

        if (model && model.count > 0) {
            currentIndex = 0
            updateCurrentCollection()
            console.log("Initial collection set to index 0")
        }
    }

    onModelChanged: {
        console.log("Collection model changed, count:", model ? model.count : 0)

        if (model && model.count > 0) {
            Qt.callLater(function() {
                currentIndex = 0
                updateCurrentCollection()
                console.log("Collection reset to index 0 after model change")
            })
        }
    }

    Behavior on indexToPosition {
        NumberAnimation { duration: 200 }
    }

    onCurrentIndexChanged: {
        console.log("=== COLLECTION INDEX CHANGED ===")
        console.log("New index:", currentIndex)

        const selectedCollection = api.collections.get(currentIndex);
        if (selectedCollection && gameGridView) {
            currentShortName = selectedCollection.shortName;
            currentCollectionName = selectedCollection.name;
            indexToPosition = currentIndex;

            console.log("Selected collection:", currentShortName, "-", currentCollectionName)

            gameGridView.currentFilter = 0;
            gameGridView.sourceModel = selectedCollection.games;
            gameGridView.model = selectedCollection.games;

            if (sounds && sounds.naviSoundLits) {
                sounds.naviSoundLits.play();
            }
            gameGridView.currentIndex = 0;
            gameGridView.positionViewAtIndex(0, GridView.Contain);
            api.memory.set('lastCollectionIndex', currentIndex);

            shortNameChanged(currentShortName);
        }
    }
}
