import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import SddmComponents 2.0

Item {
    id: root
    width: Screen.width
    height: Screen.height

    readonly property real s: Screen.height / 1200

    // --- PALETTE ---
    readonly property color accent: "#5093e3"
    readonly property color secondary: "#f1afff"
    readonly property color dim: "#8899aa"
    readonly property color bg: "#111418"

    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property real uiOpacity: 0
    property bool sessionPopupOpen: false
    property bool loginError: false

    TextConstants { id: textConstants }

    // --- HELPERS (hidden ListViews to bridge model data) ---
    ListView {
        id: sessionHelper; model: sessionModel; currentIndex: root.sessionIndex
        visible: false; width: 1; height: 1; z: -100
        delegate: Item { property string sName: model.name || "" }
    }
    ListView {
        id: userHelper; model: userModel; currentIndex: root.userIndex
        visible: false; width: 1; height: 1; z: -100
        delegate: Item {
            property string uName: model.realName || model.name || ""
            property string uLogin: model.name || ""
        }
    }

    // --- BOOT ---
    Component.onCompleted: fadeIn.start()
    Timer { interval: 300; running: true; onTriggered: passInput.forceActiveFocus() }
    NumberAnimation {
        id: fadeIn; target: root; property: "uiOpacity"
        from: 0; to: 1; duration: 1800; easing.type: Easing.OutCubic
    }

    // --- BACKGROUND ---
    Rectangle { anchors.fill: parent; color: root.bg; z: -1000 }

    Image {
        id: bgImage
        anchors.fill: parent
        source: "bg.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true; cache: true; mipmap: true
    }

    // --- GLASS ENGINE ---
    ShaderEffectSource {
        id: bgSource; sourceItem: bgImage
        visible: false; live: true; recursive: false
    }
    FastBlur {
        id: globalBlur; anchors.fill: parent
        source: bgSource; radius: 80; visible: true; z: -999
    }

    // Dark frosted glass — matches quickshell/ghostty aesthetic
    component GlassPanel: Item {
        id: gp
        property real glassRadius: 14 * s
        property color panelColor: "#15141E"
        property real panelOpacity: 0.30
        property color borderColor: "#18ffffff"
        property real borderWidth: 1.0 * s
        property bool hovered: false

        anchors.fill: parent

        Rectangle { id: maskRect; anchors.fill: parent; radius: gp.glassRadius; visible: false }

        ShaderEffectSource {
            id: localBlur; sourceItem: globalBlur; visible: false
            sourceRect: {
                var pos = gp.mapToItem(root, 0, 0);
                return Qt.rect(pos.x, pos.y, gp.width, gp.height);
            }
        }

        OpacityMask { anchors.fill: parent; source: localBlur; maskSource: maskRect }

        Rectangle {
            anchors.fill: parent; radius: gp.glassRadius
            color: gp.panelColor; opacity: gp.panelOpacity
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        Rectangle {
            anchors.fill: parent; radius: gp.glassRadius
            color: "transparent"
            border.color: gp.hovered ? "#30ffffff" : gp.borderColor
            border.width: gp.borderWidth
            Behavior on border.color { ColorAnimation { duration: 200 } }
        }
    }

    // --- VIGNETTE ---
    RadialGradient {
        anchors.fill: parent; opacity: 0.6; z: -998
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#cc000000" }
        }
    }

    // =========================================================================
    //  BLIMP CLOCK — perspective-matched overlay on the airship display
    // =========================================================================
    Item {
        id: blimpClock
        // CALIBRATION MODE — 4 corner markers for the blimp clock face
        // Adjust these until they sit on the 4 corners of the "11:59" display
        // Quad corners (calibrated):
        // TL(0.570,0.320) TR(0.655,0.319) BL(0.575,0.385) BR(0.6566,0.3867)
        // Center ≈ (0.6133, 0.3526), size ≈ 163x80 px on 1920x1200

        x: root.width * 0.6153 - width/2
        y: root.height * 0.3526 - height/2
        width: root.width * 0.080
        height: root.height * 0.090
        opacity: root.uiOpacity

        transform: [
            Rotation {
                origin.x: blimpClock.width / 2
                origin.y: blimpClock.height / 2
                axis { x: 0.04; y: 0.2; z: 0.0 }
                angle: 15
            }
        ]

        // Pixelated clock: render small, scale up with no smoothing
        Item {
            anchors.centerIn: parent
            width: clockText.width * clockText.pixelScale
            height: clockText.height * clockText.pixelScale

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                color: "#aa4488cc"; radius: 12 * s; samples: 25
                horizontalOffset: 0; verticalOffset: 0
            }

            Column {
                anchors.centerIn: parent
                spacing: 12

            Text {
                id: clockText
                property real pixelScale: 2.5
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(new Date(), "hh:mm")
                color: "#CECFD3"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18; font.weight: Font.Bold
                font.letterSpacing: 1
                smooth: false
                antialiasing: false
                renderType: Text.NativeRendering
                style: Text.Raised; styleColor: "#60000000"
                transform: Scale {
                    xScale: clockText.pixelScale
                    yScale: clockText.pixelScale
                    origin.x: clockText.width / 2
                    origin.y: clockText.height / 2
	    }
	    Timer {
    interval: 1000; running: true; repeat: true
    onTriggered: {
        let now = new Date();
        // Combining them into one string ensures 12-hour formatting
        let formatted = Qt.formatTime(now, "h:mm ap"); // e.g., "10:22 pm"
        
        // If you need them in separate text fields, split them like this:
        let parts = formatted.split(" ");
        clockText.text = parts[0];
        ampmText.text = parts[1] + ".";
    }
}

                
            }
            Text {
                id: ampmText
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(new Date(), "ap") + "."
                color: "#CECFD3"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 8; font.weight: Font.Bold
                smooth: false
                antialiasing: false
                renderType: Text.NativeRendering
                style: Text.Raised; styleColor: "#60000000"
                transform: Scale {
                    xScale: clockText.pixelScale
                    yScale: clockText.pixelScale
                    origin.x: ampmText.width / 2
                    origin.y: ampmText.height / 2
                }
            }

            } // Column
        }
    }

    // Date + tagline — top left, no card, just floating text
    Column {
        x: 70 * s; y: 80 * s
        opacity: root.uiOpacity
        spacing: 6 * s

        Text {
            text: "ぼっち・ざ・ろっく！"
            color: root.secondary; opacity: 0.5
            font.pixelSize: 16 * s; font.letterSpacing: 3 * s
        }
        Row {
            spacing: 10 * s
            Rectangle {
                width: 24 * s; height: 1 * s; color: root.accent
                anchors.verticalCenter: parent.verticalCenter; opacity: 0.5
            }
            Text {
                text: Qt.formatDate(new Date(), "dddd · MMMM d").toUpperCase()
                color: root.accent; opacity: 0.6
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14 * s; font.letterSpacing: 3 * s
            }
            Rectangle {
                width: 24 * s; height: 1 * s; color: root.accent
                anchors.verticalCenter: parent.verticalCenter; opacity: 0.5
            }
        }
    }

    // Bottom-right dark scrim so login text is readable
    RadialGradient {
        anchors.right: parent.right; anchors.bottom: parent.bottom
        width: parent.width * 0.7; height: parent.height * 0.7
        opacity: 0.95
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#bb000000" }
            GradientStop { position: 0.35; color: "#80000000" }
            GradientStop { position: 0.6; color: "#30000000" }
            GradientStop { position: 1.0; color: "transparent" }
        }
        horizontalOffset: width * 0.3
        verticalOffset: height * 0.3
    }

    // =========================================================================
    //  LOGIN PANEL — bottom right, floating terminal style
    // =========================================================================
    Column {
        id: loginPanel
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.rightMargin: 80 * s; anchors.bottomMargin: 80 * s
        width: 280 * s
        spacing: 0
        opacity: root.uiOpacity

        // Username
        Text {
            id: userDisplay
            anchors.right: parent.right
            text: userHelper.currentItem && userHelper.currentItem.uLogin
                  ? userHelper.currentItem.uLogin : "user"
            color: "white"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 22 * s; font.letterSpacing: 2 * s
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (userModel && userModel.rowCount() > 1)
                        root.userIndex = (root.userIndex + 1) % userModel.rowCount()
                }
            }
        }

        // Greeting
        Text {
            anchors.right: parent.right
            text: "w3lc0m3 b4ck!"
            color: root.secondary; opacity: 0.7
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10 * s; font.letterSpacing: 3 * s
        }

        Item { width: 1; height: 24 * s }

        // Password field
        Item {
            id: passCard
            width: parent.width; height: 36 * s

            TextInput {
                id: passInput
                anchors.left: parent.left; anchors.right: arrowHint.left
                anchors.rightMargin: 10 * s
                anchors.verticalCenter: parent.verticalCenter
                color: "white"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14 * s; font.letterSpacing: 2 * s
                echoMode: TextInput.Password; passwordCharacter: "·"
                focus: true; clip: true
                cursorVisible: false; cursorDelegate: Item { width: 0; height: 0 }
                selectionColor: root.accent

                property bool wasClicked: false
                onActiveFocusChanged: if (!activeFocus && text.length === 0) wasClicked = false
                Keys.onReturnPressed: doLogin()
                Keys.onEnterPressed: doLogin()

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "enter password"
                    color: "white"; opacity: passInput.text.length === 0 ? 0.35 : 0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14 * s; font.letterSpacing: 2 * s
                }

                Rectangle {
                    id: cursor
                    width: 2 * s; height: 16 * s; color: root.accent
                    anchors.verticalCenter: parent.verticalCenter
                    x: passInput.cursorRectangle.x
                    visible: passInput.focus && (passInput.text.length > 0 || passInput.wasClicked)
                    SequentialAnimation {
                        loops: Animation.Infinite; running: cursor.visible
                        NumberAnimation { target: cursor; property: "opacity"; from: 1; to: 0.05; duration: 450 }
                        NumberAnimation { target: cursor; property: "opacity"; from: 0.05; to: 1; duration: 450 }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: { passInput.forceActiveFocus(); passInput.wasClicked = true }
                }
            }

            Text {
                id: arrowHint
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "→"
                color: root.accent
                font.pixelSize: 16 * s
                opacity: passInput.text.length > 0 ? 1.0 : 0.2
                Behavior on opacity { NumberAnimation { duration: 200 } }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: doLogin()
                }
            }
        }

        // Focus line
        Rectangle {
            width: parent.width; height: 1 * s
            color: passInput.activeFocus ? root.accent : "#40ffffff"
            Behavior on color { ColorAnimation { duration: 300 } }
        }

        Item { width: 1; height: 10 * s }

        // Error
        Text {
            id: errorMsg
            anchors.right: parent.right
            text: ""; color: "#d06060"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10 * s; font.letterSpacing: 1 * s
        }

        Item { width: 1; height: 28 * s }

        // Bottom bar: session + power
        Rectangle {
            width: parent.width; height: 1 * s
            color: "#12ffffff"
        }

        Item { width: 1; height: 14 * s }

        Item {
            width: parent.width; height: 16 * s

            // Session (left)
            Row {
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                spacing: 8 * s
                Text {
                    text: "◈"; color: root.accent; font.pixelSize: 8 * s; opacity: 0.5
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "Hyprland"
                    color: "white"; opacity: 0.55
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10 * s; font.letterSpacing: 1 * s
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Power (right)
            Row {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                spacing: 20 * s

                Text {
                    text: "⟳"; color: "white"; opacity: 0.35
                    font.pixelSize: 14 * s
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onEntered: parent.opacity = 0.9
                        onExited: parent.opacity = 0.35
                        onClicked: sddm.reboot()
                    }
                }
                Text {
                    text: "⏻"; color: "white"; opacity: 0.35
                    font.pixelSize: 14 * s
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onEntered: parent.opacity = 0.9
                        onExited: parent.opacity = 0.35
                        onClicked: sddm.powerOff()
                    }
                }
            }
        }
    }

    // Shake animation on login fail
    Connections {
        target: sddm
        function onLoginFailed() {
            errorMsg.text = "authentication failed"
            passInput.text = ""
            passInput.forceActiveFocus()
            root.loginError = true
            shakeAnim.start()
            errorTimer.start()
        }
    }

    // =========================================================================
    //  NERV DECORATIONS — subtle corner tags
    // =========================================================================

    // Bottom-left: NERV system tag
    Column {
        anchors.left: parent.left; anchors.bottom: parent.bottom
        anchors.leftMargin: 40 * s; anchors.bottomMargin: 30 * s
        opacity: root.uiOpacity * 0.35
        spacing: 3 * s

        Text {
            text: "MAGI SYSTEM v3.01"
            color: root.accent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 9 * s; font.letterSpacing: 2 * s
        }
        Text {
            text: "CASPER · BALTHASAR · MELCHIOR"
            color: root.dim
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 8 * s; font.letterSpacing: 2 * s
        }
    }

    // Top-right: status tag
    Text {
        anchors.top: parent.top; anchors.right: parent.right
        anchors.topMargin: 30 * s; anchors.rightMargin: 40 * s
        text: "CLASSIFIED ACCESS ONLY"
        color: root.dim; opacity: root.uiOpacity * 0.3
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 9 * s; font.letterSpacing: 3 * s
    }

    Timer {
        id: errorTimer; interval: 3000
        onTriggered: { errorMsg.text = ""; root.loginError = false }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: passCard; property: "x"; to: 12; duration: 50 }
        NumberAnimation { target: passCard; property: "x"; to: -10; duration: 50 }
        NumberAnimation { target: passCard; property: "x"; to: 8; duration: 50 }
        NumberAnimation { target: passCard; property: "x"; to: -5; duration: 50 }
        NumberAnimation { target: passCard; property: "x"; to: 0; duration: 50 }
    }

    function doLogin() {
        var u = (userHelper.currentItem && userHelper.currentItem.uLogin)
                ? userHelper.currentItem.uLogin : userModel.lastUser
        sddm.login(u, passInput.text, root.sessionIndex)
    }
}
