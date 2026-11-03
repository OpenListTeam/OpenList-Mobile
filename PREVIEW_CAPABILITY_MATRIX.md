# Native preview capability matrix

| Format | Implementation | Android | iOS | Backend / limits |
|---|---|---:|---:|---|
| Images | Existing Flutter `InteractiveViewer` and network image view | Yes | Yes | Uses `fs/get` URL; fit and zoom are available. No gallery navigation is currently wired. |
| Video | `video_player` with platform decoder, play/pause, seek, buffering and fullscreen | Intended | Intended | Streams the resolved file URL rather than downloading first. Supported codecs/containers are determined by OS decoders and server/provider URL behavior; real-device playback remains unverified. |
| Audio | `video_player` audio-only controls | Intended | Intended | Foreground playback only; no playlist metadata or background audio session. Real-device playback remains unverified. |
| Remote archive listing | Core `/api/fs/archive/meta` + `/api/fs/archive/list`; nested directory navigation | Yes | Yes | Requires archive-read permission, compatible Core, and archive provider support. Password entry implemented for encrypted archives; wrong-password and inaccessible cases depend on Core response. |
| Archive member download | Core-provided `raw_url` with `sign`, `inner`, and optional `pass` query parameters | Yes | Yes | URL is returned by Core; for driver-specific `/ad` endpoints support depends on driver's extraction implementation. |
| Text / code | Existing text view, syntax-highlight package available in project but not wired here | Yes | Yes | Only text objects up to 2 MiB are loaded in memory; larger text falls back to download. |
| Markdown | Existing `flutter_smooth_markdown` rendering | Yes | Yes | Markdown is rendered as native widgets; remote images/link behavior is package dependent. |
| HTML | Not implemented as an HTML renderer | N/A | N/A | Deliberately not rendered as WebView to avoid executing untrusted scripts. Download/open externally instead. |
| PDF | Native `pdfx` pinch viewer; file bytes are fetched with same-origin authentication headers | Android | iOS | Requires a PDF-capable Core response and platform plugin support. Large PDFs are buffered in memory before rendering; external open/download remains the fallback on load failure. |
| Office documents | Not implemented natively | N/A | N/A | No built-in Office preview service was added. External viewer or download may be used by the user. |
| HLS / transcoded media | Not verified | Unknown | Unknown | Depends on Core URL/transcode configuration and device decoder; no claim of support. |

Verification in this workspace is limited to source inspection, dependency resolution and static analysis. No physical Android/iOS device or real remote media/archive/PDF files were available; video/audio codecs, range streaming, interrupted streams, PDF memory use and driver-specific extraction require device-backed acceptance testing.
