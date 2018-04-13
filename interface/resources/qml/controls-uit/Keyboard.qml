import QtQuick 2.0

Rectangle {
    id: keyboard
    objectName: "keyboard"
    color: 'green'
    opacity: 0.5

    onWidthChanged: {
        console.debug('keyboard: ', keyboard, 'onWidthChanged: ', width);        
    }
    onHeightChanged: {
        console.debug('keyboard: ', keyboard, 'onHeightChanged: ', height);        
    }

    property bool raised;
    onRaisedChanged: {
        console.debug('keyboard: ', keyboard, 'onRaisedChanged: ', raised);
    }

    property bool password;
    onPasswordChanged: {
        console.debug('keyboard: ', keyboard, 'onPasswordChanged: ', password);
    }

    property bool numeric;
    onNumericChanged: {
        console.debug('keyboard: ', keyboard, 'onNumericChanged: ', numeric);
    }

    property int raisedHeight: 0;
    onRaisedHeightChanged: {
        console.debug('keyboard: ', keyboard, 'onRaisedHeightChanged: ', raisedHeight);    
    }

    function resetShiftMode(mode) {
        console.debug('keyboard: ', keyboard, 'resetShiftMode stub called: ', mode);
    }

    onChildrenChanged: {
        console.debug(parent.objectName);
    }
}
