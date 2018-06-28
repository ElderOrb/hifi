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

    property bool raised: false;
    onRaisedChanged: {
        console.debug('keyboard: ', keyboard, 'onRaisedChanged: ', raised);
    }

    property bool password: false;
    onPasswordChanged: {
        console.debug('keyboard: ', keyboard, 'onPasswordChanged: ', password);
    }

    property bool numeric: false;
    onNumericChanged: {
        console.debug('keyboard: ', keyboard, 'onNumericChanged: ', numeric);
    }

    property int raisedHeight: 0;
    onRaisedHeightChanged: {
        console.debug('keyboard: ', keyboard, 'onRaisedHeightChanged: ', raisedHeight);    
    }

    property string mirroredText: '';
    onMirroredTextChanged: {
        console.debug('keyboard:', keyboard, 'onMirroredTextChanged: ', mirroredText);
    }

    function resetShiftMode(mode) {
        console.debug('keyboard: ', keyboard, 'resetShiftMode stub called: ', mode);
    }

    onVisibleChanged: {
        console.debug('keyboard: ', keyboard, 'onVisibleChanged: ', visible);
    }

    onChildrenChanged: {
        console.debug(parent.objectName);
    }
}
