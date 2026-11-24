// AyuGram: storage for deleted-message marks and edit history.
//
// Deleted messages are kept in Postbox untouched; this store only remembers
// which ones the server deleted, and the previous texts of edited messages.

import Foundation
import Postbox
import SwiftSignalKit

public final class AyuMessagesStore {
    public struct Edit {
        public let text: String
        public let timestamp: Int32
    }

    public static let shared = AyuMessagesStore()

    private let lock = NSLock()
    private let writeQueue = DispatchQueue(label: "ayugram.messages-store")
    private var deletedByKey: [String: Int32] = [:]
    private var editsByKey: [String: [[String: Any]]] = [:]
    private var hiddenKeys = Set<String>()
    private var writeScheduled = false
    private let path: String

    private init() {
        let directory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? NSTemporaryDirectory()
        self.path = (directory as NSString).appendingPathComponent("ayu-messages.plist")
        if let root = NSDictionary(contentsOfFile: self.path) {
            if let deleted = root["deleted"] as? [String: NSNumber] {
                for (key, value) in deleted {
                    self.deletedByKey[key] = value.int32Value
                }
            }
            if let edits = root["edits"] as? [String: [[String: Any]]] {
                self.editsByKey = edits
            }
            if let hidden = root["hidden"] as? [String] {
                self.hiddenKeys = Set(hidden)
            }
        }
        // Diagnostics: a kept message should only leave storage when the user deletes it. Log every other way it
        // goes, with the code that asked (the newest message of a cleared private chat disappears after being kept).
        ayuPostboxRemovalObserver = { ids, site in
            let kept = ids.filter { AyuMessagesStore.shared.isDeleted($0) }
            if !kept.isEmpty {
                AyuGramSettings.debugLog("kept message removed \(kept.map { "\($0.peerId.toInt64()):\($0.namespace):\($0.id)" }) by \(site)")
            }
        }
    }

    private static func key(_ id: MessageId) -> String {
        return "\(id.peerId.toInt64()):\(id.namespace):\(id.id)"
    }

    public func isDeleted(_ id: MessageId) -> Bool {
        let key = AyuMessagesStore.key(id)
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        return self.deletedByKey[key] != nil
    }

    public func markDeleted(_ id: MessageId, timestamp: Int32) {
        let key = AyuMessagesStore.key(id)
        self.lock.lock()
        self.deletedByKey[key] = timestamp
        self.lock.unlock()
        self.scheduleWrite()
    }

    /// Ids of the kept deleted messages of one chat.
    public func deletedIds(peerId: PeerId) -> [MessageId] {
        let prefix = "\(peerId.toInt64()):"
        self.lock.lock()
        let keys = self.deletedByKey.keys.filter { $0.hasPrefix(prefix) }
        self.lock.unlock()
        var result: [MessageId] = []
        for key in keys {
            let parts = key.dropFirst(prefix.count).split(separator: ":")
            if parts.count == 2, let namespace = Int32(parts[0]), let id = Int32(parts[1]) {
                result.append(MessageId(peerId: peerId, namespace: namespace, id: id))
            }
        }
        return result
    }

    /// Drops the deleted marks of messages that were removed from this device.
    public func forgetDeleted(_ ids: [MessageId]) {
        self.lock.lock()
        for id in ids {
            self.deletedByKey.removeValue(forKey: AyuMessagesStore.key(id))
        }
        self.lock.unlock()
        self.scheduleWrite()
    }

    public func isHidden(_ id: MessageId) -> Bool {
        let key = AyuMessagesStore.key(id)
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        return self.hiddenKeys.contains(key)
    }

    public func markHidden(_ id: MessageId) {
        let key = AyuMessagesStore.key(id)
        self.lock.lock()
        self.hiddenKeys.insert(key)
        self.lock.unlock()
        self.scheduleWrite()
    }

    public func addEdit(_ id: MessageId, previousText: String, timestamp: Int32) {
        let key = AyuMessagesStore.key(id)
        self.lock.lock()
        var list = self.editsByKey[key] ?? []
        list.append(["text": previousText, "date": NSNumber(value: timestamp)])
        self.editsByKey[key] = list
        self.lock.unlock()
        self.scheduleWrite()
    }

    public func edits(_ id: MessageId) -> [Edit] {
        let key = AyuMessagesStore.key(id)
        self.lock.lock()
        let list = self.editsByKey[key] ?? []
        self.lock.unlock()
        var result: [Edit] = []
        for item in list {
            if let text = item["text"] as? String {
                let timestamp = (item["date"] as? NSNumber)?.int32Value ?? 0
                result.append(Edit(text: text, timestamp: timestamp))
            }
        }
        return result
    }

    private func scheduleWrite() {
        self.lock.lock()
        let alreadyScheduled = self.writeScheduled
        self.writeScheduled = true
        self.lock.unlock()
        if alreadyScheduled {
            return
        }
        self.writeQueue.asyncAfter(deadline: .now() + 1.0, execute: { [weak self] in
            guard let self = self else {
                return
            }
            self.lock.lock()
            self.writeScheduled = false
            var deleted: [String: NSNumber] = [:]
            for (key, value) in self.deletedByKey {
                deleted[key] = NSNumber(value: value)
            }
            let root: [String: Any] = ["deleted": deleted, "edits": self.editsByKey, "hidden": Array(self.hiddenKeys)]
            self.lock.unlock()
            let _ = (root as NSDictionary).write(toFile: self.path, atomically: true)
        })
    }
}

// Rewrites a message unchanged so its version changes and the chat redraws it.
private func ayuTouchMessage(transaction: Transaction, id: MessageId) {
    transaction.updateMessage(id, update: { currentMessage in
        var storeForwardInfo: StoreMessageForwardInfo?
        if let forwardInfo = currentMessage.forwardInfo {
            storeForwardInfo = StoreMessageForwardInfo(authorId: forwardInfo.author?.id, sourceId: forwardInfo.source?.id, sourceMessageId: forwardInfo.sourceMessageId, date: forwardInfo.date, authorSignature: forwardInfo.authorSignature, psaType: forwardInfo.psaType, flags: forwardInfo.flags)
        }
        return .update(StoreMessage(id: currentMessage.id, customStableId: nil, globallyUniqueId: currentMessage.globallyUniqueId, groupingKey: currentMessage.groupingKey, threadId: currentMessage.threadId, timestamp: currentMessage.timestamp, flags: StoreMessageFlags(currentMessage.flags), tags: currentMessage.tags, globalTags: currentMessage.globalTags, localTags: currentMessage.localTags, forwardInfo: storeForwardInfo, authorId: currentMessage.author?.id, text: currentMessage.text, attributes: currentMessage.attributes, media: currentMessage.media))
    })
}

/// Makes the chat showing this message rebuild its list, so new filters apply at once.
public func ayuRefreshMessage(account: Account, id: MessageId) -> Signal<Never, NoError> {
    return account.postbox.transaction { transaction -> Void in
        ayuTouchMessage(transaction: transaction, id: id)
    }
    |> ignoreValues
}

/// "Clear Deleted": removes the kept deleted messages of one chat from this device for good.
public func ayuClearDeletedMessages(account: Account, peerId: PeerId) -> Signal<Never, NoError> {
    let ids = AyuMessagesStore.shared.deletedIds(peerId: peerId)
    if ids.isEmpty {
        return .complete()
    }
    AyuGramSettings.debugLog("clear deleted peer=\(peerId.toInt64()) count=\(ids.count)")
    return account.postbox.transaction { transaction -> Void in
        // Forgotten first, so the removal is not logged as a kept message going missing.
        AyuMessagesStore.shared.forgetDeleted(ids)
        _internal_deleteMessages(transaction: transaction, mediaBox: account.postbox.mediaBox, ids: ids)
    }
    |> ignoreValues
}

/// Hides a message on this device only. The message stays on the server and for everyone else.
public func ayuHideMessageLocally(account: Account, id: MessageId) -> Signal<Never, NoError> {
    AyuMessagesStore.shared.markHidden(id)
    return account.postbox.transaction { transaction -> Void in
        ayuTouchMessage(transaction: transaction, id: id)
    }
    |> ignoreValues
}

/// Decides what happens to messages the server reports as deleted.
/// Returns the ids that should really be removed; the rest are kept and marked as deleted.
func ayuKeepRemotelyDeletedMessages(transaction: Transaction, ids: [MessageId]) -> [MessageId] {
    if !AyuGramSettings.bool(.saveDeletedMessages) {
        return ids
    }
    let saveForBots = AyuGramSettings.bool(.saveForBots)
    let timestamp = Int32(Date().timeIntervalSince1970)
    var idsToDelete: [MessageId] = []
    for id in ids {
        if id.namespace != Namespaces.Message.Cloud {
            idsToDelete.append(id)
            continue
        }
        guard let _ = transaction.getMessage(id) else {
            idsToDelete.append(id)
            continue
        }
        if !saveForBots, let user = transaction.getPeer(id.peerId) as? TelegramUser, user.botInfo != nil {
            idsToDelete.append(id)
            continue
        }
        if AyuMessagesStore.shared.isDeleted(id) {
            continue
        }
        AyuMessagesStore.shared.markDeleted(id, timestamp: timestamp)
        AyuGramSettings.debugLog("deleted message kept \(id)")
        // Rewrite the message unchanged so its version changes and the chat redraws it with the deleted mark.
        transaction.updateMessage(id, update: { currentMessage in
            return .update(ayuUnchangedStoreMessage(currentMessage))
        })
    }
    return idsToDelete
}

/// `message` as a StoreMessage with nothing changed. Writing it back bumps the message's version, so the chat redraws
/// it (with the deleted mark when it has just been marked).
func ayuUnchangedStoreMessage(_ currentMessage: Message) -> StoreMessage {
    var storeForwardInfo: StoreMessageForwardInfo?
    if let forwardInfo = currentMessage.forwardInfo {
        storeForwardInfo = StoreMessageForwardInfo(authorId: forwardInfo.author?.id, sourceId: forwardInfo.source?.id, sourceMessageId: forwardInfo.sourceMessageId, date: forwardInfo.date, authorSignature: forwardInfo.authorSignature, psaType: forwardInfo.psaType, flags: forwardInfo.flags)
    }
    return StoreMessage(id: currentMessage.id, customStableId: nil, globallyUniqueId: currentMessage.globallyUniqueId, groupingKey: currentMessage.groupingKey, threadId: currentMessage.threadId, timestamp: currentMessage.timestamp, flags: StoreMessageFlags(currentMessage.flags), tags: currentMessage.tags, globalTags: currentMessage.globalTags, localTags: currentMessage.localTags, forwardInfo: storeForwardInfo, authorId: currentMessage.author?.id, text: currentMessage.text, attributes: currentMessage.attributes, media: currentMessage.media)
}

/// When the other side clears a chat's history for both, the server deletes every message but the newest, which it
/// turns into an invisible "history cleared" service message by an edit. With deleted messages kept, that edit is
/// a deletion: the message stays as it was, marked deleted. Returns the write to make instead of the edit, or nil to
/// apply the edit.
func ayuKeepMessageReplacedByHistoryClear(id: MessageId, previous: Message, edit: StoreMessage) -> StoreMessage? {
    guard AyuGramSettings.bool(.saveDeletedMessages), id.namespace == Namespaces.Message.Cloud else {
        return nil
    }
    let isHistoryClear: (Media) -> Bool = { media in
        if let action = media as? TelegramMediaAction, case .historyCleared = action.action {
            return true
        }
        return false
    }
    guard edit.media.contains(where: isHistoryClear), !previous.media.contains(where: isHistoryClear) else {
        return nil
    }
    if !AyuGramSettings.bool(.saveForBots), let user = previous.peers[id.peerId] as? TelegramUser, user.botInfo != nil {
        return nil
    }
    if !AyuMessagesStore.shared.isDeleted(id) {
        AyuMessagesStore.shared.markDeleted(id, timestamp: Int32(Date().timeIntervalSince1970))
    }
    AyuGramSettings.debugLog("deleted message kept \(id) (history cleared)")
    return ayuUnchangedStoreMessage(previous)
}

/// Messages fetched from the server, minus the "history cleared" placeholders that would overwrite a stored message
/// kept by `ayuKeepMessageReplacedByHistoryClear` (a history fill or a confirmation brings the placeholder back).
func ayuDropHistoryClearOverKept(transaction: Transaction, messages: [StoreMessage]) -> [StoreMessage] {
    guard AyuGramSettings.bool(.saveDeletedMessages) else {
        return messages
    }
    return messages.filter { message in
        guard case let .Id(id) = message.id, let previous = transaction.getMessage(id) else {
            return true
        }
        if let kept = ayuKeepMessageReplacedByHistoryClear(id: id, previous: previous, edit: message) {
            transaction.updateMessage(id, update: { _ in .update(kept) })
            return false
        }
        return true
    }
}

/// The newest `limit` messages of `authorId` stored in this chat (service messages left out), oldest first,
/// for "Select from User".
public func ayuMessageIdsFromAuthor(account: Account, peerId: EnginePeer.Id, authorId: EnginePeer.Id, threadId: Int64?, limit: Int) -> Signal<[EngineMessage.Id], NoError> {
    return account.postbox.transaction { transaction -> [EngineMessage.Id] in
        var result: [EngineMessage.Id] = []
        transaction.withAllMessages(peerId: peerId, { candidate in
            if candidate.author?.id == authorId && !candidate.media.contains(where: { $0 is TelegramMediaAction }) {
                if threadId == nil || candidate.threadId == threadId {
                    result.append(candidate.id)
                }
            }
            return true
        })
        if result.count > limit {
            result = Array(result.suffix(limit))
        }
        return result
    }
}

