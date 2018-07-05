import QtQuick 2.0

Rectangle {
    id: keyboard
    objectName: "keyboard"

    property bool raised: false;
    property bool password: false;
    property bool numeric: false;
    property int raisedHeight: 0;
    property string mirroredText: '';

    signal resetShiftMode(var mode);
}
