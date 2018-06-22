import QtQuick 2.0
import Hifi 1.0

import "../../controls-uit"
import "../../dialogs"
import "../../controls"

Item {
    id: tabletRoot
    objectName: "tabletRoot"
    property string username: "Unknown user"
    property string usernameShort: "Unknown user"
    property var rootMenu;
    property var openModal: null;
    property var openMessage: null;
    property var openBrowser: null;
    property string subMenu: ""
    signal showDesktop();
    property bool shown: true
    property int currentApp: -1;
    property alias tabletApps: tabletApps

    Component.onCompleted: {
        console.debug('TabletRoot created: ', tabletRoot)
        offscreenWindow.focusObjectChanged.connect(vk.onFocusObjectChanged);
    }

    VirtualKeyboard {
	    id: vk
	    parent: null

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
                          'keyboard.keyboard: ', keyboard.keyboard
                          );

            if(keyboard) {
                keyboard.keyboardContainer.keyboardRaised = raised;
                vk.mirroredText = '';
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
                if(item.hasOwnProperty("keyboardRaised")) {
                    keyboardContainer = item;

                    if(item.hasOwnProperty("keyboardContainer")) {
                        return {
                            keyboard: item.keyboardContainer,
                            keyboardContainer: keyboardContainer
                        }
                    }

                    var keyboards = findKeyboards(item, visited);
                    if(keyboards.length !== 0) {
                        var nearestKeyboard = null;
                        var minDistance = Number.MAX_VALUE;

                        for(var i = 0; i < keyboards.length; ++i) {
                            var keyboard = keyboards[i];
                            var distance = distanceToParent(keyboard, item);

                            if(minDistance > distance) {
                                minDistance = distance;
                                nearestKeyboard = keyboards[i];
                            }
                        }

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

	    Component.onCompleted: {
	         console.debug('TabletRoot: VirtualKeyboard created for ', tabletRoot)
	    }
    }

    function setOption(value) {
        option = value;
    }

    Component { id: inputDialogBuilder; TabletQueryDialog { } }
    function inputDialog(properties) {
        openModal = inputDialogBuilder.createObject(tabletRoot, properties);
        return openModal;
    }
    Component { id: messageBoxBuilder; TabletMessageBox { } }
    function messageBox(properties) {
        openMessage  = messageBoxBuilder.createObject(tabletRoot, properties);
        return openMessage;
    }

    Component { id: customInputDialogBuilder; TabletCustomQueryDialog { } }
    function customInputDialog(properties) {
        openModal = customInputDialogBuilder.createObject(tabletRoot, properties);
        return openModal;
    }

    Component { id: fileDialogBuilder; TabletFileDialog { } }
    function fileDialog(properties) {
        openModal = fileDialogBuilder.createObject(tabletRoot, properties);
        return openModal;
    }

    Component { id: assetDialogBuilder; TabletAssetDialog { } }
    function assetDialog(properties) {
        openModal = assetDialogBuilder.createObject(tabletRoot, properties);
        return openModal;
    }

    function setMenuProperties(rootMenu, subMenu) {
        tabletRoot.rootMenu = rootMenu;
        tabletRoot.subMenu = subMenu;
    }

    function isDialogOpen() {
        if (openMessage !== null || openModal !== null) {
            return true;
        }

        return false;
    }

    function closeDialog() {
        if (openMessage != null) {
            openMessage.destroy();
            openMessage = null;
        }

        if (openModal != null) {
            openModal.destroy();
            openModal = null;
        }
    }

    function isUrlLoaded(url) {
        if (currentApp >= 0) {
            var currentAppUrl = tabletApps.get(currentApp).appUrl;
            if (currentAppUrl === url) {
                return true;
            }
        }
        return false;
    }

    function loadSource(url) {
        tabletApps.clear();
        tabletApps.append({"appUrl": url, "isWebUrl": false, "scriptUrl": "", "appWebUrl": ""});
        loader.load(url)
    }

    function loadQMLOnTop(url) {
        if (!isUrlLoaded(url)) {
            tabletApps.append({"appUrl": url, "isWebUrl": false, "scriptUrl": "", "appWebUrl": ""});
            loader.load(tabletApps.get(currentApp).appUrl, function(){
	            if (loader.item.hasOwnProperty("gotoPreviousApp")) {
	                loader.item.gotoPreviousApp = true;
	            }
            });
        }
    }

    function loadWebContent(source, url, injectJavaScriptUrl) {
        if (!isUrlLoaded(url)) {
            tabletApps.append({"appUrl": source, "isWebUrl": true, "scriptUrl": injectJavaScriptUrl, "appWebUrl": url});
            loader.load(source, function() {
                loader.item.scriptURL = injectJavaScriptUrl;
                loader.item.url = url;
                if (loader.item.hasOwnProperty("gotoPreviousApp")) {
                    loader.item.gotoPreviousApp = true;
                }
            });
        }
    }

    function loadWebBase(url, injectJavaScriptUrl) {
        loadWebContent("hifi/tablet/TabletWebView.qml", url, injectJavaScriptUrl);
    }

    function loadTabletWebBase(url, injectJavaScriptUrl) {
        loadWebContent("hifi/tablet/BlocksWebView.qml", url, injectJavaScriptUrl);
    }

    function returnToPreviousApp() {
        tabletApps.remove(currentApp);
        var isWebPage = tabletApps.get(currentApp).isWebUrl;
        if (isWebPage) {
            var webUrl = tabletApps.get(currentApp).appWebUrl;
            var scriptUrl = tabletApps.get(currentApp).scriptUrl;
            loadSource("hifi/tablet/TabletWebView.qml");
            loadWebUrl(webUrl, scriptUrl);
        } else {
        	loader.load(tabletApps.get(currentApp).appUrl);
        }
    }

    function openBrowserWindow(request, profile) {
        var component = Qt.createComponent("../../controls/TabletWebView.qml");
        var newWindow = component.createObject(tabletRoot);
        newWindow.remove = true;
        newWindow.profile = profile;
        request.openIn(newWindow.webView);
        tabletRoot.openBrowser = newWindow;
    }

    function loadWebUrl(url, injectedJavaScriptUrl) {
        tabletApps.clear();
        loader.item.url = url;
        loader.item.scriptURL = injectedJavaScriptUrl;
        tabletApps.append({"appUrl": "TabletWebView.qml", "isWebUrl": true, "scriptUrl": injectedJavaScriptUrl, "appWebUrl": url});
        if (loader.item.hasOwnProperty("closeButtonVisible")) {
            loader.item.closeButtonVisible = false;
        }
    }

    // used to send a message from qml to interface script.
    signal sendToScript(var message);

    // used to receive messages from interface script
    function fromScript(message) {
        if (loader.item.hasOwnProperty("fromScript")) {
            loader.item.fromScript(message);
        }
    }

    SoundEffect {
        id: buttonClickSound
        volume: 0.1
        source: "../../../sounds/Gamemaster-Audio-button-click.wav"
    }

    function playButtonClickSound() {
        // Because of the asynchronous nature of initalization, it is possible for this function to be
        // called before the C++ has set the globalPosition context variable.
        if (typeof globalPosition !== 'undefined') {
            buttonClickSound.play(globalPosition);
        }
    }

    function setUsername(newUsername) {
        username = newUsername;
        usernameShort = newUsername.substring(0, 8);

        if (newUsername.length > 8) {
            usernameShort = usernameShort + "..."
        }
    }

    ListModel {
        id: tabletApps
        onCountChanged: {
            currentApp = count - 1
        }
    }

    // Hook up callback for clara.io download from the marketplace.
    Connections {
        id: eventBridgeConnection
        target: eventBridge
        onWebEventReceived: {
            if (message.slice(0, 17) === "CLARA.IO DOWNLOAD") {
                ApplicationInterface.addAssetToWorldFromURL(message.slice(18));
            }
        }
    }

	Item {
		id: loader
        objectName: "loader";
        anchors.fill: parent;
    	property string source: "";
    	property var item: null;
    	signal loaded;

		onWidthChanged: {
    		if (loader.item) {
	        	loader.item.width = loader.width;
    		}
		}

    	onHeightChanged: {
    		if (loader.item) {
	        	loader.item.height = loader.height;
    		}
		}

    	function load(newSource, callback) {
            if (loader.source == newSource) {
                loader.loaded();
                return;
            }

            if (loader.item) {
                loader.item.destroy();
                loader.item = null;
            }

	        QmlSurface.load(newSource, loader, function(newItem) {
	        	loader.item = newItem;
	        	loader.item.width = loader.width;
	        	loader.item.height = loader.height;
	        	loader.loaded();
	            if (loader.item.hasOwnProperty("sendToScript")) {
	                loader.item.sendToScript.connect(tabletRoot.sendToScript);
	            }
	            if (loader.item.hasOwnProperty("setRootMenu")) {
	                loader.item.setRootMenu(tabletRoot.rootMenu, tabletRoot.subMenu);
	            }
	            loader.item.forceActiveFocus();

	            if (openModal) {
	                openModal.canceled();
	                openModal.destroy();
	                openModal = null;
	            }

	            if (openBrowser) {
	                openBrowser.destroy();
	                openBrowser = null;
	            }

	            if (callback) {
	            	callback();
	            }
	        });
    	}
	}

    width: 480
    height: 706

    function setShown(value) {
        if (value === true) {
            HMD.openTablet(HMD.tabletContextualMode) // pass in current contextual mode flag to maintain flag (otherwise uses default false argument)
        } else {
            HMD.closeTablet()
        }
    }
}
