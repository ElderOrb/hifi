import QtQuick 2.7

VirtualKeyboard {
    id: vk
    property var currentFocusItem: null;

    function onFocusObjectChanged(focusObject) {
        console.debug('onFocusObjectChanged: focusObject = ', focusObject)

        var item = focusObject;

        // Raise and lower keyboard for QML text fields.
        // HTML text fields are handled in emitWebEvent() methods - testing READ_ONLY_PROPERTY prevents action for HTML files.
        var READ_ONLY_PROPERTY = "readOnly";
        var raiseKeyboard = item.activeFocus && item[READ_ONLY_PROPERTY] === false;
        console.debug('raiseKeyboard: ', raiseKeyboard);

        if(currentFocusItem && !raiseKeyboard) {
            setKeyboardRaised(currentFocusItem, false);
        }
        setKeyboardRaised(item, raiseKeyboard); // Always set focus so that alphabetic / numeric setting is updated.
        currentFocusItem = item;
    }

    function distanceToParent(from, to) {
        var i = 0;
        while (true) {
            if (from === null) {
                return -1;
            } else if (from === to) {
                return i;
            }

            ++i;
            from = from.parent;
        }
        return i;
    }

    function setKeyboardRaised(item, raised) {
        var keyboard = findNearestKeyboard(item);
        console.debug('activeFocusItemChanged: keyboard = ', keyboard,
                      'keyboard.keyboardContainer: ', keyboard.keyboardContainer,
                      'keyboard.keyboard: ', keyboard.keyboard,
                      'raised: ', raised
                      );

        if(keyboard) {
            console.debug('keyboard.keyboardContainer.keyboardRaised = ', raised)
            keyboard.keyboardContainer.keyboardRaised = raised;
            vk.mirroredText = '';

            var numeric = false;
            while (item !== keyboard.keyboardContainer) {
                numeric = numeric || item.toString().indexOf("SpinBox") === 0;
                item = item.parent;
            }

            if (keyboard.keyboardContainer.hasOwnProperty("punctuationMode")) {
                keyboard.keyboardContainer["punctuationMode"] = numeric;
            }

            console.debug('vk.parent = ', keyboard.keyboard)
            vk.parent = keyboard.keyboard;
        } else {
            vk.parent = null;
        }
    }

    function findChildren(item, exclude, objectName, onChildFoundCallback) {
        for(var i = 0; i < item.children.length; ++i) {
            var child = item.children[i];
            if(child !== exclude && child.objectName === objectName) {
                onChildFoundCallback(child);
            }
            findChildren(child, exclude, objectName, onChildFoundCallback);
        }
    }

    function findKeyboards(item, exclude) {
        var keyboards = [];
        findChildren(item, exclude, "keyboard", function(keyboard) {
            keyboards.push(keyboard);
        })
        return keyboards;
    }

    function findNearestKeyboard(focusedItem) {

        console.debug('findNearestKeyboard: focusedItem = ', focusedItem)
        var item = focusedItem;
        var keyboardContainer = null;
        var visited = null;

        while(item) {
            console.debug("item: ", item);

            if(item.hasOwnProperty("keyboardRaised")) {
                keyboardContainer = item;

                if(item.hasOwnProperty("keyboardContainer")) {
                    return {
                        keyboard: item.keyboardContainer,
                        keyboardContainer: keyboardContainer
                    }
                }

                var keyboards = findKeyboards(item, visited);
                console.debug("found keyboards: ", keyboards.join('|'))

                if(keyboards.length !== 0) {
                    var nearestKeyboard = null;
                    var minDistance = Number.MAX_VALUE;

                    for(var i = 0; i < keyboards.length; ++i) {
                        var keyboard = keyboards[i];
                        var distance = distanceToParent(keyboard, item);
                        console.debug('keyboard distance: ', keyboard, distance);

                        if(minDistance > distance) {
                            minDistance = distance;
                            nearestKeyboard = keyboards[i];
                        }
                    }

                    console.debug('nearestKeyboard keyboard: ', nearestKeyboard);
                    return {
                        keyboard: nearestKeyboard,
                        keyboardContainer: keyboardContainer
                    }
                }
            }

            item = item.parent;
        }

        return null;
    }

    onCollapsePressed: {
        setKeyboardRaised(currentFocusItem, false);
    }
}
