import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQml.Models 2.1

Rectangle {
    anchors.fill: parent
    id: root

    property int buttonAreaHeight: 50


    property color centerColor: 'lightGray'

    property int outerRadius: 50
    property int innerRadius: 18
    property int highlightRadius: 6

    property color pointerColor: 'lightBlue'
    property color highlightColor: 'lime green'
    property color highlightItemColor: 'transparent'
    property double itemOpacity: 0.8

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
            cellWidth: parent.width / 3
            cellHeight: parent.height / 3
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

                        function containsMouse(point) {
                            var mapped = outerCircle.mapFromGlobal(point.x, point.y)

                            // console.debug('mapped: ', mapped)
                            var containsResult = outerCircle.contains(mapped)
                            // console.debug('contains: ', containsResult)

                            return containsResult;
                        }

                        function getCenter() {
                            return Qt.point(x + width / 2, y + height / 2)
                        }

                        Rectangle {
                            id: outerCircle
                            anchors.centerIn: parent
                            width: outerRadius * 2
                            height: outerRadius * 2
                            radius: outerRadius
                            antialiasing: true
                            color: 'black'
                            opacity: itemOpacity

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

                            rotation: {
                                var angle = getRotationAngle();
                                console.debug('angle: ', angle)
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

                            Text {
                                anchors.right: outerCircle.right
                                anchors.verticalCenter: outerCircle.verticalCenter
                                color: highlightColor
                                font.bold: true
                                font.pointSize: outerRadius / 3
                                text: ">"
                                visible: parent.nextItemIndex() !== -1
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
                    for(var i = 0; i < 9; ++i) {
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

            property int selectionCandidateIndex;
            onSelectionCandidateIndexChanged: {
                if(selectionCandidateIndex != -1) {
                    // console.debug('starting timer...');
                    selectionTimer.restart();
                } else {
                    // console.debug('stopping timer...');
                    selectionTimer.stop();
                }
            }

            property var selectedItems: []
            property var selectedItemsRevision: 0

            Timer {
                id: selectionTimer
                repeat: false
                interval: 200
                onTriggered: {
                    // console.debug('timer triggered!!!');

                    gridView.model.get(parent.selectionCandidateIndex).selected = true;
                    parent.selectedItems.push(parent.selectionCandidateIndex);
                    parent.selectedItemsRevision++;

                    dragHandle.adjustToCenter(gridView.model.get(parent.selectionCandidateIndex))
                    dragHandle.updateAllowedTargets(parent.selectionCandidateIndex)
                }
            }

            onPositionChanged: {
                // console.debug('positionChanged: ', mouse.x, mouse.y)

                // dragHandle.adjustPosition(mouse);

                var centerOfDragItem = dragHandle.getCenter();
                var item = gridView.itemAt(centerOfDragItem.x, centerOfDragItem.y)
                var mappedPos = root.mapToGlobal(centerOfDragItem.x, centerOfDragItem.y);

                if(item && item.containsMouse(mappedPos)) {
                    var modelIndex = gridView.indexAt(centerOfDragItem.x, centerOfDragItem.y)
                    var modelItem = gridView.model.get(modelIndex);

                    if(!modelItem.selected) {
                        if(selectionCandidateIndex !== modelItem.index) {
                            selectionCandidateIndex = modelItem.index
                        }
                    }
                } else {
                    selectionCandidateIndex = -1
                }
            }

            onPressed: {
                var item = gridView.itemAt(mouse.x, mouse.y)

                if(item) {
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
                var count = 9

                for(var i = 0; i < gridView.model.count; ++i) {
                    if(gridView.model.get(i).selected)
                        continue;

                    allowedTargets.push(gridView.model.get(i))
                }

                /*
                for(var i = 0; i < allowedTargets.length; ++i) {
                    console.debug('allowed: ', allowedTargets[i])
                }
                */
            }

            property point invalidTarget: Qt.point(-1, -1)
            property point target: invalidTarget
            property double k: 0;

            color: dragArea.drag.active ? highlightItemColor : 'transparent'
            height: 40
            width: 40
            radius: 20

            function adjustPosition(mouse) {

                lastMousePos = Qt.point(mouse.x, mouse.y);

                var mouseX = mouse.x;
                var mouseY = mouse.y;

                var currentVector = Qt.vector2d(mouseX, mouseY).minus(Qt.vector2d(start.x, start.y))
                if(currentVector.length() < 50)
                    return;

                console.debug('current: ', currentVector, 'allowedItems: ', allowedTargets.length);

                var biggestCos = -1;
                var biggestCosIndex = 0;

                for(var i = 0; i < allowedTargets.length; ++i) {
                    var allowedItem = allowedTargets[i];
                    var allowedPos = allowedItem.getCenter();

                    var expected = Qt.vector2d(allowedPos.x, allowedPos.y).minus(Qt.vector2d(start.x, start.y));
                    console.debug('expected: ', expected)

                    var cos = currentVector.dotProduct(expected) / (currentVector.length() * expected.length());
                    console.debug('cos: ', cos);

                    if(cos > biggestCos) {
                        biggestCos = cos;
                        biggestCosIndex = i;
                    }
                }

                var angle = Math.acos(biggestCos);
                console.debug('selected biggestCos: ', biggestCos, 'angle: ', angle)

                if(biggestCos < 0) {
                    x = start.x;
                    y = start.y
                } else {
                    var allowedItem = allowedTargets[biggestCosIndex];
                    target = allowedItem.getCenter()
                    k = (target.y - start.y) / (target.x - start.x)
                }

                var dx = x - start.x
                var dy = y - start.y

                if(Math.abs(dx) > Math.abs(dy)) {
                    y = k * dx + start.y
                } else {
                    x = dy / k + start.x
                }
            }
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
                dragArea.selectionCandidateIndex = -1

                for(var i = 0; i < gridView.model.count; ++i)
                    gridView.model.get(i).selected = false

                overlay.itemRect = Qt.rect(0, 0, 0, 0)
            }
        }
    }
}
