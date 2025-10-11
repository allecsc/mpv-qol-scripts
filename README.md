

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

# 🎯 Smart Subtitle Selector

Ends the nightmare of manually cycling through subtitle tracks. This script intelligently scans and selects the best subtitle track based on your preferences, automatically rejecting "Forced" or "Commentary" tracks.  

<details>
<summary><strong>Find out how it works!</strong></summary>

  > *An intelligent script to automatically select the correct subtitle track.*

### 😤 The Problem This Solves

When playing media with multiple subtitle tracks, MPV's default behavior often selects an undesirable track, such as "Signs & Songs" or "Forced," leading to a frustrating user experience. The user must then manually cycle through all available tracks on every single file to find the main dialogue track.

### ✨ The Solution

This script replaces MPV's default logic with an intelligent, priority-based system. It analyzes the titles of all available subtitle tracks and automatically selects the one that best matches the user's configured preferences, ignoring commentary or utility tracks.

This provides a "set it and forget it" solution that ensures the correct dialogue track is selected automatically, every time.

### 🤔 How It Works:

The script ranks subtitle tracks based on a tiered priority system:

1.  **Priority Tier:** First, it searches for tracks containing keywords that indicate a primary dialogue track (e.g., "dialogue," "full").
2.  **Normal Tier:** If no priority tracks are found, it falls back to any standard subtitle track that isn't explicitly rejected.
3.  **Rejected Tier:** It actively ignores any track containing keywords that mark it as a utility track (e.g., "signs," "songs," "commentary").

### 😯 Real Example:
```
Available tracks:
❌ English [Forced] 
❌ English [Signs/Songs]
✅ English [Full Dialogue] ← This one gets picked!
❌ Commentary Track
```

## 🚀 Quick Setup

### 1\. File Placement

```
📁 portable_config/
├── 📁 scripts/
│   └── 📄 smart_subs.lua
└── 📁 script-opts/
    └── 📄 smart_subs.conf
```

### 2\. MPV Configuration

For the script to take control, you must disable MPV's default subtitle selection logic. In your `mpv.conf` file, comment out or delete the following line:

```ini
# sid=auto
```

### ⚙️ Configuration

The script's behavior is controlled via `smart_subs.conf`.

```ini
# Languages to select, in order of preference.
preferred_langs = en,eng

# Keywords that identify a high-priority dialogue track.
priority_keywords = dialogue,full,complete

# Keywords that identify tracks to be ignored.
reject_keywords = signs,songs,commentary
```

### Example Configurations:

  * **For Multi-Language Users:** `preferred_langs = en,eng,jp,jpn`
  * **For Anime Fans:** `reject_keywords = signs,songs,commentary,forced,karaoke`
  * **For Movie Fans (with accessibility):** `priority_keywords = dialogue,full,complete,sdh`

## 🔧 Troubleshooting

  * **If the script isn't working:**
    1.  Ensure the `.lua` and `.conf` files are in the correct folders.
    2.  Confirm that `sid=auto` has been removed from `mpv.conf`.
  * **If the wrong track is selected:**
    1.  Check the track titles in your media file.
    2.  Add any unwanted keywords (e.g., "Forced") to `reject_keywords`.
    3.  Add any desired keywords to `priority_keywords`.
  * **To see the script's decision-making process:**
    1.  Enable the MPV console (press `~`). The script will log its actions, such as `Subtitle Selector: Found a PRIORITY track. Activating subtitle track #2`.

## 🎉 The Bottom Line
Install once, configure to your taste, then never think about subtitles again. The script just quietly does the right thing while you focus on actually watching your content.
</details>
</br>

# 🧠 Automatic Profile Manager

This script is the central nervous system of the entire configuration. It completely eliminates the need for manual profile switching by intelligently analyzing every file you play and applying the perfect profile for the content. 

<details>
<summary><strong>Find out how it works!</strong></summary>

  > *Because your 4K HDR movies shouldn't look like 20-year-old anime (and vice-versa)*

### 😤 The Annoying Problem This Fixes

You've spent hours crafting the perfect mpv profiles: one for crisp, vibrant anime; another for cinematic, tone-mapped HDR movies; and a third with deinterlacing for that old show you downloaded.

But every time you open a file, you have to manually switch between them. Or worse, you try to build a complex `profile-cond` system that constantly breaks, gets into fights with itself, and picks the wrong profile half the time because of weird race conditions. It's a fragile, frustrating mess.

### ✨ The Smart Solution

This script is the central brain your mpv config has been missing. It completely takes over the job of profile selection, analyzing every file on load using an advanced, multi-step process that thinks like a human. It applies the **one, correct profile** for what you're watching. No conditions, no fighting, no mistakes.

It's the set-it-and-forget-it system that finally makes your carefully tuned profiles work automatically, correctly distinguishing between anime, movies, and live-action dramas.

### 🤔 How It Thinks (The Decision Tree)

This script's sole purpose is to analyze the video file and apply the appropriate profile from the [**Visually Stunning Predefined Profiles**](https://github.com/allecsc/Stremio-Kai/tree/main?tab=readme-ov-file#-visually-stunning-predefined-profiles) table. It uses a powerful, two-tiered system to identify content with high accuracy and runs a lightning-fast check on every file, asking a series of questions to determine its exact nature and apply the perfect profile:

1. **Tier 1: High-Confidence "Fingerprint" Check**
  * First, it scans for metadata "fingerprints" that are strong indicators of anime. This includes things like:
      * Styled subtitle formats (`.ass`)
      * "Signs & Songs" subtitle tracks
      * Anime-specific chapter names ("Part A", "Part B")
      * Embedded font files
  * If it finds any of these, it confidently applies an anime profile. This method is smart enough to correctly identify anime **movies, specials, and even dubbed anime** that would fool simpler checks.

2. **Tier 2: General Episodic Check (Fallback)**
  * If the "fingerprints" aren't found, the script falls back to a safer, more general check. It asks two questions:
      1.  Does it have an Asian language audio track (Japanese, Chinese, etc.)?
      2.  Is its duration under 40 minutes (like a typical TV episode)?
  * If the answer to both is yes, it applies an anime profile. This reliably catches standard anime episodes while correctly **excluding live-action Asian dramas**, which are longer.

If a file matches neither tier, it receives the standard `sdr` or `hdr` profile.

## 🚀 Quick Setup

### 0. Prerequisite: The mpv.conf Connection ⚠️

This script is the "brain" of a profile system, but it is not the profiles themselves. The script's logic is designed to apply profile names (e.g., [anime-hdr], [general]) that must exist in your mpv.conf file.

  - **For Standalone Use:** It is highly recommended to use the provided [mpv.conf](https://github.com/allecsc/Stremio-Kai/blob/main/portable_config/mpv.conf) from the [Stremio Kai](https://github.com/allecsc/Stremio-Kai) project as a starting point. This file contains all the necessary profiles that this script is pre-configured to look for.

  - **For Advanced Users:** If you have your own extensive mpv.conf, you can adapt the script to your needs. You will need to edit the profile-manager.lua file and change the profile names inside the script's logic to match the names you use in your personal configuration.

This script is powerful, but it needs a well-defined set of profiles to manage. Using the provided mpv.conf is the easiest way to ensure everything works correctly out of the box.

### **1. Drop The File**

```

📁 portable_config/
└── 📁 scripts/
    └── 📄 profile-manager.lua        ← The Brain

```
### **2. Prepare Your `mpv.conf`**

This script is smart, but it's not a mind reader. It needs profiles to apply. Make sure your `mpv.conf` contains the profiles it will look for:

* `[anime-sdr]`
* `[anime-hdr]`
* `[anime-old]`
* `[hdr]`
* `[sdr]`

### **3. Clean Your `mpv.conf`**

This is critical. The script is now in charge. **Delete every `profile-cond=...` line** from your `mpv.conf`. If you don't, the old system will fight with the new script and cause chaos.

### ⚙️ Configuration Magic

This script has no `.conf` file, but it's still easy to configure. A **configuration table** has been placed at the very top of the `profile-manager.lua` file.

You can easily tweak the script's core logic without digging through the code:
* Add a new language for detection.
* Change the 40-minute duration threshold.
* Add new keywords to look for in chapter or subtitle titles.

Of course, the main way to configure is still by editing your profiles in `mpv.conf`. The script simply acts as the intelligent switch for the settings you've already defined.

Want your `[anime]` profile to be brighter? Edit `[anime]` in `mpv.conf`. Want your `[hdr]` profile to use different tone-mapping? Edit `[hdr]`. The script simply acts as the intelligent switch for the settings you've already defined.

### 🤔 How It Actually Works

When a video starts loading, the script patiently waits in the background.

1.  **🔍 Waits for Clues**: It observes mpv's properties, waiting for **all** the necessary data (`track-list` and `video-params`) to be fully populated. This crushes the race conditions that plague other methods.
2.  **🧠 Runs Once**: As soon as the data is ready, the script runs its decision tree logic exactly one time.
3.  **⚡ Takes Action**: It applies the single best profile (e.g., `apply-profile anime-hdr`) and then goes to sleep until the next file is loaded.

### 😯 Real Examples

| If the file is...                                       | The script will apply... | Why?                                                     |
| ------------------------------------------------------- | ------------------------ | -------------------------------------------------------- |
| 1080p Anime, Japanese audio, 24 min                     | `[anime-sdr]`            | Tier 2: Asian audio + short duration.                    |
| 2160p K-Drama, Korean audio, 60 min, HDR                | `[hdr]`                  | Tier 2: Fails duration check. Correctly not anime.       |
| 1080p Anime Movie, Japanese audio, 120 min, ASS subs    | `[anime-sdr]`            | Tier 1: Detects `.ass` subtitles, ignores long duration. |
| 720p Dubbed Anime, English audio, 24 min, "Signs" track | `[anime-sdr]`            | Tier 1: Detects "Signs" track, ignores English audio.    |
| 2160p Hollywood Movie, English audio, HDR               | `[hdr]`                  | Fails both tiers. Correctly not anime.                   |

## 🔧 Troubleshooting

### 🤔 **"It's not working!"**

* Make sure the `profile-manager.lua` file is in the correct `scripts` folder.
* Check that you **deleted all `profile-cond=` lines** from `mpv.conf`. This is the #1 cause of problems.
* Open the mpv console (`~` key) and look for logs prefixed with `[profile-manager]`. They will tell you exactly what the script is doing.

### 😡 **"It picked the wrong profile!"**

* Look at the log! The script now logs the **exact reason** for its choice.
* Open the mpv console (`~` key) and look for the `[profile-manager]` logs. You will see a line like:
    * `Reason: Tier 1 (ASS Subtitle Format)`
    * `Reason: Tier 2 (Asian Audio + Short Duration)`
    * `Reason: Default (No Anime Detected)`
* This tells you *why* it made its choice, allowing you to see if the file's metadata is the problem or if a tweak to the script's configuration table is needed.

## 🎉 The Bottom Line
Install it, clean your `mpv.conf`, and enjoy a player that is finally smart enough to use your profiles correctly. This is the robust, centralized logic that ends the profile wars for good.
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
