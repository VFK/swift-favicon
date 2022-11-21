# Swift Favicon
Get urls to higher quality website icons than `/favicon.ico`


## Usage
Use with **Package Manager**.

```swift
import Favicon

let url = URL(string: "https://example.com")!
let favicon = Favicon(url: url)
let faviconUrl: URL? = await favicon.url() // Large size by default
```

### Blacklisting icon extensions
You might want to skip icons with certain extensions.

For example SwiftUI doesn't render SVG images at the time of writing.

Use this constructor:
```swift
let favicon = Favicon(url: url, blacklistedExtensions: [".svg"])
```

## Icon Size Classes
```swift
let smallIconUrl = await favicon.url(size: .small)
let mediumIconUrl = await favicon.url(size: .medium)
let largeIconUrl = await favicon.url(size: .large)
```
Returned result is the highest quality icon within it's class.

### How sizes are determined
Unless the size is set explicitly (through `sizes` attribute) size class is just an educated guess e.g. `rel="icon"`, "shortcut icon" etc. are small, "apple-touch" stuff is medium, the rest is large.

If size is set then everything below 32 pixels is small, up to 180 is medium and the rest is large.

This seems to give pretty good results but your mileage may vary. Feel free to open an issue if it doesn't work for you.

## Chosing the "best" icon manually
If you're unhappy with how this library sorts and groups icons you can request all icons that this library could find and pick what you want:
```swift
let icons: [Icon] = await favicon.icons()
```

```swift
struct Icon {
    let url: URL // Absolute url to the icon
    let iconClass: IconClass // Enum. Icon source from "rel" attribute usually. .appleTouchIcon, .icon etc.
    let sizeClass: IconSizeClass // Enum. .small, .medium or .large
}
```
