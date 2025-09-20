import QtQuick 2.15
import "utils.js" as Utils

Rectangle {
    id: gameInfoRect
    anchors.centerIn: parent
    width: parent.width * 0.92
    height: parent.height * 0.92
    color: "#F0F0F0"
    radius: 10
    visible: false
    z: 2

    property var currentGame
    property var sounds
    property bool showGameInfo: false
    property int currentPage: 1
    property int totalPages: 1
    property string paginatedDescription: ""
    property real linesPerPage: 0

    signal favoriteStatusChanged()

    property var pageBreaks: []

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * 0.59
        color: "#e8e8e8"
        radius: parent.radius

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.radius
            color: parent.color
        }
    }

    Row {
        anchors.fill: parent
        anchors.margins: 10
        spacing: Math.max(10, parent.width * 0.02)

        Item {
            width: parent.width * 0.4
            height: parent.height

            Image {
                id: gameScreenshot
                source: currentGame && currentGame.assets.screenshots.length > 0 ? currentGame.assets.screenshots[0] : ""
                fillMode: Image.PreserveAspectFit
                width: parent.width
                height: parent.height
                mipmap: true
                smooth: true
                visible: status === Image.Ready
            }

            Text {
                id: noScreenshot
                text: "No image available"
                anchors.centerIn: parent
                width: parent.width * 0.9
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                color: "#303030"
                font.bold: true
                font.pixelSize: parent.height * 0.1
                elide: Text.ElideRight
                maximumLineCount: 3
                visible: !gameScreenshot.visible
            }
        }

        Item {
            width: parent.width * 0.58
            height: parent.height

            Column {
                width: parent.width
                spacing: Math.max(5, gameInfoRect.height * 0.01)

                Text {
                    id: gameTitle
                    text: currentGame ? currentGame.title : ""
                    color: "black"
                    font.pixelSize: Math.max(16, gameInfoRect.width * 0.03)
                    font.bold: true
                    width: parent.width
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    id: textShort
                    text: currentGame ? Utils.getRandomShortText() : "A different looking world!"
                    color: "black"
                    font.pixelSize: Math.max(14, gameInfoRect.width * 0.025)
                    width: parent.width
                    wrapMode: Text.WordWrap
                }


                Row {
                    spacing: 10
                    width: parent.width
                    Text {
                        text: currentGame ? currentGame.publisher : ""
                        font.pixelSize: Math.max(12, gameInfoRect.width * 0.015)
                        color: "#424242"
                    }
                    Text {
                        text: currentGame ? "Released in " + currentGame.releaseYear : ""
                        font.pixelSize: Math.max(12, gameInfoRect.width * 0.015)
                        color: "#424242"
                    }
                }

                Row {
                    spacing: 10
                    width: parent.width
                    Text {
                        text: currentGame ? "Number of players: " + currentGame.players : ""
                        font.pixelSize: Math.max(12, gameInfoRect.width * 0.015)
                        color: "#424242"
                    }
                    Text {
                        text: currentGame ? "Playing time: " + Utils.formatPlayTime(currentGame.playTime) : ""
                        font.pixelSize: Math.max(12, gameInfoRect.width * 0.015)
                        color: "#424242"
                    }

                    Text {
                        text: currentGame ? "Favorite: " + (currentGame.favorite ? "Yes" : "No") : ""
                        font.pixelSize: Math.max(12, gameInfoRect.width * 0.015)
                        color: "#424242"
                    }
                }

                Text {
                    id: textLong
                    text: currentGame ? Utils.getRandomLongText() : "Discover the surprises that the special world has in store for you!"
                    font.pixelSize: Math.max(12, gameInfoRect.width * 0.015)
                    color: "black"
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Column {
                    id: descripPage
                    width: parent.width
                    spacing: gameInfoRect.height * 0.05

                    Item {
                        id: descripItem
                        width: parent.width
                        height: gameInfoRect.height * 0.5 - (gameInfoRect.height * 0.01)
                        clip: true

                        Item {
                            id: descContainer
                            anchors.fill: parent

                            Text {
                                id: descText
                                width: parent.width
                                text: currentGame ? paginatedDescription : ""
                                font.pixelSize: Math.max(20, gameInfoRect.width * 0.024)
                                color: "#424242"
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    Text {
                        id: measureText
                        width: descText.width
                        text: currentGame ? currentGame.description : ""
                        font.pixelSize: descText.font.pixelSize
                        wrapMode: Text.WordWrap
                        visible: false
                    }

                    Item {
                        width: parent.width
                        height: 30
                        visible: totalPages > 1

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.rightMargin: parent.width * 0.5
                            width: 50
                            height: 30
                            color: "#80000000"
                            radius: 5

                            Text {
                                anchors.centerIn: parent
                                text: currentPage + "/" + totalPages
                                color: "white"
                                font.pixelSize: 14
                            }
                        }
                    }
                }
            }
        }
    }

    function updatePaginatedDescription() {
        if (!currentGame || !currentGame.description) {
            paginatedDescription = ""
            totalPages = 1
            pageBreaks = []
            return
        }

        var containerHeight = descripItem.height
        var lineHeight = measureText.font.pixelSize * 1.2
        linesPerPage = Math.floor(containerHeight / lineHeight)
        measureText.text = currentGame.description
        var totalLines = Math.ceil(measureText.contentHeight / lineHeight)
        totalPages = Math.ceil(totalLines / linesPerPage)

        if (totalPages <= 1) {
            paginatedDescription = currentGame.description
            return
        }

        calculatePageBreaks()

        if (currentPage <= pageBreaks.length) {
            var startIndex = currentPage === 1 ? 0 : pageBreaks[currentPage - 2]
            var endIndex = pageBreaks[currentPage - 1]
            paginatedDescription = currentGame.description.substring(startIndex, endIndex)
        }
    }

    function calculatePageBreaks() {
        pageBreaks = []
        var fullText = currentGame.description
        var words = fullText.split(/\s+/)
        var currentText = ""
        var wordIndex = 0

        for (var page = 1; page <= totalPages; page++) {
            var pageText = ""
            var testText = currentText

            while (wordIndex < words.length) {
                var nextWord = words[wordIndex]
                var testWithNextWord = testText + (testText ? " " : "") + nextWord
                measureText.text = testWithNextWord

                if (measureText.contentHeight > descripItem.height && testText !== "") {
                    break
                }

                testText = testWithNextWord
                wordIndex++
            }

            pageBreaks.push(fullText.indexOf(testText) + testText.length)
            currentText = ""

            if (wordIndex >= words.length) {
                pageBreaks[pageBreaks.length - 1] = fullText.length
                break
            }
        }
    }

    function navigatePages() {
        if (totalPages <= 1) return

            if (currentPage < totalPages) {
                currentPage++
            } else {
                currentPage = 1
            }
            updatePaginatedDescription()
    }

    onCurrentGameChanged: {
        currentPage = 1
        updatePaginatedDescription()
        textShort.text = currentGame ? Utils.getRandomShortText() : ""
        textLong.text = currentGame ? Utils.getRandomLongText() : ""
    }

    Keys.onPressed: {
        if (!event.isAutoRepeat) {
            if (api.keys.isCancel(event)) {
                event.accepted = true
                showGameInfo = false
                gameGridView.forceActiveFocus()
                sounds.infotogrid.play()
            }
            else if (api.keys.isAccept(event)) {
                event.accepted = true
                if (totalPages <= 1) {
                    sounds.errorSound.play()
                } else {
                    sounds.detailsNextSound.play()
                    navigatePages()
                }
            }
            else if (api.keys.isDetails(event)) {
                event.accepted = true;
                if (currentGame) {
                    var newFavoriteStatus = !currentGame.favorite;
                    currentGame.favorite = newFavoriteStatus;
                    sounds.naviSoundGrid.play();
                    if (gameGridView && gameGridView.favoriteToggled) {
                        gameGridView.favoriteToggled(currentGame, newFavoriteStatus);
                    }

                    favoriteStatusChanged();
                }
            }
            else if (api.keys.isNextPage(event) && currentPage < totalPages) {
                event.accepted = true
                currentPage++
                updatePaginatedDescription()
            }
            else if (api.keys.isPrevPage(event) && currentPage > 1) {
                event.accepted = true
                currentPage--
                updatePaginatedDescription()
            }
        }
    }
}
