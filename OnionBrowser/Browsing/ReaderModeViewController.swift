//
//  ReaderModeViewController.swift
//  OnionBrowser
//
//  Copyright © 2012 - 2023, Tigas Ventures, LLC (Mike Tigas)
//
//  This file is part of Onion Browser. See LICENSE file for redistribution terms.
//

import UIKit
import WebKit

class ReaderModeViewController: UIViewController, WKNavigationDelegate {

	private let url: URL?

	private let titleText: String

	private let html: String

	private lazy var webView: WKWebView = {
		let conf = WKWebViewConfiguration()
		conf.allowsInlineMediaPlayback = false
		conf.allowsPictureInPictureMediaPlayback = false

		let wv = WKWebView(frame: .zero, configuration: conf)
		wv.navigationDelegate = self
		wv.accessibilityLabel = NSLocalizedString("Reader Mode", comment: "VoiceOver")
		wv.accessibilityHint = NSLocalizedString("Web content in reader view", comment: "VoiceOver")

		return wv
	}()

	private lazy var loadingIndicator: UIActivityIndicatorView = {
		let indicator = UIActivityIndicatorView(style: .large)
		indicator.hidesWhenStopped = true
		indicator.accessibilityLabel = NSLocalizedString("Loading", comment: "VoiceOver")

		return indicator
	}()


	init(url: URL?, title: String, html: String) {
		self.url = url
		self.titleText = title
		self.html = html

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .systemBackground

		navigationItem.leftBarButtonItem = UIBarButtonItem(
			barButtonSystemItem: .done, target: self, action: #selector(done))
		navigationItem.title = titleText.isEmpty
			? NSLocalizedString("Reader Mode", comment: "Scene title")
			: titleText

		navigationController?.navigationBar.prefersLargeTitles = false

		webView.add(to: view)

		loadingIndicator.add(to: view)

		let fullHTML = ReaderModeManager.shared.wrapInReaderHTML(title: titleText, html: html)
		webView.loadHTMLString(fullHTML, baseURL: url)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		loadingIndicator.startAnimating()
	}


	// MARK: - WKNavigationDelegate

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		loadingIndicator.stopAnimating()
	}

	func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
		loadingIndicator.stopAnimating()
	}

	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
				 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

		if navigationAction.navigationType == .other {
			decisionHandler(.allow)
			return
		}

		if let url = navigationAction.request.url, url.absoluteString != "about:blank" {
			dismiss(animated: true) {
				[weak self] in
				guard let url = self?.url else { return }

				for vc in AppDelegate.shared?.browsingUis ?? [] {
					if let tab = vc.tabs.first(where: { $0.url == url }) {
						tab.load(navigationAction.request.url)
						break
					}
				}
			}

			decisionHandler(.cancel)
			return
		}

		decisionHandler(.allow)
	}


	// MARK: - Actions

	@objc
	private func done() {
		dismiss(animated: true)
	}
}
