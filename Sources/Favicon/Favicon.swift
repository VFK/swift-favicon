import Foundation

public struct Icon: Comparable {
    let url: URL
    let iconClass: IconClass
    let sizeClass: IconSizeClass
    
    public static func < (lhs: Icon, rhs: Icon) -> Bool {
        if lhs.sizeClass.rawValue == rhs.sizeClass.rawValue {
            return IconClass.allCases.firstIndex(of: lhs.iconClass)! < IconClass.allCases.firstIndex(of: rhs.iconClass)!
        }
        
        return lhs.sizeClass.rawValue < rhs.sizeClass.rawValue
    }
}

public enum IconClass: String, CaseIterable {
    case msapplicationTitleImage = "msapplication-TileImage"
    case appleTouchIconPrecomposed = "apple-touch-icon-precomposed"
    case appleTouchIcon = "apple-touch-icon"
    case shortcutIcon = "shortcut icon"
    case alternateIcon = "alternate icon"
    case icon = "icon"
    case fluidIcon = "fluid-icon"
    
    var sizeClass: IconSizeClass {
        switch self {
        case .msapplicationTitleImage:
            return .large
        case .appleTouchIcon, .appleTouchIconPrecomposed, .fluidIcon:
            return .medium
        case .shortcutIcon, .alternateIcon, .icon:
            return .small
        }
    }
}

public enum IconSizeClass: Int {
    case small
    case medium
    case large
}

protocol FaviconRequester {
    func get(url: URL) async -> String?
}

struct Requester: FaviconRequester {
    func get(url: URL) async -> String? {
        let config = URLSessionConfiguration.default
        let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
        config.httpAdditionalHeaders = ["User-Agent": userAgent]
        
        let session = URLSession(configuration: config)
        guard let (data, _) = try? await session.data(from: url) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

public struct Favicon {
    public private(set) var url: URL
    private let requester: FaviconRequester
    private var baseUrl: URL? { URL(string: "/", relativeTo: url) }
    private let blacklistedExtensions: [String]
    
    private func getSizeClass(by size: Int) -> IconSizeClass {
        switch size {
        case ..<32:
            return .small
        case 32...180:
            return .medium
        case 181...:
            return .large
        default:
            return .small
        }
    }
    
    private let tagRegex = #"<(?:link|meta)[^>]*>"#
    private let attributeRegex = #"(\w+)=(?:["']([^"'>]+)["']|([^"'\s>]+))"#
    
    private func groups(in string: String, for regexPattern: String) -> [[String]] {
        let regex = try! NSRegularExpression(pattern: regexPattern)
        let matches = regex.matches(in: string, range: NSRange(string.startIndex..., in: string))
        return matches.map { match in
            return (0..<match.numberOfRanges).map {
                let rangeBounds = match.range(at: $0)
                guard let range = Range(rangeBounds, in: string) else { return "" }
                return String(string[range])
            }
        }
    }
    
    public init(url: URL, blacklistedExtensions: [String] = []) {
        self.url = url
        self.requester = Requester()
        self.blacklistedExtensions = blacklistedExtensions
    }
    
    init(url: URL, blacklistedExtensions: [String] = [], requester: FaviconRequester) {
        self.url = url
        self.requester = requester
        self.blacklistedExtensions = blacklistedExtensions
    }
    
    private func relIcon(from element: [String: String]) -> Icon? {
        guard let rel = element["rel"], let iconClass = IconClass(rawValue: rel) else { return nil }
        guard let relHref = element["href"], let relUrl = URL(string: relHref, relativeTo: baseUrl)?.absoluteURL else { return nil }
        guard !blacklistedExtensions.contains(where: relHref.hasSuffix) else { return nil }
        
        if let realSize = element["sizes"]?.split(separator: "x").last, let size = Int(realSize) {
            return Icon(url: relUrl, iconClass: iconClass, sizeClass: getSizeClass(by: size))
        }
        
        return Icon(url: relUrl, iconClass: iconClass, sizeClass: iconClass.sizeClass)
    }
    
    private func metaIcon(from element: [String: String]) -> Icon? {
        guard let name = element["property"] ?? element["name"], let iconClass = IconClass(rawValue: name) else { return nil }
        guard let content = element["content"], let url = URL(string: content, relativeTo: baseUrl)?.absoluteURL else { return nil }
        guard !blacklistedExtensions.contains(where: content.hasSuffix) else { return nil }
        
        return Icon(url: url, iconClass: iconClass, sizeClass: iconClass.sizeClass)
    }
    
    public func icons() async -> [Icon] {
        guard let page = await requester.get(url: url) else { return [] }
        
        let output = groups(in: page, for: tagRegex).map {
            groups(in: $0.first!, for: attributeRegex).reduce(into: [:]) { result, item in
                result[item[1]] = item[2].isEmpty ? item[3] : item[2]
            }
        }

        var result = output.compactMap { relIcon(from: $0) ?? metaIcon(from: $0) }.sorted()
        if result.isEmpty {
            guard let faviconUrl = URL(string: "/favicon.ico", relativeTo: baseUrl)?.absoluteURL else { return result }
            result.append(Icon(url: faviconUrl, iconClass: .icon, sizeClass: .small))
        }
        
        return result
    }
    
    public func url(size: IconSizeClass = .large) async -> URL? {
        let icons = await icons()
        let sorted = icons.sorted()
        return sorted.last { $0.sizeClass == size }?.url ?? sorted.last?.url
    }
}
