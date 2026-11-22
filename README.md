# Goschn

**Press a shortcut, type in any language, hit Enter: the translation lands where your cursor was.**

![The Goschn panel translating German to Spanish](docs/panel.png)

A tiny native macOS menu bar app. It uses Apple's on-device translation, so it is free, private and works offline. No account, no API key, no dependencies.

## Install

Needs macOS 26 or later and Xcode 26.4 or later.

```bash
git clone https://github.com/ddkbs/goschn.git
cd goschn
./scripts/install.sh
```

This builds `Goschn.app`, copies it to `/Applications` and starts it. It launches at login; you can turn that off in the menu.

To paste automatically, click **Allow auto-paste…** in the panel and enable Goschn under *System Settings → Privacy & Security → Accessibility*. Without it, Enter only copies.

## Keys

| Key | Action |
| --- | --- |
| `⇧⌘Space` | Open or close (change it in the menu) |
| `↩` | Copy and paste into the app you came from |
| `⌘↩` | Copy only |
| `⇧↩` | New line |
| `⌘1` … `⌘5` | Switch between your recent target languages |
| `⇥` | Swap direction |
| `esc` | Close and keep the draft |

## Languages

Over 20 languages in every direction: click a language name at the bottom of the panel to change it.

- The language you type is detected. Set a fixed one if detection gets in your way.
- Text that is already in the target language is translated back to your own, so one shortcut works both ways.
- Very short or unclear text counts as your own language. It is taken from macOS; change it under **My Language** in the menu.

## Good to know

- The translation is the only thing left on your clipboard; nothing is stored and nothing leaves your Mac.
- Line breaks, indentation and list markers stay as you typed them.
- With Apple's larger model it takes about half a second. If it is not available, Goschn uses the smaller one and offers to download the language.
- Very repetitive text can make the larger model repeat itself.

There is also a command line mode:

```bash
"/Applications/Goschn.app/Contents/MacOS/Goschn" --to fr --translate "Bis gleich"
```

## Development

```bash
swift test          # unit tests
scripts/build.sh    # build/Goschn.app
```

`GoschnCore` holds the logic (layout, language detection, debouncing, shortcuts) and is fully tested. `Goschn` is the thin AppKit/SwiftUI shell around it. `build.sh` signs with the first code signing certificate it finds; without one, macOS asks for the Accessibility permission again after every rebuild.

## License

[MIT](LICENSE)
