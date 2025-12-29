

<div align="center">
  <h1>MPV Quality-of-Life Script Collection</h1>
  <img src="https://img.shields.io/badge/🪟%20Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Windows" />
  <img src="https://img.shields.io/badge/%20MPV-663399?style=for-the-badge&logo=mpv&logoColor=white" alt="MPV" />
  <img src="https://img.shields.io/badge/%20Lua-2C2D72?style=for-the-badge&logo=lua&logoColor=white" alt="Lua" />
  <img src="https://img.shields.io/badge/License-GPLv3-blue.svg?style=for-the-badge" alt="License: GPL v3" />
  <img src="https://img.shields.io/badge/Maintained-Yes-green.svg?style=for-the-badge" alt="Maintained: Yes" />
</div>
  </br>
  
This is a collection of powerful, high-quality Lua scripts designed to enhance and automate the MPV player. While originally developed for the [Stremio Kai](https://github.com/allecsc/Stremio-Kai) project, these scripts are fully standalone, general-purpose, and built to be universally useful for any type of content.

The philosophy behind these scripts is to provide a polished, "it just works" experience out of the box, while still offering deep configuration options for power-users. Every script is designed to be highly adjustable to your specific needs and viewing habits.

If you need any assistance tailoring a script for your unique setup, please open a discussion.<br>

---

# 🔔 Notify Skip

Binge-watch like a pro. This script provides a configurable, Netflix-style system for skipping intros, outros, and previews, with a multi-layered detection system that uses chapter titles, positions, and even silence to know when to offer a skip.

<details>
<summary><strong>Find out how it works!</strong></summary>

  > *An automated system for skipping intros, outros, and previews.*

### 😤 The Problem This Solves

During a binge-watching session, the flow between episodes is constantly interrupted by opening credits, ending credits, and previews. This forces you to manually skip forward, which is tedious, imprecise, and breaks immersion.

### ✨ The Solution

This script elevates your viewing experience by intelligently identifying skippable content and presenting a clean, non-intrusive toast notification, just like on major streaming services. It uses a sophisticated, multi-layered detection system to handle files with or without chapters, ensuring you can seamlessly move between episodes with a single keypress.

### 🤔 How It Works: A Multi-Layered Approach

The script analyzes each file using a hierarchy of detection methods to ensure the highest possible accuracy.

1.  **Chapter-Based Detection (Primary Method)**
    This is the most accurate mode, used on files with embedded chapters. The script analyzes the chapter list to find skippable segments.
      * **High Confidence:** If a chapter has a descriptive title matching known patterns (e.g., "Intro," "Ending," "Outro"), it's considered a high-confidence match.
      * **Medium Confidence:** If a chapter is untitled (e.g., "Chapter 1") but is in a common position for an intro, it's considered a medium-confidence match.

2.  **Intelligent Fallback (For Chapter-less Files)**
    If a video file has no chapters, the script switches to its intelligent fallback mode.
      * **Time-Gated Scanning:** To avoid interrupting actual content, this mode only scans for breaks during the **first and last few minutes** of the file, where intros and outros are expected.
      * **Silence Detection:** Within these time windows, the script actively listens for periods of silence that typically precede or follow a skippable segment.
      * **Contextual Prompts:** Based on *when* the silence is detected, it will generate a contextual notification (e.g., "Skip Intro" or "Skip Outro").

3.  **Proactive Notifications**
    In all cases, the script's default behavior is to proactively display a skip notification, giving you the choice to act. For those who prefer a fully automated experience, an `auto_skip` option can be enabled for high-confidence (titled) chapters.

### **😯 Real Example (Anime with Chapters):**

Chapters found:  
✅ "Opening"        → Skippable\! Notification appears.  
❌ "Part A"         → Not skippable.  
❌ "Part B"         → Not skippable.  
✅ "Ending"         → Skippable\! Notification appears.  
✅ "Next Preview"   → Skippable\! Notification appears.

## 🚀 Quick Setup

### File Placement:

```
📁 portable_config/
├── 📁 scripts/
│   └── 📁 notify_skip/
│       ├── 📄 main.lua
│       ├── 📁 lib/
│       └── 📁 elements/
└── 📁 script-opts/
    └── 📄 notify_skip.conf
```

### ⚙️ Configuration

The script's behavior is controlled via `notify_skip.conf`. These settings are read directly from the script's code:

```ini
# Categories of chapters to look for, separated by semicolons.
skip_categories=opening;ending;preview;recap

# Use the most flexible "contains" patterns instead of the script's defaults.
# Use ^OP or ^ED to match the exact word "OP" or "ED" at the start of the title.
# Use OP$ or ED$ to match the exact word "OP" or "ED" at the end of the title.
opening_patterns=OP|Opening|Intro|Introduction|Theme|Song|Main Theme|Title|Open|Teaser
ending_patterns=ED|Ending|Outro|End|Credits|Closing|Epilogue
preview_patterns=Preview|Coming Up|Next|Trailer
recap_patterns=Recap|Previously|Last Time|Summary|Story So Far

# Auto-skip detected intro/outro chapters
auto_skip=no

# Minimum duration to consider as valid skip exit (seconds)
min_skip_duration=10

# Maximum duration for skippable chapters (seconds)
# Chapters outside these windows will not trigger notifications
intro_time_window=200     # Skip notifications are shown ONLY during the first 200 seconds (3 minutes 20 seconds)
outro_time_window=300     # Skip notifications are shown ONLY during the last 300 seconds (5 minutes)

# Show OSD notification when skippable content is detected
show_notification=yes

# Duration to show notification in seconds
# Default: 30 seconds
notification_duration=15

# Duration to show notification in seconds, for black frame / silence detection method (Lower Accuracy)
# Default: 5 seconds -> False positives chance, so lower screen time
filters_notification_duration=15
```

## 🔧 Troubleshooting

  * **If it's not skipping anything:**
      * Ensure the `.lua` and `.conf` files are in the correct folders. 
      * Check the MPV console (`~` key) for any error messages.
      * The video file may not contain any chapters or silent periods for the script to detect.
  * **If it tries to skip the whole episode:**
      * This is prevented by the `intro_time_window=200` and `outro_time_window=300` safety feature in the script, which stops it from ever skipping more than approximately 3 minutes.

### 🙏 Origins & Acknowledgements

This script began by merging concepts from two foundational projects. It has since evolved significantly, incorporating a new multi-layered detection engine and a unique toast notification system.

However, it proudly stands on the shoulders of the original scripts, and full credit for the core idea goes to their authors:

* **[po5/chapterskip](https://github.com/po5/chapterskip)**
* **[rui-ddc/skip-intro](https://github.com/rui-ddc/skip-intro)**
* **[tomasklaen/uosc](https://github.com/tomasklaen/uosc)**

## **🎉 The Bottom Line**
Go right to your favorite part! This script provides a polished, pop-up notification that gives you precise, one-press control to skip content exactly when you want. It’s a quality-of-life upgrade that makes your player feel less like a tool and more like a premium service.
</details>

<div align="center">
<img width="730" alt="Screenshot 2025-09-15 143608" src="https://github.com/user-attachments/assets/77f60d4a-2eed-4353-a28a-71b7ba31a6b9" />
</div>

## ☑️ BIG UPDATE 

- **2 Versions**
  - **notify_skip** -> Simple notification, skip is triggered by **pressing Tab**
  - **notify_skip_click** -> Interactive button, skip is triggered by **clicking the notification** or by **pressing Tab**. _Will conflict with UOSC since it's built on it._
- Parallel detection system with silence detection and black frame detection
- Improved notification detection
- Some false positives are still expected, but they will disappear quickly.
- Works with all media, not just anime.
  
<details>
<summary><strong>📄 Complete Changelog</strong></summary>

- **Button Infrastructure Integration**: Added a complete button rendering system with globals like `config`, `options`, `fg`, `bg`, `display`, and `button_state` for interactive UI elements, including a `SkipNotificationButton` class for user interactions.
- **Enhanced State Management**: Introduced a more structured `state` object with sub-objects for `detection`, `ui`, `observers`, and `cache`, replacing the simpler state variables in the old version.
- **Improved Chapter Detection**: Enhanced `find_skip_chapters()` to prioritize titled chapters over positional ones, with better pattern matching for categories like opening, ending, preview, and recap, and added duration/time window checks.
- **Dual Detection Mode**: Streamlined to a two-mode system ("chapter" or "silence"), with improved fallback logic where silence detection only activates if no black frame detection occurs.
- **Minimum Skip Duration**: Added `min_skip_duration` option (default 10 seconds) to prevent skipping very short segments, ensuring meaningful skips.
- **Intro Skip Blocking**: Implemented `intro_skipped` flag to prevent repeated intro notifications after a substantial skip, with reset logic when entering outro windows or seeking back.
- **Skip Suppression Mechanism**: Added `start_skip_suppression()` with a 5-second timer to prevent spam notifications after user interactions or seeks.
- **Enhanced Filter Management**: Improved filter initialization and state management for `blackdetect` and `silencedetect`, with separate notification and skipping filters.
- **Better Event Parsing**: Fixed and improved parsing of filter metadata events in `skip_detection_trigger()` for more reliable black frame and silence detection.
- **UI Improvements**: Replaced ASS overlays with interactive buttons via `SkipNotificationButton`, including persistent display options and better message handling.
- **Notification Logic Refinement**: Updated notification triggers to respect suppression timers and intro skip status, with time-window-based message determination ("Skip Opening" vs "Skip Ending").
- **Seek Handling**: Enhanced `on_seek()` to reset `intro_skipped` when seeking back to the beginning, allowing re-enabling of intro notifications.
- **Setup and Initialization**: Added delayed setup (`finalize_setup()`) with 3.5-second timeout to ensure compatibility with other scripts, and improved mode detection based on chapter availability.
- **Performance Optimizations**: Added render loop management with `request_render()` and display dimension updates for efficient UI rendering.
- **Configuration Options**: Expanded options including `min_skip_duration`, refined detection parameters, and better pattern strings for chapter categories.
- **Logging and Debugging**: Enhanced logging throughout for better troubleshooting, including debug messages for skip durations and detection events.
- **Error Handling**: Improved robustness in functions like `skip_to_chapter_end()` to prevent looping at video end.
- **Code Cleanup**: Removed redundant code, improved variable naming, and added comments for clarity, making the codebase more professional and easier to understand.
</details>

<div align="center">
<p><h3>✨ New UI Notification ✨</h3></p>
<img width="322" alt="new_notification" src="https://github.com/user-attachments/assets/07253eef-8533-426a-87f5-87688c895275" />
</div>

</br>

# 🎯 Smart Track Selector

Ends the nightmare of manually cycling through audio and subtitle tracks. This script intelligently scans and selects the best tracks based on your preferences, with full support for **non-English languages** (Cyrillic, Japanese, etc.).

<details>
<summary><strong>Find out how it works!</strong></summary>

> _An intelligent script to automatically select the correct audio and subtitle tracks._

### 😤 The Problem This Solves

When playing media with multiple tracks, MPV's default behavior often selects undesirable options:

- **Subtitles:** "Signs & Songs" instead of full dialogue
- **Audio:** Russian dubs instead of Japanese original

The user must then manually cycle through all available tracks on every file.

### ✨ The Solution

This script replaces MPV's default logic with an intelligent, priority-based system that:

- Analyzes track titles and languages
- Scores tracks based on your preferences
- Rejects unwanted languages and keywords
- Works with **any language** including Cyrillic (надписи, полные, etc.)

### 🤔 How It Works

The script uses a **scoring system** to rank tracks:

1. **Rejection Phase:** Tracks matching reject keywords or languages are eliminated
2. **External Preference:** (Optional) External subs can be prioritized over embedded
3. **Language Priority:** Tracks matching preferred languages are ranked by position in your list
4. **Priority Keywords:** Tracks with keywords (e.g., "dialogue", "full") get a bonus
5. **Tiebreaker:** Track order in the file breaks ties

> **New in v1.1+:** The script watches for late-loading external subtitles and re-evaluates if a better option appears.

### 😯 Real Example

**Subtitles:**

```
❌ Russian "Надписи" (rejected: matches "надписи" keyword)
❌ English [Signs/Songs] (rejected: contains "sign")
✅ English [Full Dialogue] ← Selected!
❌ Commentary Track (rejected: contains "commentary")
```

**Audio:**

```
❌ Russian Dub (rejected: language in reject list)
✅ Japanese Original ← Selected!
❌ English Dub (lower priority than Japanese)
```

## 🚀 Quick Setup

### 1. File Placement

```
📁 portable_config/
├── 📁 scripts/
│   └── 📄 smart_track_selector.lua
└── 📁 script-opts/
    └── 📄 smart_track_selector.conf
```

### 2. MPV Configuration

For the script to take control, disable MPV's default track selection in `mpv.conf`:

```ini
# Comment out or remove these lines:
# sid=auto
# aid=auto
```

## ⚙️ Configuration

The script's behavior is controlled via `smart_track_selector.conf`.

### Subtitle Settings

```ini
# Language priority (first match wins)
sub_preferred_langs=en,eng,english

# Keywords that boost track priority
sub_priority_keywords=dialogue,full,complete,subs,subtitles,default,hearing,sdh

# Keywords that disqualify tracks
sub_reject_keywords=sign,song,commentary,forced,karaoke,op,ed,credit

# Languages to never select (leave empty if none)
sub_reject_langs=
```

### Audio Settings

```ini
# Language priority (Japanese first for anime)
audio_preferred_langs=ja,jpn,japanese,en,eng,english

# Keywords that boost track priority
audio_priority_keywords=original

# Keywords that disqualify tracks
audio_reject_keywords=commentary,descriptive,audio description

# Languages to never select (e.g., avoid Russian dubs)
audio_reject_langs=ru,rus,russian
```

### Behavior Settings

```ini
# Skip tracks marked as "forced" (yes/no)
skip_forced_tracks=yes

# Prefer external subtitle files over embedded tracks (yes/no)
# When enabled, manually added subtitle files are prioritized over embedded subs.
# Useful if you frequently add your own subtitle files.
# Note: Reject keywords still apply - external subs with rejected keywords are skipped.
prefer_external_subs=no

# Match audio to video language (yes/no)
# When enabled, if the video track has a language tag (vlang), prefer audio
# matching that language. Useful for watching content in its ORIGINAL language.
# Example: Video has vlang=de → German audio is selected automatically
match_audio_to_video=yes

# Use forced subtitles for native audio (yes/no)
# When enabled, if the selected audio matches a forced subtitle's language,
# that forced sub is selected. Useful for foreign dialogue in native-language films.
use_forced_for_native=yes

# Enable verbose logging for debugging (yes/no)
debug_logging=no
```

## 🌍 Non-English Keyword Support

### Case Sensitivity

| Character Type     | Case-Insensitive? | Example                                 |
| ------------------ | ----------------- | --------------------------------------- |
| **ASCII** (A-Z)    | ✅ Yes            | `sign` matches "Sign", "SIGNS", "signs" |
| **Cyrillic** (А-Я) | ❌ No             | `надписи` does NOT match "Надписи"      |
| **Japanese/Other** | ❌ No             | Exact match only                        |

### How to Handle Non-ASCII Keywords

For Cyrillic, Japanese, or other non-ASCII keywords, **include all case variants** you want to match:

```ini
# Russian example - include both lowercase and capitalized forms
sub_reject_keywords=надписи,Надписи,НАДПИСИ,субтитры,Субтитры

# Common patterns (first letter capitalized is most common)
sub_priority_keywords=полные,Полные,диалоги,Диалоги
```

> **Tip:** Most track titles use title case (first letter capitalized), so including both `надписи` and `Надписи` covers 99% of cases.

### ASCII Keywords (English, etc.)

ASCII keywords are fully case-insensitive — just use lowercase:

```ini
# These will match: "Signs", "SIGNS", "signs", "Sign & Song", etc.
sub_reject_keywords=sign,song,commentary,forced
```

## 🔧 Troubleshooting

- **Script not working:**

  1. Ensure files are in the correct folders
  2. Confirm `sid=auto` and `aid=auto` are removed from `mpv.conf`

- **Wrong track selected:**

  1. Enable `debug_logging=yes` in the conf file
  2. Press `` ` `` to open MPV console and see scoring details
  3. Add unwanted keywords to the appropriate reject list

- **Non-ASCII keywords not matching:**
  1. Include all case variants (e.g., `надписи,Надписи`)
  2. Ensure the conf file is saved as UTF-8 encoding

## 🎉 The Bottom Line

Install once, configure to your taste, then never think about track selection again. The script quietly does the right thing while you focus on actually watching your content.

**Features:**

- ✅ Audio track selection with language rejection
- ✅ Subtitle selection with keyword filtering
- ✅ Scoring-based selection (more accurate)
- ✅ Defense mechanism (protects selection for 5 seconds)
- ✅ External subtitle watching (re-evaluates when late subs load)
- ✅ External subtitle preference (optional: prioritize manually added subs)
- ✅ Video language matching (auto-select original audio based on vlang)
- ✅ Forced subs for native audio (show foreign dialogue subs when watching native)
- ✅ Works with any language (see case-sensitivity notes above)

</details>
</br>

# 🧠 Automatic Profile Manager

This script is the central nervous system of your mpv configuration. It eliminates manual profile switching by intelligently analyzing every file you play and applying the perfect profile for the content.

<details>
<summary><strong>Find out how it works!</strong></summary>

> _Because your 4K HDR movies shouldn't look like 20-year-old anime (and vice-versa)_

### 😤 The Annoying Problem This Fixes

You've spent hours crafting the perfect mpv profiles: one for crisp anime; another for cinematic HDR movies; and a third for legacy content.

But every time you open a file, you have to manually switch. Building complex `profile-cond` systems often leads to race conditions and inconsistent results. This script provides a centralized, robust solution.

### ✨ The Smart Solution

This script takes over profile selection using a multi-step logic that analyzes metadata as it becomes available. It distinguishing between anime, movies, and live-action content with high accuracy.

### 🤔 How It Thinks (The Decision Tree)

The script uses a tiered heuristic system to identify content:

1. **Tier 1: High-Confidence "Fingerprint" Check**

   - Scans for markers specific to animated content (especially fansubs):
     - **Japanese Audio + Embedded Fonts**: A nearly definitive combination for anime.
     - **"Signs & Songs" Subtitle Tracks**: Common in anime releases to translate on-screen text.
   - If found, it applies an anime profile immediately.

2. **Tier 2: General Episodic Check (Fallback)**
   - If no specific fingerprints are found, it falls back to a duration-based check:
     - Is it **Japanese or Chinese** audio?
     - Is the duration **under 40 minutes**?
   - This reliably catches standard anime/donghua episodes while excluding long-form live-action dramas.

If a file matches neither, it receives the standard `sdr` or `hdr` profile based on HDR detection.

## 🚀 Quick Setup

### 0. Prerequisite: The `mpv.conf` Connection ⚠️

The script applies specific profile names that **must** exist in your `mpv.conf`:

- `[anime-sdr]`
- `[anime-hdr]`
- `[anime-old]` (For 4:3 or interlaced anime)
- `[hdr]`
- `[sdr]`

### **1. Drop The File**

```
📁 portable_config/
└── 📁 scripts/
    └── 📄 profile-manager-standalone.lua
```

### **2. Clean Your `mpv.conf`**

**Delete every `profile-cond=...` line** from your `mpv.conf`. The script is now in charge; overlapping conditions will cause conflicts.

### ⚙️ Configuration

A **configuration table** is at the top of the `.lua` file for easy tweaking:

- Change the 40-minute duration threshold.
- Add or remove language codes for detection.
- Add new keywords for subtitle track detection.

### 🤔 How It Actually Works

1. **🔍 Waiting for Data**: The script observes `video-params`. It waits for all metadata (Primaries, Gamma, Matrix) to populate to ensure perfect HDR detection and stability.
2. **🧠 Single Run**: Logic runs exactly once per file load.
3. **⚡ Final Action**: Applies the profile and unregisters itself to save CPU.
4. **� A/V Resync**: Performs a 0.1s micro-seek 0.5s after load to force audio/video resync (essential when applying heavy shaders/filters).

## 🔧 Troubleshooting

### 🤔 **"It's not working!"**

- Open the mpv console (`~` key) and look for `[profile-manager]` logs.
- Ensure `video-params` are being detected (some rare stream formats take longer to populate).

### 😡 **"It picked the wrong profile!"**

Check the logged reason:

- `Reason: Tier 1 (Embedded Fonts + Japanese Audio)`
- `Reason: Tier 1 (Subtitle Track: 'Signs & Songs')`
- `Reason: Tier 2 (Japanese/Chinese Audio + Short Duration)`
- `Reason: Default (No Anime Detected)`

## 🎉 The Bottom Line

Modern, centralized logic that ends the "profile-cond" wars. Install it, forget it, and enjoy your content exactly as it was meant to be seen.

</details>
</br>


# ⚡ Instant Seeker - Reactive Filter Bypass

Heavy filters like SVP can cause debilitating lag when seeking. This script acts like a performance clutch, instantly and temporarily disengaging the filter chain the moment you seek, allowing for instantaneous rewinds and fast-forwards.  

<details>
<summary><strong>Find out how it works!</strong></summary>

  > *Because seeking shouldn't require a coffee break.*

### 😤 The Annoying Problem This Fixes

You're watching a buttery-smooth, 60fps interpolated video thanks to SVP and other heavy filters. You miss a line of dialogue and tap the left arrow key to jump back 5 seconds.

**...and the video freezes.**

The audio skips back instantly, but the video stutters and hangs for what feels like an eternity as the CPU screams, trying to re-process everything. That "quick rewind" just shattered your immersion. Seeking is supposed to be instant, not a punishment for using high-quality filters.

### ✨ The Smart Solution

This script is like a performance clutch for your video player. It's smart enough to know that seeking doesn't require complex video processing. The moment you seek, it temporarily disengages the heavy filters, letting you zip around the timeline instantly. Once you stop seeking, it seamlessly re-engages them.

The result? You get instant, lag-free seeking *and* the full quality of your video filters during normal playback. It’s the best of both worlds.

### Why It's Better Than Other Scripts:
- **🧠 Reactive, Not Dumb**: It doesn't just turn filters off and on. It validates its own actions against yours, so it never fights you if you manually toggle SVP.
- **💪 Rock Solid**: Handles rapid-fire seeks (like holding down the arrow key) and seeking while paused without breaking a sweat.
- **🎯 Surgical Precision**: It only targets the heavy filters you specify (like SVP) and leaves everything else alone.

## 🚀 Quick Setup

### Drop These Files:
```

📁 portable_config/
├── 📁 scripts/
│   └── 📄 reactive_vf_bypass.lua    ← The Clutch
└── 📁 script-opts/
    └── 📄 vf_bypass.conf            ← The Target List

```

### ⚙️ Configuration Magic

Edit `vf_bypass.conf` to tell the script which filters are "heavy" enough to be disabled during seeks.

```ini
# Keywords that identify your heavy filters (comma-separated)
# If a video filter contains any of these words, the script will manage it.
svp_keywords=SVP,vapoursynth
```

Most users will never need to change this. The default `SVP,vapoursynth` covers 99% of motion interpolation setups.

*Note: The 1.5-second restore delay is hardcoded in the script for maximum stability and to prevent race conditions. It's the sweet spot between responsiveness and reliability.*

### 🤔 How It Actually Works (The Clutch Analogy)

Think of playing a video with SVP like driving a car in first gear—lots of power, but not nimble.

1.  **Pressure Detected**: The moment you press a seek key, the script detects it.
2.  **Clutch In**: It instantly disengages the heavy video filters. The player is now in "neutral"—lightweight and incredibly responsive.
3.  **Shift Gears**: You can now seek backwards and forwards instantly, with zero lag or stuttering. If you keep seeking, the "clutch" stays in.
4.  **Clutch Out**: A moment after your *last* seek, the script smoothly re-engages the exact same filter chain. You're back in gear, enjoying buttery-smooth playback as if nothing happened.

The entire process is so fast, it's almost imperceptible. All you notice is that seeking finally works the way it's supposed to.

## 🔧 Troubleshooting

### 😵‍💫 **"It's not doing anything\!"**

  - Make sure your active video filter actually contains one of the keywords from `vf_bypass.conf` (e.g., "SVP"). If it doesn't, the script will correctly ignore it.
  - Check the mpv console (`~` key) for logs. The script is very talkative and will tell you if it's loading and what it's doing.

### 😡 **"The filters aren't coming back\!"**

  - This is extremely unlikely due to the script's validation logic. However, if it happens, it means another script or manual command is interfering. The logs will reveal the culprit. The script is designed to be defensive and will reset itself if it detects external changes.

## 🎉 The Bottom Line
This is a fire-and-forget script that fixes one of the most significant performance bottlenecks when using heavy video filters. Install it and enjoy a snappy, responsive player without sacrificing visual quality.
</details>
