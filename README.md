# Local Memory

Free early evaluation for Windows x64: import English WAV recordings, transcribe on your CPU, search and correct transcripts, and export Markdown. No cloud account or subscription is needed for those functions.

[Download the evaluation and read its limits](https://github.com/Results-First/local-memory-windows-validation/releases/tag/evaluation-7fe3bfe9)

The updated workspace includes passage-level Edit controls and a multiline editor with Save/Cancel. Playback includes surrounding audio instead of cutting exactly at estimated speech timestamps. This remains an early evaluation.

![Local Memory passage editor, using synthetic demonstration text](assets/passage-editor.png)

Supports mono/stereo 16-bit PCM WAV up to 256 MiB and optional JSON transcripts with timed start/end/text/speaker segments. The English speech model is included. Medium, Workbench, Python and cloud accounts are not required. Optional generated answers require a separately installed local model server. No microphone/system-audio capture, MP3/video import, speaker recognition or wearable pairing is included.

Recordings and transcripts are retained in a local, unencrypted library. See the release listing for storage details, evaluation terms and SHA256. Free personal/internal-business evaluation has no activation or expiry. Later pay-once editions are separate.

## Verification

Release notes link the exact ZIP's Windows Server 2022 and 2025 acceptance run. Local checks cover passage editing, correction history, search/export, original preservation and playback-buffer boundaries. The packaged editor was also exercised with real Windows input. In six public human-speech samples, buffered clips retained all six reference ending words in a supplementary recognition check, versus four with exact timestamp cuts. This is not a guarantee for all recordings or audio devices. First-run warnings and bare consumer Windows compatibility are not fully verified.

This repository contains test infrastructure, not application source. The standard hosted Windows tests use synthetic audio and retain receipts in workflow logs. No artifact/cache storage is requested.
