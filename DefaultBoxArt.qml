import QtQuick 2.15

Item {
    id: root
    anchors.fill: parent

    property string iconSource: "assets/systems/icon_0.png"
    property real iconScale: 0.5
    property real iconOpacity: 0.85

    Rectangle {
        anchors.fill: parent
        color: "#000000"
    }

    Image {
        id: placeholderIcon
        source: root.iconSource
        anchors.centerIn: parent
        fillMode: Image.PreserveAspectFit
        mipmap: true
        smooth: true
        asynchronous: true
        cache: true
        sourceSize.width: 512
        sourceSize.height: 512
        width: Math.min(root.width, root.height) * root.iconScale
        height: width
        opacity: root.iconOpacity
        visible: status === Image.Ready
    }
}
