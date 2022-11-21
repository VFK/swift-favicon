import XCTest
@testable import Favicon

struct MockRequester: FaviconRequester {
    func get(url: URL) async -> String? {
"""
<!DOCTYPE html>
<html lang="en"  data-a11y-animated-images="system">
  <head>
    <meta charset="utf-8">
    <meta property="og:image" content="/images/modules/site/social-cards/campaign-social.png" />
    <link rel=icon href=https://example.com/three/favicon.png>
    <link href=/four/favicon--16x16.png rel=icon sizes=16x16 type=image/png>
    <link rel="alternate icon" class="js-site-favicon" type="image/svg+xml" href="https://example.com/one/favicon.svg" >
    <link rel='alternate icon' type='image/svg+xml' href='https://example.com/two/favicon.bmp' />
    <link rel="apple-touch-icon-precomposed" type="image/x-icon" href="https://example.com/six/favicon.ico" sizes="16x16 24x24 32x32 48x48 256x256" />
    <link
        rel="apple-touch-icon"
        type="image/png"
        sizes="32x32"
        href="https://example.com/five/favicon-32.png"
    >
   </head>
</html>
"""
    }
}

let correctResults = [
    Icon(url: URL(string: "https://example.com/one/favicon.svg")!, iconClass: .alternateIcon, sizeClass: .small),
    Icon(url: URL(string: "https://example.com/two/favicon.bmp")!, iconClass: .alternateIcon, sizeClass: .small),
    Icon(url: URL(string: "https://example.com/three/favicon.png")!, iconClass: .icon, sizeClass: .small),
    Icon(url: URL(string: "https://example.com/four/favicon--16x16.png")!, iconClass: .icon, sizeClass: .small),
    Icon(url: URL(string: "https://example.com/five/favicon-32.png")!, iconClass: .appleTouchIcon, sizeClass: .medium),
    Icon(url: URL(string: "https://example.com/six/favicon.ico")!, iconClass: .appleTouchIconPrecomposed, sizeClass: .large),
]

final class FaviconTests: XCTestCase {
    func testShouldParseEverything() async {
        let url = URL(string: "https://example.com")!
        let mock = MockRequester()
        let favicon = Favicon(url: url, requester: mock)
        
        let results = await favicon.icons()
        XCTAssertEqual(results, correctResults)
        
        let smallUrl = await favicon.url(size: .small)
        let mediumUrl = await favicon.url(size: .medium)
        let largeUrl = await favicon.url(size: .large)
        let defaultLarge = await favicon.url()
        
        XCTAssertEqual(smallUrl, correctResults[3].url)
        XCTAssertEqual(mediumUrl, correctResults[4].url)
        XCTAssertEqual(largeUrl, correctResults[5].url)
        XCTAssertEqual(defaultLarge, correctResults[5].url)
    }
    
    func testShouldBlacklistExtensions() async {
        let url = URL(string: "https://example.com")!
        let mock = MockRequester()
        let favicon = Favicon(url: url, blacklistedExtensions: [".png", ".bmp"], requester: mock)
        
        let blacklistedResults = correctResults.filter { !$0.url.absoluteString.hasSuffix(".png") && !$0.url.absoluteString.hasSuffix(".bmp") }
        let results = await favicon.icons()
        XCTAssertEqual(results, blacklistedResults)
    }
}
