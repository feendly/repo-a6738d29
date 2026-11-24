# AyuGram for iOS: feature status

One row per AyuGram Desktop setting or feature (source: `ayu/ayu_settings.h`
and the `ayu/features` and `ayu/ui` folders). Updated 2026-11-24 (run 45291403361 installed).

Status values:

- **TESTED**: implemented and seen working on the iPad.
- **LOG ONLY**: implemented; the app's log shows the right behaviour, but it
  has not been observed from the other account.
- **UNTESTED**: implemented and compiled (or compiling), not yet tried.
- **TODO**: not implemented.
- **N/A**: desktop-only; no iOS equivalent planned, or replaced as noted.

## Summary

| Status | Rows |
|---|---|
| TESTED | 80 |
| LOG ONLY | 4 |
| UNTESTED | 10 |
| TODO | 0 |
| N/A | 13 |

Some rows group several related desktop settings, so the row count is lower than the number of individual settings.

## Desktop look and layout (2026-11-23 parity pass)

Compared side by side with AyuGram Desktop 7.2.9 on the PC (account luki), and by three read-only code reviews
against the desktop source. Device results: TESTING rows 148 to 152.

- Settings follow desktop: "AyuGram Preferences" with a main page (logo, version, Categories, Links) and the
  AyuGram, Filters, General, Appearance, Chats and Other pages, with desktop's sections, order, names, texts and
  row icons (desktop's own icon files, converted by `F:\ayugram-ios\tmp\parity\gen_assets.py`). Desktop-only rows
  (tray, MD3 switches, window and bubble sliders, donations, crash reporting, URL scheme) are left out; the iOS-only
  switches are in Other.
- Deleted and edited marks with "Replace with Icons" use desktop's bin and pencil, tinted like the time.
- Message menu items use desktop's names, icons, order and Hidden / Shown / Extended Menu choice. iOS has no
  CTRL/SHIFT, so Extended Menu items sit in an "AyuGram" submenu of the message menu.
- Differences kept on purpose: the profile picker is a row ("Global Settings" or this account); Avatar Corners is
  Circle or Square, not a slider; a locked Ghost Mode option shows a lock symbol instead of being dimmed; the
  History screen is a sheet; Shot and Shadow Ban are message-menu items.
- Not ported yet (desktop has them): View Deleted, Show/Hide Filtered, Delete own messages, Open Channel, Burn,
  Copy Callback Data, Pack Owner in Details, the burnt-media icon beside the time, the deleted mark on service
  messages, AyuGram items in forum-topic menus, translucent deleted stickers and round videos, peer names and an
  add button in the Shadow Ban list, Select Chat for per-chat filters, and the AyuGram logo as the default app icon
  (the app still starts with Telegram's icon; the AyuGram icons are in Appearance).

## Ghost mode

| Setting | Desktop default | iOS status | Notes |
|---|---|---|---|
| sendReadMessages | on | TESTED | One tick stays on the sender's side with it off |
| sendReadStories | on | UNTESTED | Gate in place, no story test yet |
| sendOnlinePackets | on | LOG ONLY | |
| sendUploadProgress (typing) | on | LOG ONLY | |
| sendOfflinePacketAfterOnline | off | LOG ONLY | Log shows an offline status sent every 5 s while enabled |
| ghostModeActive (master switch) | off | TESTED | Flips the five switches both ways |
| markReadAfterAction | on | LOG ONLY | Reacting sends one read receipt (log `read forced`, `read push SENT`) |
| useScheduledMessages | off | TESTED | Only with online status off, as on desktop. Message arrives about 12 s later; input field clears at once (run 43012742764) |
| sendWithoutSound | Never | TESTED | Two switches: always, or only in ghost mode. Checked on the receiving account: a message sent with "Always Send Silently" arrives marked silent (TESTING row 146) |
| suggestGhostModeBeforeViewingStory | on | UNTESTED | Prompt when opening someone's stories from the chat list (run 43349311751). Ghost Mode stays on afterwards; desktop turns it off again when the story closes. Stories opened from a profile or a chat avatar are not covered |
| Per-setting "locked" flags (5) | off | TESTED | Five Lock switches. With Read Receipts locked, switching Ghost Mode on and off left it alone and changed the other four |
| useGlobalGhostMode (per-account ghost) | on | TESTED | "One Ghost Mode for All Accounts". Off: ghost switches and their locks are stored per account and follow the account in front (the only one that reads chats and goes online). Run 43814121847 |
| "Read message" context action | - | TESTED | "Send Read Receipt" in the long-press menu; nash saw two ticks (run 43002933120) |

## Message history

| Setting | Desktop default | iOS status | Notes |
|---|---|---|---|
| saveDeletedMessages | on | TESTED | Live deletion in a private chat. A deleted photo message keeps its picture when it had loaded before the deletion (TESTING row 114); voice and video not tried |
| saveMessagesHistory (edits) | on | TESTED | "Edit History" in the long-press menu |
| saveForBots | off | UNTESTED | |
| deletedMark | broom | TESTED | Broom shown. Custom mark: prompt opens with the current value; custom mark saved and shown (row 42) |
| editedMark | "edited" | TESTED | Custom text, run 43002933120 |
| semiTransparentDeletedMessages | off | TESTED | Bubble messages only (run 43084196247) |
| Deleted messages while app is closed | - | TESTED | App now stays running in the background (see Stay Connected). Kept a deletion sent from another device while the app was in the background (TESTING row 43). Not captured after a device reboot until the app runs again |
| Deleted messages in groups and channels | - | TESTED | Group: nash's message deleted for everyone stays visible for luki with the deleted mark. Channel: log only |
| Self-destructing media, cleared history, deleted chats | - | UNTESTED | View-once and timed photos, videos and voice messages are kept after they are opened or expire (follows the deleted-messages switch; not in secret chats). NEEDS THE USER: the test accounts cannot create view-once media without microphone, camera or photo access, which was not granted over VNC; send a view-once photo or voice message to nash or luki from another device, open it, and check it stays. Cleared history: TESTED in a private chat cleared for both by the other side; every message is kept, including the newest, which the server edits into an invisible "history cleared" service message (TESTING row 144). Deleted chats: TESTED; when the other side deletes a private chat for both, the chat stays in the list with every message kept and marked deleted (TESTING row 145) |
| Proper database instead of a plist file | - | N/A | NOT PORTED, FOR THE USER TO CONFIRM: internal storage only, nothing to see in the app. Kept deletions and edit history live in a plist store that has worked through every test; desktop's separate database is not needed for any ported feature |
| Edit history viewer | - | TESTED | Sheet listing each earlier version with its time and a copy button |

## Filters

| Setting | Desktop default | iOS status |
|---|---|---|
| filtersEnabled (regex filters) | off | TESTED (filter "blockme" hid nash's message for luki) |
| filtersEnabledInChats | off | TESTED |
| hideFromBlocked | off | TESTED (groups only: after luki blocked nash, nash's messages and join notice disappeared from the Test group. Only for users whose blocked state the app has loaded or changed since this version. The chat list preview shows "Filtered message" once the row is redrawn; the author's name stays) |
| shadowBanIds | empty | TESTED (via message menu, shown in the filter list as user:<id>) |
| filterZalgo | off | TESTED (nash's zalgo message hidden for luki, "Filtered message" in the chat list) |
| Per-chat filters, import/export | - | TESTED | "Add to Filters for This Chat" in the message menu stores `chat:<id>:<pattern>`; "Copy Filters to Clipboard" and "Import Filters from Clipboard" in settings (own JSON format, not desktop's). Run 43806809468. Not checked that the same text stays visible in another chat |

## Premium, ads and clutter

| Setting | Desktop default | iOS status | Notes |
|---|---|---|---|
| disableAds | on | UNTESTED | Needs a channel that shows ads; the one checked (32K subscribers) showed none even with the switch off |
| localPremium | off | TESTED | Client side: premium flag for the logged-in accounts (star, premium-only rows). Server-enforced features stay locked. Restart to apply |
| premiumStickersAsCopy | on | TESTED | Not in AyuGram Desktop; added at the user's request. Re-uploads a premium sticker and sends the copy. Animated stickers tested; user confirmed it shows as a sticker on another device; video stickers not checked. From run 43330220187 the copy send closes the panel, clears the reply bar and keeps the reply like a normal send (confirmed by the user) |
| Filtered/hidden messages in chat list preview | - | TESTED | Shows "Filtered message" |
| disableStories | off | UNTESTED | Switch on; no stories were available to compare (tried again on November 16: none in nash's chat list with the switch off either) |
| disableCustomBackgrounds | off | UNTESTED | Ignores a photo wallpaper set for one chat, as on desktop; chat themes are left alone (seen November 16: a chat theme stayed with the switch on, which matches desktop). NEEDS THE USER: setting a photo wallpaper needs Photos access |
| disableOpenLinkWarning | off | TESTED | Hidden links in chats and in profiles open without "Open link?"; links with a login part and proxy links still ask (TESTING row 133) |
| disableNotificationsDelay | off | N/A | Desktop delays its own notifications while another device is online; iOS notifications come from Apple's push service and have no such delay to remove |
| disableGreetingSticker | off | TESTED | An empty private chat shows only "No messages here yet...": no sticker, no "tap on the greeting below" (TESTING row 140) |
| hidePremiumStatuses | off | TESTED | Chat list only: the status icon next to a contact's name disappears |
| collapseSimilarChannels | on | TESTED | Similar channels under the "you joined" notice start collapsed; tapping the notice opens them. Channels whose list was already loaded keep their state |
| hideSimilarChannels | off | TESTED | The Similar Channels panel shown after joining a channel is gone with the switch on (run 43536445199) |
| showOnlyAddedEmojisAndStickers | off | TESTED | Sticker panel only: trending strip and suggested packs gone after reopening the chat. Emoji panel not covered |
| unlimitedRecentStickers | off | TESTED | Keeps up to 200 recent stickers on the device instead of 20; 22 kept after 23 were sent (TESTING row 137). After switching off the list shrinks back one sticker at a time as new ones are sent, as the stock store trims |

## Send confirmations

| Setting | Desktop default | iOS status |
|---|---|---|
| stickerConfirmation | off | TESTED (alert and Cancel; OK path not tried) |
| gifConfirmation | off | TESTED (saved, recent, search and trending GIFs; Cancel and OK) |
| voiceConfirmation | off | UNTESTED (run 43002933120; covers recordings sent from the preview, not hold-and-release) |
| roundConfirmation | off | UNTESTED (same switch as voice) |

## Appearance

| Setting | Desktop default | iOS status | Notes |
|---|---|---|---|
| showMessageSeconds | off | TESTED | |
| showPeerId | Bot API | TESTED | ID row in user profiles; on/off only |
| appIcon | default | TESTED | The 12 AyuGram Desktop icons (Default, Alt, Discord, Spotify, Extera, Nothing, Bard, YaPlus, Win95, Chibi, Chibi2, Extera2) are in the stock picker, Settings, Appearance, App Icon. Converted from the round desktop artwork and filled to a square with the edge colour. Run 43820003583; the home screen itself was not looked at (not reachable over VNC) |
| monoFont / main font | system | TESTED | "Monospace Font" row takes a font name; regular weight only (bold and italic monospace stay Menlo). Desktop has no separate main-font setting. Run 43814121847 |
| messageBubbleRadius | 16 | N/A | Stock setting exists: Appearance, Message Corners |
| removeMessageTail | off | TESTED | |
| avatarCorners | 23 | TESTED | On/off switch for rounded squares, not a radius slider; restart to apply |
| singleCornerRadius | off | TESTED | "Round Avatars for Forums Too": forum chats use the same avatar shape as other chats; restart to apply (TESTING row 131) |
| materialSwitches | on | N/A | iOS uses system switches |
| simpleQuotesAndReplies | off | TESTED | Reply, quote and link preview blocks lose the fill and emoji pattern; the side line stays (run 43536445199, checked on a link preview) |
| replaceBottomInfoWithIcons | on | TESTED | "Icons Instead of Edited and Deleted Marks": a pencil glyph for edited and a bin glyph for deleted next to the time, overriding the custom marks. Text glyphs, not drawn icons as on desktop (run 43556106622) |
| adaptiveCoverColor | on | N/A | NOT PORTED, FOR THE USER TO CONFIRM: tints desktop AyuGram's own profile-music button with the cover's colour. iOS shows profile music with the stock design, which has no such button (see Saved music) |
| improveLinkPreviews | off | TESTED | Previews for X, TikTok, Reddit, Instagram and Pixiv links are requested from the mirror hosts desktop uses; the message text keeps the original link (run 43561780256) |
| hideFastShare | off | TESTED | Share arrow next to channel posts gone |
| showChannelReactions | on | TESTED | Reaction row under a channel post hidden with the switch off |
| showGroupReactions | on | TESTED | Run 43002933120 |
| showPrivateChatReactions | on | TESTED | Reaction hidden with the switch off |
| wideMultiplier | 1.0 | N/A | Desktop window layout |
| hideNotificationCounters | off | TESTED | Chats tab counter only (run 43084196247) |
| hideNotificationBadge | off | UNTESTED | With the app in front the badge is cleared and comes back when switched off (TESTING row 135). From run 43968637447 the switch is copied into the app group and the notification extension sets the badge to 0; the copy was seen, but no push arrived during a 10-minute background watch (row 142). Needs a message in an unmuted chat while the app is in the background. CANNOT BE SEEN ON THE TEST IPAD: no push reaches this TrollStore install at all (row 147: an unmuted chat got a message with the app in the background and iOS recorded no notification), so the extension never runs. Needs an install that receives pushes |
| hideAllChatsFolder | off | TESTED | Hides the All Chats tab when there is at least one folder and starts on the first folder. The All Chats list stays reachable from the Chats tab long-press menu (no tab is highlighted then); swiping does not reach it |
| channelBottomButton | Discuss | TESTED | Two switches: "Discuss Instead of Mute" (on by default; only for channels with a discussion group, others keep Mute) and "Hide". Discuss opens the linked group (run 43527721168) |
| quickAdminShortcuts | on | TESTED | Recent Actions (admins) and Administrators (group members, channel admins) in the menu shown by holding the chat avatar; desktop has top-bar buttons. Administrators seen working (run 43561780256); Recent Actions seen in a group with topics, whose own top-right menu carries both items (TESTING row 134). A basic group has neither item |

## Message field buttons

| Setting | Desktop default | iOS status |
|---|---|---|
| showAttachButtonInMessageField | on | TESTED (run 43084196247) |
| showCommandsButtonInMessageField | on | TESTED (a bot's "Open" menu button disappears; a bot with the "/" commands button was not at hand) |
| showEmojiButtonInMessageField | on | TESTED |
| showMicrophoneButtonInMessageField | on | TESTED |
| showAutoDeleteButtonInMessageField | on | TESTED (the "1mo" timer button disappears) |
| showGiftButtonInMessageField | on | TESTED | Hides the gift button in a channel's bottom bar (run 43527721168). No chat at hand shows the button in the message field itself, so that place is unverified |
| showAiEditorButtonInMessageField | on | TESTED | The AI button that appears above the attach button once a draft reaches three lines (run 43536445199) |
| showAttachPopup | on | N/A (hover popup) |
| showEmojiPopup | on | N/A (hover popup) |

## Context menu items

| Setting | Desktop default | iOS status |
|---|---|---|
| showReactionsPanelInContextMenu | Visible | TESTED (on/off only, run 43084196247) |
| showViewsPanelInContextMenu | Visible | TESTED (on/off only, run 43084196247) |
| showHideMessageInContextMenu | Hidden | TESTED (Message disappears on this device and stays hidden after reopening) |
| showUserMessagesInContextMenu | With modifier | TESTED ("User Messages" in a group opens the search filtered to that member) |
| showMessageDetailsInContextMenu | With modifier | TESTED (Alert with message, chat and sender IDs and date) |
| showRepeatMessageInContextMenu | Hidden | TESTED (text messages only) |
| showAddFilterInContextMenu | Visible | TESTED (Adds the text as a filter; matching messages hide; tap the filter in settings to remove) |

## Side drawer and tray (desktop navigation)

| Setting | iOS status | Notes |
|---|---|---|
| showMyProfileInDrawer, showBotsInDrawer, showNewGroupInDrawer, showNewChannelInDrawer, showContactsInDrawer, showCallsInDrawer, showSavedMessagesInDrawer, showNightModeToggleInDrawer | N/A | iOS has no drawer |
| showLReadToggleInDrawer / showSReadToggleInDrawer | TESTED | Both items appear in the Settings tab long-press menu and Read on Server asks for confirmation (run 43322077655). The actions themselves were not run: they mark every chat of the account as read |
| showGhostToggleInDrawer | TESTED | Long-press the Settings tab: Turn Ghost Mode On/Off |
| showStreamerToggleInDrawer | TESTED | "Turn Streamer Mode On/Off" in the Settings tab long-press menu; the label flips after each tap |
| showGhostToggleInTray / showStreamerToggleInTray | N/A | Could map to home-screen quick actions |

## Larger features

| Feature | iOS status | Notes |
|---|---|---|
| AyuGram settings screen | TESTED | Ghost, history, filters and other sections; Add Filter prompt works |
| Streamer mode | TESTED | Hides own phone number in Settings only (run 43084196247) |
| Message shot (messages as image) | TESTED | "Message Shot" in the message menu renders the message (or the selected messages on screen) into one image and opens the share sheet. Desktop's theme and layout options are not ported. Run 43814121847; the image itself was not opened, only its size in the log |
| Forward without author / from restricted chats / repeat message | TESTED | Hiding the sender name is a stock option in the forward panel. Repeat is the context-menu item (text messages). With "Allow Copy and Save in Restricted Chats" on, Copy and Forward show in chats with protected content and the message goes out as a copy; a text message from a restricted group arrived with no "Forwarded from" header (TESTING row 129). The switch also lifts the screen-capture protection of such chats (row 130). Photos and files are sent by reference, no re-upload, and albums are not kept together; neither was tried |
| Translator providers (Telegram, Google, Yandex, native) | TESTED | "Translator" row in the Other section cycles Telegram, Google, Yandex. Google and Yandex use desktop's endpoints for the Translate action; plain text only (formatting is dropped), and chat-wide auto-translate stays on Telegram. No separate "native" provider. Run 43827376720 |
| Webview options (spoof Android, larger size) | TESTED | "Report Android to Mini Apps" TESTED by log (the mini app address from the server says ios with it off and android with it on). The two size options resize the desktop mini app window and have no iOS equivalent |
| `tg://ayu` settings links | TESTED | `tg://ayusettings` opens the AyuGram screen |
| Saved music, cover search | N/A | NOT PORTED, FOR THE USER TO CONFIRM: stock Telegram for iOS already shows profile music and looks up missing album art itself. Desktop AyuGram's additions are its own button design and an iTunes cover lookup for that button |
| Crash reporting to AyuGram | N/A | Deliberately not ported |
| Donate / plugin info boxes | N/A | Desktop project specific |

## iOS-only additions

| Feature | Status | Notes |
|---|---|---|
| Stay Connected in Background | TESTED | Kept a deletion sent from another device while the app was in the background (TESTING row 43). Shows the system location indicator |
| All accounts receive updates at once | TESTED | Part of keep-alive. Seen in TESTING row 114: nash received luki's message and kept its deletion while luki was the account in front |
| Debug log and test override files | TESTED | Test aids; to be removed or hidden before release |
| Link cleaner for outgoing messages | TESTED | Requested by the user 2026-11-12. "Remove Tracking from Links I Send" drops known tracking parameters; "Strict Link Cleaning" drops every parameter a site does not need and the fragment, after Link Cleaner (corbindavenport/link-cleaner-js, MIT). Only text the system link detector recognises as a web link is changed, bare domains included; Telegram links and code are left alone. Edited messages are not covered |
| Edit Sticker on premium stickers | TESTED | Requested by the user 2026-11-12. Offered when Send Premium Stickers as a Copy is on; the edited sticker is a new upload and is delivered. The editor produces a still image, so the animation is lost. Checked from the sticker panel menu, not from the message menu |
