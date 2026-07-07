import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: false

    ContentSection {
        icon: "lock"
        title: Translation.tr("General")

        ConfigSwitch {
            buttonIcon: "lock_outline"
            text: Translation.tr("Use Hyprlock instead of Quickshell")
            checked: Config.options.lock.useHyprlock
            onCheckedChanged: {
                Config.options.lock.useHyprlock = checked;
            }
            StyledToolTip {
                text: Translation.tr("Enforce the use of the external Hyprlock over the default Quickshell lockscreen overlay.")
            }
        }

        ConfigSwitch {
            buttonIcon: "power_settings_new"
            text: Translation.tr("Launch on startup")
            checked: Config.options.lock.launchOnStartup
            onCheckedChanged: {
                Config.options.lock.launchOnStartup = checked;
            }
            StyledToolTip {
                text: Translation.tr("Start the lock screen daemon when the session begins.")
            }
        }
    }

    ContentSection {
        icon: "security"
        title: Translation.tr("Security")

        ConfigSwitch {
            buttonIcon: "password"
            text: Translation.tr("Require password to power off/restart")
            checked: Config.options.lock.security.requirePasswordToPower
            onCheckedChanged: {
                Config.options.lock.security.requirePasswordToPower = checked;
            }
            StyledToolTip {
                text: Translation.tr("Block the system power menu until the screen is unlocked.")
            }
        }

        ConfigSwitch {
            buttonIcon: "key"
            text: Translation.tr("Also unlock keyring")
            checked: Config.options.lock.security.unlockKeyring
            onCheckedChanged: {
                Config.options.lock.security.unlockKeyring = checked;
            }
            StyledToolTip {
                text: Translation.tr("Automatically unlock the login keyring when unlocking the session.")
            }
        }
    }

    ContentSection {
        icon: "notifications"
        title: Translation.tr("Notifications")

        ConfigSwitch {
            buttonIcon: "notifications"
            text: Translation.tr("Show notifications on lock screen")
            checked: Config.options.lock.notifications.enable
            onCheckedChanged: {
                Config.options.lock.notifications.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Anyone with physical access to the machine will be able to see them.")
            }
        }

        ContentSubsection {
            title: Translation.tr("Position")
            icon: "picture_in_picture"
            Layout.fillWidth: true

            ConfigSelectionArray {
                currentValue: Config.options.lock.notifications.position
                onSelected: newValue => {
                    Config.options.lock.notifications.position = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Top left"),
                        icon: "north_west",
                        value: "top_left"
                    },
                    {
                        displayName: Translation.tr("Top right"),
                        icon: "north_east",
                        value: "top_right"
                    },
                    {
                        displayName: Translation.tr("Bottom left"),
                        icon: "south_west",
                        value: "bottom_left"
                    },
                    {
                        displayName: Translation.tr("Bottom right"),
                        icon: "south_east",
                        value: "bottom_right"
                    }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Privacy level")
            icon: "visibility"
            Layout.fillWidth: true

            ConfigSelectionArray {
                currentValue: Config.options.lock.notifications.privacy
                onSelected: newValue => {
                    Config.options.lock.notifications.privacy = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Full content"),
                        icon: "visibility",
                        value: "full"
                    },
                    {
                        displayName: Translation.tr("Hide content"),
                        icon: "visibility_off",
                        value: "redacted"
                    },
                    {
                        displayName: Translation.tr("Count only"),
                        icon: "numbers",
                        value: "countOnly"
                    }
                ]
            }
        }

        ConfigSwitch {
            buttonIcon: "history"
            text: Translation.tr("Only notifications received while locked")
            checked: Config.options.lock.notifications.onlySinceLock
            onCheckedChanged: {
                Config.options.lock.notifications.onlySinceLock = checked;
            }
        }

        ConfigSpinBox {
            icon: "format_list_numbered"
            text: Translation.tr("Maximum notifications shown")
            value: Config.options.lock.notifications.maxShown
            from: 1
            to: 10
            stepSize: 1
            onValueChanged: {
                Config.options.lock.notifications.maxShown = value;
            }
        }

        ContentSubsection {
            title: Translation.tr("App list")
            icon: "apps"
            Layout.fillWidth: true

            ConfigSelectionArray {
                currentValue: Config.options.lock.notifications.appListMode
                onSelected: newValue => {
                    Config.options.lock.notifications.appListMode = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Blocklist"),
                        icon: "block",
                        value: "blocklist"
                    },
                    {
                        displayName: Translation.tr("Allowlist"),
                        icon: "check_circle",
                        value: "allowlist"
                    }
                ]
            }

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("App names, one per line")
                wrapMode: TextEdit.NoWrap
                Component.onCompleted: text = Config.options.lock.notifications.appList.join("\n")
                onTextChanged: {
                    Config.options.lock.notifications.appList = text.split("\n").map(line => line.trim()).filter(line => line.length > 0);
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Filters")
            icon: "filter_alt"
            Layout.fillWidth: true

            ConfigSwitch {
                buttonIcon: "hourglass_disabled"
                text: Translation.tr("Hide transient notifications")
                checked: Config.options.lock.notifications.filters.skipTransient
                onCheckedChanged: {
                    Config.options.lock.notifications.filters.skipTransient = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "low_priority"
                text: Translation.tr("Hide low-urgency notifications")
                checked: Config.options.lock.notifications.filters.skipLowUrgency
                onCheckedChanged: {
                    Config.options.lock.notifications.filters.skipLowUrgency = checked;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Critical notifications")
            icon: "priority_high"
            Layout.fillWidth: true

            ConfigSelectionArray {
                currentValue: Config.options.lock.notifications.filters.criticalOverride
                onSelected: newValue => {
                    Config.options.lock.notifications.filters.criticalOverride = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Always show full"),
                        icon: "priority_high",
                        value: "full"
                    },
                    {
                        displayName: Translation.tr("No exception"),
                        icon: "do_not_disturb_on",
                        value: "none"
                    }
                ]
            }
        }
    }

    ContentSection {
        icon: "style"
        title: Translation.tr("Style: General")

        ConfigSwitch {
            buttonIcon: "align_horizontal_center"
            text: Translation.tr("Center clock")
            checked: Config.options.lock.centerClock
            onCheckedChanged: {
                Config.options.lock.centerClock = checked;
            }
            StyledToolTip {
                text: Translation.tr("Position the clock directly in the center of the screen.")
            }
        }

        ConfigSwitch {
            buttonIcon: "text_fields"
            text: Translation.tr("Show \"Locked\" text")
            checked: Config.options.lock.showLockedText
            onCheckedChanged: {
                Config.options.lock.showLockedText = checked;
            }
            StyledToolTip {
                text: Translation.tr("Display an explicit indicator text below the password field.")
            }
        }

        ConfigSwitch {
            buttonIcon: "category"
            text: Translation.tr("Use varying shapes for password characters")
            checked: Config.options.lock.materialShapeChars
            onCheckedChanged: {
                Config.options.lock.materialShapeChars = checked;
            }
            StyledToolTip {
                text: Translation.tr("Replace the standard dots with random Material You shapes when typing the password.")
            }
        }
    }

    ContentSection {
        icon: "blur_on"
        title: Translation.tr("Style: Blurred")

        ConfigSwitch {
            buttonIcon: "lens_blur"
            text: Translation.tr("Enable blur")
            checked: Config.options.lock.blur.enable
            onCheckedChanged: {
                Config.options.lock.blur.enable = checked;
            }
        }

        ConfigSpinBox {
            enabled: Config.options.lock.blur.enable
            icon: "zoom_in"
            text: Translation.tr("Extra wallpaper zoom (%)")
            value: Config.options.lock.blur.extraZoom * 100
            from: 0
            to: 100
            stepSize: 5
            onValueChanged: {
                Config.options.lock.blur.extraZoom = value / 100;
            }
        }
    }
}
