// AyuGram: message shot. Renders messages that are on screen into one image and opens the share sheet.

import Foundation
import UIKit
import Display
import TelegramCore
import Postbox
import TelegramPresentationData
import AccountContext
import ChatMessageItemView
import ChatMessageItem

extension ChatControllerImpl {
    func ayuPresentMessageShot(messageIds: Set<MessageId>) {
        var shots: [(index: MessageIndex, image: UIImage)] = []
        self.chatDisplayNode.historyNode.forEachVisibleMessageItemNode { itemNode in
            guard let item = itemNode.item else {
                return
            }
            var matches = false
            for (message, _) in item.content {
                if messageIds.contains(message.id) {
                    matches = true
                    break
                }
            }
            if !matches {
                return
            }
            let bounds = itemNode.view.bounds
            if bounds.width <= 0.0 || bounds.height <= 0.0 {
                return
            }
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            let image = renderer.image { _ in
                itemNode.view.drawHierarchy(in: bounds, afterScreenUpdates: false)
            }
            shots.append((item.message.index, image))
        }
        if shots.isEmpty {
            AyuGramSettings.debugLog("message shot: no visible message node")
            return
        }
        shots.sort(by: { $0.index < $1.index })

        let padding: CGFloat = 12.0
        let width = (shots.map { $0.image.size.width }.max() ?? 0.0)
        let height = shots.reduce(0.0, { $0 + $1.image.size.height }) + padding * 2.0
        let backgroundColor = self.presentationData.theme.list.plainBackgroundColor
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = true
        let result = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { context in
            backgroundColor.setFill()
            context.fill(CGRect(origin: CGPoint(), size: CGSize(width: width, height: height)))
            var y = padding
            for shot in shots {
                shot.image.draw(at: CGPoint(x: 0.0, y: y))
                y += shot.image.size.height
            }
        }
        AyuGramSettings.debugLog("message shot: messages=\(shots.count) size=\(Int(width))x\(Int(height))")

        let activityController = UIActivityViewController(activityItems: [result], applicationActivities: nil)
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(origin: CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY), size: CGSize(width: 1.0, height: 1.0))
            popover.permittedArrowDirections = []
        }
        self.context.sharedContext.applicationBindings.presentNativeController(activityController)
    }
}
