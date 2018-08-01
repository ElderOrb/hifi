import QtQuick 2.0
import QtQuick 2.0
import QtGraphicalEffects 1.0

Item {

    property alias border: borderRectangle.border
    property alias source: image.source
    property alias fillMode: image.fillMode
    property alias radius: mask.radius
    property alias status: image.status
    property alias progress: image.progress

    Image {
        id: image
        anchors.fill: parent
        visible: false
    }

    Rectangle {
        id: mask
        anchors.fill: image
        visible: false
    }

    OpacityMask {
        anchors.fill: image
        source: image
        maskSource: mask
    }

    Rectangle {
        id: borderRectangle
        anchors.fill: parent

        radius: mask.radius
        color: "transparent"
    }
}
