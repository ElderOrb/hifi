import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQml.Models 2.1

Rectangle {
    anchors.fill: parent
    id: root

    property int buttonAreaHeight: 50
    property color centerColor: 'lightGray'

    property int itemRadius: 50
    property int innerRadius: 18
    property int highlightRadius: 6

    property color pointerColor: 'lightBlue'
    property color highlightColor: 'lime green'
    property color highlightItemColor: 'lime green'
    property double itemOpacity: 0.8

    property int itemsCount: 10
    property int columnsCount: 3
    property int rowsCount: Math.ceil(itemsCount / columnsCount);

    property color allowedTargetIndicatorColor: 'black'
    property int allowedTargetIndicatorRadius : 4

    // implementation
    property var allowedTargets: []
    property int selectedItemIndex: -1
    property var selectedItems: []

    function updateAllowedTargets(modelIndex) {
        // console.debug('updating allowed positions for modelIndex: ', modelIndex)

        var newAllowedTargets = [];

        var count = gridView.model.count
        var row = Math.floor(modelIndex / columnsCount);
        var column = modelIndex % columnsCount;

        for(var r = Math.max(row - 1, 0); r <= Math.min(row + 1, rowsCount - 1); ++r) {
            for(var c = Math.max(column - 1, 0); c <= Math.min(column + 1, columnsCount - 1); ++c) {
                if(r === row && c === column) {
                    continue; // skip self
                }

                var index  = r * columnsCount + c;
                if(index >= count) {
                    break;
                }

                var targetItem = gridView.model.get(index)
                if(!targetItem.selected) {
                    newAllowedTargets.push(targetItem);
                }
            }
        }

        for(var i = 0; i < newAllowedTargets.length; ++i) {
            console.debug('allowed: ', newAllowedTargets[i])
        }

        allowedTargets = newAllowedTargets;
    }



    gradient: Gradient {
        GradientStop {
            position: 0
            color: "#d8d8d5"
        }

        GradientStop {
            position: 0.012
            color: "#c1bf9e"
        }

        GradientStop {
            position: 1
            color: "#58563e"
        }
    }

    Item {
        anchors.fill: parent
        anchors.bottomMargin: buttonAreaHeight

        Canvas {
            id: connections
            anchors.fill: parent

            onPaint: {

                var ctx = getContext("2d")
                ctx.reset();

                if(selectedItems.length !== 0) {
                    ctx.beginPath()
                    ctx.strokeStyle = centerColor
                    ctx.lineCap = 'round'
                    ctx.lineJoin = 'round'
                    ctx.lineWidth = innerRadius * 2

                    for(var i = 0; i < selectedItems.length; ++i) {
                        var itemIndex = selectedItems[i];
                        var delegateItem = gridView.model.get(itemIndex)
                        if(i === 0) {
                            ctx.moveTo(delegateItem.x + delegateItem.width / 2, delegateItem.y + delegateItem.height / 2)
                        } else {
                            ctx.lineTo(delegateItem.x + delegateItem.width / 2, delegateItem.y + delegateItem.height / 2)
                        }
                    }

                    ctx.stroke()
                }

                if(!dragArea.dragging)
                    return

                ctx.beginPath()
                ctx.strokeStyle = pointerColor
                ctx.lineCap = 'round'
                ctx.lineWidth = innerRadius * 2
                ctx.moveTo(start.x, start.y)
                ctx.lineTo(end.x, end.y)
                ctx.stroke()
            }

            property point start: selectedItemIndex === -1 ? Qt.point(0, 0) : gridView.model.get(selectedItemIndex).getCenter()
            property point end: dragHandle.getCenter()
            onEndChanged: {
                requestPaint();
            }

            property var selectedItems: root.selectedItems
            onSelectedItemsChanged: {
                requestPaint();
            }
        }

        GridView {
            id: gridView

            anchors.fill: parent
            cellWidth: parent.width / columnsCount
            cellHeight: parent.height / rowsCount
            interactive: false

            model: ObjectModel {
                id: objectModel
                property var numpadItemBuilder: Component {
                    Item {
                        id: delegate
                        objectName: "delegate" + index

                        property bool selected: false
                        property int index: 0
                        property int number: 0

                        width: gridView.cellWidth
                        height: gridView.cellHeight

                        function containsMouse(pos) {

                            var localPos = mapFromItem(null, pos.x, pos.y);
                            var outerCirclePos = mapToItem(outerCircle, localPos.x, localPos.y);
                            var containsResult = outerCircle.contains(outerCirclePos);

                            return containsResult;
                        }

                        function getCenter() {
                            return Qt.point(x + width / 2, y + height / 2)
                        }

                        function getRotationAngle() {

                            var nextIndex = nextItemIndex();
                            if(nextIndex === -1)
                                return 0;

                            var nextItem = gridView.model.get(nextIndex);

                            var normalizedConnectionVector =  Qt.vector2d(nextItem.x, nextItem.y).minus(Qt.vector2d(delegate.x, delegate.y)).normalized();
                            var normalizedXAxisVector = Qt.vector2d(1, 0).normalized();

                            var cos = normalizedConnectionVector.dotProduct(normalizedXAxisVector);
                            var angle = Math.acos(cos) * (180 / Math.PI);

                            if(angle === 90) {
                                if(normalizedConnectionVector.y < 0)
                                    angle += 180
                            }

                            return angle;
                        }

                        function nextItemIndex() {
                            var indexOfIndex = selectedItems.indexOf(index);
                            if(indexOfIndex === -1)
                                return -1

                            if(indexOfIndex >= (selectedItems.length - 1))
                                return -1

                            return selectedItems[indexOfIndex + 1]
                        }

                        Rectangle {
                            id: outerCircle
                            anchors.centerIn: parent
                            width: itemRadius * 2
                            height: itemRadius * 2
                            radius: itemRadius
                            antialiasing: true
                            color: 'black'
                            opacity: itemOpacity

                            Item {
                                anchors.fill: parent
                                rotation: {
                                    var angle = getRotationAngle();
                                    console.debug('angle: ', angle)
                                    return angle;
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: highlightColor
                                    font.bold: true
                                    font.pointSize: itemRadius / 3
                                    text: ">"
                                    visible: nextItemIndex() !== -1
                                }
                            }

                            Rectangle {
                                id: circle

                                anchors.centerIn: parent
                                width: innerRadius * 2
                                height: innerRadius * 2
                                radius: innerRadius
                                color: centerColor
                                opacity: itemOpacity

                                Rectangle {
                                    id: allowedTargetIndicator
                                    anchors.centerIn: parent

                                    width: allowedTargetIndicatorRadius * 2
                                    height: allowedTargetIndicatorRadius * 2
                                    radius: allowedTargetIndicatorRadius
                                    color: allowedTargetIndicatorColor

                                    visible: {
                                        var isAllowed = allowedTargets.indexOf(delegate) !== -1
                                        return isAllowed
                                    }
                                }
                            }

                            Text {
                                anchors.fill: parent
                                text: number
                            }
                        }

                        Rectangle {
                            id: highlight
                            visible: selected
                            anchors.centerIn: parent
                            width: outerCircle.width + highlightRadius * 2
                            height: outerCircle.height + highlightRadius * 2
                            radius: outerCircle.width / 2 + highlightRadius

                            antialiasing: true
                            color: 'transparent'
                            border.color: highlightColor
                            border.width: highlightRadius
                        }
                    }
                }

                Component.onCompleted: {
                    for(var i = 0; i < itemsCount; ++i) {
                        objectModel.append(numpadItemBuilder.createObject(gridView, {index: i, number: i + 1}))
                    }
                }
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            drag.target: dragHandle
            z: -1

            property bool dragging: false;

            onReleased: {
                dragging = false;
            }

            function selectItem(item) {
                selectedItemIndex = item.index
                item.selected = true;

                var newSelectedItems = selectedItems.slice(); // this is required to make bindings work
                newSelectedItems.push(selectedItemIndex);
                selectedItems = newSelectedItems;

                dragHandle.adjustToCenter(item)
                updateAllowedTargets(selectedItemIndex)
            }

            onPositionChanged: {
                var centerOfDragItem = dragHandle.getCenter();
                var item = gridView.itemAt(centerOfDragItem.x, centerOfDragItem.y)

                if(item && item.containsMouse(mapToItem(null, centerOfDragItem.x, centerOfDragItem.y))) {
                    if (allowedTargets.indexOf(item) === -1) {
                        return;
                    }

                    if(!item.selected) {
                        if(selectedItemIndex !== item.index) {
                            selectItem(item)
                        }
                    }
                } else {
                    selectedItemIndex = selectedItems.length !== 0 ? selectedItems.slice(-1)[0] : -1
                }
            }

            onPressed: {
                var item = gridView.itemAt(mouse.x, mouse.y)
                console.debug('pressed: ', mouse.x, mouse.y, 'global: ', dragArea.mapToGlobal(mouse.x, mouse.y), 'window: ', dragArea.mapToItem(null, mouse.x, mouse.y))

                if(item && item.containsMouse(mapToItem(null, mouse.x, mouse.y))) {
                    selectItem(item)
                    dragging = true;
                }
            }
        }

        Rectangle {
            id: dragHandle

            function adjustToCenter(item) {
                var rect = item.mapToItem(gridView, 0, 0, item.width, item.height)

                // console.debug('adjust to center of ', item);

                var centerX = rect.x + rect.width / 2
                var centerY = rect.y + rect.height / 2

                x = rect.x + (rect.width - width) / 2
                y = rect.y + (rect.height - height) / 2
            }

            function getCenter() {
                return Qt.point(x + width / 2, y + height / 2)
            }

            property point lastMousePos;

            property point invalidTarget: Qt.point(-1, -1)
            property point target: invalidTarget
            property double k: 0;

            color: dragArea.drag.active ? highlightItemColor : 'transparent'
            height: 40
            width: 40
            radius: 20
        }
    }

    Item {
        height: buttonAreaHeight

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "X";
            onClicked: {
                allowedTargets = []
                selectedItems = []
                selectedItemIndex = -1

                for(var i = 0; i < gridView.model.count; ++i)
                    gridView.model.get(i).selected = false
            }
        }
    }
}
