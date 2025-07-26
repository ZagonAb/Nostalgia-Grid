import QtQuick 2.15
import QtMultimedia 5.15

Item {
    property alias toCollec: toCollec
    property alias toGames: toGames
    property alias naviSoundLits: naviSoundLits
    property alias naviSoundGrid: naviSoundGrid
    property alias toDetails: toDetails
    property alias infotogrid: infotogrid
    property alias launchgame: launchgame

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
}
