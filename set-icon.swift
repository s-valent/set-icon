import Foundation
import Cocoa


guard CommandLine.arguments.count > 1 else {
    print("usage: set-icon <icns-file> [<file>]")
    print("       set-icon <dir-of-icns>")
    exit(1)
}

if CommandLine.arguments.count == 3, CommandLine.arguments[1].hasSuffix(".icns"), !CommandLine.arguments[2].hasSuffix(".icns") {
    let iconPath = CommandLine.arguments[1]
    let file = CommandLine.arguments[2]
    setIcon(iconPath, for: file)
} else {
    for path in CommandLine.arguments[1...] {
        if path.hasSuffix(".icns") {
            if let url = URL(string: path) {
                let file = url.lastPathComponent.removingSuffix(".icns")
                setIcon(path, for: file)
            }
        } else {
            replaceIcons(dir: path)
        }
    }
}


func replaceIcons(dir: String) {
    let enumerator = FileManager.default.enumerator(atPath: dir)
    while let file = enumerator?.nextObject() as? String {
        if file.hasSuffix(".icns") {
            let iconPath = "\(dir)/\(file)"
            let file = file.removingSuffix(".icns")
            setIcon(iconPath, for: file)
        }
    }
}


func setIcon(_ iconPath: String, for file: String) {
    let iconURL = URL(fileURLWithPath: iconPath)
    guard let icon = NSImage(contentsOf: iconURL) else {
        print("icon \(iconPath) not found")
        return
    }
    if let path = getPath(for: file) {
        print("setting icon for \(file)")
        NSWorkspace.shared.setIcon(icon, forFile: path)
    } else {
        print("file \(file) not found")
    }
}


func getPath(for file: String) -> String? {
    if FileManager.default.fileExists(atPath: file) { return file }
    let appPathByName = getPath(bundleID: runAppleScript("id of app \"\(file)\"") ?? "")
    let appPathByID = getPath(bundleID: file)
    return appPathByName ?? appPathByID
}

func getPath(bundleID: String) -> String? {
    return NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)?.path(percentEncoded: false)
}


func runAppleScript(_ script: String) -> String? {
    var error: NSDictionary?
    if let scriptObject = NSAppleScript(source: script) {
        let output = scriptObject.executeAndReturnError(&error)
        return output.stringValue
    }
    return nil
}


extension String {
    func removingSuffix(_ prefix: String) -> String {
        guard self.hasSuffix(prefix) else { return self }
        return String(self.dropLast(prefix.count))
    }
}
