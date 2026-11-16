// AyuGram: local settings store.
//
// Mirrors the setting names and defaults of AyuGram Desktop (ayu/ayu_settings.h).
// Backed by UserDefaults so it can be read synchronously from any queue.

import Foundation

public final class AyuGramSettings {
    public enum BoolKey: String, CaseIterable {
        // Ghost mode
        case sendReadMessages
        case sendReadStories
        case sendOnlinePackets
        case sendUploadProgress
        case sendOfflinePacketAfterOnline
        case markReadAfterAction
        case useScheduledMessages

        // Message history
        case saveDeletedMessages
        case saveMessagesHistory
        case saveForBots

        // Other
        case disableAds
        case localPremium
        case showMessageSeconds
        case keepAliveInBackground
        case disableStories
        case disableOpenLinkWarning
        case showPeerId
        case sendWithoutSoundAlways
        case sendWithoutSoundInGhost
        case allowSavingRestrictedContent
        case filtersEnabled
        case filtersEnabledInChats
        case hideNotificationBadge
        case stickerConfirmation
        case showMessageDetailsInContextMenu
        case showAddFilterInContextMenu
        case showHideMessageInContextMenu
        case gifConfirmation
        case disableGreetingSticker
        case voiceConfirmation
        case hideSimilarChannels
        case hidePremiumStatuses
        case showChannelReactions
        case showGroupReactions
        case showPrivateChatReactions
        case filterZalgo
        case showRepeatMessageInContextMenu
        case hideFastShare
        case disableCustomBackgrounds
        case semiTransparentDeletedMessages
        case showReactionsPanelInContextMenu
        case showViewsPanelInContextMenu
        case showAttachButtonInMessageField
        case streamerMode
        case premiumStickersAsCopy
        case squareAvatars
        case removeMessageTail
        case showMicrophoneButtonInMessageField
        case pauseKeepAliveOnLowBattery
        case showCommandsButtonInMessageField
        case showEmojiButtonInMessageField
        case showAutoDeleteButtonInMessageField
        case showGiftButtonInMessageField
        case hideNotificationCounters
        case lockSendReadMessages
        case lockSendReadStories
        case lockSendOnlinePackets
        case lockSendUploadProgress
        case lockSendOfflinePacketAfterOnline
        case showLReadToggleInDrawer
        case showSReadToggleInDrawer
        case showGhostToggleInDrawer
        case showStreamerToggleInDrawer
        case unlimitedRecentStickers
        case showOnlyAddedEmojisAndStickers
        case showUserMessagesInContextMenu
        case hideFromBlocked
        case cleanLinks
        case cleanLinksStrict
        case suggestGhostModeBeforeViewingStory
        case hideAllChatsFolder
        case collapseSimilarChannels
        case spoofWebviewAsAndroid
        case channelBottomButtonDiscuss
        case channelBottomButtonHidden
        case singleCornerRadius
        case simpleQuotesAndReplies
        case showAiEditorButtonInMessageField
        case replaceBottomInfoWithIcons
        case improveLinkPreviews
        case quickAdminShortcuts
        case showMessageShotInContextMenu
        case useGlobalGhostMode

        public var defaultValue: Bool {
            switch self {
            case .sendReadMessages, .sendReadStories, .sendOnlinePackets, .sendUploadProgress:
                return true
            case .sendOfflinePacketAfterOnline:
                return false
            case .markReadAfterAction:
                return true
            case .useScheduledMessages:
                return false
            case .saveDeletedMessages, .saveMessagesHistory:
                return true
            case .saveForBots:
                return false
            case .disableAds:
                return true
            case .localPremium:
                return false
            case .showMessageSeconds:
                return false
            case .keepAliveInBackground:
                return false
            case .disableStories, .disableOpenLinkWarning:
                return false
            case .showPeerId:
                return true
            case .sendWithoutSoundAlways, .sendWithoutSoundInGhost:
                return false
            case .allowSavingRestrictedContent:
                return false
            case .filtersEnabled, .filtersEnabledInChats:
                return false
            case .hideNotificationBadge, .stickerConfirmation:
                return false
            case .showHideMessageInContextMenu, .gifConfirmation, .disableGreetingSticker:
                return false
            case .voiceConfirmation, .hideSimilarChannels, .hidePremiumStatuses:
                return false
            case .showChannelReactions, .showGroupReactions, .showPrivateChatReactions:
                return true
            case .filterZalgo, .showRepeatMessageInContextMenu:
                return false
            case .hideFastShare, .disableCustomBackgrounds, .semiTransparentDeletedMessages:
                return false
            case .streamerMode, .hideNotificationCounters:
                return false
            case .premiumStickersAsCopy:
                return true
            case .squareAvatars, .removeMessageTail:
                return false
            case .showMicrophoneButtonInMessageField, .pauseKeepAliveOnLowBattery:
                return true
            case .showCommandsButtonInMessageField, .showEmojiButtonInMessageField, .showAutoDeleteButtonInMessageField, .showGiftButtonInMessageField:
                return true
            case .showReactionsPanelInContextMenu, .showViewsPanelInContextMenu, .showAttachButtonInMessageField:
                return true
            case .showMessageDetailsInContextMenu, .showAddFilterInContextMenu, .showUserMessagesInContextMenu:
                return true
            case .lockSendReadMessages, .lockSendReadStories, .lockSendOnlinePackets, .lockSendUploadProgress, .lockSendOfflinePacketAfterOnline:
                return false
            case .showLReadToggleInDrawer, .showStreamerToggleInDrawer:
                return false
            case .showSReadToggleInDrawer, .showGhostToggleInDrawer, .suggestGhostModeBeforeViewingStory, .collapseSimilarChannels, .channelBottomButtonDiscuss, .showAiEditorButtonInMessageField, .replaceBottomInfoWithIcons, .quickAdminShortcuts, .showMessageShotInContextMenu, .useGlobalGhostMode:
                return true
            case .unlimitedRecentStickers, .showOnlyAddedEmojisAndStickers, .hideFromBlocked, .cleanLinks, .cleanLinksStrict, .hideAllChatsFolder, .spoofWebviewAsAndroid, .channelBottomButtonHidden, .singleCornerRadius, .simpleQuotesAndReplies, .improveLinkPreviews:
                return false
            }
        }

        fileprivate var storageKey: String {
            return "ayu.\(self.rawValue)"
        }
    }

    private static let defaults = UserDefaults.standard

    // Ghost settings can be kept per account ("One Ghost Mode for All Accounts" off).
    // They then follow the account that is in front, the only one that reads chats and goes online.
    private static let perAccountKeys: Set<BoolKey> = [
        .sendReadMessages, .sendReadStories, .sendOnlinePackets, .sendUploadProgress, .sendOfflinePacketAfterOnline,
        .markReadAfterAction, .useScheduledMessages,
        .lockSendReadMessages, .lockSendReadStories, .lockSendOnlinePackets, .lockSendUploadProgress, .lockSendOfflinePacketAfterOnline
    ]
    private static let activeAccountLock = NSLock()
    private static var activeAccountIdValue: Int64 = 0

    public static func setActiveAccount(_ peerId: Int64) {
        activeAccountLock.lock()
        let changed = activeAccountIdValue != peerId
        activeAccountIdValue = peerId
        activeAccountLock.unlock()
        if changed {
            debugLog("active account=\(peerId) globalGhost=\(bool(.useGlobalGhostMode)) sendRead=\(bool(.sendReadMessages)) sendOnline=\(bool(.sendOnlinePackets))")
        }
    }

    private static func effectiveStorageKey(_ key: BoolKey) -> String {
        if key != .useGlobalGhostMode && perAccountKeys.contains(key) {
            let isGlobal = (defaults.object(forKey: BoolKey.useGlobalGhostMode.storageKey) as? Bool) ?? BoolKey.useGlobalGhostMode.defaultValue
            if !isGlobal {
                activeAccountLock.lock()
                let accountId = activeAccountIdValue
                activeAccountLock.unlock()
                if accountId != 0 {
                    return "\(key.storageKey).\(accountId)"
                }
            }
        }
        return key.storageKey
    }

    public static func bool(_ key: BoolKey) -> Bool {
        if let value = overrideValue(key) {
            return value
        }
        if let value = defaults.object(forKey: effectiveStorageKey(key)) as? Bool {
            return value
        }
        return key.defaultValue
    }

    public static func setBool(_ key: BoolKey, _ value: Bool) {
        defaults.set(value, forKey: effectiveStorageKey(key))
        if key == .hideNotificationBadge {
            mirrorHideBadge()
        }
    }

    // The notification extension writes the badge onto each push it shows, but cannot read the app's own
    // defaults, so "Hide App Icon Badge" is copied into the app group's defaults for it.
    private static let hideBadgeAppGroupKey = "ayu.hideNotificationBadge"

    /// Called by the main app: copies the current "Hide App Icon Badge" value into the app group.
    public static func mirrorHideBadge() {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            return
        }
        UserDefaults(suiteName: "group.\(bundleId)")?.set(bool(.hideNotificationBadge), forKey: hideBadgeAppGroupKey)
    }

    /// Read by the notification extension, which passes the app group name.
    public static func hideBadgeFromAppGroup(_ appGroupName: String) -> Bool {
        return UserDefaults(suiteName: appGroupName)?.bool(forKey: hideBadgeAppGroupKey) ?? false
    }

    /// Name of the font used for monospace text; nil means the stock Menlo. Display reads the same key.
    public static var monoFont: String? {
        if let value = defaults.string(forKey: "ayu.monoFont"), !value.isEmpty {
            return value
        }
        return nil
    }

    public static func setMonoFont(_ value: String) {
        defaults.set(value, forKey: "ayu.monoFont")
    }

    /// Text shown next to the time of a message the server deleted.
    public static var deletedMark: String {
        if bool(.replaceBottomInfoWithIcons) {
            return "\u{1F5D1}"
        }
        if let value = defaults.string(forKey: "ayu.deletedMark"), !value.isEmpty {
            return value
        }
        return "\u{1F9F9}"
    }

    public static func setDeletedMark(_ value: String) {
        defaults.set(value, forKey: "ayu.deletedMark")
    }

    /// Custom replacement for the "edited" label; nil means the stock label.
    public static var editedMark: String? {
        if bool(.replaceBottomInfoWithIcons) {
            return "\u{270E}"
        }
        if let value = defaults.string(forKey: "ayu.editedMark"), !value.isEmpty {
            return value
        }
        return nil
    }

    public static func setEditedMark(_ value: String) {
        defaults.set(value, forKey: "ayu.editedMark")
    }

    /// Link used to request a preview: swaps a few hosts for mirrors that return richer previews.
    public static func betterLinkPreview(_ url: String) -> String {
        if !bool(.improveLinkPreviews) {
            return url
        }
        // Links typed without a scheme ("x.com/...") have no host until one is added
        let normalized = url.contains("://") ? url : "https://" + url
        guard var components = URLComponents(string: normalized), let rawHost = components.host, !rawHost.isEmpty else {
            return url
        }
        let host = rawHost.lowercased()
        if host == "twitter.com" || host == "x.com" {
            components.host = "fixupx.com"
        } else if host == "tiktok.com" || host.hasSuffix(".tiktok.com") {
            components.host = host.replacingOccurrences(of: "tiktok.com", with: "kktiktok.com")
        } else if host == "reddit.com" || host == "www.reddit.com" {
            components.host = "vxreddit.com"
        } else if host == "instagram.com" || host == "www.instagram.com" {
            components.host = "kkclip.com"
        } else if host == "pixiv.net" || host == "www.pixiv.net" {
            components.host = "phixiv.net"
        } else {
            return url
        }
        let result = components.string ?? url
        debugLog("link preview \(url) -> \(result)")
        return result
    }

    /// View-once and self-destructing photos, videos and voice messages stay in the chat after they are opened
    /// or expire. Follows the "save deleted messages" switch, as on desktop. Secret chats are not covered.
    public static var keepSelfDestructingMedia: Bool {
        return bool(.saveDeletedMessages)
    }

    // MARK: Test hooks

    // A plist of setting name -> Bool at <tmp>/ayu-override.plist overrides stored values.
    // Used by the on-device test loop to switch settings without touching the UI.
    private static let overrideLock = NSLock()
    private static var overrideCache: [String: Bool] = [:]
    private static var overrideCheckedAt: Double = 0.0

    private static func overrideValue(_ key: BoolKey) -> Bool? {
        overrideLock.lock()
        defer {
            overrideLock.unlock()
        }
        let now = CFAbsoluteTimeGetCurrent()
        if now - overrideCheckedAt > 2.0 {
            overrideCheckedAt = now
            let path = NSTemporaryDirectory() + "ayu-override.plist"
            if let dict = NSDictionary(contentsOfFile: path) as? [String: Bool] {
                overrideCache = dict
            } else {
                overrideCache = [:]
            }
        }
        return overrideCache[key.rawValue]
    }

    private static let logLock = NSLock()

    /// Appends a line to <tmp>/ayu-debug.log.
    public static func debugLog(_ text: String) {
        let line = "\(Date().timeIntervalSince1970) \(text)\n"
        let path = NSTemporaryDirectory() + "ayu-debug.log"
        logLock.lock()
        defer {
            logLock.unlock()
        }
        if let file = fopen(path, "a") {
            fputs(line, file)
            fclose(file)
        }
    }

    // MARK: Ghost mode

    public static var sendReadMessages: Bool {
        readOverrideLock.lock()
        let overrideActive = CFAbsoluteTimeGetCurrent() < readOverrideUntil
        let overrideValue = readOverrideValue
        readOverrideLock.unlock()
        if overrideActive {
            return overrideValue
        }
        return bool(.sendReadMessages)
    }

    // "Read on Local" / "Read on Server": for a short time read receipts are forced off or on,
    // whatever the stored setting says, while every chat is marked as read.
    private static let readOverrideLock = NSLock()
    private static var readOverrideValue: Bool = true
    private static var readOverrideUntil: Double = 0.0

    public static func overrideSendReadMessages(_ value: Bool, seconds: Double) {
        readOverrideLock.lock()
        readOverrideValue = value
        readOverrideUntil = CFAbsoluteTimeGetCurrent() + seconds
        readOverrideLock.unlock()
        debugLog("read override value=\(value) seconds=\(seconds)")
    }

    /// Recent stickers kept on the device (the stock client keeps 20).
    public static var recentStickersLimit: Int {
        return bool(.unlimitedRecentStickers) ? 200 : 20
    }
    public static var sendReadStories: Bool { return bool(.sendReadStories) }
    public static var sendOnlinePackets: Bool { return bool(.sendOnlinePackets) }
    public static var sendUploadProgress: Bool { return bool(.sendUploadProgress) }
    public static var sendOfflinePacketAfterOnline: Bool { return bool(.sendOfflinePacketAfterOnline) }

    /// Ghost mode counts as active when every packet type is suppressed, as on desktop.
    // Each ghost setting, the value it has while ghost mode is on, and its lock.
    // A locked setting is left alone by the ghost mode switch, as on desktop.
    private static let ghostKeys: [(key: BoolKey, ghostValue: Bool, lock: BoolKey)] = [
        (key: .sendReadMessages, ghostValue: false, lock: .lockSendReadMessages),
        (key: .sendReadStories, ghostValue: false, lock: .lockSendReadStories),
        (key: .sendOnlinePackets, ghostValue: false, lock: .lockSendOnlinePackets),
        (key: .sendUploadProgress, ghostValue: false, lock: .lockSendUploadProgress),
        (key: .sendOfflinePacketAfterOnline, ghostValue: true, lock: .lockSendOfflinePacketAfterOnline)
    ]

    public static var isGhostModeActive: Bool {
        var unlockedCount = 0
        for entry in ghostKeys {
            if bool(entry.lock) {
                continue
            }
            unlockedCount += 1
            if bool(entry.key) != entry.ghostValue {
                return false
            }
        }
        return unlockedCount != 0
    }

    public static func setGhostModeActive(_ active: Bool) {
        for entry in ghostKeys {
            if bool(entry.lock) {
                continue
            }
            setBool(entry.key, active ? entry.ghostValue : !entry.ghostValue)
        }
    }

    // MARK: One-shot read override

    private static let forcedReadLock = NSLock()
    private static var forcedReadPeerIds = Set<Int64>()

    // Local Premium: the logged-in accounts are treated as Premium by the client.
    private static let ownAccountLock = NSLock()
    private static var ownAccountIds = Set<Int64>()

    public static func registerOwnAccount(_ peerId: Int64) {
        ownAccountLock.lock()
        ownAccountIds.insert(peerId)
        ownAccountLock.unlock()
    }

    public static func isLocalPremiumAccount(_ peerId: Int64) -> Bool {
        ownAccountLock.lock()
        let isOwn = ownAccountIds.contains(peerId)
        ownAccountLock.unlock()
        return isOwn && bool(.localPremium)
    }

    /// Allows the next read receipt for this peer to be sent even while read receipts are suppressed.
    public static func forceReadOnce(peerId: Int64) {
        forcedReadLock.lock()
        forcedReadPeerIds.insert(peerId)
        forcedReadLock.unlock()
    }

    static func consumeForcedRead(peerId: Int64) -> Bool {
        forcedReadLock.lock()
        defer {
            forcedReadLock.unlock()
        }
        return forcedReadPeerIds.remove(peerId) != nil
    }
}

// AyuGram: message filters. Incoming messages whose text matches any pattern are hidden.
public final class AyuFilters {
    private static let lock = NSLock()
    private static var cachedPatterns: [String]?
    private static var cachedRegexes: [NSRegularExpression] = []
    private static var cachedUserIds = Set<Int64>()
    private static var cachedChatRegexes: [Int64: [NSRegularExpression]] = [:]
    private static let storageKey = "ayu.filters"

    /// Entries of the form "chat:<peer id>:<pattern>" apply in that chat only.
    public static let chatPrefix = "chat:"

    public static func chatEntry(peerId: Int64, pattern: String) -> String {
        return "\(chatPrefix)\(peerId):\(pattern)"
    }

    /// Entries of the form "user:<id>" are shadow bans, not text patterns.
    public static let userPrefix = "user:"

    // Call with the lock held.
    private static func rebuildCacheIfNeeded() {
        if cachedPatterns != nil {
            return
        }
        let current = self.patterns
        cachedPatterns = current
        var regexes: [NSRegularExpression] = []
        var userIds = Set<Int64>()
        var chatRegexes: [Int64: [NSRegularExpression]] = [:]
        for pattern in current {
            if pattern.hasPrefix(userPrefix) {
                if let id = Int64(pattern.dropFirst(userPrefix.count)) {
                    userIds.insert(id)
                }
                continue
            }
            if pattern.hasPrefix(chatPrefix) {
                let rest = pattern.dropFirst(chatPrefix.count)
                if let separator = rest.firstIndex(of: ":"), let peerId = Int64(rest[rest.startIndex ..< separator]) {
                    let chatPattern = String(rest[rest.index(after: separator)...])
                    if let regex = try? NSRegularExpression(pattern: chatPattern, options: [.caseInsensitive]) {
                        chatRegexes[peerId, default: []].append(regex)
                    }
                }
                continue
            }
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                regexes.append(regex)
            }
        }
        cachedRegexes = regexes
        cachedUserIds = userIds
        cachedChatRegexes = chatRegexes
    }

    /// Shadow ban: messages from these users are hidden in groups and channels.
    public static func isShadowBanned(_ userId: Int64) -> Bool {
        lock.lock()
        rebuildCacheIfNeeded()
        let result = cachedUserIds.contains(userId)
        lock.unlock()
        return result
    }

    // Blocked users, mirrored from the account's data as it is loaded or changed,
    // so the chat can hide their messages without a database lookup.
    private static let blockedKey = "ayu.blockedPeerIds"
    private static var cachedBlocked: Set<Int64>?

    // Call with the lock held.
    private static func loadedBlocked() -> Set<Int64> {
        if let cachedBlocked = cachedBlocked {
            return cachedBlocked
        }
        let stored = (UserDefaults.standard.array(forKey: blockedKey) as? [NSNumber]) ?? []
        let loaded = Set(stored.map { $0.int64Value })
        cachedBlocked = loaded
        return loaded
    }

    public static func setBlocked(_ peerId: Int64, _ blocked: Bool) {
        lock.lock()
        var current = loadedBlocked()
        var changed = false
        if blocked {
            changed = current.insert(peerId).inserted
        } else {
            changed = current.remove(peerId) != nil
        }
        cachedBlocked = current
        lock.unlock()
        if changed {
            UserDefaults.standard.set(current.map { NSNumber(value: $0) }, forKey: blockedKey)
        }
    }

    public static func isBlocked(_ peerId: Int64) -> Bool {
        lock.lock()
        let result = loadedBlocked().contains(peerId)
        lock.unlock()
        return result
    }

    public static var patterns: [String] {
        return (UserDefaults.standard.array(forKey: storageKey) as? [String]) ?? []
    }

    public static func setPatterns(_ patterns: [String]) {
        UserDefaults.standard.set(patterns, forKey: storageKey)
        lock.lock()
        cachedPatterns = nil
        lock.unlock()
    }

    /// The filter list as text that can be pasted into another install.
    public static func exportString() -> String {
        let object: [String: Any] = ["version": 1, "filters": patterns]
        if let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]), let string = String(data: data, encoding: .utf8) {
            return string
        }
        return patterns.joined(separator: "\n")
    }

    /// Merges filters from exported text (or one pattern per line). Returns how many were added, nil if nothing usable was found.
    public static func importString(_ string: String) -> Int? {
        var incoming: [String] = []
        if let data = string.data(using: .utf8), let object = try? JSONSerialization.jsonObject(with: data, options: []) {
            if let dict = object as? [String: Any], let list = dict["filters"] as? [String] {
                incoming = list
            } else if let list = object as? [String] {
                incoming = list
            } else {
                return nil
            }
        } else {
            incoming = string.components(separatedBy: .newlines)
        }
        incoming = incoming.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty && $0.count <= 500 }
        if incoming.isEmpty {
            return nil
        }
        var current = patterns
        var added = 0
        for pattern in incoming {
            if !current.contains(pattern) {
                current.append(pattern)
                added += 1
            }
        }
        if added != 0 {
            setPatterns(current)
        }
        return added
    }

    public static func matches(_ text: String, peerId: Int64 = 0) -> Bool {
        if text.isEmpty {
            return false
        }
        lock.lock()
        rebuildCacheIfNeeded()
        var regexes = cachedRegexes
        if peerId != 0, let chatRegexes = cachedChatRegexes[peerId] {
            regexes.append(contentsOf: chatRegexes)
        }
        lock.unlock()
        let range = NSRange(text.startIndex..., in: text)
        for regex in regexes {
            if regex.firstMatch(in: text, options: [], range: range) != nil {
                return true
            }
        }
        return false
    }

    /// True when the text stacks many combining marks on its characters ("zalgo" text).
    public static func isZalgo(_ text: String) -> Bool {
        var combining = 0
        var total = 0
        for scalar in text.unicodeScalars {
            total += 1
            let value = scalar.value
            if (value >= 0x0300 && value <= 0x036F) || (value >= 0x1AB0 && value <= 0x1AFF) || (value >= 0x1DC0 && value <= 0x1DFF) || (value >= 0x20D0 && value <= 0x20FF) || (value >= 0xFE20 && value <= 0xFE2F) {
                combining += 1
            }
        }
        return combining >= 12 && combining * 3 >= total
    }

    public static func shouldHide(text: String, isIncoming: Bool, isPrivateChat: Bool, peerId: Int64 = 0) -> Bool {
        if !isIncoming || !AyuGramSettings.bool(.filtersEnabled) {
            return false
        }
        if isPrivateChat && !AyuGramSettings.bool(.filtersEnabledInChats) {
            return false
        }
        if AyuGramSettings.bool(.filterZalgo) && isZalgo(text) {
            return true
        }
        return matches(text, peerId: peerId)
    }
}
