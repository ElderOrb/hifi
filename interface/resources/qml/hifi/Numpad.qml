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
    property color highlightItemColor: 'transparent'
    property double itemOpacity: 0.8

    property int itemsCount: 10
    property int columnsCount: 3
    property int rowsCount: Math.ceil(itemsCount / columnsCount);

    property color allowedPositionHighlightColor: Qt.rgba(0, 0.5, 0, 0.5)
    property int allowedPositionHightlightRadius: 4

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
                // console.debug('paint: start = ', start, 'end = ', end)

                var ctx = getContext("2d")

                ctx.reset();

                if(selectedItems.length != 0) {
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

            onStartChanged: {
                // console.debug('start = ', start, 'end = ', end)
            }

            property point start: dragHandle.start
            property point end: dragHandle.getCenter()
            onEndChanged: {
                // console.debug('start = ', start, 'end = ', end)
                requestPaint();
            }

            property var selectedItems: dragArea.selectedItems
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

                            var localPos = mapFromItem(null, pos.x, pos.y)
                            var outerCirclePos = mapToItem(outerCircle, localPos.x, localPos.y)

                            console.debug('containsMouse: ', localPos, outerCirclePos)
                            var containsResult = outerCircle.contains(outerCirclePos)
                            console.debug('contains: ', containsResult)

                            return containsResult;
                        }

                        function getCenter() {
                            return Qt.point(x + width / 2, y + height / 2)
                        }

                        function getRotationAngle() {

                            var revision = dragArea.selectedItemsRevision;
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

                            var revision = dragArea.selectedItemsRevision;
                            var indexOfIndex = dragArea.selectedItems.indexOf(index);
                            if(indexOfIndex === -1)
                                return -1

                            if(indexOfIndex >= (dragArea.selectedItems.length - 1))
                                return -1

                            return dragArea.selectedItems[indexOfIndex + 1]
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

        Canvas {
            id: overlay
            anchors.fill: parent

            property point start: dragHandle.start
            property point end: dragHandle.getCenter()
            onEndChanged: {
                // console.debug('start = ', start, 'end = ', end)
                requestPaint();
            }

            property var allowedItems: dragHandle.allowedTargets
            onAllowedItemsChanged: {
                requestPaint();
            }

            onPaint: {

                var ctx = getContext("2d")
                ctx.reset();
                ctx.beginPath()

                for(var i = 0; i < allowedItems.length; ++i) {
                    var allowedItem = allowedItems[i];
                    var allowedPosition = allowedItem.getCenter();

                    ctx.strokeStyle = allowedPositionHighlightColor
                    ctx.lineCap = 'round'
                    ctx.lineWidth = innerRadius * 2

                    var x = allowedPosition.x - allowedPositionHightlightRadius / 2
                    var y = allowedPosition.y - allowedPositionHightlightRadius / 2

                    ctx.ellipse(x, y, allowedPositionHightlightRadius, allowedPositionHightlightRadius)
                    ctx.fill()
                }

                /*

                if(!dragArea.dragging)
                    return

                ctx.beginPath()
                ctx.strokeStyle = pointerColor
                ctx.lineCap = 'round'
                ctx.lineWidth = innerRadius * 2
                ctx.moveTo(start.x, start.y)
                ctx.lineTo(end.x, end.y)
                ctx.stroke()
                */

                /*
                var ctx = getContext("2d")

                ctx.reset();

                if(itemRect != Qt.rect(0, 0, 0, 0)) {
                    ctx.beginPath()
                    ctx.fillStyle = Qt.rgba(0.3, 0.3, 0.3, 0.7)
                    ctx.fillRect(itemRect.x, itemRect.y, itemRect.width, itemRect.height);
                    ctx.closePath()
                }
                */
            }

            property rect itemRect: Qt.rect(0, 0, 0, 0);
            onItemRectChanged: {
                // console.debug('rect = ', itemRect);
                requestPaint();
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

            property int selectedItemIndex;
            property var selectedItems: []
            property var selectedItemsRevision: 0

            onPositionChanged: {
                var centerOfDragItem = dragHandle.getCenter();
                var item = gridView.itemAt(centerOfDragItem.x, centerOfDragItem.y)

                if(item && item.containsMouse(mapToItem(null, centerOfDragItem.x, centerOfDragItem.y))) {
                    if (dragHandle.allowedTargets.indexOf(item) === -1) {
                        return;
                    }

                    if(!item.selected) {
                        if(selectedItemIndex !== item.index) {
                            selectedItemIndex = item.index

                            item.selected = true;
                            selectedItems.push(selectedItemIndex);
                            selectedItemsRevision++;

                            dragHandle.adjustToCenter(item)
                            dragHandle.updateAllowedTargets(selectedItemIndex)
                        }
                    }
                } else {
                    selectedItemIndex = -1
                }
            }

            onPressed: {
                var item = gridView.itemAt(mouse.x, mouse.y)
                console.debug('pressed: ', mouse.x, mouse.y, 'global: ', dragArea.mapToGlobal(mouse.x, mouse.y), 'window: ', dragArea.mapToItem(null, mouse.x, mouse.y))

                if(item && item.containsMouse(mapToItem(null, mouse.x, mouse.y))) {
                    var modelIndex = gridView.indexAt(mouse.x, mouse.y)
                    var modelItem = gridView.model.get(modelIndex);

                    var selectionIndex = modelItem.index

                    gridView.model.get(selectionIndex).selected = true
                    selectedItems.push(selectionIndex);

                    dragHandle.adjustToCenter(gridView.model.get(selectionIndex))
                    dragHandle.updateAllowedTargets(selectionIndex)

                    dragging = true;
                }
            }
        }

        Rectangle {
            id: dragHandle

            function adjustToCenter(item) {
                var rect = item.mapToItem(gridView, 0, 0, item.width, item.height)

                overlay.itemRect = rect
                // console.debug('adjust to center of ', item);

                var centerX = rect.x + rect.width / 2
                var centerY = rect.y + rect.height / 2

                x = rect.x + (rect.width - width) / 2
                y = rect.y + (rect.height - height) / 2

                // console.debug('adjust to center: x = ', x, 'y = ', y);

                start = Qt.point(centerX, centerY);
            }

            function getCenter() {
                return Qt.point(x + width / 2, y + height / 2)
            }

            property point start;
            property point lastMousePos;
            property var allowedTargets: []

            function updateAllowedTargets(modelIndex) {
                // console.debug('updating allowed positions for modelIndex: ', modelIndex)

                allowedTargets = [];

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
                            allowedTargets.push(targetItem);
                        }
                    }
                }

                for(var i = 0; i < allowedTargets.length; ++i) {
                    console.debug('allowed: ', allowedTargets[i])
                }
            }

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
                dragHandle.start = Qt.point(0, 0);
                dragHandle.allowedTargets = []
                dragArea.selectedItems = []
                dragArea.selectedItemIndex = -1

                for(var i = 0; i < gridView.model.count; ++i)
                    gridView.model.get(i).selected = false

                overlay.itemRect = Qt.rect(0, 0, 0, 0)
            }
        }
    }
}
