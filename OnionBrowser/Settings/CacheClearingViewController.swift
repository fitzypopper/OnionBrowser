//
//  CacheClearingViewController.swift
//  OnionBrowser
//
//  Created by opencode on 13.09.26.
//  Copyright © 2012 - 2026, Tigas Ventures, LLC (Mike Tigas)
//
//  This file is part of Onion Browser. See LICENSE file for redistribution terms.
//

import UIKit
import Eureka
import WebKit
import MBProgressHUD

class CacheClearingViewController: FixedFormViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = NSLocalizedString("Clear Cache & Data", comment: "Scene title")


		// MARK: - Clear All Data

		form
		+++ Section(header: NSLocalizedString("Clear All Data", comment: "Section header"),
					footer: NSLocalizedString("Remove all website data (cache, cookies, local storage, etc.) for non-whitelisted sites.",
											  comment: "Section footer"))

		<<< ButtonRow() {
			$0.title = NSLocalizedString("Clear All Data", comment: "Button title")
			$0.cell.textLabel?.textColor = .systemRed
			$0.cell.textLabel?.numberOfLines = 0
		}
		.cellUpdate { cell, _ in
			cell.textLabel?.textAlignment = .natural
		}
		.onCellSelection { [weak self] _, _ in
			self?.confirmAndExecute(
				message: NSLocalizedString("This will remove all website data for non-whitelisted sites. Continue?",
										   comment: "Confirmation message"),
				action: { [weak self] in
					WebsiteStorage.shared.cleanup()
					self?.showSuccess(NSLocalizedString("All data cleared!", comment: "Success message"))
				})
		}


		// MARK: - Clear Cache Only

		+++ Section(header: NSLocalizedString("Clear Cache Only", comment: "Section header"),
					footer: NSLocalizedString("Remove disk cache, memory cache, and fetch cache. Cookies and local storage will not be affected.",
											  comment: "Section footer"))

		<<< ButtonRow() {
			$0.title = NSLocalizedString("Clear Cache", comment: "Button title")
			$0.cell.textLabel?.textColor = .systemRed
			$0.cell.textLabel?.numberOfLines = 0
		}
		.cellUpdate { cell, _ in
			cell.textLabel?.textAlignment = .natural
		}
		.onCellSelection { [weak self] _, _ in
			self?.confirmAndExecute(
				message: NSLocalizedString("This will clear disk cache, memory cache, and fetch cache. Continue?",
										   comment: "Confirmation message"),
				action: { [weak self] in
					WebsiteStorage.shared.clearCache()
					self?.showSuccess(NSLocalizedString("Cache cleared!", comment: "Success message"))
				})
		}


		// MARK: - Clear Cookies Only

		+++ Section(header: NSLocalizedString("Clear Cookies Only", comment: "Section header"),
					footer: NSLocalizedString("Remove all cookies. Cache and local storage will not be affected.",
											  comment: "Section footer"))

		<<< ButtonRow() {
			$0.title = NSLocalizedString("Clear Cookies", comment: "Button title")
			$0.cell.textLabel?.textColor = .systemRed
			$0.cell.textLabel?.numberOfLines = 0
		}
		.cellUpdate { cell, _ in
			cell.textLabel?.textAlignment = .natural
		}
		.onCellSelection { [weak self] _, _ in
			self?.confirmAndExecute(
				message: NSLocalizedString("This will remove all cookies. Continue?",
										   comment: "Confirmation message"),
				action: { [weak self] in
					WebsiteStorage.shared.clearCookies()
					self?.showSuccess(NSLocalizedString("Cookies cleared!", comment: "Success message"))
				})
		}


		// MARK: - Clear Local Storage Only

		+++ Section(header: NSLocalizedString("Clear Local Storage Only", comment: "Section header"),
					footer: NSLocalizedString("Remove local storage, session storage, IndexedDB, and WebSQL databases. Cache and cookies will not be affected.",
											  comment: "Section footer"))

		<<< ButtonRow() {
			$0.title = NSLocalizedString("Clear Local Storage", comment: "Button title")
			$0.cell.textLabel?.textColor = .systemRed
			$0.cell.textLabel?.numberOfLines = 0
		}
		.cellUpdate { cell, _ in
			cell.textLabel?.textAlignment = .natural
		}
		.onCellSelection { [weak self] _, _ in
			self?.confirmAndExecute(
				message: NSLocalizedString("This will remove all local storage data. Continue?",
										   comment: "Confirmation message"),
				action: { [weak self] in
					WebsiteStorage.shared.clearLocalStorage()
					self?.showSuccess(NSLocalizedString("Local storage cleared!", comment: "Success message"))
				})
		}
	}


	// MARK: - Private Methods

	private func confirmAndExecute(message: String, action: @escaping () -> Void) {
		AlertHelper.present(
			self,
			message: message,
			title: NSLocalizedString("Confirm", comment: "Alert title"),
			actions: [
				AlertHelper.destructiveAction(NSLocalizedString("Clear", comment: "Button title")) { _ in
					action()
				},
				AlertHelper.cancelAction()
			])
	}

	private func showSuccess(_ message: String) {
		let hud = MBProgressHUD.showAdded(to: navigationController?.view ?? view, animated: true)
		hud.mode = .text
		hud.label.text = message
		hud.hide(animated: true, afterDelay: 2)
	}
}
