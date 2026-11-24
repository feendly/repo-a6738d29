# AyuGram for iOS: gaps against AyuGram Desktop

Work queue from a read-only audit of AyuGram Desktop's source (`F:\ayugram-ios\AyuGramDesktop`, all 403 `ayu_`
strings and the 199 stock files AyuGram patches) against this port, 2026-11-24. Desktop paths are relative to
`Telegram/SourceFiles/`; iOS paths to `submodules/`. Strings that desktop code never uses (Android-only features
such as Peek Online, read and typing exclusions, Save Last Seen Date, database export) are not listed.

Order of work: ghost-mode leaks first, then tracker corrections, then missing features by size.

Fixed since the audit and tested on the iPad (TESTING rows 153-161): deleted and edited icons, Add Filter editor,
chat menu items, folder tab counters, the reaction picker where reactions are hidden, Filter Zalgo stripping, filter
scope for private chats, deleted stickers kept and dimmed, basic group ID.

Fixed, not yet tested: channel views, thread reads and pinned-story views in ghost mode, scheduled sending rules,
shadow bans and blocked users under Enable Filters and covering forwards, Disable Ads for sponsored search results and
the promoted chat, seconds in last-seen times, messages removed by auto-delete kept (commits d713406a to 94f4587a);
seconds in read, edited and sent times in the message menu, Send With Sound, tg://chat?id=, tg://ayusettings?s=,
"User not found.", the unread-reaction button and badge where reactions are hidden, the datacenter as the ID row
label, the "ID copied" toast, topic IDs (commit b0751176); Read on Interact after sending, poll votes, bot peer
requests, Send Now and quick replies, Read Message up to the chosen message, the "Official app" session row, Pack
Owner and Copy ID in the sticker pack menu, replies to kept deleted messages as quotes, forwards of them as copies,
the time on service messages, Show/Hide Filtered, Open Channel, Shadow Ban and Delete own messages in the chat menu,
search by ID, View Deleted, Copy Callback Data, story rings removed with Disable Stories (the commit after
b0751176). STATUS.md rows were rewritten to match.

Left in section 1 on purpose: desktop still marks mentions and reactions read in ghost mode; the port does not send
them, which is stricter (for the user to confirm).

## 1. Ghost mode leaks (activity still sent while it should not be)

| Gap | Desktop | iOS |
|---|---|---|
| Channel post views counted with read receipts off | `api/api_views.cpp:106` passes increment = sendReadMessages | `TelegramCore/Sources/State/AccountViewTracker.swift:739` always increments |
| Forum topics and comment threads send read receipts | `data/data_replies_list.cpp:1012` gated | `TelegramEngine/Messages/ApplyMaxReadIndexInteractively.swift:222, 258, 300`, `ReplyThreadHistory.swift:392, 401` not gated |
| Pinned and profile stories send views | `data/data_stories.cpp:1466` gated | `TelegramEngine/Messages/Stories.swift:2126` not gated |
| Mentions and reactions marked read | still sent on desktop (`apiwrap.cpp:1466, 1476`) | never sent in ghost mode (`ManagedConsumePersonalMessagesActions.swift:256`) |
| Scheduled sending | requires Ghost Mode active (`ayu/ayu_settings.h:100`); delay grows with file size, 17 s for albums, x1.2 behind a proxy | checks only the online switch, always +12 s (`EnqueueMessage.swift:819, 823`) |
| Read on Interact | after sending, reaction, poll vote, bot button, "send now", quick reply | after a reaction only (`MessageReactions.swift:26`) |
| Read Message | reads up to the chosen message, marks its media, mentions and reactions | pushes the chat's local read state (`SynchronizePeerReadState.swift:475`) |

## 2. STATUS.md rows that describe the wrong thing

- filterZalgo: desktop strips the combining marks (text, names, signatures) and works without Enable Filters; the
  port hides the whole message and only while filters are on.
- filtersEnabledInChats: desktop's switch covers every chat except broadcast channels (groups too); the port
  treats it as private chats only.
- Streamer mode: desktop hides the app's windows from screen capture; the port hides the phone number in Settings.
- hideNotificationCounters: desktop hides the unread counters on the folder tabs; the port hides the Chats tab badge.
- showGiftButtonInMessageField: desktop always hides the channel gift button and the switch covers user chats.
- Copy and save in restricted chats: desktop allows it always; the port has a switch, off by default.
- Rows written before the 2026-11-23 rework still describe the old controls (see the parity section of STATUS.md).

## 3. Missing features

Message history and forwarding
- Messages removed by a chat's auto-delete timer are kept as deleted on desktop (`history/history_item.cpp:4409`);
  the port deletes them (`ManagedAutoremoveMessageOperations.swift:85`).
- Replying to a kept deleted message sends a quote block with the author and text (`ayu/utils/telegram_helpers.cpp:1033`).
- Forwarding a kept deleted message or self-destructing media sends a copy (`ayu/features/forward/ayu_forward.cpp:236`).
- View Deleted, Clear Deleted (Clear Deleted is now ported), Show/Hide Filtered in the chat menu.
- Burn (expire view-once media), the burnt icon beside the time, the deleted mark on service messages.
- Time badge on service messages (`history/view/history_view_service_message.cpp:525`).

Sending
- "Send With Sound" when silent sending is the default (`menu/menu_send.cpp:757`).
- "Send as Sticker" for one image in the send box (`boxes/send_files_box.cpp:1279`).
- Free custom emoji through tg://emoji?id= links, sent and drawn (`ayu/utils/telegram_helpers.cpp:1147, 1205`).

Profiles, search, lists
- Registration / creation / join date popup on the ID row (`info/profile/info_profile_actions.cpp:1419`).
- Peer ID for basic groups and topics, own ID on the Settings page, datacenter as the row label, "ID copied" toast.
- Search by ID ("Found by ID") and "ID: n" under results (`dialogs/dialogs_widget.cpp:3377`).
- tg://chat?id= links and "User not found." (`ayu/ayu_url_handlers.cpp:66`).
- tg://ayusettings?s=<setting> opening one setting.
- Mutual contact icon and toast (`boxes/peer_list_controllers.cpp:76`).
- "Official app" row in session details (`settings/sections/settings_active_sessions.cpp:465`).
- Sticker pack box: Copy ID and Pack Owner; Pack Owner in Details.
- Delete own messages and Open Channel in the chat menu; AyuGram items in forum-topic menus.
- Developer, supporter and official badges (need AyuGram's remote config; possibly N/A).

Filters
- Per-filter Case Insensitive and Reversed; album captions, button text and type tags in the matched text.
- View Filters for one chat with Excluded Filters; Select Chat.
- Import from URL, publish on dpaste, "Apply filter changes?" sheet; desktop's export format.
- Shadow ban and blocked users also cover channels, forwards and via-bot messages, typing status, reactions,
  comment avatars and notifications; Shadow Ban in the profile menu.

Appearance and clutter
- disableAds also blocks sponsored search results and the promoted chat.
- disableStories also stops loading stories and removes story rings in the chat list and profiles.
- Hide Reactions also hides the reaction picker in the message menu and the unread-reaction badge.
- Show Message Seconds also covers last-seen text and read/reacted times.
- Translucent deleted stickers and round videos; channel author tag as an icon with Replace with Icons.
- AyuGram logo as the default app icon.

Media
- Save and copy for view-once media and any story; changed tooltips on kept view-once media.

Other
- Local Premium notice on the Premium screen; translated AyuGram strings (all text is English);
  "Copy Callback Data"; "Plain forwarding is not allowed." note.

Desktop-only, judged N/A (for the user to confirm): reordering files in the send box, seeking round videos in the
viewer, Spotify links opening the app, phone-number click falling back to a user ID, the Windows jump list,
Update AyuGram button, plugin files, Register URL Scheme.
