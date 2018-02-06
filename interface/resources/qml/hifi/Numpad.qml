import QtQuick 2.6
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
    property color dragHandleItemColor: showDragHandle.checked ? 'lime green' : 'transparent'
    property double itemOpacity: 0.8

    property int itemsCount: 9
    property int columnsCount: 3
    property int rowsCount: Math.ceil(itemsCount / columnsCount);

    property color allowedTargetIndicatorColor: 'black'
    property int allowedTargetIndicatorRadius : 4

    // implementation
    property var allowedTargets: []
    property int selectedItemIndex: -1
    property var selectedItemsIndexes: []

    function updateAllowedTargets(modelIndex) {
        // console.debug('updating allowed positions for modelIndex: ', modelIndex)

        var newAllowedTargets = [];

        var count = gridView.model.count;
        var row = Math.floor(modelIndex / columnsCount);
        var column = modelIndex % columnsCount;

        for(var r = 0; r < rowsCount; ++r) {
            for(var c = 0; c < columnsCount; ++c) {
                if(r === row && c === column) {
                    continue; // skip self
                }

                var index  = r * columnsCount + c;
                var targetItem = gridView.model.get(index);

                if(Math.abs(r - row) <= 1 && Math.abs(c - column) <= 1) { // close item
                    if(!targetItem.selected) {
                        newAllowedTargets.push(targetItem);
                    }
                } else {
                    if((c == column && r !== row) || // the same row
                       (r == row && c != column) || // the same column
                       (Math.abs(r - row) === Math.abs(c - column)) // the same diagonal
                    ) {
                        continue;
                    }

                    if(!targetItem.selected) {
                        newAllowedTargets.push(targetItem);
                    }
                }
            }
        }

        for(var i = 0; i < newAllowedTargets.length; ++i) {
            console.debug('allowed: ', newAllowedTargets[i]);
        }

        allowedTargets = newAllowedTargets;
    }

    function toDegree(radian) {
         return radian * (180 / Math.PI)
    }

    function getBestCandidate(mouse) {

        if(allowedTargets.length === 0)
            return null;

        var currentSelectedPos = gridView.model.get(selectedItemsIndexes[selectedItemsIndexes.length - 1]).getCenter();
        var currentVector = Qt.vector2d(mouse.x, mouse.y).minus(Qt.vector2d(currentSelectedPos.x, currentSelectedPos.y))

        // console.debug('current: ', currentVector, 'allowedItems: ', allowedTargets.length);

        var biggestCos = -1;
        var biggestCosIndex = 0;

        for(var i = 0; i < allowedTargets.length; ++i) {
            var allowedPos = allowedTargets[i].getCenter();

            var expected = Qt.vector2d(allowedPos.x, allowedPos.y).minus(Qt.vector2d(currentSelectedPos.x, currentSelectedPos.y));
            // console.debug('expected: ', expected)

            var cos = currentVector.dotProduct(expected) / (currentVector.length() * expected.length());
            // console.debug('cos: ', cos);

            if(cos > biggestCos) {
                biggestCos = cos;
                biggestCosIndex = i;
            }
        }

        var angle = toDegree(Math.acos(biggestCos));
        var target = allowedTargets[biggestCosIndex]
        var center = target.getCenter()

        return {
            'item': target,
            'angle': angle,
            'center': center,
            'distance': Qt.vector2d(mouse.x, mouse.y).minus(Qt.vector2d(center.x, center.y)).length()
        }
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

                if(!dragArea.pressed)
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

            property var selectedItems: root.selectedItemsIndexes
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

                            var normalizedConnectionVector =  Qt.vector2d(nextItem.x, -nextItem.y).minus(Qt.vector2d(delegate.x, -delegate.y)).normalized();
                            var normalizedXAxisVector = Qt.vector2d(1, 0).normalized();

                            var cos = normalizedConnectionVector.dotProduct(normalizedXAxisVector);
                            var angle = Math.acos(cos) * (180 / Math.PI);

                            // console.debug('rotationAngle: ', angle, 'normalizedConnectionVector.y < 0: ', normalizedConnectionVector.y < 0);
                            if(normalizedConnectionVector.y > 0)
                                angle = -angle

                            return angle;
                        }

                        function nextItemIndex() {
                            var indexOfIndex = selectedItemsIndexes.indexOf(index);
                            if(indexOfIndex === -1)
                                return -1

                            if(indexOfIndex >= (selectedItemsIndexes.length - 1))
                                return -1

                            return selectedItemsIndexes[indexOfIndex + 1]
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
                                rotation: getRotationAngle()

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
                                    visible: allowedTargets.indexOf(delegate) !== -1
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

            property var mousePosDuringSelection: Qt.point(0, 0)

            function selectItem(item, mouse) {
                mousePosDuringSelection = Qt.point(mouse.x, mouse.y)
                selectedItemIndex = item.index
                item.selected = true;

                var newSelectedItems = selectedItemsIndexes.slice(); // this is required to make bindings work
                newSelectedItems.push(selectedItemIndex);
                selectedItemsIndexes = newSelectedItems;

                dragHandle.adjustToCenter(item)
                updateAllowedTargets(selectedItemIndex)
            }

            onPositionChanged: {
                var centerOfDragItem = dragHandle.getCenter();
                var item = gridView.itemAt(centerOfDragItem.x, centerOfDragItem.y)

                if(item && item.containsMouse(mapToItem(null, centerOfDragItem.x, centerOfDragItem.y))) {
                    if (allowedTargets.indexOf(item) !== -1 && !item.selected && selectedItemIndex !== item.index) {
                        selectItem(item, mouse)
                    }
                } else {
                    selectedItemIndex = selectedItemsIndexes.length !== 0 ? selectedItemsIndexes.slice(-1)[0] : -1
                }

                if(allowedTargets.length === 0) {
                    return;
                }

                if(selectedItemsIndexes.length > 1) {

                    var previousSelectedPos = gridView.model.get(selectedItemsIndexes[selectedItemsIndexes.length - 2]).getCenter();
                    var currentSelectedPos = gridView.model.get(selectedItemsIndexes[selectedItemsIndexes.length - 1]).getCenter();

                    var selectedDirection = Qt.vector2d(currentSelectedPos.x - previousSelectedPos.x, currentSelectedPos.y - previousSelectedPos.y);
                    var mouseDirection = Qt.vector2d(mouse.x - previousSelectedPos.x, mouse.y - previousSelectedPos.y);

                    var cos = selectedDirection.dotProduct(mouseDirection) / (selectedDirection.length() * mouseDirection.length());
                    var angle = toDegree(Math.acos(cos));

                    var candidate = getBestCandidate(mouse)
                    if(candidate !== null) {
                        var initialDistanceToCandidate = Qt.vector2d(mousePosDuringSelection.x, mousePosDuringSelection.y).minus(Qt.vector2d(candidate.center.x, candidate.center.y)).length();
                        // console.debug('candidate angle: ', candidate.angle, 'candidate distance: ', candidate.distance, 'initial distance: ', initialDistanceToCandidate);

                        if(candidate.angle > 90)
                            return;

                        if(candidate.distance >= initialDistanceToCandidate)
                            return;

                        if(snapToPath.checked)
                            dragHandle.adjustToAllowedPath(mouse, candidate)
                        else
                            dragHandle.moveCenter(mouse)
                    }
                } else {
                    dragHandle.moveCenter(mouse)
                }
            }

            onPressed: {
                var item = gridView.itemAt(mouse.x, mouse.y)
                console.debug('pressed: ', mouse.x, mouse.y, 'global: ', dragArea.mapToGlobal(mouse.x, mouse.y), 'window: ', dragArea.mapToItem(null, mouse.x, mouse.y))

                if(item && item.containsMouse(mapToItem(null, mouse.x, mouse.y))) {
                    selectItem(item, mouse)
                }
            }
        }

        Rectangle {
            id: dragHandle

            visible: selectedItemIndex !== -1

            function isCenteredIn(item) {
                var rect = item.mapToItem(gridView, 0, 0, item.width, item.height)
                var centerX = rect.x + (rect.width - width) / 2;
                var centerY = rect.y + (rect.height - height) / 2;

                return x === centerX && y === centerY;
            }

            function adjustToCenter(item) {
                var rect = item.mapToItem(gridView, 0, 0, item.width, item.height)

                x = rect.x + (rect.width - width) / 2
                y = rect.y + (rect.height - height) / 2
            }

            function getCenter() {
                return Qt.point(x + width / 2, y + height / 2)
            }

            function moveCenter(pos) {
                x = pos.x - width / 2
                y = pos.y - height / 2
            }

            function adjustToAllowedPath(mouse, candidate) {

                if(candidate === null)
                    return;

                var currentSelectedPos = gridView.model.get(selectedItemsIndexes[selectedItemsIndexes.length - 1]).getCenter();

                var newX = mouse.x;
                var newY = mouse.y;

                var k = (candidate.center.y - currentSelectedPos.y) / (candidate.center.x - currentSelectedPos.x)

                var dx = newX - currentSelectedPos.x
                var dy = newY - currentSelectedPos.y

                if(Math.abs(dx) > Math.abs(dy)) {
                    newY = k * dx + currentSelectedPos.y
                } else {
                    newX = dy / k + currentSelectedPos.x
                }

                moveCenter(Qt.point(newX, newY))
            }

            color: dragArea.pressed ? dragHandleItemColor : 'transparent'
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

        Row {
            anchors.horizontalCenter: parent.horizontalCenter

            CheckBox {
                id: snapToPath
                text: "Snap to allowed path"

                contentItem: Text {
                    text: snapToPath.text
                    font: snapToPath.font
                    color: 'white'
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: snapToPath.indicator.width + snapToPath.spacing
                }
            }

            CheckBox {
                id: showDragHandle
                text: "Show drag handle"
                checked: true

                contentItem: Text {
                    text: showDragHandle.text
                    font: showDragHandle.font
                    color: 'white'
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: showDragHandle.indicator.width + showDragHandle.spacing
                }
            }

            Button {
                text: "X";
                onClicked: {
                    allowedTargets = []
                    selectedItemsIndexes = []
                    selectedItemIndex = -1

                    for(var i = 0; i < gridView.model.count; ++i)
                        gridView.model.get(i).selected = false
                }
            }

        }
    }
}
