//
//  FeatureTests.swift
//  OnionBrowser Tests
//
//  Created by Sigge on 13.09.26.
//  Copyright © 2012 - 2023, Tigas Ventures, LLC (Mike Tigas)
//
//  This file is part of Onion Browser. See LICENSE file for redistribution terms.
//

import XCTest
import WebKit
@testable import OnionBrowser

class FeatureTests: XCTestCase {

    // MARK: - Settings Tests

    func test_blockAllCookies_defaultValue_isFalse() {
        UserDefaults.standard.removeObject(forKey: "block_all_cookies")
        XCTAssertFalse(Settings.blockAllCookies, "blockAllCookies should default to false")
    }

    func test_readerMode_defaultValue_isFalse() {
        UserDefaults.standard.removeObject(forKey: "reader_mode")
        XCTAssertFalse(Settings.readerMode, "readerMode should default to false")
    }

    func test_blockAllCookies_setAndGet_worksCorrectly() {
        Settings.blockAllCookies = true
        XCTAssertTrue(Settings.blockAllCookies)

        Settings.blockAllCookies = false
        XCTAssertFalse(Settings.blockAllCookies)
    }

    func test_readerMode_setAndGet_worksCorrectly() {
        Settings.readerMode = true
        XCTAssertTrue(Settings.readerMode)

        Settings.readerMode = false
        XCTAssertFalse(Settings.readerMode)
    }

    // MARK: - CookieBlocker Tests

    func test_cookieBlocker_shared_exists() {
        let sut = CookieBlocker.shared
        XCTAssertNotNil(sut, "CookieBlocker.shared should exist")
    }

    func test_cookieBlocker_blockScript_isNotEmpty() {
        let config = WKWebViewConfiguration()
        CookieBlocker.shared.blockCookies(for: config)
        XCTAssertFalse(config.userContentController.userScripts.isEmpty,
                       "blockCookies should add at least one user script")
    }

    func test_cookieBlocker_blockScript_containsExpectedPatterns() {
        let config = WKWebViewConfiguration()
        CookieBlocker.shared.blockCookies(for: config)

        guard let script = config.userContentController.userScripts.first else {
            XCTFail("Expected a user script after blockCookies")
            return
        }

        XCTAssertTrue(script.source.contains("Object.defineProperty"),
                      "Script should use Object.defineProperty")
        XCTAssertTrue(script.source.contains("document.cookie"),
                      "Script should reference document.cookie")
    }

    func test_cookieBlocker_unblockCookies_removesScripts() {
        let config = WKWebViewConfiguration()
        CookieBlocker.shared.blockCookies(for: config)
        XCTAssertFalse(config.userContentController.userScripts.isEmpty)

        CookieBlocker.shared.unblockCookies(for: config)
        XCTAssertTrue(config.userContentController.userScripts.isEmpty,
                      "unblockCookies should remove all cookie blocker scripts")
    }

    func test_cookieBlocker_blockCookies_doesNotDuplicateScripts() {
        let config = WKWebViewConfiguration()
        CookieBlocker.shared.blockCookies(for: config)
        let countAfterFirst = config.userContentController.userScripts.count

        CookieBlocker.shared.blockCookies(for: config)
        let countAfterSecond = config.userContentController.userScripts.count

        XCTAssertEqual(countAfterFirst, countAfterSecond,
                       "blockCookies should not add duplicate scripts")
    }

    // MARK: - ReaderModeManager Tests

    func test_readerModeManager_shared_exists() {
        let sut = ReaderModeManager.shared
        XCTAssertNotNil(sut, "ReaderModeManager.shared should exist")
    }

    func test_readerModeManager_isEnabled_readsFromUserDefaults() {
        UserDefaults.standard.set(true, forKey: "reader_mode")
        XCTAssertTrue(ReaderModeManager.shared.isEnabled)

        UserDefaults.standard.set(false, forKey: "reader_mode")
        XCTAssertFalse(ReaderModeManager.shared.isEnabled)
    }

    func test_readerModeManager_readerCSS_isNotEmpty() {
        let css = ReaderModeManager.shared.readerCSS
        XCTAssertFalse(css.isEmpty, "readerCSS should not be empty")
    }

    func test_readerModeManager_readabilityJS_isNotEmpty() {
        let js = ReaderModeManager.shared.readabilityJS
        XCTAssertFalse(js.isEmpty, "readabilityJS should not be empty")
    }

    func test_readerModeManager_wrapInReaderHTML_containsTitle() {
        let sut = ReaderModeManager.shared
        let html = sut.wrapInReaderHTML(title: "Test Title", html: "<p>Body</p>")

        XCTAssertTrue(html.contains("Test Title"), "Wrapped HTML should contain the title")
        XCTAssertTrue(html.contains("<h1>"), "Wrapped HTML should have an h1 element")
        XCTAssertTrue(html.contains("<p>Body</p>"), "Wrapped HTML should contain the body content")
    }

    func test_readerModeManager_wrapInReaderHTML_validDocumentStructure() {
        let sut = ReaderModeManager.shared
        let html = sut.wrapInReaderHTML(title: "Title", html: "content")

        XCTAssertTrue(html.contains("<!DOCTYPE html>"), "Should be a valid HTML document")
        XCTAssertTrue(html.contains("<html lang=\"en\">"), "Should have html tag with lang")
        XCTAssertTrue(html.contains("<head>"), "Should have head section")
        XCTAssertTrue(html.contains("<body>"), "Should have body section")
        XCTAssertTrue(html.contains("</html>"), "Should close html tag")
        XCTAssertTrue(html.contains("<style>"), "Should include inline CSS")
    }

    func test_readerModeManager_wrapInReaderHTML_emptyTitle_noH1() {
        let sut = ReaderModeManager.shared
        let html = sut.wrapInReaderHTML(title: "", html: "content")

        XCTAssertFalse(html.contains("<h1>"), "Empty title should not produce an h1 element")
    }

    // MARK: - WebsiteStorage Tests

    func test_websiteStorage_shared_exists() {
        let sut = WebsiteStorage.shared
        XCTAssertNotNil(sut, "WebsiteStorage.shared should exist")
    }

    func test_websiteStorage_clearCache_exists() {
        let storage = WebsiteStorage.shared
        // Verify the method exists and can be called without crashing.
        // The actual async cleanup is internal to WebKit; we just ensure no crash.
        storage.clearCache()
    }

    func test_websiteStorage_clearCookies_exists() {
        let storage = WebsiteStorage.shared
        storage.clearCookies()
    }

    func test_websiteStorage_clearLocalStorage_exists() {
        let storage = WebsiteStorage.shared
        storage.clearLocalStorage()
    }
}
