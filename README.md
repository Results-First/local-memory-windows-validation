# Local Memory

Free early evaluation for Windows x64: import English WAV recordings, transcribe on your CPU, search and correct transcripts, and export Markdown. No cloud account or subscription is needed for those functions.

[Download the evaluation and read its limits](https://github.com/Results-First/local-memory-windows-validation/releases/tag/evaluation-7b4169a9)

The interface is a basic prototype. Visual redesign remains unfinished. This is not a polished commercial edition.

Supports mono/stereo 16-bit PCM WAV up to 256 MiB and existing Medium JSON transcripts. The English speech model is included. Optional generated answers require a separately installed local model server. No microphone/system-audio capture, MP3/video import, speaker recognition or wearable pairing is included.

Recordings and transcripts are retained in a local, unencrypted library. See the release listing for storage details, evaluation terms and SHA256. Free personal/internal-business evaluation has no activation or expiry. Later pay-once editions are separate.

## Verification

The exact published ZIP passed automated storage and offline audio workflow tests on separate Windows Server 2022 and 2025 runners. The operator reported all five native desktop checks passed: import, search, playback/stop, export and reopen. First-run warnings and bare consumer Windows compatibility are not fully verified.

This repository contains test infrastructure, not application source. The standard hosted Windows tests use synthetic audio and retain receipts in workflow logs. No artifact/cache storage is requested.
