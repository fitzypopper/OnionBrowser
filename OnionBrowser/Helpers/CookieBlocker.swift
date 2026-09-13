//
//  CookieBlocker.swift
//  OnionBrowser
//
//  Created by Sigge on 13.09.26.
//  Copyright © 2012 - 2023, Tigas Ventures, LLC (Mike Tigas)
//
//  This file is part of Onion Browser. See LICENSE file for redistribution terms.
//

import WebKit

/// Manages blocking of all cookies via JavaScript injection into WKWebView pages.
class CookieBlocker {

	static let shared = CookieBlocker()

	private static let blockScript = """
		(function() {
			Object.defineProperty(document, 'cookie', {
				get: function() { return ''; },
				set: function() { /* blocked */ }
			});

			var cookies = document.cookie.split(';');
			for (var i = 0; i < cookies.length; i++) {
				var cookie = cookies[i];
				var eqPos = cookie.indexOf('=');
				var name = eqPos > -1 ? cookie.substr(0, eqPos) : cookie;
				document.cookie = name.trim() + '=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=/';
			}
		})();
	"""

	private static let scriptName = "onionbrowser_cookie_blocker"

	/// Injects a user script that overrides `document.cookie` to block all cookies for the given web view configuration.
	func blockCookies(for configuration: WKWebViewConfiguration) {
		// Remove existing block script first to avoid duplicates.
		unblockCookies(for: configuration)

		let script = WKUserScript(
			source: Self.blockScript,
			injectionTime: .atDocumentStart,
			forMainFrameOnly: false)

		configuration.userContentController.addUserScript(script)
	}

	/// Removes the cookie-blocking user script from the given web view configuration.
	func unblockCookies(for configuration: WKWebViewConfiguration) {
		for (index, script) in configuration.userContentController.userScripts.enumerated().reversed() {
			if script.source == Self.blockScript {
				configuration.userContentController.removeUserScript(at: index)
			}
		}
	}
}
