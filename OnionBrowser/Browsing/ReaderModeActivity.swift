//
//  ReaderModeActivity.swift
//  OnionBrowser
//
//  Copyright © 2012 - 2024, Tigas Ventures, LLC (Mike Tigas)
//
//  This file is part of Onion Browser. See LICENSE file for redistribution terms.
//

import UIKit

class ReaderModeActivity: UIActivity {

	override var activityType: UIActivity.ActivityType? {
		return UIActivity.ActivityType("com.onionbrowser.readerMode")
	}

	override var activityTitle: String? {
		return NSLocalizedString("Open in Reader Mode", comment: "Activity title")
	}

	override var activityImageName: String? {
		return "doc.plaintext"
	}

	override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
		guard let tab = activityItems.first as? Tab else {
			return false
		}

		return !tab.url.isSpecial
	}

	override func prepare(withActivityItems activityItems: [Any]) {
		guard let tab = activityItems.first as? Tab else {
			return
		}

		self.tab = tab
	}

	override func perform() {
		guard let tab = tab else {
			activityDidFinish(false)
			return
		}

		Task {
			if let content = await ReaderModeManager.shared.extractContent(from: tab.webView) {
				let readerVC = ReaderModeViewController(
					url: tab.url,
					title: content.title,
					html: content.html)

				await MainActor.run {
					if let scene = tab.window?.windowScene {
						let rootVC = scene.windows.first?.rootViewController
						var presentedVC = rootVC
						while let pvc = presentedVC?.presentedViewController {
							presentedVC = pvc
						}
						presentedVC?.present(readerVC, animated: true)
					}
				}
			}

			await MainActor.run {
				self.activityDidFinish(true)
			}
		}
	}

	private var tab: Tab?
}
