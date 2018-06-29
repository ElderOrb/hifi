//
//  HifiVirtualKeyboard.qml
//
//  Created by Alexander Ivash on 28 Jun 2018
//  Copyright 2018 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

import QtQuick 2.7

VirtualKeyboard {
    id: vk
    property var currentFocusItem: null;

    // keyboard handling for HTML/WebEngine controls
    function onWebEventReceived(webEvent) {
        console.debug('HifiVirtualKeyboard.onWebEventReceived: ', webEvent)
        var RAISE_KEYBOARD = "_RAISE_KEYBOARD";
        var RAISE_KEYBOARD_NUMERIC = "_RAISE_KEYBOARD_NUMERIC";
        var LOWER_KEYBOARD = "_LOWER_KEYBOARD";
        var RAISE_KEYBOARD_NUMERIC_PASSWORD = "_RAISE_KEYBOARD_NUMERIC_PASSWORD";
        var RAISE_KEYBOARD_PASSWORD = "_RAISE_KEYBOARD_PASSWORD";

        var messageString = webEvent;
        if(messageString.indexOf(RAISE_KEYBOARD) === 0) {
            var numeric = (messageString === RAISE_KEYBOARD_NUMERIC || messageString === RAISE_KEYBOARD_NUMERIC_PASSWORD);
            var passwordField = (messageString === RAISE_KEYBOARD_PASSWORD || messageString === RAISE_KEYBOARD_NUMERIC_PASSWORD);
            setKeyboardRaised(currentFocusItem, true, numeric, passwordField);
        } else {
            setKeyboardRaised(currentFocusItem, false, false, false);
        }
    }

    // keyboard handling for QML controls
    function onFocusObjectChanged(focusObject) {
        console.debug('HifiVirtualKeyboard.onFocusObjectChanged: focusObject = ', focusObject)

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

    function setKeyboardRaised(item, raised, numeric, password) {
        console.debug('setKeyboardRaised: item = ', item, ', raised = ', raised, ', numeric = ', numeric, ', password = ', password);

        var keyboardKinfo = findNearestKeyboard(item);
        console.debug('activeFocusItemChanged: keyboardKinfo = ', keyboardKinfo,
                      'keyboardKinfo.keyboardContainer: ', keyboardKinfo.keyboardContainer,
                      'keyboardKinfo.keyboard: ', keyboardKinfo.keyboard,
                      'raised: ', raised,
                      'numeric: ', numeric,
                      'password: ', password
                      );

        if(keyboardKinfo) {
            console.debug('keyboardKinfo.keyboardContainer.keyboardRaised = ', raised)
            keyboardKinfo.keyboardContainer.keyboardRaised = raised;

            if(numeric === undefined) {
                numeric = false;
                while (item !== keyboardKinfo.keyboardContainer) {
                    if(item.toString().indexOf("SpinBox") === 0) {
                        numeric = true;
                        break;
                    }

                    if(item.hasOwnProperty('inputMethodHints') && item.inputMethodHints === Qt.ImhDigitsOnly) {
                        numeric = true;
                        break;
                    }

                    item = item.parent;
                }
            }

            if(password !== undefined) {
                if (keyboardKinfo.keyboardContainer.hasOwnProperty("passwordField")) {
                    keyboardKinfo.keyboardContainer["passwordField"] = password;
                }
            }

            if (keyboardKinfo.keyboardContainer.hasOwnProperty("punctuationMode")) {
                keyboardKinfo.keyboardContainer["punctuationMode"] = numeric;
            }

            console.debug('vk.parent = ', keyboardKinfo.keyboard)
            vk.parent = keyboardKinfo.keyboard;
            mirroredText = '';
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
