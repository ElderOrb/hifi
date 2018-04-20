import Hifi 1.0 as Hifi
import QtQuick 2.5
import "../../styles-uit"
import "../../controls-uit" as HifiControlsUit
import "../../controls" as HifiControls

Rectangle {
    id: root;
    visible: false;
    anchors.fill: parent;
    color: Qt.rgba(0, 0, 0, 0.5);
    z: 999;

    property string titleText: 'Create Favorite'
    property string favoriteNameText: favoriteName.text
    property string avatarImageUrl: null
    property int wearablesCount: 0

    property string button1color: hifi.buttons.noneBorderlessGray;
    property string button1text: 'CANCEL'
    property string button2color: hifi.buttons.blue;
    property string button2text: 'CONFIRM'

    property var onButton2Clicked;
    property var onButton1Clicked;

    function open(avatar) {
        favoriteName.text = '';
        avatarImageUrl = avatar.url;
        wearablesCount = avatar.wearables.count;

        visible = true;
    }

    function close() {
        console.debug('closing');
        visible = false;
    }

    HifiConstants {
        id: hifi
    }

    // This object is always used in a popup.
    // This MouseArea is used to prevent a user from being
    //     able to click on a button/mouseArea underneath the popup.
    MouseArea {
        anchors.fill: parent;
        propagateComposedEvents: false;
        hoverEnabled: true;
    }

    Rectangle {
        id: mainContainer;
        width: Math.max(parent.width * 0.8, 400)
        height: contentContainer.height + title.height + 50
        onHeightChanged: {
            console.debug('mainContainer: height = ', height)
        }

        anchors.centerIn: parent

        color: "white"

        TextStyle1 {
            id: title
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 30
            anchors.leftMargin: 30
            anchors.rightMargin: 30

            text: root.titleText
        }

        Item {
            id: contentContainer
            width: parent.width - 50
            height: childrenRect.height

            anchors.top: title.bottom
            anchors.topMargin: 10
            anchors.left: parent.left;
            anchors.leftMargin: 30;
            anchors.right: parent.right;
            anchors.rightMargin: 30;

            Row {
                id: bodyRow

                spacing: 44

                AvatarThumbnail {
                    imageUrl: avatarImageUrl
                    wearablesCount: avatarWearablesCount
                }

                InputTextStyle4 {
                    id: favoriteName
                    anchors.verticalCenter: parent.verticalCenter
                    placeholderText: "Enter Favorite Name"
                }
            }

            DialogButtons {
                anchors.top: bodyRow.bottom
                anchors.topMargin: 20
                anchors.left: parent.left
                anchors.right: parent.right

                yesButton.enabled: favoriteNameText !== ''
                yesText: root.button2text
                noText: root.button1text

                onYesClicked: function() {
                    if(onButton2Clicked) {
                        onButton2Clicked();
                    } else {
                        root.close();
                    }
                }

                onNoClicked: function() {
                    if(onButton1Clicked) {
                        onButton1Clicked();
                    } else {
                        root.close();
                    }
                }
            }
        }
    }
}
