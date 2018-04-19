import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQml.Models 2.1
import QtGraphicalEffects 1.0
import "../controls-uit" as HifiControls
import "../styles-uit"
import "avatarapp"

Rectangle {
    id: root
    width: 480
	height: 706
    color: style.colors.white

    property var selectedAvatar;
    property string avatarName: selectedAvatar ? selectedAvatar.name : ''
    property string avatarUrl: selectedAvatar ? selectedAvatar.url : null
    property int avatarWearablesCount: selectedAvatar ? selectedAvatar.wearables.count : 0
    property bool isAvatarInFavorites: selectedAvatar ? selectedAvatar.favorite : false

    Component.onCompleted: {
        selectedAvatar = view.model.get(view.currentIndex)
        console.debug('wearables: ', selectedAvatar.wearables)
    }

    AvatarAppStyle {
        id: style
    }

    Rectangle {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        height: 84
        color: style.colors.lightGrayBackground

        HiFiGlyphs {
            id: avatarIcon
            anchors.left: parent.left
            anchors.leftMargin: 23
            anchors.top: parent.top
            anchors.topMargin: 29

            size: 38
            text: "<"
        }

        TextStyle6 {
            anchors.left: avatarIcon.right
            anchors.leftMargin: 4
            anchors.verticalCenter: avatarIcon.verticalCenter
            text: 'Avatar'
        }

        HiFiGlyphs {
            anchors.right: parent.right
            anchors.rightMargin: 30
            anchors.verticalCenter: avatarIcon.verticalCenter
            text: "&"
        }
    }

    Rectangle {
        id: mainBlock
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: favoritesBlock.top

        TextStyle1 {
            anchors.left: parent.left
            anchors.leftMargin: 30
            anchors.top: parent.top
            anchors.topMargin: 34
        }

        TextStyle1 {
            id: displayNameLabel
            anchors.left: parent.left
            anchors.leftMargin: 30
            anchors.top: parent.top
            anchors.topMargin: 34
            text: 'Display Name'
        }

        InputTextStyle4 {
            anchors.left: displayNameLabel.right
            anchors.leftMargin: 30
            anchors.verticalCenter: displayNameLabel.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 36
            width: 232
            text: 'ThisIsDisplayName'

            HiFiGlyphs {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                size: 36
                text: "\ue00d"
            }
        }

        ShadowImage {
            id: avatarImage
            width: 134
            height: 134
            anchors.left: displayNameLabel.left
            anchors.top: displayNameLabel.bottom
            anchors.topMargin: 31
            source: avatarUrl
        }

        AvatarWearablesIndicator {
            anchors.right: avatarImage.right
            anchors.bottom: avatarImage.bottom
            anchors.rightMargin: -radius
            anchors.bottomMargin: 6.08
            wearablesCount: avatarWearablesCount
            visible: avatarWearablesCount !== 0
        }

        Row {
            id: star

            anchors.top: parent.top
            anchors.topMargin: 119
            anchors.left: avatarImage.right
            anchors.leftMargin: 30.5

            spacing: 12.3

            Image {
                width: 21.2
                height: 19.3
                source: isAvatarInFavorites ? '../../images/FavoriteIconActive.svg' : '../../images/FavoriteIconInActive.svg'
                anchors.verticalCenter: parent.verticalCenter
            }

            TextStyle5 {
                text: isAvatarInFavorites ? avatarName : "Add to Favorites"
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    enabled: !isAvatarInFavorites
                    anchors.fill: parent
                    onClicked: {
                        console.debug('selectedAvatar.url', selectedAvatar.url)
                        createFavorite.open(selectedAvatar);
                    }
                }
            }
        }

        TextStyle3 {
            id: avatarNameLabel
            text: avatarName
            anchors.left: avatarImage.right
            anchors.leftMargin: 30
            anchors.top: parent.top
            anchors.topMargin: 154
        }

        TextStyle3 {
            id: wearablesLabel
            anchors.left: avatarImage.right
            anchors.leftMargin: 30
            anchors.top: avatarNameLabel.bottom
            anchors.topMargin: 16
            text: 'Wearables'
        }

        SquareLabel {
            anchors.right: parent.right
            anchors.rightMargin: 30
            anchors.verticalCenter: avatarNameLabel.verticalCenter
            glyphText: "."
            glyphRotation: 45
        }

        SquareLabel {
            anchors.right: parent.right
            anchors.rightMargin: 30
            anchors.verticalCenter: wearablesLabel.verticalCenter
            glyphText: "\ue02e"

            visible: avatarWearablesCount !== 0

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    adjustWearables.open();
                }
            }
        }

        TextStyle3 {
            anchors.right: parent.right
            anchors.rightMargin: 30
            anchors.verticalCenter: wearablesLabel.verticalCenter
            font.underline: true
            text: "Add"
            visible: avatarWearablesCount === 0

            MouseArea {
                anchors.fill: parent
                property url getWearablesUrl: '../../images/samples/hifi-place-77312e4b-6f48-4eb4-87e2-50444d8e56d1.png'

                onClicked: {
                    var selectedAvatar = view.model.get(view.currentIndex);

                    popup.button2text = 'AvatarIsland'
                    popup.button1text = 'CANCEL'
                    popup.titleText = 'Get Wearables'
                    popup.bodyText = 'Buy wearables from <a href="https://fake.link">Marketplace</a>' + '\n' +
                                     'Wear wearable from <a href="https://fake.link">My Purchases</a>' + '\n' +
                                     'You can visit the domain “AvatarIsland”' + '\n' +
                                     'to get wearables'

                    popup.imageSource = getWearablesUrl;
                    popup.onButton2Clicked = function() {
                        popup.close();
                        gotoAvatarAppPanel.visible = true;
                    }
                    popup.open();
                }
            }
        }
    }

    Rectangle {
        id: favoritesBlock
        height: 369

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        color: style.colors.lightGrayBackground

        TextStyle1 {
            id: favoritesLabel
            anchors.top: parent.top
            anchors.topMargin: 9
            anchors.left: parent.left
            anchors.leftMargin: 30
            text: "Favorites"
        }

        TextStyle8 {
            id: manageLabel
            anchors.top: parent.top
            anchors.topMargin: 9
            anchors.right: parent.right
            anchors.rightMargin: 30
            text: "Manage"
            color: style.colors.blueHighlight
        }

        Item {
            anchors.left: parent.left
            anchors.leftMargin: 30
            anchors.right: parent.right
            anchors.rightMargin: 30

            anchors.top: favoritesLabel.bottom
            anchors.topMargin: 9
            anchors.bottom: parent.bottom

            GridView {
                id: view
                anchors.fill: parent
                model: AvatarsModel {
                    id: model
                    Component.onCompleted: {
                        for(var i = 0; i < model.count; ++i) {
                            var originalUrl = model.get(i).url;
                            if(originalUrl !== '') {
                                var resolvedUrl = Qt.resolvedUrl(originalUrl);
                                console.debug('url: ', originalUrl, 'resolved: ', resolvedUrl);
                                model.setProperty(i, 'url', resolvedUrl);
                            }
                        }
                    }
                }

                flow: GridView.FlowTopToBottom

                cellHeight: 92 + 36
                cellWidth: 92 + 18

                delegate: Item {
                    id: delegateRoot
                    height: GridView.view.cellHeight
                    width: GridView.view.cellWidth

                    Item {
                        id: container
                        width: 92
                        height: 92

                        states: [
                            State {
                                name: "hovered"
                                when: favoriteAvatarMouseArea.containsMouse;
                                PropertyChanges { target: container; y: -5 }
                                PropertyChanges { target: favoriteAvatarImage; dropShadowRadius: 10 }
                                PropertyChanges { target: favoriteAvatarImage; dropShadowVerticalOffset: 6 }
                            }
                        ]

                        AvatarThumbnail {
                            id: favoriteAvatarImage
                            imageUrl: url
                            wearablesCount: wearables ? wearables.count : 0
                            visible: url !== ''

                            MouseArea {
                                id: favoriteAvatarMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                property url getWearablesUrl: '../../images/samples/hifi-place-77312e4b-6f48-4eb4-87e2-50444d8e56d1.png'

                                onClicked: {
                                    if(delegateRoot.GridView.view.currentIndex !== index) {
                                        var currentItem = delegateRoot.GridView.view.model.get(index);

                                        popup.button2text = 'CONFIRM'
                                        popup.button1text = 'CANCEL'
                                        popup.titleText = 'Load Favorite: {AvatarName}'.replace('{AvatarName}', currentItem.name)
                                        popup.bodyText = 'This will switch your current avatar and wearables that you are wearing with a new avatar and wearables.'
                                        popup.onButton2Clicked = function() {
                                            selectedAvatar = currentItem;
                                            popup.close();
                                            delegateRoot.GridView.view.currentIndex = index;
                                        }
                                        popup.open();
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: highlight
                            anchors.fill: favoriteAvatarImage
                            visible: delegateRoot.GridView.isCurrentItem
                            color: 'transparent'
                            border.width: 2
                            border.color: style.colors.blueHighlight
                        }

                        ShadowRectangle {
                            width: 92
                            height: 92
                            color: style.colors.blueHighlight
                            visible: url === ''

                            Rectangle {
                                anchors.centerIn: parent
                                color: 'white'
                                width: 48
                                height: 48
                            }

                            MouseArea {
                                anchors.fill: parent
                                property url getAvatarsUrl: '../../images/samples/hifi-place-get-avatars.png'

                                onClicked: {
                                    console.debug('getAvatarsUrl: ', getAvatarsUrl);
                                    var selectedAvatar = view.model.get(view.currentIndex);

                                    popup.button2text = 'AvatarIsland'
                                    popup.button1text = 'CANCEL'
                                    popup.titleText = 'Get Avatars'

                                    popup.bodyText = 'Buy avatars from <a href="https://fake.link">Marketplace</a>' + '\n' +
                                                     'Wear avatars from <a href="https://fake.link">My Purchases</a>' + '\n' +
                                                     'You can visit the domain “BodyMart”' + '\n' +
                                                     'to get avatars'

                                    popup.imageSource = getAvatarsUrl;
                                    popup.onButton2Clicked = function() {
                                        popup.close();
                                        gotoAvatarAppPanel.visible = true;
                                    }
                                    popup.open();
                                }
                            }
                        }
                    }

                    TextStyle7 {
                        id: text
                        width: 92
                        anchors.top: container.bottom
                        anchors.topMargin: 8
                        anchors.horizontalCenter: container.horizontalCenter
                        verticalAlignment: Text.AlignTop
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        text: name
                    }
                }
            }

        }
    }

    AdjustWearables {
        id: adjustWearables
    }

    MessageBox {
        id: popup
    }

    CreateFavoriteDialog {
        id: createFavorite
    }

    Rectangle {
        id: gotoAvatarAppPanel
        anchors.fill: parent
        anchors.leftMargin: 19
        anchors.rightMargin: 19

        // color: 'green'
        visible: false
        onVisibleChanged: {
            if(visible) {
                // todo: make better solution when api available

                console.debug('selectedAvatar.wearables: ', selectedAvatar.wearables)
                var tmp = selectedAvatar;
                selectedAvatar.wearables = ['hat', 'sunglasses', 'bracelet']
                selectedAvatar = null;
                selectedAvatar = tmp;

                console.debug('selectedAvatar.wearables count: ', selectedAvatar.wearables.count)
            }
        }

        Rectangle {
            width: 442
            height: 447
            // color: 'yellow'

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 259

            TextStyle1 {
                anchors.fill: parent
                horizontalAlignment: "AlignHCenter"
                wrapMode: "WordWrap"
                text: "You are teleported to “AvatarIsland” VR world and you buy a hat, sunglasses and a bracelet."
            }
        }

        Rectangle {
            width: 442
            height: 177
            // color: 'yellow'

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40

            TextStyle1 {
                anchors.fill: parent
                horizontalAlignment: "AlignHCenter"
                wrapMode: "WordWrap"
                text: '<a href="https://fake.link">Click here to open the Avatar app.</a>'

                MouseArea {
                    anchors.fill: parent
                    onClicked: gotoAvatarAppPanel.visible = false;
                }
            }
        }
    }

    /*
    HifiConstants { id: hifi }

    HifiControls.SpinBox {
        id: scaleSpinner;
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; }
        decimals: 2;
        minimumValue: 0.01
        maximumValue: 10
        stepSize: 0.05;

        labelInside: "X:"
        colorScheme: hifi.colorSchemes.dark
        colorLabelInside: hifi.colors.redHighlight

        value: attachment ? attachment.scale : 1.0
        onValueChanged: {
            if (completed && attachment && attachment.scale !== value) {
                attachment.scale = value;
                updateAttachment();
            }
        }
        onFocusChanged: doSelectAttachment(this, focus);
    }
    */
}
