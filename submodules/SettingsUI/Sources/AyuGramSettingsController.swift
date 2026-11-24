// AyuGram: settings screens.
//
// Laid out as in AyuGram Desktop (ayu/ui/settings): a main page with the logo, the categories
// and the links, and one page per category (AyuGram, Filters, General, Appearance, Chats, Other).
// Row titles, descriptions and icons are desktop's. Desktop-only rows (tray, window size, MD3
// switches) are left out; additions that only exist on iOS sit in the Other page.

import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import PromptUI
import AppBundle

// MARK: Pages

private enum AyuPage: Equatable {
    case main
    case ghost
    case filters
    case filterList
    case shadowBanList
    case general
    case appearance
    case chats
    case other

    var title: String {
        switch self {
        case .main:
            return ""
        case .ghost:
            return "AyuGram"
        case .filters:
            return "Filters"
        case .filterList:
            return "Shared Filters"
        case .shadowBanList:
            return "Shadow Ban"
        case .general:
            return "General"
        case .appearance:
            return "Appearance"
        case .chats:
            return "Chats"
        case .other:
            return "Other"
        }
    }

    static func named(_ name: String) -> AyuPage? {
        switch name {
        case "ghost":
            return .ghost
        case "filters":
            return .filters
        case "filterList":
            return .filterList
        case "shadowBanList":
            return .shadowBanList
        case "general":
            return .general
        case "appearance":
            return .appearance
        case "chats":
            return .chats
        case "other":
            return .other
        default:
            return nil
        }
    }
}

// MARK: Rows

private struct AyuSubItem: Equatable {
    let id: String
    let title: String
    let selected: Bool
}

private enum AyuRow: Equatable {
    case logo(title: String, text: String, iconName: String?)
    case header(String)
    case footer(String)
    case toggle(title: String, value: Bool, icon: String?)
    case expandable(title: String, value: Bool, expanded: Bool, subItems: [AyuSubItem], lockable: Bool)
    case value(title: String, label: String, icon: String?, arrow: Bool)
    case action(title: String, destructive: Bool)
    case appIcons(icons: [PresentationAppIcon], current: String?)
    case batteryLevel(value: Int32)
}

private final class AyuSettingsArguments {
    let toggle: (String, Bool) -> Void
    let activate: (String) -> Void
    let toggleExpanded: (String) -> Void
    let toggleSubItem: (String, String) -> Void
    let longPressSubItem: (String, String) -> Void
    let selectAppIcon: (PresentationAppIcon) -> Void
    let updateBatteryLevel: (String, Int32) -> Void

    init(toggle: @escaping (String, Bool) -> Void, activate: @escaping (String) -> Void, toggleExpanded: @escaping (String) -> Void, toggleSubItem: @escaping (String, String) -> Void, longPressSubItem: @escaping (String, String) -> Void, selectAppIcon: @escaping (PresentationAppIcon) -> Void, updateBatteryLevel: @escaping (String, Int32) -> Void) {
        self.toggle = toggle
        self.activate = activate
        self.toggleExpanded = toggleExpanded
        self.toggleSubItem = toggleSubItem
        self.longPressSubItem = longPressSubItem
        self.selectAppIcon = selectAppIcon
        self.updateBatteryLevel = updateBatteryLevel
    }
}

private func ayuRowIcon(_ name: String?, theme: PresentationTheme) -> UIImage? {
    guard let name = name else {
        return nil
    }
    return generateTintedImage(image: UIImage(bundleImageName: name), color: theme.list.itemPrimaryTextColor)
}

private struct AyuEntry: ItemListNodeEntry {
    let sectionIndex: Int32
    let sortIndex: Int32
    let id: String
    let row: AyuRow

    var section: ItemListSectionId {
        return self.sectionIndex
    }

    var stableId: String {
        return self.id
    }

    static func ==(lhs: AyuEntry, rhs: AyuEntry) -> Bool {
        return lhs.sectionIndex == rhs.sectionIndex && lhs.sortIndex == rhs.sortIndex && lhs.id == rhs.id && lhs.row == rhs.row
    }

    static func <(lhs: AyuEntry, rhs: AyuEntry) -> Bool {
        return lhs.sortIndex < rhs.sortIndex
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuSettingsArguments
        let id = self.id
        switch self.row {
        case let .logo(title, text, iconName):
            return AyuGramLogoHeaderItem(presentationData: presentationData, title: title, text: text, iconName: iconName, sectionId: self.section)
        case let .header(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .footer(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .toggle(title, value, icon):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, icon: ayuRowIcon(icon, theme: presentationData.theme), title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggle(id, value)
            })
        case let .expandable(title, value, expanded, subItems, lockable):
            let item = ItemListExpandableSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, value: value, isExpanded: expanded, subItems: subItems.map { subItem in
                return ItemListExpandableSwitchItem.SubItem(id: AnyHashable(subItem.id), title: subItem.title, isSelected: subItem.selected, isEnabled: true)
            }, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggle(id, value)
            }, selectAction: {
                arguments.toggleExpanded(id)
            }, subAction: { subItem in
                if let subId = subItem.id.base as? String {
                    arguments.toggleSubItem(id, subId)
                }
            })
            if lockable {
                item.subLongPressAction = { subItem in
                    if let subId = subItem.id.base as? String {
                        arguments.longPressSubItem(id, subId)
                    }
                }
            }
            return item
        case let .value(title, label, icon, arrow):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: ayuRowIcon(icon, theme: presentationData.theme), title: title, label: label, sectionId: self.section, style: .blocks, disclosureStyle: arrow ? .arrow : .none, action: {
                arguments.activate(id)
            })
        case let .action(title, destructive):
            return ItemListActionItem(presentationData: presentationData, systemStyle: .glass, title: title, kind: destructive ? .destructive : .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.activate(id)
            })
        case let .appIcons(icons, current):
            return ThemeSettingsAppIconItem(theme: presentationData.theme, strings: presentationData.strings, systemStyle: .glass, sectionId: self.section, icons: icons, isPremium: true, currentIconName: current, updated: { icon in
                arguments.selectAppIcon(icon)
            })
        case let .batteryLevel(value):
            return EnergyUsageBatteryLevelItem(systemStyle: .glass, theme: presentationData.theme, strings: presentationData.strings, value: value, sectionId: self.section, updated: { value in
                arguments.updateBatteryLevel(id, value)
            })
        }
    }
}

private final class AyuEntryBuilder {
    private(set) var entries: [AyuEntry] = []
    private var sectionIndex: Int32 = 0
    private var sortIndex: Int32 = 0

    func nextSection() {
        self.sectionIndex += 1
    }

    func add(_ id: String, _ row: AyuRow) {
        self.entries.append(AyuEntry(sectionIndex: self.sectionIndex, sortIndex: self.sortIndex, id: id, row: row))
        self.sortIndex += 1
    }

    /// Starts a new section with a title.
    func header(_ text: String) {
        self.nextSection()
        self.add("header-\(self.sectionIndex)", .header(text))
    }

    /// Explanation under the current section.
    func footer(_ text: String) {
        self.add("footer-\(self.sectionIndex)-\(self.sortIndex)", .footer(text))
    }

    /// A switch bound to a stored setting. `inverted` is for rows worded as the opposite of the setting.
    func toggle(_ key: AyuGramSettings.BoolKey, _ title: String, inverted: Bool = false, icon: String? = nil) {
        let stored = AyuGramSettings.bool(key)
        self.add((inverted ? "n:" : "k:") + key.rawValue, .toggle(title: title, value: inverted ? !stored : stored, icon: icon))
    }

    func value(_ id: String, _ title: String, _ label: String, icon: String? = nil, arrow: Bool = true) {
        self.add(id, .value(title: title, label: label, icon: icon, arrow: arrow))
    }
}

// MARK: Screen state

private final class AyuScreenState {
    var expanded = Set<String>()
    var accountCount: Int = 1
    var accountName: String = ""
}

private let ayuGhostOptions: [(key: AyuGramSettings.BoolKey, lock: AyuGramSettings.BoolKey, title: String, inverted: Bool)] = [
    (key: .sendReadMessages, lock: .lockSendReadMessages, title: "Don't Read Messages", inverted: true),
    (key: .sendReadStories, lock: .lockSendReadStories, title: "Don't Read Stories", inverted: true),
    (key: .sendOnlinePackets, lock: .lockSendOnlinePackets, title: "Don't Send Online", inverted: true),
    (key: .sendUploadProgress, lock: .lockSendUploadProgress, title: "Don't Send Typing", inverted: true),
    (key: .sendOfflinePacketAfterOnline, lock: .lockSendOfflinePacketAfterOnline, title: "Go Offline Automatically", inverted: false)
]

private let ayuSilentOptions: [String] = ["Never", "When using Ghost Mode", "Always"]
private let ayuPeerIdOptions: [String] = ["Hide", "Telegram API", "Bot API"]
private let ayuChannelButtonOptions: [String] = ["Hide", "Mute", "Discuss"]
private let ayuContextMenuOptions: [String] = ["Hidden", "Shown", "Extended Menu"]

/// Message menu rows of the Chats page. The two panels cannot move into a submenu, so they are only shown or hidden.
private let ayuContextMenuRows: [(key: AyuGramSettings.BoolKey, title: String, icon: String, extendable: Bool)] = [
    (key: .showReactionsPanelInContextMenu, title: "Reactions Panel", icon: "Ayu/MenuReactions", extendable: false),
    (key: .showViewsPanelInContextMenu, title: "Views Panel", icon: "Ayu/MenuShowInChat", extendable: false),
    (key: .showHideMessageInContextMenu, title: "Hide", icon: "Ayu/MenuClear", extendable: true),
    (key: .showUserMessagesInContextMenu, title: "User Messages", icon: "Ayu/MenuTTL", extendable: true),
    (key: .showMessageDetailsInContextMenu, title: "Details", icon: "Ayu/MenuInfo", extendable: true),
    (key: .showRepeatMessageInContextMenu, title: "Repeat Message", icon: "Ayu/Repeat", extendable: true),
    (key: .showSaveToSavedInContextMenu, title: "Save to Saved Messages", icon: "Chat/Context Menu/Fave", extendable: true),
    (key: .showSelectFromUserInContextMenu, title: "Select from User", icon: "Chat/Context Menu/SelectAll", extendable: true),
    (key: .showReplyPrivatelyInContextMenu, title: "Reply Privately", icon: "Chat/Context Menu/Reply", extendable: true),
    (key: .showAddFilterInContextMenu, title: "Add Filter", icon: "Ayu/MenuAddToFolder", extendable: true)
]

private func ayuSharedFilters() -> [String] {
    return AyuFilters.patterns.filter { entry in
        let pattern = ayuFilterPattern(entry)
        return !pattern.hasPrefix(AyuFilters.userPrefix) && !pattern.hasPrefix(AyuFilters.chatPrefix)
    }
}

/// A stored filter entry without its "disabled" marker.
private func ayuFilterPattern(_ entry: String) -> String {
    if entry.hasPrefix(AyuFilters.disabledPrefix) {
        return String(entry.dropFirst(AyuFilters.disabledPrefix.count))
    }
    return entry
}

private func ayuShadowBans() -> [String] {
    return AyuFilters.patterns.filter { $0.hasPrefix(AyuFilters.userPrefix) }
}

private func ayuChatFilters() -> [String] {
    return AyuFilters.patterns.filter { $0.hasPrefix(AyuFilters.chatPrefix) }
}

// MARK: Entries

private func ayuSettingsEntries(page: AyuPage, state: AyuScreenState, appIcons: [PresentationAppIcon], currentAppIcon: String?) -> [AyuEntry] {
    let b = AyuEntryBuilder()

    switch page {
    case .main:
        b.nextSection()
        let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
        b.add("logo", .logo(title: "AyuGram for iOS v\(version)", text: "Telegram for iOS fork focused on customization and ToS-breaking features.", iconName: currentAppIcon ?? "AyuDefault"))

        b.header("CATEGORIES")
        b.value("page:ghost", "AyuGram", "", icon: "Ayu/MenuGroupReactions")
        b.value("page:filters", "Filters", "", icon: "Ayu/MenuTagFilter")
        b.value("page:general", "General", "", icon: "Ayu/MenuShowAll")
        b.value("page:appearance", "Appearance", "", icon: "Ayu/MenuPalette")
        b.value("page:chats", "Chats", "", icon: "Ayu/MenuChatBubble")
        b.value("page:other", "Other", "", icon: "Ayu/MenuFave")

        b.header("LINKS")
        b.value("link:https://t.me/ayugram", "Channel", "@ayugram", icon: "Ayu/MenuChannel", arrow: false)
        b.value("link:https://t.me/ayugramchat", "Chats", "@ayugramchat", icon: "Ayu/MenuChats", arrow: false)
        b.value("link:https://translate.ayugram.one", "Translate", "Crowdin", icon: "Ayu/MenuTranslate", arrow: false)
        b.value("link:https://docs.ayugram.one", "Documentation", "docs.ayugram.one", icon: "Ayu/MenuIpAddress", arrow: false)

    case .ghost:
        b.header("GHOST ESSENTIALS")
        if state.accountCount > 1 {
            let isGlobal = AyuGramSettings.bool(.useGlobalGhostMode)
            b.value("ghostProfile", "Profile", isGlobal ? "Global Settings" : (state.accountName.isEmpty ? "This Account" : state.accountName))
        }
        var ghostSubItems: [AyuSubItem] = []
        for option in ayuGhostOptions {
            let stored = AyuGramSettings.bool(option.key)
            let locked = AyuGramSettings.bool(option.lock)
            ghostSubItems.append(AyuSubItem(id: option.key.rawValue, title: locked ? "\(option.title) \u{1F512}" : option.title, selected: option.inverted ? !stored : stored))
        }
        b.add("ghostMode", .expandable(title: "Ghost Mode", value: AyuGramSettings.isGhostModeActive, expanded: state.expanded.contains("ghostMode"), subItems: ghostSubItems, lockable: true))
        b.add("markRead", .toggle(title: "Read on Interact", value: AyuGramSettings.bool(.markReadAfterAction), icon: nil))
        let readOnInteractText = "Automatically marks a message as read when you send a new one or tap a reaction."
        if state.expanded.contains("ghostMode") {
            b.footer("Long-press any option to prevent it from changing when toggling Ghost Mode.\n\n\(readOnInteractText)")
        } else {
            b.footer(readOnInteractText)
        }

        b.nextSection()
        b.add("scheduled", .toggle(title: "Schedule Messages", value: AyuGramSettings.bool(.useScheduledMessages), icon: nil))
        b.footer("Automatically schedules outgoing messages to send after ~12 seconds (longer for media). Using this feature, you won't appear online.\nAvoid using on unreliable networks.")

        b.nextSection()
        b.value("silent", "Send without Sound", ayuSilentOptions[AyuGramSettings.sendWithoutSoundMode])
        b.footer("Sends outgoing messages without sound by default.")

        b.nextSection()
        b.toggle(.suggestGhostModeBeforeViewingStory, "Story Ghost Mode Alert")
        b.footer("Displays an alert before opening a story, suggesting you enable Ghost Mode.")

        b.header("SPY ESSENTIALS")
        b.toggle(.saveDeletedMessages, "Save Deleted Messages")
        b.toggle(.saveMessagesHistory, "Save Edits History")

        b.nextSection()
        b.toggle(.saveForBots, "Save in Bot Dialogs")

        b.header("OTHER")
        b.toggle(.localPremium, "Local Telegram Premium")
        b.toggle(.disableAds, "Disable Ads")
        b.footer("With local Telegram Premium, you won't get increased limits or be able to send animated emojis. It takes effect after restarting the app.")

    case .filters:
        b.header("MESSAGE FILTERS")
        b.toggle(.filtersEnabled, "Enable Filters")
        b.toggle(.filtersEnabledInChats, "Enable Shared Filters in Chats")
        b.toggle(.hideFromBlocked, "Hide from Blocked Users")

        b.nextSection()
        b.value("page:filterList", "Shared Filters", "")
        b.value("page:shadowBanList", "Shadow Ban", "")

        let chatFilters = ayuChatFilters()
        if !chatFilters.isEmpty {
            b.header("CHATS")
            for entry in chatFilters.prefix(100) {
                b.value("c:\(entry)", String(entry.dropFirst(AyuFilters.chatPrefix.count)), "", arrow: false)
            }
            b.footer("Filters added for a single chat. Tap one to remove it.")
        }

        b.nextSection()
        b.add("filters:import", .action(title: "Import", destructive: false))
        if !AyuFilters.patterns.isEmpty {
            b.add("filters:export", .action(title: "Export", destructive: false))
            b.add("filters:clear", .action(title: "Clear", destructive: true))
        }
        b.footer("Import pastes a filter list from the clipboard; Export copies yours to it.")

    case .filterList:
        b.nextSection()
        b.add("filters:add", .action(title: "Add Filter", destructive: false))
        let filters = ayuSharedFilters()
        if filters.isEmpty {
            b.footer("No filters here yet.")
        } else {
            b.header("FILTERS")
            for entry in filters.prefix(200) {
                b.value("f:\(entry)", ayuFilterPattern(entry), entry.hasPrefix(AyuFilters.disabledPrefix) ? "Disabled" : "", arrow: false)
            }
        }

    case .shadowBanList:
        b.nextSection()
        let bans = ayuShadowBans()
        if bans.isEmpty {
            b.add("shadowBanEmpty", .footer("No filters here yet."))
        } else {
            b.add("header-bans", .header("FILTERS"))
            for entry in bans.prefix(200) {
                b.value("u:\(entry)", String(entry.dropFirst(AyuFilters.userPrefix.count)), "", arrow: false)
            }
        }

    case .general:
        b.header("TRANSLATE MESSAGES")
        b.value("translator", "Translation Provider", AyuTranslator.provider.title)

        b.header("VOICE MESSAGES")
        b.toggle(.localTranscription, "Voice-to-Text on Device")
        b.footer("Transcribes voice messages on your device, without Telegram Premium. Asks for speech recognition access the first time.")

        b.header("GENERAL")
        b.toggle(.disableStories, "Disable Stories")
        b.toggle(.disableOpenLinkWarning, "Disable Open Link Warning")
        b.toggle(.clickableBioLinks, "Clickable Links in Bios")
        b.toggle(.confirmCalls, "Confirm Before Calling")
        let collapseSimilar = AyuGramSettings.bool(.collapseSimilarChannels)
        let hideSimilar = AyuGramSettings.bool(.hideSimilarChannels)
        b.add("similar", .expandable(title: "Disable Similar Channels", value: collapseSimilar && hideSimilar, expanded: state.expanded.contains("similar"), subItems: [
            AyuSubItem(id: "k:collapseSimilarChannels", title: "Collapse Similar Channels", selected: collapseSimilar),
            AyuSubItem(id: "k:hideSimilarChannels", title: "Hide Similar Channels Tab", selected: hideSimilar)
        ], lockable: false))

        b.nextSection()
        b.toggle(.filterZalgo, "Filter Zalgo")
        b.toggle(.improveLinkPreviews, "Improve Link Previews")
        let confirmSticker = AyuGramSettings.bool(.stickerConfirmation)
        let confirmGif = AyuGramSettings.bool(.gifConfirmation)
        let confirmVoice = AyuGramSettings.bool(.voiceConfirmation)
        let confirmRound = AyuGramSettings.bool(.roundConfirmation)
        b.add("confirm", .expandable(title: "Send Confirmations", value: confirmSticker || confirmGif || confirmVoice || confirmRound, expanded: state.expanded.contains("confirm"), subItems: [
            AyuSubItem(id: "k:stickerConfirmation", title: "Stickers", selected: confirmSticker),
            AyuSubItem(id: "k:gifConfirmation", title: "GIFs", selected: confirmGif),
            AyuSubItem(id: "k:voiceConfirmation", title: "Voice Messages", selected: confirmVoice),
            AyuSubItem(id: "k:roundConfirmation", title: "Round Videos", selected: confirmRound)
        ], lockable: false))
        b.toggle(.showMessageSeconds, "Show Message Seconds")
        b.value("peerId", "Show Peer ID", ayuPeerIdOptions[AyuGramSettings.peerIdDisplay.rawValue])

        b.header("WEBVIEW")
        b.toggle(.spoofWebviewAsAndroid, "Spoof Client as Android")

    case .appearance:
        if !appIcons.isEmpty {
            b.header("APP ICON")
            b.add("appIcons", .appIcons(icons: appIcons, current: currentAppIcon))
        }

        b.nextSection()
        b.toggle(.hideNotificationBadge, "Hide Notification Badge")
        b.footer("Hides the notification counter on the app icon.")

        b.header("AVATAR CORNERS")
        b.value("avatarCorners", "Avatar Corners", AyuGramSettings.bool(.squareAvatars) ? "Square" : "Circle")
        b.toggle(.singleCornerRadius, "Single Corner Radius")
        b.footer("Forums will have the same avatar shape as chats. Avatar changes take effect after restarting the app.")

        b.header("APPEARANCE")
        b.toggle(.disableCustomBackgrounds, "Disable Custom Backgrounds")
        b.toggle(.hidePremiumStatuses, "Hide Premium Statuses")
        b.value("monoFont", "Monospace Font", AyuGramSettings.monoFont ?? "Default")

        b.header("CHAT FOLDERS")
        b.toggle(.hideNotificationCounters, "Hide Notification Counters")
        b.toggle(.hideAllChatsFolder, "Hide \"All Chats\" Tab")
        b.toggle(.rememberLastFolder, "Open Last Folder")

        b.header("DRAWER ELEMENTS")
        b.toggle(.showLReadToggleInDrawer, "Read on Local", icon: "Ayu/LRead")
        b.toggle(.showSReadToggleInDrawer, "Read on Server", icon: "Ayu/SRead")
        b.toggle(.showGhostToggleInDrawer, "Ghost Mode", icon: "Ayu/Ghost")
        b.toggle(.showStreamerToggleInDrawer, "Streamer Mode", icon: "Ayu/Streamer")
        b.footer("On iOS these are in the menu that opens when you hold the Settings tab.")

    case .chats:
        b.header("STICKERS AND EMOJI")
        b.toggle(.showOnlyAddedEmojisAndStickers, "Show Only Added Emojis & Stickers")
        b.toggle(.unlimitedRecentStickers, "Unlimited Recent Stickers")
        b.toggle(.standardEmojiFirst, "Standard Emoji First")
        let hideChannelReactions = !AyuGramSettings.bool(.showChannelReactions)
        let hideGroupReactions = !AyuGramSettings.bool(.showGroupReactions)
        let hidePrivateReactions = !AyuGramSettings.bool(.showPrivateChatReactions)
        b.add("hideReactions", .expandable(title: "Hide Reactions", value: hideChannelReactions || hideGroupReactions || hidePrivateReactions, expanded: state.expanded.contains("hideReactions"), subItems: [
            AyuSubItem(id: "n:showChannelReactions", title: "Channels", selected: hideChannelReactions),
            AyuSubItem(id: "n:showGroupReactions", title: "Groups", selected: hideGroupReactions),
            AyuSubItem(id: "n:showPrivateChatReactions", title: "Private Chats", selected: hidePrivateReactions)
        ], lockable: false))

        b.header("GROUPS AND CHANNELS")
        b.value("channelButton", "Channel Bottom Button", ayuChannelButtonOptions[AyuGramSettings.channelBottomButtonMode])
        b.toggle(.quickAdminShortcuts, "Quick Admin Shortcuts")
        b.toggle(.disableGreetingSticker, "Disable Greeting Sticker")
        b.toggle(.showMessageShotInContextMenu, "Show Message Shot")
        b.footer("Allows taking a screenshot of the selected messages.")

        b.header("MESSAGES")
        b.toggle(.replaceBottomInfoWithIcons, "Replace with Icons")
        if !AyuGramSettings.bool(.replaceBottomInfoWithIcons) {
            b.value("deletedMark", "Deleted Mark", AyuGramSettings.deletedMarkText)
            b.value("editedMark", "Edited Mark", AyuGramSettings.editedMarkText ?? "edited")
        }
        b.toggle(.removeMessageTail, "Remove Message Tail")
        b.toggle(.hideFastShare, "Hide Side \"Share\" Button")
        b.toggle(.simpleQuotesAndReplies, "Disable Colorful Replies")
        b.toggle(.semiTransparentDeletedMessages, "Translucent Deleted Messages")
        b.toggle(.doubleTapToEdit, "Double-Tap to Edit")
        b.toggle(.disableDeleteAnimation, "Disable Delete Animation")
        b.toggle(.disablePullToNextChannel, "Disable Pull to Next Channel")
        b.footer("Double-tapping your own message opens it for editing instead of adding a reaction.")

        b.header("MESSAGE FIELD")
        b.toggle(.sendWithReturnKey, "Send with Return Key")
        b.toggle(.hideSendAsButton, "Hide \"Send As\" Button")

        b.header("CONTEXT MENU ELEMENTS")
        for row in ayuContextMenuRows {
            if row.key == .showAddFilterInContextMenu && !AyuGramSettings.bool(.filtersEnabled) {
                continue
            }
            var visibility = AyuGramSettings.contextMenuVisibility(row.key)
            if !row.extendable && visibility == .extended {
                visibility = .shown
            }
            b.value("cm:\(row.key.rawValue)", row.title, ayuContextMenuOptions[visibility.rawValue], icon: row.icon)
        }
        b.footer("Extended menu items are shown under AyuGram in the message menu.")

        b.header("MESSAGE FIELD ELEMENTS")
        b.toggle(.showAttachButtonInMessageField, "Attach", icon: "Ayu/FieldAttach")
        b.toggle(.showCommandsButtonInMessageField, "Commands", icon: "Ayu/FieldCommands")
        b.toggle(.showAutoDeleteButtonInMessageField, "TTL", icon: "Ayu/FieldTTL")
        b.toggle(.showEmojiButtonInMessageField, "Emoji", icon: "Ayu/FieldEmoji")
        b.toggle(.showMicrophoneButtonInMessageField, "Voice", icon: "Ayu/FieldVoice")
        b.toggle(.showGiftButtonInMessageField, "Gift", icon: "Ayu/FieldGift")
        b.toggle(.showAiEditorButtonInMessageField, "AI Editor", icon: "Chat/Input/Text/InputAIIcon")

    case .other:
        b.header("AYUGRAM FOR IOS")
        b.toggle(.keepAliveInBackground, "Stay Connected in Background")
        b.footer("Keeps AyuGram running in the background, so deleted messages are saved even when the app is closed. Needs location access and uses more battery. Takes effect after restarting the app.")

        if AyuGramSettings.bool(.keepAliveInBackground) {
            b.header("PAUSE ON LOW BATTERY")
            b.add("keepAliveBattery", .batteryLevel(value: Int32(AyuGramSettings.keepAlivePauseBatteryLevel)))
            b.footer("Stops staying connected in the background when the battery drops below this level and the device isn't charging.")
        }

        b.nextSection()
        b.toggle(.cleanLinks, "Remove Tracking from Links I Send")
        b.toggle(.cleanLinksStrict, "Strict Link Cleaning")
        b.footer("Removes tracking from links in messages you send. Strict cleaning removes more and may break some links.")

        b.nextSection()
        b.toggle(.allowSavingRestrictedContent, "Allow Copy and Save in Restricted Chats")
        b.toggle(.premiumStickersAsCopy, "Send Premium Stickers as a Copy")
        b.toggle(.streamerMode, "Streamer Mode")
        b.footer("Streamer Mode hides your phone number in Settings.")

        b.nextSection()
        b.value("reset", "Reset Settings", "", icon: "Ayu/MenuRestore", arrow: false)
    }

    return b.entries
}

// MARK: Controller

public func ayuGramSettingsController(context: AccountContext) -> ViewController {
    return ayuGramSettingsPageController(context: context, page: .main)
}

/// tg://ayusettings?s=<setting>: the page that holds that setting, as desktop opens its section.
/// Names are desktop's (filterZalgo, hideNotificationCounters, ...); an unknown one opens the main page.
public func ayuGramSettingsController(context: AccountContext, setting: String) -> ViewController {
    guard let page = ayuPageHolding(setting: setting) else {
        return ayuGramSettingsController(context: context)
    }
    return ayuGramSettingsPageController(context: context, page: page)
}

private func ayuPageHolding(setting: String) -> AyuPage? {
    let name = setting.lowercased()
    let matches: (String) -> Bool = { id in
        let lowered = id.lowercased()
        return lowered == name || lowered.hasSuffix(":" + name)
    }
    let state = AyuScreenState()
    let pages: [AyuPage] = [.ghost, .filters, .general, .appearance, .chats, .other]
    for page in pages {
        for entry in ayuSettingsEntries(page: page, state: state, appIcons: [], currentAppIcon: nil) {
            if matches(entry.id) {
                return page
            }
            if case let .expandable(_, _, _, subItems, _) = entry.row, subItems.contains(where: { matches($0.id) }) {
                return page
            }
        }
    }
    return nil
}

/// The shared filters list, opened from the chat menu ("View Filters").
public func ayuGramFiltersController(context: AccountContext) -> ViewController {
    return ayuGramSettingsPageController(context: context, page: .filterList)
}

private func ayuGramSettingsPageController(context: AccountContext, page: AyuPage) -> ViewController {
    AyuGramSettings.debugLog("ui ayuGramSettingsController created page=\(page.title.isEmpty ? "main" : page.title)")
    let version = Atomic<Int>(value: 0)
    let versionPromise = ValuePromise<Int>(0, ignoreRepeated: false)
    let bump: () -> Void = {
        versionPromise.set(version.modify { $0 + 1 })
    }
    let state = AyuScreenState()

    var presentControllerImpl: ((ViewController) -> Void)?
    var pushControllerImpl: ((ViewController) -> Void)?
    var openUrlImpl: ((String) -> Void)?

    let allAppIcons = context.sharedContext.applicationBindings.getAvailableAlternateIcons()
    let appIcons = allAppIcons.filter { $0.name.hasPrefix("Ayu") }
    let currentAppIcon = ValuePromise<String?>(context.sharedContext.applicationBindings.getAlternateIconName(), ignoreRepeated: false)

    let presentAlert: (String) -> Void = { text in
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        presentControllerImpl?(textAlertController(context: context, title: nil, text: text, actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})]))
    }

    // A sheet with one row per option; the current one is ticked.
    let presentChoice: (String, [String], Int, @escaping (Int) -> Void) -> Void = { title, options, selected, apply in
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let actionSheet = ActionSheetController(presentationData: presentationData)
        var items: [ActionSheetItem] = []
        items.append(ActionSheetTextItem(title: title))
        for (index, option) in options.enumerated() {
            items.append(ActionSheetButtonItem(title: index == selected ? "\u{2713} \(option)" : option, color: .accent, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
                apply(index)
                bump()
            }))
        }
        actionSheet.setItemGroups([ActionSheetItemGroup(items: items), ActionSheetItemGroup(items: [
            ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
            })
        ])])
        presentControllerImpl?(actionSheet)
    }

    // A sheet with destructive or plain actions for one list entry.
    let presentActions: (String, [(String, Bool, () -> Void)]) -> Void = { title, actions in
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let actionSheet = ActionSheetController(presentationData: presentationData)
        var items: [ActionSheetItem] = []
        items.append(ActionSheetTextItem(title: title, parseMarkdown: false))
        for (actionTitle, destructive, action) in actions {
            items.append(ActionSheetButtonItem(title: actionTitle, color: destructive ? .destructive : .accent, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
                action()
                bump()
            }))
        }
        actionSheet.setItemGroups([ActionSheetItemGroup(items: items), ActionSheetItemGroup(items: [
            ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
            })
        ])])
        presentControllerImpl?(actionSheet)
    }

    let removeFilterEntry: (String) -> Void = { entry in
        AyuFilters.setPatterns(AyuFilters.patterns.filter { $0 != entry })
    }

    let editFilter: (String?) -> Void = { existing in
        let controller = promptController(context: context, text: existing == nil ? "Add Filter" : "Edit Filter", subtitle: "Regular expression. Matching incoming messages are hidden.", value: existing.map { ayuFilterPattern($0) }, placeholder: "Expression", apply: { value in
            guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
                return
            }
            if (try? NSRegularExpression(pattern: value, options: [.caseInsensitive])) == nil {
                presentAlert("Regex syntax error")
                return
            }
            var patterns = AyuFilters.patterns
            if let existing = existing, let index = patterns.firstIndex(of: existing) {
                patterns[index] = existing.hasPrefix(AyuFilters.disabledPrefix) ? AyuFilters.disabledPrefix + value : value
            } else if !patterns.contains(value) {
                patterns.append(value)
            }
            AyuFilters.setPatterns(patterns)
            bump()
        })
        presentControllerImpl?(controller)
    }

    let arguments = AyuSettingsArguments(toggle: { id, value in
        if id.hasPrefix("k:"), let key = AyuGramSettings.BoolKey(rawValue: String(id.dropFirst(2))) {
            AyuGramSettings.setBool(key, value)
        } else if id.hasPrefix("n:"), let key = AyuGramSettings.BoolKey(rawValue: String(id.dropFirst(2))) {
            AyuGramSettings.setBool(key, !value)
        } else {
            switch id {
            case "ghostMode":
                AyuGramSettings.setGhostModeActive(value)
            case "markRead":
                // As on desktop, reading on interaction and scheduled sending exclude each other.
                AyuGramSettings.setBool(.markReadAfterAction, value)
                if value {
                    AyuGramSettings.setBool(.useScheduledMessages, false)
                }
            case "scheduled":
                AyuGramSettings.setBool(.useScheduledMessages, value)
                if value {
                    AyuGramSettings.setBool(.markReadAfterAction, false)
                }
            case "similar":
                AyuGramSettings.setBool(.collapseSimilarChannels, value)
                AyuGramSettings.setBool(.hideSimilarChannels, value)
            case "confirm":
                AyuGramSettings.setBool(.stickerConfirmation, value)
                AyuGramSettings.setBool(.gifConfirmation, value)
                AyuGramSettings.setBool(.voiceConfirmation, value)
                AyuGramSettings.setBool(.roundConfirmation, value)
            case "hideReactions":
                AyuGramSettings.setBool(.showChannelReactions, !value)
                AyuGramSettings.setBool(.showGroupReactions, !value)
                AyuGramSettings.setBool(.showPrivateChatReactions, !value)
            default:
                break
            }
        }
        bump()
    }, activate: { id in
        if id.hasPrefix("page:") {
            if let target = AyuPage.named(String(id.dropFirst(5))) {
                pushControllerImpl?(ayuGramSettingsPageController(context: context, page: target))
            }
            return
        }
        if id.hasPrefix("link:") {
            openUrlImpl?(String(id.dropFirst(5)))
            return
        }
        if id.hasPrefix("cm:") {
            guard let key = AyuGramSettings.BoolKey(rawValue: String(id.dropFirst(3))), let row = ayuContextMenuRows.first(where: { $0.key == key }) else {
                return
            }
            var current = AyuGramSettings.contextMenuVisibility(key)
            if !row.extendable && current == .extended {
                current = .shown
            }
            let options = row.extendable ? ayuContextMenuOptions : Array(ayuContextMenuOptions.prefix(2))
            presentChoice("Choose when to show the item", options, current.rawValue, { index in
                if let value = AyuGramSettings.ContextMenuVisibility(rawValue: index) {
                    AyuGramSettings.setContextMenuVisibility(key, value)
                }
            })
            return
        }
        if id.hasPrefix("f:") {
            let entry = String(id.dropFirst(2))
            let isDisabled = entry.hasPrefix(AyuFilters.disabledPrefix)
            presentActions(ayuFilterPattern(entry), [
                ("Edit", false, {
                    editFilter(entry)
                }),
                (isDisabled ? "Enable" : "Disable", false, {
                    var patterns = AyuFilters.patterns
                    if let index = patterns.firstIndex(of: entry) {
                        patterns[index] = isDisabled ? ayuFilterPattern(entry) : AyuFilters.disabledPrefix + entry
                        AyuFilters.setPatterns(patterns)
                    }
                }),
                ("Delete", true, {
                    removeFilterEntry(entry)
                })
            ])
            return
        }
        if id.hasPrefix("u:") {
            let entry = String(id.dropFirst(2))
            presentActions("User \(entry.dropFirst(AyuFilters.userPrefix.count))", [
                ("Delete", true, {
                    removeFilterEntry(entry)
                })
            ])
            return
        }
        if id.hasPrefix("c:") {
            let entry = String(id.dropFirst(2))
            presentActions(String(entry.dropFirst(AyuFilters.chatPrefix.count)), [
                ("Delete", true, {
                    removeFilterEntry(entry)
                })
            ])
            return
        }
        switch id {
        case "ghostProfile":
            let name = state.accountName.isEmpty ? "This Account" : state.accountName
            presentChoice("Ghost Mode", ["Global Settings", name], AyuGramSettings.bool(.useGlobalGhostMode) ? 0 : 1, { index in
                let wasGlobal = AyuGramSettings.bool(.useGlobalGhostMode)
                AyuGramSettings.setBool(.useGlobalGhostMode, index == 0)
                if wasGlobal != (index == 0) {
                    presentAlert(index == 0 ? "Switched to same settings for all accounts." : "Switched to individual settings for each account.")
                }
            })
        case "silent":
            presentChoice("Send without Sound", ayuSilentOptions, AyuGramSettings.sendWithoutSoundMode, { index in
                AyuGramSettings.setSendWithoutSoundMode(index)
            })
        case "translator":
            let providers = AyuTranslator.Provider.allCases
            presentChoice("Translation Provider", providers.map { $0.title }, providers.firstIndex(of: AyuTranslator.provider) ?? 0, { index in
                AyuTranslator.setProvider(providers[index])
            })
        case "peerId":
            presentChoice("Show Peer ID", ayuPeerIdOptions, AyuGramSettings.peerIdDisplay.rawValue, { index in
                if let value = AyuGramSettings.PeerIdDisplay(rawValue: index) {
                    AyuGramSettings.setPeerIdDisplay(value)
                }
            })
        case "avatarCorners":
            presentChoice("Avatar Corners", ["Circle", "Square"], AyuGramSettings.bool(.squareAvatars) ? 1 : 0, { index in
                AyuGramSettings.setBool(.squareAvatars, index == 1)
            })
        case "channelButton":
            presentChoice("Channel Bottom Button", ayuChannelButtonOptions, AyuGramSettings.channelBottomButtonMode, { index in
                AyuGramSettings.setChannelBottomButtonMode(index)
            })
        case "monoFont":
            let controller = promptController(context: context, text: "Monospace Font", subtitle: "Font name, such as Courier or Menlo-Regular. Leave empty for the default. Reopen a chat to see it.", value: AyuGramSettings.monoFont, placeholder: "Default", apply: { value in
                guard let value = value else {
                    return
                }
                let name = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty && UIFont(name: name, size: 12.0) == nil {
                    presentAlert("No font named \"\(name)\" on this device.")
                    return
                }
                AyuGramSettings.setMonoFont(name)
                bump()
            })
            presentControllerImpl?(controller)
        case "deletedMark":
            let controller = promptController(context: context, text: "Deleted Mark", subtitle: "Shown next to the time of deleted messages. Leave empty for the default.", value: AyuGramSettings.deletedMarkText, placeholder: "\u{1F9F9}", apply: { value in
                guard let value = value else {
                    return
                }
                AyuGramSettings.setDeletedMark(value.trimmingCharacters(in: .whitespacesAndNewlines))
                bump()
            })
            presentControllerImpl?(controller)
        case "editedMark":
            let controller = promptController(context: context, text: "Edited Mark", subtitle: "Replaces the \"edited\" label on edited messages. Leave empty for the default.", value: AyuGramSettings.editedMarkText, placeholder: "edited", apply: { value in
                guard let value = value else {
                    return
                }
                AyuGramSettings.setEditedMark(value.trimmingCharacters(in: .whitespacesAndNewlines))
                bump()
            })
            presentControllerImpl?(controller)
        case "filters:add":
            editFilter(nil)
        case "filters:import":
            if let string = UIPasteboard.general.string, let added = AyuFilters.importString(string) {
                presentAlert(added == 0 ? "Filters are the same as current." : "Filters successfully imported.")
                bump()
            } else {
                presentAlert("Failed to import filters.")
            }
        case "filters:export":
            UIPasteboard.general.string = AyuFilters.exportString()
            let count = AyuFilters.patterns.count
            presentAlert(count == 1 ? "1 filter copied to the clipboard." : "\(count) filters copied to the clipboard.")
        case "filters:clear":
            presentActions("Are you sure you want to clear all filters?", [
                ("Clear", true, {
                    AyuFilters.setPatterns([])
                })
            ])
        case "reset":
            presentActions("Are you sure you want to reset all AyuGram preferences to their defaults?", [
                ("Yes", true, {
                    AyuGramSettings.resetAll()
                    AyuFilters.setPatterns(AyuFilters.patterns.filter { !$0.hasPrefix(AyuFilters.userPrefix) })
                    presentAlert("Done")
                })
            ])
        default:
            break
        }
    }, toggleExpanded: { id in
        if state.expanded.contains(id) {
            state.expanded.remove(id)
        } else {
            state.expanded.insert(id)
        }
        bump()
    }, toggleSubItem: { id, subId in
        if id == "ghostMode" {
            if let option = ayuGhostOptions.first(where: { $0.key.rawValue == subId }), !AyuGramSettings.bool(option.lock) {
                AyuGramSettings.setBool(option.key, !AyuGramSettings.bool(option.key))
            }
        } else if subId.count > 2, let key = AyuGramSettings.BoolKey(rawValue: String(subId.dropFirst(2))) {
            AyuGramSettings.setBool(key, !AyuGramSettings.bool(key))
        }
        bump()
    }, longPressSubItem: { id, subId in
        guard id == "ghostMode", let option = ayuGhostOptions.first(where: { $0.key.rawValue == subId }) else {
            return
        }
        let isLocked = AyuGramSettings.bool(option.lock)
        if !isLocked && ayuGhostOptions.filter({ !AyuGramSettings.bool($0.lock) }).count <= 1 {
            return
        }
        AyuGramSettings.setBool(option.lock, !isLocked)
        bump()
    }, selectAppIcon: { icon in
        currentAppIcon.set(icon.name)
        context.sharedContext.applicationBindings.requestSetAlternateIconName(icon.name, { _ in
        })
    }, updateBatteryLevel: { _, value in
        AyuGramSettings.setKeepAlivePauseBatteryLevel(Int(value))
        bump()
    })

    // The profile row of the AyuGram page needs the number of accounts and this account's name.
    let accountInfoDisposable = MetaDisposable()
    if page == .ghost {
        let accountCount = context.sharedContext.activeAccountContexts
        |> take(1)
        |> map { value -> Int in
            return value.accounts.count
        }
        let accountPeer = context.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: context.account.peerId))
        accountInfoDisposable.set((combineLatest(accountCount, accountPeer)
        |> deliverOnMainQueue).start(next: { count, peer in
            state.accountCount = count
            if let peer = peer, case let .user(user) = peer {
                state.accountName = [user.firstName, user.lastName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
            }
            bump()
        }))
    }

    let signal = combineLatest(context.sharedContext.presentationData, versionPromise.get(), currentAppIcon.get())
    |> deliverOnMainQueue
    |> map { presentationData, _, currentAppIcon -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(page.title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back), animateChanges: false)
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: ayuSettingsEntries(page: page, state: state, appIcons: appIcons, currentAppIcon: currentAppIcon), style: .blocks, emptyStateItem: nil, animateChanges: false)

        return (controllerState, (listState, arguments))
    }
    |> afterDisposed {
        accountInfoDisposable.dispose()
    }

    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root))
    }
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    openUrlImpl = { [weak controller] url in
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        context.sharedContext.openExternalUrl(context: context, urlContext: .generic, url: url, forceExternal: false, presentationData: presentationData, navigationController: controller?.navigationController as? NavigationController, dismissInput: {})
    }
    // Returning to a page refreshes it: a sub-page may have changed what it shows.
    controller.didAppear = { _ in
        bump()
    }
    return controller
}

// MARK: Logo header of the main page

private final class AyuGramLogoHeaderItem: ListViewItem, ItemListItem {
    let presentationData: ItemListPresentationData
    let title: String
    let text: String
    let iconName: String?
    let sectionId: ItemListSectionId
    let isAlwaysPlain: Bool = true

    init(presentationData: ItemListPresentationData, title: String, text: String, iconName: String?, sectionId: ItemListSectionId) {
        self.presentationData = presentationData
        self.title = title
        self.text = text
        self.iconName = iconName
        self.sectionId = sectionId
    }

    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, neighbors: ListViewItemNeighbors, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = AyuGramLogoHeaderItemNode()
            let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topFacet: neighbors.previous?.base(ItemListNeighborFacet.self), bottomFacet: neighbors.next?.base(ItemListNeighborFacet.self)))

            node.contentSize = layout.contentSize
            node.insets = layout.insets

            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { _ in apply() })
                })
            }
        }
    }

    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, neighbors: ListViewItemNeighbors, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            guard let nodeValue = node() as? AyuGramLogoHeaderItemNode else {
                return
            }

            let makeLayout = nodeValue.asyncLayout()

            async {
                let (layout, apply) = makeLayout(self, params, itemListNeighbors(item: self, topFacet: neighbors.previous?.base(ItemListNeighborFacet.self), bottomFacet: neighbors.next?.base(ItemListNeighborFacet.self)))
                Queue.mainQueue().async {
                    completion(layout, { _ in
                        apply()
                    })
                }
            }
        }
    }
}

private final class AyuGramLogoHeaderItemNode: ListViewItemNode, ItemListItemNode {
    private let iconNode: ASImageNode
    private let titleNode: TextNode
    private let textNode: TextNode

    private var item: AyuGramLogoHeaderItem?

    var tag: ItemListItemTag? {
        return nil
    }

    init() {
        self.iconNode = ASImageNode()
        self.iconNode.displaysAsynchronously = false
        self.iconNode.contentMode = .scaleAspectFill
        self.iconNode.clipsToBounds = true

        self.titleNode = TextNode()
        self.titleNode.isUserInteractionEnabled = false
        self.titleNode.contentsScale = UIScreenScale

        self.textNode = TextNode()
        self.textNode.isUserInteractionEnabled = false
        self.textNode.contentsScale = UIScreenScale

        super.init(layerBacked: false)

        self.addSubnode(self.iconNode)
        self.addSubnode(self.titleNode)
        self.addSubnode(self.textNode)
    }

    func asyncLayout() -> (_ item: AyuGramLogoHeaderItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        let makeTitleLayout = TextNode.asyncLayout(self.titleNode)
        let makeTextLayout = TextNode.asyncLayout(self.textNode)

        return { [weak self] item, params, neighbors in
            let sideInset: CGFloat = 32.0
            let topInset: CGFloat = 12.0
            let iconSize = CGSize(width: 96.0, height: 96.0)
            let iconSpacing: CGFloat = 14.0
            let textSpacing: CGFloat = 6.0
            let bottomInset: CGFloat = 8.0

            let contentWidth = params.width - params.leftInset - params.rightInset
            let constrainedSize = CGSize(width: max(1.0, contentWidth - sideInset * 2.0), height: CGFloat.greatestFiniteMagnitude)

            let (titleLayout, titleApply) = makeTitleLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: item.title, font: Font.semibold(20.0), textColor: item.presentationData.theme.list.itemPrimaryTextColor), backgroundColor: nil, maximumNumberOfLines: 2, truncationType: .end, constrainedSize: constrainedSize, alignment: .center, cutout: nil, insets: UIEdgeInsets()))
            let (textLayout, textApply) = makeTextLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: item.text, font: Font.regular(15.0), textColor: item.presentationData.theme.list.freeTextColor), backgroundColor: nil, maximumNumberOfLines: 0, truncationType: .end, constrainedSize: constrainedSize, alignment: .center, cutout: nil, insets: UIEdgeInsets()))

            let contentHeight = topInset + iconSize.height + iconSpacing + titleLayout.size.height + textSpacing + textLayout.size.height + bottomInset
            let layout = ListViewItemNodeLayout(contentSize: CGSize(width: params.width, height: contentHeight), insets: itemListNeighborsGroupedInsets(neighbors, params))

            return (layout, {
                guard let strongSelf = self else {
                    return
                }
                if strongSelf.item?.iconName != item.iconName || strongSelf.iconNode.image == nil {
                    if let iconName = item.iconName {
                        strongSelf.iconNode.image = UIImage(named: iconName, in: getAppBundle(), compatibleWith: nil)
                    } else {
                        strongSelf.iconNode.image = nil
                    }
                }
                strongSelf.item = item

                let _ = titleApply()
                let _ = textApply()

                // Desktop shows its logo as a circle.
                strongSelf.iconNode.cornerRadius = iconSize.width / 2.0
                strongSelf.iconNode.frame = CGRect(origin: CGPoint(x: params.leftInset + floorToScreenPixels((contentWidth - iconSize.width) / 2.0), y: topInset), size: iconSize)
                strongSelf.titleNode.frame = CGRect(origin: CGPoint(x: params.leftInset + floorToScreenPixels((contentWidth - titleLayout.size.width) / 2.0), y: topInset + iconSize.height + iconSpacing), size: titleLayout.size)
                strongSelf.textNode.frame = CGRect(origin: CGPoint(x: params.leftInset + floorToScreenPixels((contentWidth - textLayout.size.width) / 2.0), y: topInset + iconSize.height + iconSpacing + titleLayout.size.height + textSpacing), size: textLayout.size)
            })
        }
    }

    override func animateInsertion(_ currentTimestamp: Double, duration: Double, options: ListViewItemAnimationOptions) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.4)
    }

    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
}
