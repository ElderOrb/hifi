import QtQuick 2.0
import QtQuick.Controls 2.2

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

                console.debug('paint: start = ', start, 'end = ', end)

                var ctx = getContext("2d")

                ctx.reset();

                if(selectedItems.length != 0) {
                    ctx.beginPath()
                    ctx.strokeStyle = centerColor
                    ctx.lineWidth = innerRadius * 2

                    for(var i = 0; i < selectedItems.length; ++i) {
                        var item = selectedItems[i];
                        var delegateItem = item.item
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
                ctx.lineWidth = innerRadius * 2
                ctx.moveTo(start.x, start.y)
                ctx.lineTo(end.x, end.y)
                ctx.stroke()
            }

            property point start: dragHandle.start
            onStartChanged: {
                console.debug('start = ', start, 'end = ', end)
            }

            property point end: dragHandle.getCenter()
            onEndChanged: {
                console.debug('start = ', start, 'end = ', end)
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

            model: ListModel {
                ListElement {
                    property bool selected: false
                    property int index: 0
                }
                ListElement {
                    property bool selected: false
                    property int index: 1
                }
                ListElement {
                    property bool selected: false
                    property int index: 2
                }
                ListElement {
                    property bool selected: false
                    property int index: 3
                }
                ListElement {
                    property bool selected: false
                    property int index: 4
                }
                ListElement {
                    property bool selected: false
                    property int index: 5
                }
                ListElement {
                    property bool selected: false
                    property int index: 6
                }
                ListElement {
                    property bool selected: false
                    property int index: 7
                }
                ListElement {
                    property bool selected: false
                    property int index: 8
                }
            }

            delegate: Item {
                id: delegate
                objectName: "delegate" + index

                width: GridView.view.cellWidth
                height: GridView.view.cellHeight

                function containsMouse(point) {
                    var mapped = outerCircle.mapFromGlobal(point.x, point.y)

                    console.debug('mapped: ', mapped)
                    var containsResult = outerCircle.contains(mapped)
                    console.debug('contains: ', containsResult)

                    return containsResult;
                }

                Rectangle {
                    id: outerCircle
                    anchors.centerIn: parent
                    width: outerRadius * 2
                    height: outerRadius * 2
                    radius: outerRadius
                    antialiasing: true
                    color: 'black'

                    Rectangle {
                        id: circle

                        anchors.centerIn: parent
                        width: innerRadius * 2
                        height: innerRadius * 2
                        radius: innerRadius
                        color: centerColor
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

        Canvas {
            id: overlay
            anchors.fill: parent

            onPaint: {

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

                /*
                var context = getContext("2d");

                // Make canvas all white
                context.beginPath();
                context.clearRect(0, 0, width, height);
                context.fill();

                // Fill inside with blue, leaving 10 pixel border
                context.beginPath();
                context.fillStyle = "blue"
                context.fillRect(10, 10, width - 20, height - 20);
                context.fill();

                // Draw a line
                context.beginPath();
                context.lineWidth = 2;
                context.moveTo(30, 30);
                context.strokeStyle = "red"
                context.lineTo(width-30, height-30);
                context.stroke();

                // Draw a circle
                context.beginPath();
                context.fillStyle = "orange"
                context.strokeStyle = "red"
                context.moveTo(width/2+60, height/2);
                context.arc(width/2, height/2, 60, 0, 2*Math.PI, true)
                context.fill();
                context.stroke();

                // Draw some text
                context.beginPath();
                context.strokeStyle = "lime green"
                context.font = "20px sans-serif";
                context.text("Hello, world!", width/2, 50);
                context.stroke();
                */
            }

            property rect itemRect: Qt.rect(0, 0, 0, 0);
            onItemRectChanged: {
                console.debug('rect = ', itemRect);
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
            property var selectionCandidate;
            property var selectionCandidateItem;

            onSelectionCandidateChanged: {
                console.debug('selectionCandidate: ', selectionCandidate);
                if(selectionCandidate) {
                    console.debug('starting timer...');
                    selectionTimer.restart();
                } else {
                    console.debug('stopping timer...');
                    selectionTimer.stop();
                }
            }

            property var selectedItems: []

            Timer {
                id: selectionTimer
                repeat: false
                interval: 200
                onTriggered: {
                    console.debug('timer triggered!!!');

                    parent.selectionCandidate.selected = true;
                    parent.selectedItems.push({
                                                  'index: ' : parent.selectionCandidate.index,
                                                  'item' : parent.selectionCandidateItem
                                              });

                    dragHandle.adjustToCenter(parent.selectionCandidateItem)
                    dragHandle.updateAllowedPositions(parent.selectionCandidate.index)
                }
            }

            onPositionChanged: {
                console.debug('positionChanged: ', mouse.x, mouse.y)

                dragHandle.adjustPosition(mouse);

                var centerOfDragItem = dragHandle.getCenter();
                var item = gridView.itemAt(centerOfDragItem.x, centerOfDragItem.y)
                var mappedPos = root.mapToGlobal(centerOfDragItem.x, centerOfDragItem.y);

                if(item && item.containsMouse(mappedPos)) {
                    var modelIndex = gridView.indexAt(centerOfDragItem.x, centerOfDragItem.y)
                    var modelItem = gridView.model.get(modelIndex);

                    if(!modelItem.selected) {
                        // console.debug('selectionCandidate: ', selectionCandidate, 'modelItem: ', modelItem)

                        if(selectionCandidateIndex != modelItem.index) {
                            console.debug('selectionCandidateIndex != modelItem.index')

                            selectionCandidateIndex = modelItem.index
                            selectionCandidateItem = item
                            selectionCandidate = modelItem
                        }
                    }
                } else {
                    selectionCandidateIndex = -1
                    selectionCandidate = null
                    selectionCandidateItem = null
                }
            }

            onPressed: {
                var item = gridView.itemAt(mouse.x, mouse.y)

                if(item) {
                    var modelIndex = gridView.indexAt(mouse.x, mouse.y)
                    var modelItem = gridView.model.get(modelIndex);

                    selectionCandidateIndex = modelItem.index
                    selectionCandidateItem = item
                    selectionCandidate = modelItem

                    selectionCandidate.selected = true;
                    selectedItems.push({
                                           'index: ' : selectionCandidate.index,
                                           'item' : selectionCandidateItem
                                       });

                    dragHandle.adjustToCenter(selectionCandidateItem)
                    dragHandle.updateAllowedPositions(selectionCandidate.index)

                    dragging = true;
                }
            }
        }

        Rectangle {
            id: dragHandle

            function adjustToCenter(item) {
                var rect = item.mapToItem(gridView, 0, 0, item.width, item.height)

                overlay.itemRect = rect
                console.debug('adjust to center of ', item);

                var centerX = rect.x + rect.width / 2
                var centerY = rect.y + rect.height / 2

                x = rect.x + (rect.width - width) / 2
                y = rect.y + (rect.height - height) / 2

                console.debug('adjust to center: x = ', x, 'y = ', y);

                start = Qt.point(centerX, centerY);
            }

            function getCenter() {
                return Qt.point(x + width / 2, y + height / 2)
            }

            property point start;
            property point lastMousePos;
            property var allowedPositions: []

            function updateAllowedPositions(modelIndex) {
                console.debug('updating allowed positions for modelIndex: ', modelIndex)

                allowedPositions = [];
                var count = 9

                var row = Math.floor(modelIndex / 3)
                var column = modelIndex % 3

                var leftRow = Math.floor((modelIndex - 1) / 3);
                var rightRow = Math.floor((modelIndex + 1) / 3);
                var topColumn = ((modelIndex - 3) % 3)
                var bottomColumn = ((modelIndex + 3) % 3)

                var hasLeft = row == leftRow;
                if(hasLeft)
                    allowedPositions.push(Qt.point(x - gridView.cellWidth, y));

                var hasRight = row == rightRow
                if(hasRight)
                    allowedPositions.push(Qt.point(x + gridView.cellWidth, y));

                var hasTop = (modelIndex - 3) >= 0 && column == topColumn
                if(hasTop)
                   allowedPositions.push(Qt.point(x, y - gridView.cellHeight));

                var hasBottom = (modelIndex + 3) < count && column == bottomColumn;
                if(hasBottom)
                   allowedPositions.push(Qt.point(x, y + gridView.cellHeight));

                if(hasLeft && hasTop)
                    allowedPositions.push(Qt.point(x - gridView.cellWidth, y - gridView.cellHeight));

                if(hasRight && hasTop)
                    allowedPositions.push(Qt.point(x + gridView.cellWidth, y - gridView.cellHeight));

                if(hasLeft && hasBottom)
                    allowedPositions.push(Qt.point(x - gridView.cellWidth, y + gridView.cellHeight));

                if(hasRight && hasBottom)
                    allowedPositions.push(Qt.point(x + gridView.cellWidth, y + gridView.cellHeight));

                for(var i = 0; i < allowedPositions.length; ++i) {
                    console.debug('allowed: ', allowedPositions[i])
                }
            }

            property point invalidTarget: Qt.point(-1, -1)
            property point target: invalidTarget
            property double k: 0;

            color: dragArea.drag.active ? highlightColor : 'transparent'
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

                console.debug('current: ', currentVector, 'allowedPositions: ', allowedPositions.length);

                var biggestCos = -1;
                var biggestCosIndex = 0;

                for(var i = 0; i < allowedPositions.length; ++i) {
                    var allowedPos = allowedPositions[i];
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
                    target = allowedPositions[biggestCosIndex];
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
                dragArea.selectedItems = []
                dragArea.selectionCandidateIndex = -1
                dragArea.selectionCandidateItem = null
                dragArea.selectionCandidate = null

                for(var i = 0; i < gridView.model.count; ++i)
                    gridView.model.get(i).selected = false

                overlay.itemRect = Qt.rect(0, 0, 0, 0)
            }
        }
    }
}
