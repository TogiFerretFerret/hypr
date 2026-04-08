import QtQuick
import Quickshell
import Quickshell.Wayland
import "./shim"

ShellRoot {
    id: shellRoot

    property string themePath: Quickshell.shellDir
    readonly property var sddm: sddmShim.sddm
    readonly property var config: sddmShim.config
    readonly property var userModel: sddmShim.userModel
    readonly property var sessionModel: sddmShim.sessionModel
    property bool authenticated: false
    property bool sessionLocked: true

    SddmShim {
        id: sddmShim
        themePath: shellRoot.themePath
    }

    Connections {
        target: sddmShim.sddm
        function onLoginSucceeded() {
            shellRoot.authenticated = true
            shellRoot.sessionLocked = false

            if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== "") {
                Quickshell.execDetached(["hyprctl", "keyword", "misc:allow_session_lock_restore", "1"]);
            }
            Quickshell.execDetached(["loginctl", "unlock-session"]);
            quitTimer.start()
        }
    }

    Timer {
        id: quitTimer
        interval: 800
        onTriggered: Qt.quit()
    }

    Loader {
        active: true
        sourceComponent: Component {
            WlSessionLock {
                id: lock
                locked: shellRoot.sessionLocked
                surface: Component {
                    WlSessionLockSurface {
                        color: "black"
                        Loader {
                            anchors.fill: parent
                            source: "file://" + shellRoot.themePath + "/Main.qml"
                            onLoaded: item.forceActiveFocus()
                        }
                    }
                }
            }
        }
    }
}
