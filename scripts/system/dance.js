"use strict";

//
//  dance.js
//  scripts/system/
//
//  Created by Alexander Ivash on 02/27/2018
//  Copyright 2018 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//
/* global Script, Users, Overlays, AvatarList, Controller, Camera, getControllerWorldLocation, UserActivityLogger */

(function () { // BEGIN LOCAL_SCOPE
    console.debug('*** dance.js ***');

    var DANCE_QML_SOURCE = Script.resolvePath("Dance.qml");
    var dances = [];

    // Setup the dance button
    var buttonName = "DANCE";

    console.debug('dance.js: 1');

    var tablet = Tablet.getTablet("com.highfidelity.interface.tablet.system");

    console.debug('dance.js: 2');

    var button = tablet.addButton({
                                  icon: "icons/tablet-icons/bubble-i.svg",
                                  activeIcon: "icons/tablet-icons/bubble-a.svg",
                                  text: buttonName,
                                  sortOrder: 4
                              });

    console.debug('dance.js: connect clicked & screenChanged...');

    button.clicked.connect(onTabletButtonClicked);
    tablet.screenChanged.connect(onTabletScreenChanged);

    var onDanceScreen = false;

    function onTabletScreenChanged(type, url) {
        console.debug('dance.js: onTabletScreenChanged: ', type, url)

        onDanceScreen = (type === "QML" && url === DANCE_QML_SOURCE);
        wireEventBridge(onDanceScreen);
        // for toolbar mode: change button to active when window is first openend, false otherwise.
        button.editProperties({isActive: onDanceScreen});
    }

    function onTabletButtonClicked() {
        if (onDanceScreen) {
            // for toolbar-mode: go back to home screen, this will close the window.
            tablet.gotoHomeScreen();
        } else {
            tablet.loadQMLSource(DANCE_QML_SOURCE);
        }
    }

    var FINISHED = 3; // The resource has completly finished loading and is ready.
    var FAILED = 4; // Downloading the resource has failed.

    function fromQml(message) { // messages are {method, params}, like json-rpc. See also sendToQml.
        console.debug(JSON.stringify(message, null, '\t'));

        switch (message.method) {
        case 'start':
            MyAvatar.overrideAnimation(message.animationData.animURL, message.animationData.playbackRate, true, 0, message.animationData.endFrame);
            break;
        case 'stop':

            MyAvatar.restoreAnimation();
            break;

        case 'prefetch':
            var resource = AnimationCache.prefetch(message.animationURL);
            var index = message.index;

            console.debug('resource state: ', resource.state, 'for ', message.animationURL)
            if(resource.state === FINISHED || resource.state === FAILED) {
                sendToQml({'method' : 'prefetchNotification', 'index' : index, 'state' : resource.state})
            } else {
                resource.stateChanged.connect(function(state) {
                    sendToQml({'method' : 'prefetchNotification', 'index' : index, 'state' : state})
                });
            }
            dances.push(resource);

            break;

        default:
            print('Unrecognized message from Dance.qml:', JSON.stringify(message));
        }
    }

    function sendToQml(message) {
        tablet.sendToQml(message);
    }

    var hasEventBridge = false;
    function wireEventBridge(on) {
        if (on) {
            if (!hasEventBridge) {
                console.debug('connecting to fromQml');
                tablet.fromQml.connect(fromQml);
                hasEventBridge = true;
            }
        } else {
            if (hasEventBridge) {
                console.debug('disconnecting from fromQml');
                tablet.fromQml.disconnect(fromQml);
                hasEventBridge = false;
            }
        }
    }

    // Cleanup the tablet button and overlays when script is stopped
    Script.scriptEnding.connect(function () {
        if (onDanceScreen) {
            tablet.gotoHomeScreen();
        }

        button.clicked.disconnect(onTabletButtonClicked);
        tablet.screenChanged.disconnect(onTabletScreenChanged);

        if (tablet) {
            tablet.removeButton(button);
        }
    });

}()); // END LOCAL_SCOPE
