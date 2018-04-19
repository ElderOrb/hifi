import "../../styles-uit"
import QtQuick 2.9
import QtGraphicalEffects 1.0

Item {
    property alias source: image.source
    property alias dropShadowRadius: shadow.radius
    property alias dropShadowHorizontalOffset: shadow.horizontalOffset
    property alias dropShadowVerticalOffset: shadow.verticalOffset

    Image {
        id: image
        width: parent.width
        height: parent.height
    }

    DropShadow {
        id: shadow
        anchors.fill: image
        radius: 6
        horizontalOffset: 0
        verticalOffset: 3
        color: Qt.rgba(0, 0, 0, 0.25)
        source: image
    }
}
