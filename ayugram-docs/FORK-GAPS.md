# Features in Swiftgram and Nicegram that AyuGram for iOS lacks

Compiled 2026-11-24 from twelve research reports (full reports in the session notes folder
`fork-research/`). Sources: Swiftgram (github.com/Swiftgram/Telegram-iOS, swiftgram.app, App Store
id6471879502) and Nicegram (github.com/nicegram/Nicegram-iOS, nicegram.me, App Store id1608870673).
"SG" = Swiftgram, "NG" = Nicegram. Everything below runs on the device unless noted.

Nicegram's AI, hidden chats, keywords UI, backup and chat export live in a private package
(`packages/nicegram-assistant-ios`) that is empty in the public repo: those can only be rewritten,
not copied.

## Small

### Message menu and selection
- Save to Saved Messages in one tap (SG, NG)
- Select all from this user, up to 100-500 messages, for bulk forward/delete (SG, NG)
- Reply Privately to a group message (NG)
- Delete all service messages in a chat (NG)
- Selection bar: Save, Forward as Copy, Copy text of all selected (NG)
- Message as JSON (SG, NG; partly covered by Details)
- Forward in the link long-press menu (SG)
- Download a voice message as m4a to the share sheet (NG)
- Ban / Restrict directly from the menu for admins (NG)

### Chat and input
- Double-tap own message to edit (SG)
- Send with the keyboard's Return key (SG, NG)
- Hide the "Send As" button (SG)
- Turn off the deletion "dust" animation (SG)
- Turn off pull to next channel / topic (SG)
- Emoji tab first; standard emoji before custom packs (SG)
- Sticker size slider; hide time on stickers (SG)
- Wide channel posts (SG)
- Bring back a closed pinned-message bar (SG)
- Hide the camera tile or its live preview in the attachment picker (SG)
- Round videos start with the rear camera (SG, NG)
- Save manually downloaded videos to Photos (NG)

### Voice and translation
- On-device voice-to-text for non-Premium accounts: stock `localTranscription` path exists, only
  needs a setting and the speech permission (SG, NG)

### Chat list, tabs, folders
- Hide Contacts tab; tab names on/off; wide tab bar (SG, NG)
- Remember / open the last folder (SG, NG)
- Folders at the bottom (stock debug flag) (SG)
- Turn off chat-list swipe actions, or only swipe-to-delete (SG)
- Turn off pull-down story camera (SG)
- Folder tab spacing, "All" vs "All Chats" title (SG)

### Profiles and settings
- Call confirmation (SG, NG)
- Chat creation date, member join date, mutual-contact label, phone country (SG)
- Session api_id for unofficial sessions (SG)
- Long-press profile photo to save it (NG)
- All links in bios tappable (NG)
- Copy own ID in Settings (NG)
- Passcode auto-lock "Immediately" / 5 s / 10 s (SG, NG)
- More mute durations: 1 h, 4 h, 8 h, 1 day, 2 days (SG, NG)
- 1 GB cache option (SG)
- More than 3 accounts (SG unlimited, NG 1000) — our limit is in `AccountUtils.swift`
- Force device microphone, VoIP over TCP (stock debug flags) (SG)
- Proxy "use system DNS" (SG)
- Apply recommended privacy settings in one tap (NG; our own preset)
- Extra community language packs from Telegram's platform (SG, NG)
- Always allow YouTube picture-in-picture (SG, NG)

## Medium

- Translate button on foreign messages, translating in the bubble, with ignore list (SG, NG)
- Translate own draft before sending, language remembered per chat (SG, NG)
- Whole-chat translation through Google/Yandex without Premium (SG)
- Apple on-device translation as a provider (iOS 18 only; our test iPad is iOS 17.7) (SG, NG)
- Local quick replies typed with "&" (NG; stock quick replies need Premium)
- Send a gallery video as a round video (SG, NG)
- Formatting toolbar above the keyboard (SG Pro, code is local)
- Per-item switches for stock message-menu items (SG)
- Compact chat list, 1-2 preview lines (SG)
- Hide tab bar; search button in the tab bar (SG)
- Combined photo/video/GIF viewer; video controls in a menu; swipe up for PiP; AirPlay (SG)
- Send HD photos (2560 px) and a photo quality slider (SG)
- Upload / download boost (SG)
- Name-colour saturation slider (SG)
- Search field on the settings page (SG)
- Reset switches in the iOS Settings app for crash-on-launch recovery (SG)
- Hidden chats: hide from the list, mutes too (NG, logic closed)
- "Activities": a user's recent messages across groups you share (NG, Premium there)
- Voice typing into the draft with Apple speech recognition (NG idea, rebuilt locally)
- Hide account name in notifications; pinned / mention notification modes (SG Pro) — cannot
  be tested here: this install receives no pushes
- Registration date estimated locally from the user ID (SG and NG use their own servers)
- Chat export as text (NG, logic closed)

## Large

- Double Bottom: a second passcode showing a different set of accounts (NG)
- Keyword folder (NG)
- Call recording to Saved Messages or a chosen chat (NG; needs their WebRTC fork)
- Account session backup to Keychain / iCloud / file (SG Pro, NG): stores login keys, needs a
  security decision before building

## Not portable or not wanted

- Nicegram AI (assistant, AI replies, summaries, shortcuts, agent marketplace): Nicegram's paid
  backend. Could be rebuilt with the user's own API key or Apple's on-device models.
- Nicegram Calls, wallet / NFT / crypto Stars, account shop, ads and promo chats, data sharing,
  analytics, God's Eye / WhiteBridge people lookup, Swiftgram server announcements and paywall.
- Unlocking chats Telegram restricts on iOS (both forks use a server-provided list).
