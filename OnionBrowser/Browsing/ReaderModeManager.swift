//
//  ReaderModeManager.swift
//  OnionBrowser
//
//  Copyright © 2012 - 2023, Tigas Ventures, LLC (Mike Tigas)
//
//  This file is part of Onion Browser. See LICENSE file for redistribution terms.
//

import UIKit
import WebKit

/// Provides reader mode functionality by extracting article content and wrapping it in a clean, readable HTML layout.
class ReaderModeManager {

	static let shared = ReaderModeManager()

	/// Whether reader mode is currently enabled globally.
	var isEnabled: Bool {
		get {
			UserDefaults.standard.bool(forKey: "reader_mode")
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "reader_mode")
		}
	}

	let readerCSS: String = """
		:root {
			--bg-color: #ffffff;
			--text-color: #1a1a1a;
			--muted-color: #666666;
			--border-color: #e0e0e0;
		}

		@media (prefers-color-scheme: dark) {
			:root {
				--bg-color: #1c1c1e;
				--text-color: #e5e5e7;
				--muted-color: #98989f;
				--border-color: #38383a;
			}
		}

		* {
			margin: 0;
			padding: 0;
			box-sizing: border-box;
		}

		body {
			background-color: var(--bg-color);
			color: var(--text-color);
			font-family: Georgia, "Times New Roman", Times, serif;
			font-size: 18px;
			line-height: 1.75;
			padding: 24px;
			max-width: 720px;
			margin: 0 auto;
		}

		h1 {
			font-size: 28px;
			line-height: 1.3;
			margin-bottom: 8px;
		}

		.byline {
			color: var(--muted-color);
			font-size: 14px;
			margin-bottom: 24px;
			padding-bottom: 16px;
			border-bottom: 1px solid var(--border-color);
		}

		p {
			margin-bottom: 16px;
		}

		img {
			max-width: 100%;
			height: auto;
			margin: 16px 0;
			border-radius: 4px;
		}

		figure {
			margin: 20px 0;
		}

		figcaption {
			color: var(--muted-color);
			font-size: 14px;
			margin-top: 6px;
		}

		blockquote {
			border-left: 3px solid var(--border-color);
			margin: 16px 0;
			padding: 8px 20px;
			color: var(--muted-color);
			font-style: italic;
		}

		pre, code {
			background-color: var(--border-color);
			padding: 2px 6px;
			border-radius: 3px;
			font-size: 15px;
		}

		pre {
			padding: 16px;
			overflow-x: auto;
			margin: 16px 0;
		}

		pre code {
			background-color: transparent;
			padding: 0;
		}

		a {
			color: #007aff;
			text-decoration: underline;
		}

		@media (prefers-color-scheme: dark) {
			a {
				color: #0a84ff;
			}
		}

		ul, ol {
			padding-left: 24px;
			margin-bottom: 16px;
		}

		li {
			margin-bottom: 4px;
		}

		table {
			width: 100%;
			border-collapse: collapse;
			margin: 16px 0;
		}

		th, td {
			border: 1px solid var(--border-color);
			padding: 8px 12px;
			text-align: left;
		}

		th {
			background-color: var(--border-color);
			font-weight: bold;
		}
		"""

	let readabilityJS: String = """
		(function() {
			function getTextContent(el) {
				if (!el) return "";
				return (el.textContent || el.innerText || "").trim();
			}

			function countTextBlocks(el) {
				if (!el) return 0;
				var blocks = el.querySelectorAll("p, li, h1, h2, h3, h4, h5, h6, blockquote, td, pre");
				return blocks.length;
			}

			function getInnerHTML(el) {
				if (!el) return "";
				return el.innerHTML || "";
			}

			function extractByline() {
				var selectors = [
					"[rel='author']",
					".author",
					".byline",
					"[itemprop='author']",
					".article-author",
					".post-author",
					".entry-author",
					".story-byline",
					"[class*='author']",
					"[class*='byline']"
				];
				for (var i = 0; i < selectors.length; i++) {
					var el = document.querySelector(selectors[i]);
					if (el) {
						var text = getTextContent(el);
						if (text.length > 0 && text.length < 200) return text;
					}
				}
				return "";
			}

			function extractContent() {
				var title = document.title || "";

				var titleEl = document.querySelector("h1");
				if (titleEl) {
					var t = getTextContent(titleEl);
					if (t.length > 0) title = t;
				}

				var byline = extractByline();
				var content = "";
				var contentEl = null;

				contentEl = document.querySelector("article");
				if (!contentEl) contentEl = document.querySelector("main");
				if (!contentEl) contentEl = document.querySelector("[role='main']");

				if (!contentEl) {
					var candidates = [
						document.querySelector(".post-content"),
						document.querySelector(".article-content"),
						document.querySelector(".entry-content"),
						document.querySelector(".story-body"),
						document.querySelector(".article-body"),
						document.querySelector(".post-body"),
						document.querySelector(".content-body"),
						document.querySelector("#article-content"),
						document.querySelector("#content"),
						document.querySelector(".content")
					];
					for (var i = 0; i < candidates.length; i++) {
						if (candidates[i] && countTextBlocks(candidates[i]) > 2) {
							contentEl = candidates[i];
							break;
						}
					}
				}

				if (!contentEl) {
					var divs = document.querySelectorAll("div");
					var bestDiv = null;
					var bestScore = 0;
					for (var i = 0; i < divs.length; i++) {
						var div = divs[i];
						var textLen = getTextContent(div).length;
						var blockCount = countTextBlocks(div);
						var score = textLen + blockCount * 100;
						if (score > bestScore && blockCount >= 3) {
							bestScore = score;
							bestDiv = div;
						}
					}
					contentEl = bestDiv;
				}

				if (contentEl) {
					var clone = contentEl.cloneNode(true);
					var removeEls = clone.querySelectorAll("script, style, nav, header, footer, .sidebar, .ad, .ads, .advertisement, [class*='social'], [class*='share'], [class*='related'], [class*='comment'], [class*='nav'], [class*='menu'], [class*='header'], [class*='footer'], [class*='widget'], iframe, form, button, input");
					for (var i = 0; i < removeEls.length; i++) {
						removeEls[i].parentNode.removeChild(removeEls[i]);
					}
					content = getInnerHTML(clone);
				}

				if (!content || content.trim().length < 100) {
					var bodyClone = document.body.cloneNode(true);
					var removeEls = bodyClone.querySelectorAll("script, style, nav, header, footer, .sidebar, .ad, .ads, iframe, form, button, input, [class*='social'], [class*='share']");
					for (var i = 0; i < removeEls.length; i++) {
						removeEls[i].parentNode.removeChild(removeEls[i]);
					}
					content = getInnerHTML(bodyClone);
				}

				return JSON.stringify({
					title: title,
					byline: byline,
					content: content
				});
			}

			return extractContent();
		})();
		"""

	private init() {}

	/// Extracts the main article content from a web page using a readability algorithm.
	func extractContent(from webView: WKWebView) async -> (title: String, html: String)? {
		guard let result = await webView.evaluateJavaScript(readabilityJS) as? String,
			  let data = result.data(using: .utf8),
			  let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
			  let content = json["content"],
			  !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		else {
			return nil
		}

		let title = json["title"] ?? ""
		let byline = json["byline"] ?? ""

		var html = content
		if !byline.isEmpty {
			html = "<p class=\"byline\">\(byline)</p>\n\(content)"
		}

		return (title: title, html: html)
	}

	/// Wraps extracted article content in a complete HTML document with reader-friendly styling.
	func wrapInReaderHTML(title: String, html: String) -> String {
		var titleBlock = ""
		if !title.isEmpty {
			titleBlock = "<h1>\(title)</h1>"
		}

		return """
			<!DOCTYPE html>
			<html lang="en">
			<head>
				<meta charset="utf-8">
				<meta name="viewport" content="width=device-width, initial-scale=1">
				<style>\(readerCSS)</style>
			</head>
			<body>
				\(titleBlock)
				\(html)
			</body>
			</html>
			"""
	}
}
