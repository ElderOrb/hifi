import QtQuick 2.2
import QtQuick.Controls 2.3
import QtGraphicalEffects 1.0

Rectangle {
    id: root
    anchors.fill: parent

    LinearGradient {
        anchors.fill: parent
        start: Qt.point(0, 0)
        end: Qt.point(0, height)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "lightgreen" }
            GradientStop { position: 1.0; color: "green" }
        }
    }

    property var animFolder: "https://hifi-content.s3.amazonaws.com/wadewatts/Dance/";
    property var animFolder2: "https://brainstormer.keybase.pub/High%20Fidelity/Animations/Old/"
    property var animationMap: [
        /////////////////////
        // from dancefloor.js
        {keyNote: 88,keyColor: 40, animURL: animFolder + "Swing Dancing 699.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 699},
        {keyNote: 87,keyColor: 40, animURL: animFolder + "Swing Dancing 156.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 156},
        {keyNote: 86,keyColor: 40, animURL: animFolder + "Swing Dancing 74.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 74},
        {keyNote: 85,keyColor: 72, animURL: animFolder + "Snake Hip Hop Dance 458.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 458},
        {keyNote: 84,keyColor: 40, animURL: animFolder + "Slide Hip Hop Dance 519.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 519},
        {keyNote: 83,keyColor: 40, animURL: animFolder + "Silly Dancing 163.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 163},
        {keyNote: 82,keyColor: 40, animURL: animFolder + "Silly Dancing 115.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 115},
        {keyNote: 81,keyColor: 40, animURL: animFolder + "Shuffling 225.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 225},

        {keyNote: 78,keyColor: 50, animURL: animFolder + "Samba Dancing 594.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 594},
        {keyNote: 77,keyColor: 50, animURL: animFolder + "Samba Dancing 559.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 559},
        {keyNote: 76,keyColor: 72, animURL: animFolder + "Salsa Dancing 135.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 135},
        {keyNote: 75,keyColor: 40, animURL: animFolder + "Salsa Dancing 73.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 73},
        {keyNote: 74,keyColor: 72, animURL: animFolder + "Salsa Dancing 68.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 68},
        {keyNote: 73,keyColor: 72, animURL: animFolder + "Rumba Dancing 71.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 71},
        {keyNote: 72,keyColor: 50, animURL: animFolder + "Robot Hip Hop Dance 463.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 463},
        {keyNote: 71,keyColor: 20, animURL: animFolder + "Macarena Dance 247.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 247},

        {keyNote: 68,keyColor: 72, animURL: animFolder + "Jazz Dancing 163.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 163},
        {keyNote: 67,keyColor: 40, animURL: animFolder + "Jazz Dancing 70.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 70},
        {keyNote: 66,keyColor: 40, animURL: animFolder + "Jazz Dancing 61.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 61},
        {keyNote: 65,keyColor: 20, animURL: animFolder + "House Dancing 641.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 641},
        {keyNote: 64,keyColor: 54, animURL: animFolder + "Hip Hop Dancing 557.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 557},
        {keyNote: 63,keyColor: 72, animURL: animFolder + "Hip Hop Dancing 473.fbx", playbackRate: 15, animLoop: true, startFrame: 0, endFrame: 473},
        {keyNote: 62,keyColor: 54, animURL: animFolder + "Hip Hop Dancing 413.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 413},
        {keyNote: 61,keyColor: 54, animURL: animFolder + "Hip Hop Dancing 409.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 409},

        {keyNote: 58,keyColor: 54, animURL: animFolder + "Hip Hop Dancing 391.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 391},
        {keyNote: 57,keyColor: 54, animURL: animFolder + "Hip Hop Dancing 212.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 212},
        {keyNote: 56,keyColor: 54, animURL: animFolder + "Hip Hop Dancing 190.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 190},
        {keyNote: 55,keyColor: 54, animURL: animFolder + "Hip Hop Dancing 156.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 156},
        {keyNote: 54,keyColor: 54, animURL: animFolder + "Hip Hop Dancing 142.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 142},
        {keyNote: 53,keyColor: 72, animURL: animFolder + "Hip Hop Dancing 134.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 134},
        {keyNote: 52,keyColor: 54, animURL: animFolder + "Hip Hop Dancing 123.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 123},
        {keyNote: 51,keyColor: 54, animURL: animFolder + "Hip Hop Dancing 101.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 101},

        {keyNote: 48,keyColor: 20, animURL: animFolder + "Hokey Pokey 350.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 350},
        {keyNote: 47,keyColor: 20, animURL: animFolder + "Gangnam Style 371.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 371},
        {keyNote: 46,keyColor: 72, animURL: animFolder + "Dancing Twerk 456.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 465},
        {keyNote: 45,keyColor: 20, animURL: animFolder + "Dancing Running Man 325.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 325},
        {keyNote: 44,keyColor: 20, animURL: animFolder + "Dancing 243.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 243},
        {keyNote: 43,keyColor: 20, animURL: animFolder + "Dancing 220.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 220},
        {keyNote: 42,keyColor: 20, animURL: animFolder + "Chicken Dance 143.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 143},
        {keyNote: 41,keyColor: 72, animURL: animFolder + "Can Can 110.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 110},

        {keyNote: 38,keyColor: 20, animURL: animFolder + "Brooklyn Uprock 146.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 146},
        {keyNote: 37,keyColor: 20, animURL: animFolder + "Breakdance Uprock Var 1 63.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 63},
        {keyNote: 36,keyColor: 20, animURL: animFolder + "Breakdance Uprock 63.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 63},
        {keyNote: 35,keyColor: 20, animURL: animFolder + "Breakdance Ready 63.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 63},
        {keyNote: 34,keyColor: 20, animURL: animFolder + "Bboy Uprock 69.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 69},
        {keyNote: 33,keyColor: 20, animURL: animFolder + "Bboy Hip Hop Move 68.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 68},
        {keyNote: 32,keyColor: 20, animURL: animFolder + "Bboy Hip Hop Move 66.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 66},
        {keyNote: 31,keyColor: 72, animURL: animFolder + "Arms Hip Hop Dance 659.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 659},

        {keyNote: 28,keyColor: 20, animURL: animFolder + "Wave Hip Hop Dance 479.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 479},
        {keyNote: 27,keyColor: 20, animURL: animFolder + "Wave Hip Hop Dance 35.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 35},
        {keyNote: 26,keyColor: 20, animURL: animFolder + "Twist Dance 283.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 283},
        {keyNote: 25,keyColor: 20, animURL: animFolder + "Tut Hip Hop Dance 508.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 508},
        {keyNote: 24,keyColor: 20, animURL: animFolder + "Swing Dancing 741.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 741},

        /////////////////////
        // from midiEmote.js
        {keyNote: 81,keyColor: 40, animURL: animFolder2 + "Sitting.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 35},
        {keyNote: 78,keyColor: 40, animURL: animFolder2 + "Bellydancing.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 761},
        {keyNote: 77,keyColor: 40, animURL: animFolder2 + "Jazz Dancing.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 61},
        {keyNote: 76,keyColor: 40, animURL: animFolder2 + "Samba Dancing.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 323},
        {keyNote: 75,keyColor: 40, animURL: animFolder2 + "Wave Hip Hop Dance.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 479},
        {keyNote: 74,keyColor: 40, animURL: animFolder2 + "Gangnam Style.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 371},
        {keyNote: 72,keyColor: 40, animURL: animFolder2 + "Hip Hop Dancing1.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 473},
        {keyNote: 71,keyColor: 40, animURL: animFolder2 + "Chicken Dance.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 143},
        {keyNote: 68,keyColor: 40, animURL: animFolder2 + "Hip Hop Dancing2.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 190},
        {keyNote: 67,keyColor: 40, animURL: animFolder2 + "Excited.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 197},
        {keyNote: 65,keyColor: 40, animURL: animFolder2 + "House Dancing.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 594},
    // Misc
        {keyNote: 64,keyColor: 50, animURL: animFolder2 + "Looking Around.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 190},
        {keyNote: 63,keyColor: 50, animURL: "https://s3-us-west-2.amazonaws.com/highfidelityvr/waving.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 84},
        {keyNote: 62,keyColor: 50, animURL: "https://hifi-public.s3.amazonaws.com/ozan/anim/kneel/kneel.fbx", playbackRate: 30, animLoop: false, startFrame: 0, endFrame: 82},
        {keyNote: 61,keyColor: 50, animURL: "https://s3.amazonaws.com/hifi-public/animations/ClapAnimations/ClapHands_Standing.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 53},
        {keyNote: 58,keyColor: 50, animURL: animFolder2 + "Defeated.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 203},
        {keyNote: 57,keyColor: 50, animURL: animFolder2 + "Jumping.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 97},
        {keyNote: 56,keyColor: 50, animURL: animFolder2 + "Standing Using Touchscreen Tablet.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 994},
        {keyNote: 55,keyColor: 50, animURL: animFolder2 + "Loser.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 98},
        {keyNote: 54,keyColor: 50, animURL: animFolder2 + "Searching Pockets.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 150},
        {keyNote: 53,keyColor: 50, animURL: animFolder2 + "Agony.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 82},
    //Drunk
        {keyNote: 52,keyColor: 50, animURL: animFolder2 + "Drunk Idle Variation.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 119},
        {keyNote: 51,keyColor: 50, animURL: animFolder2 + "Tripping.fbx", playbackRate: 30, animLoop: false, startFrame: 0, endFrame: 63},
    // Fighting
        {keyNote: 41,keyColor: 20, animURL: animFolder2 + "Taunt.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 85},
        {keyNote: 42,keyColor: 20, animURL: animFolder2 + "Sword And Shield Kick.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 36},
        {keyNote: 43,keyColor: 20, animURL: animFolder2 + "Boxing.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 65},
        {keyNote: 44,keyColor: 20, animURL: animFolder2 + "Punching.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 30},
        {keyNote: 45,keyColor: 20, animURL: animFolder2 + "Roundhouse Kick.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 568},
        {keyNote: 46,keyColor: 20, animURL: animFolder2 + "Lead Jab.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 54},
        {keyNote: 47,keyColor: 20, animURL: animFolder2 + "Taunt2.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 139},
        {keyNote: 48,keyColor: 20, animURL: animFolder2 + "Illegal Elbow Punch.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 68},
        {keyNote: 31,keyColor: 20, animURL: animFolder2 + "Body Jab Cross.fbx", playbackRate: 30, animLoop: true, startFrame: 0, endFrame: 66}
    ];

    property int stateInitial: -1
    property int stateFinished: 3
    property int stateFailed: 4

    Component.onCompleted: {
        var extractTitle = function(url) {
            return url.split('/').pop();
        }

        for(var i = 0; i < animationMap.length; ++i) {
            var animation = animationMap[i];
            dancesModel.append({
                animationData: animation,
                title: extractTitle(animation.animURL),
                animationState: stateInitial
            })

            sendToScript({'method' : 'prefetch', 'animationURL' : animation.animURL, 'index' : i})
        }
    }

    function fromScript(message) {
        switch (message.method) {
        case 'prefetchNotification':
            console.debug('updating', message.index, 'with a new state:', message.state)
            dancesModel.setProperty(message.index, 'animationState', message.state)
            break;
        }
    }

    ListModel {
        id: dancesModel
    }

    Button {
        id: dummy
        visible: false
    }

    GridView {
        id: dancesView
        anchors.fill: parent
        anchors.margins: 20

        cellHeight: dummy.height + 10
        cellWidth: width / 3

        model: dancesModel

        ButtonGroup {
            id: group
        }

        delegate: Item {
            height: titleButton.implicitHeight
            width: dancesView.cellWidth
            RoundButton {
                id: titleButton
                text: title
                checkable: true
                width: dancesView.cellWidth * 0.95
                anchors.horizontalCenter: parent.horizontalCenter
                ButtonGroup.group: group
                property bool wasChecked: false

                enabled: animationState=== stateFinished
                onEnabledChanged: {
                    console.debug('onEnabledChanged: ', 'animationState = ', animationState, 'stateFinished = ', stateFinished, 'title: ', title)
                }

                Colorize {
                    anchors.fill: parent
                    lightness: 0.75
                    hue: 0
                    saturation: 1
                    visible: animationState === stateFailed
                }

                onPressed: {
                    wasChecked = checked;
                }

                onClicked: {
                    if(wasChecked && checked)
                        checked = false;

                    console.debug('sendToScript: ', JSON.stringify(animationData, null, '\t'))
                    sendToScript({'method' : checked ? 'start' : 'stop', 'animationData' : animationData})
                }
            }
        }
    }

    signal sendToScript(var message);
}
