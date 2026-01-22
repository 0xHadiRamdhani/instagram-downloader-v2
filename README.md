# InstaGrab

> A standalone Flutter application for downloading public Instagram media using direct HTML metadata parsing. No backend, no login, clean architecture.

## Features

- **Paste & Download** - Simply paste any public Instagram Reel or Post URL
- **Clipboard Listener** - Auto-detects Instagram URLs from clipboard
- **Download Progress** - Real-time download progress indicator
- **Save to Gallery** - Media saved directly to device gallery
- **Download History** - Track all your previous downloads
- **Dark Mode** - Beautiful Instagram-inspired dark theme

## Getting Started

```bash
flutter pub get
flutter run
```

## Usage

1. Copy any public Instagram Reel or Post URL
2. Open InstaGrab - URL is auto-detected from clipboard
3. Tap "Fetch Media" to preview
4. Tap "Download" to save to gallery

## Limitations

- Only works with **public** Instagram content
- Carousel posts may not extract all images
- If Instagram changes HTML structure, parser may need updates

## License

MIT License
