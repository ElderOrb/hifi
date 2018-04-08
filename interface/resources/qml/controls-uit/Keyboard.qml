import QtQuick 2.0

Rectangle {
    objectName: "keyboard"
    color: 'gray'

    property bool raised;
    onRaisedChanged: {
        console.debug('onRaisedChanged: ', raised);
    }

    property bool password;
    onPasswordChanged: {
        console.debug('onPasswordChanged: ', password);
    }

        height: raisedHeight
    property bool numeric;
            height: raisedHeight
    onNumericChanged: {
            height: raisedHeight
        console.debug('onNumericChanged: ', numeric);
    }

    onChildrenChanged: {
        console.debug(parent.objectName)
    }
}
