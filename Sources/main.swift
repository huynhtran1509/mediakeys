#!/usr/bin/swift

// Program that lets your media keys control [cmus](https://github.com/cmus/cmus)
// You'll need to run `launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist` or the media keys
// will still try control iTunes

import AppKit

final class MediaKeys : NSApplication {
    var repeated = false

    override func sendEvent(_ theEvent: NSEvent) {
        guard theEvent.type == .systemDefined && theEvent.subtype.rawValue == 8 else { return super.sendEvent(theEvent) }

        let keyCode = (theEvent.data1 & 0xFFFF0000) >> 16
        let keyFlags = theEvent.data1 & 0x0000FFFF
        let keyState = (keyFlags & 0xFF00) >> 8
        let keyRepeat = keyFlags & 0x1

        handleKey(Int32(keyCode), withState: Int32(keyState), isRepeating: Bool(keyRepeat == 1))
    }

    func handleKey(_ key: Int32, withState state: Int32, isRepeating repeating: Bool) {
        if state == NX_KEYDOWN && repeating {
            switch key {
            case NX_KEYTYPE_FAST:
                repeated = true
                launchCMUSRemote(with: "-k", "+5")
            case NX_KEYTYPE_REWIND:
                repeated = true
                launchCMUSRemote(with: "-k", "-5")
            default:
                break
            }
        } else if state == NX_KEYUP {
            guard !repeated else { return repeated = false }

            switch key {
            case NX_KEYTYPE_PLAY:
                launchCMUSRemote(with: "-u")
            case NX_KEYTYPE_FAST:
                launchCMUSRemote(with: "-n")
            case NX_KEYTYPE_REWIND:
                launchCMUSRemote(with: "-r")
            default:
                break
            }
        }
    }

    func launchCMUSRemote(with args: String...) {
        let task = Process()

        task.launchPath = "/usr/local/bin/cmus-remote"
        task.arguments = args
        task.launch()
    }
}

MediaKeys().run()
