--[[
  @name Smart Track Selector
  @description Automatically selects best audio and subtitle tracks based on configurable preferences
  @version 1.2.0
  @author allecsc
  
  @changelog
    v1.2.0 - Added prefer_external_subs option: external subs are prioritized
             over embedded when enabled (useful for manual subtitle files)
    v1.1.0 - Added external subtitle watching: re-evaluates when new subs
             load if no preferred language was found initially (10s window)
    v1.0.0 - Complete rewrite from smart_subs.lua
           - Added audio track selection with rejection lists
           - Improved scoring system (language priority + keyword position)
           - Added defense mechanism for both audio and subtitles
           - Fixed keyword matching (ASCII case-insensitive, substring search)
  
  @requires
    - script-opts/smart_track_selector.conf
  
  Case Sensitivity:
    - ASCII (A-Z):     Case-insensitive (sign matches SIGNS, Signs, etc.)
    - Non-ASCII:       Case-sensitive (надписи does NOT match Надписи)
                       Include all case variants in config for non-ASCII keywords
  
  Scoring Hierarchy:
    1. Language Priority  - Position in preferred_langs list (lower = better)
    2. Keyword Priority   - Position in priority_keywords list (lower = better)
                           Tracks with NO keyword get neutral score (middle of list)
    3. Track Order        - File order as tiebreaker (lower = better)
--]]

local mp = require 'mp'
local options = require 'mp.options'

--------------------------------------------------------------------------------
-- 1. CONFIGURATION
--------------------------------------------------------------------------------
-- All defaults are empty. Actual values come from smart_track_selector.conf
local config = {
    -- Subtitle settings
    sub_preferred_langs = "",
    sub_priority_keywords = "",
    sub_reject_keywords = "",
    sub_reject_langs = "",

    -- Audio settings
    audio_preferred_langs = "",
    audio_priority_keywords = "",
    audio_reject_keywords = "",
    audio_reject_langs = "",

    -- Behavior
    skip_forced_tracks = true,
    prefer_external_subs = false,  -- When true, external subs are preferred over embedded
    debug_logging = false
}

options.read_options(config, "smart_track_selector")

--------------------------------------------------------------------------------
-- 2. CONSTANTS (not configurable)
--------------------------------------------------------------------------------
local DEFENSE_DURATION = 5   -- seconds to defend selection from external changes
local WATCH_WINDOW = 10      -- seconds to watch for new subtitle tracks
local DEBOUNCE_DELAY = 0.3   -- seconds to debounce rapid track-list changes
local SCRIPT_NAME = "smart_track_selector"

--------------------------------------------------------------------------------
-- 3. STATE
--------------------------------------------------------------------------------
local state = {
    best_sid = nil,
    best_aid = nil,
    defense_active = false,
    parsed_config = nil,      -- Cache parsed lists
    -- External sub watching
    initial_sub_count = 0,    -- Sub count at file-loaded
    watch_active = false,     -- Whether we're watching for new subs
    debounce_timer = nil,     -- Debounce timer for track-list changes
    initial_sub_had_lang = false  -- Did initial selection find preferred language?
}

--------------------------------------------------------------------------------
-- 4. LOGGING
--------------------------------------------------------------------------------
local function log_info(msg)
    mp.msg.info(msg)
end

local function log_debug(msg)
    if config.debug_logging then
        mp.msg.verbose("[DEBUG] " .. msg)
    end
end

local function log_verbose(msg)
    mp.msg.verbose(msg)
end

--------------------------------------------------------------------------------
-- 5. STRING MATCHING UTILITIES
--------------------------------------------------------------------------------

-- Check if haystack contains needle (case-insensitive for ASCII only)
-- For non-ASCII characters (Cyrillic, Japanese, etc.), matching is CASE-SENSITIVE.
-- Users should include all case variants in their keyword lists for non-ASCII.
local function contains_keyword(haystack, needle)
    if not haystack or not needle or needle == "" then return false end

    -- Try case-insensitive match using ASCII lowercase
    local lower_haystack = haystack:lower()
    local lower_needle = needle:lower()

    -- Plain string find (no pattern matching)
    return lower_haystack:find(lower_needle, 1, true) ~= nil
end

--------------------------------------------------------------------------------
-- 6. PARSING
--------------------------------------------------------------------------------

-- Parse comma-separated string into array (trimmed, no case conversion here)
local function parse_list(str)
    if not str or str == "" then return {} end

    local list = {}
    for item in string.gmatch(str, "([^,]+)") do
        local trimmed = item:match("^%s*(.-)%s*$")
        if trimmed and trimmed ~= "" then
            table.insert(list, trimmed)
        end
    end
    return list
end

-- Parse all config lists once
local function parse_config()
    if state.parsed_config then return state.parsed_config end

    state.parsed_config = {
        sub = {
            preferred_langs = parse_list(config.sub_preferred_langs),
            priority_keywords = parse_list(config.sub_priority_keywords),
            reject_keywords = parse_list(config.sub_reject_keywords),
            reject_langs = parse_list(config.sub_reject_langs)
        },
        audio = {
            preferred_langs = parse_list(config.audio_preferred_langs),
            priority_keywords = parse_list(config.audio_priority_keywords),
            reject_keywords = parse_list(config.audio_reject_keywords),
            reject_langs = parse_list(config.audio_reject_langs)
        }
    }

    log_debug("Parsed config:")
    log_debug("  sub_preferred_langs: " .. table.concat(state.parsed_config.sub.preferred_langs, ", "))
    log_debug("  sub_reject_keywords: " .. table.concat(state.parsed_config.sub.reject_keywords, ", "))
    log_debug("  audio_preferred_langs: " .. table.concat(state.parsed_config.audio.preferred_langs, ", "))
    log_debug("  audio_reject_langs: " .. table.concat(state.parsed_config.audio.reject_langs, ", "))

    return state.parsed_config
end

--------------------------------------------------------------------------------
-- 7. TRACK EVALUATION
--------------------------------------------------------------------------------

-- Check if language matches any in the list
local function matches_language(track_lang, lang_list)
    if not track_lang or #lang_list == 0 then return false, 0 end

    for i, lang in ipairs(lang_list) do
        if contains_keyword(track_lang, lang) then
            return true, i  -- Return position for scoring
        end
    end
    return false, 0
end

-- Check if title contains any keyword from the list, returns position (1 = best)
local function matches_keyword(title, keyword_list)
    if not title or #keyword_list == 0 then return false, 0 end

    for i, keyword in ipairs(keyword_list) do
        if contains_keyword(title, keyword) then
            return true, i  -- Return position for scoring
        end
    end
    return false, 0
end

-- Evaluate a single track, returns nil if rejected, or a score table
local function evaluate_track(track, track_type, cfg)
    local title = track.title or ""
    local lang = track.lang or ""

    log_debug(string.format("  Evaluating %s track #%d: lang='%s', title='%s'",
        track_type, track.id, lang, title))

    -- REJECTION CHECKS (early exit)

    -- Check forced tracks
    if config.skip_forced_tracks and track.forced then
        log_debug("    → REJECTED: forced track")
        return nil
    end

    -- Check rejected languages
    if matches_language(lang, cfg.reject_langs) then
        log_debug("    → REJECTED: language in reject list")
        return nil
    end

    -- Check rejected keywords in title
    if matches_keyword(title, cfg.reject_keywords) then
        log_debug("    → REJECTED: keyword in title matches reject list")
        return nil
    end

    -- SCORING

    local score = {
        is_external = track.external or false,  -- External sub bonus (when enabled)
        lang_priority = 0,       -- Lower is better (position in preferred list)
        keyword_priority = 999,  -- Lower is better (position in priority keywords)
        track_order = track.id   -- Tiebreaker
    }

    -- Language scoring
    local lang_match, lang_pos = matches_language(lang, cfg.preferred_langs)
    if lang_match then
        score.lang_priority = lang_pos
        log_debug(string.format("    + Language match at priority %d", lang_pos))
    else
        score.lang_priority = 999  -- No match = lowest priority
        log_debug("    - No language match")
    end

    -- Priority keyword scoring
    -- Keywords at the END of the list are fallbacks (e.g., sdh, hearing)
    -- Tracks with NO keyword match are preferred over fallback keywords
    -- Tracks with EARLY keywords (dialogue, full) are preferred over no keyword
    local kw_match, kw_pos = matches_keyword(title, cfg.priority_keywords)
    if kw_match then
        -- Matched keyword - use position (1 = best, higher = worse)
        score.keyword_priority = kw_pos
        log_debug(string.format("    + Priority keyword match at position %d", kw_pos))
    else
        -- No keyword match - neutral score (better than late keywords like SDH)
        -- Use half the list length as neutral point, so early keywords beat it
        local neutral_score = math.floor(#cfg.priority_keywords / 2) + 1
        score.keyword_priority = neutral_score
        log_debug(string.format("    = No priority keyword (neutral score %d)", neutral_score))
    end

    -- Log external status if prefer_external_subs is enabled
    if config.prefer_external_subs and track_type == "sub" and score.is_external then
        log_debug("    ★ External subtitle (prioritized)")
    end

    return score
end

-- Compare two scores, return true if score_a is better than score_b
local function is_better_score(score_a, score_b)
    if not score_b then return true end
    if not score_a then return false end

    -- External preference (only for subs, when enabled)
    -- External subs win over embedded when prefer_external_subs is on
    if config.prefer_external_subs then
        if score_a.is_external and not score_b.is_external then
            return true
        end
        if not score_a.is_external and score_b.is_external then
            return false
        end
    end

    -- Language priority (lower is better)
    if score_a.lang_priority < score_b.lang_priority then
        return true
    end
    if score_a.lang_priority > score_b.lang_priority then
        return false
    end

    -- Priority keyword position (lower is better, 999 = no match)
    if score_a.keyword_priority < score_b.keyword_priority then
        return true
    end
    if score_a.keyword_priority > score_b.keyword_priority then
        return false
    end

    -- Track order as tiebreaker (lower is better)
    return score_a.track_order < score_b.track_order
end

--------------------------------------------------------------------------------
-- 8. SELECTION LOGIC
--------------------------------------------------------------------------------

local function select_best_track(track_type)
    local track_list = mp.get_property_native("track-list")
    if not track_list then return nil end

    local cfg = parse_config()[track_type]
    if not cfg then
        log_info("No config for track type: " .. track_type)
        return nil
    end

    -- Check if we have any preferences configured
    local has_prefs = #cfg.preferred_langs > 0 or #cfg.reject_keywords > 0 or
                      #cfg.reject_langs > 0 or #cfg.priority_keywords > 0

    if not has_prefs then
        log_debug("No preferences configured for " .. track_type .. ", skipping selection")
        return nil
    end

    log_info(string.format("Analyzing %s tracks...", track_type))

    local best_track = nil
    local best_score = nil

    for _, track in ipairs(track_list) do
        if track.type == track_type then
            local score = evaluate_track(track, track_type, cfg)

            if score and is_better_score(score, best_score) then
                best_track = track
                best_score = score
            end
        end
    end

    if best_track then
        log_info(string.format("Selected %s track #%d: %s (%s)",
            track_type, best_track.id,
            best_track.title or "(no title)",
            best_track.lang or "(no lang)"))
        return best_track.id
    else
        log_info("No suitable " .. track_type .. " track found")
        return nil
    end
end

--------------------------------------------------------------------------------
-- 9. DEFENSE MECHANISM
--------------------------------------------------------------------------------

local function defend_subtitle(name, value)
    if not state.defense_active or not state.best_sid then return end

    if value and value ~= state.best_sid then
        mp.set_property("sid", state.best_sid)
        log_verbose(string.format("Restored subtitle track #%d (overrode external change)", state.best_sid))
    end
end

local function defend_audio(name, value)
    if not state.defense_active or not state.best_aid then return end

    if value and value ~= state.best_aid then
        mp.set_property("aid", state.best_aid)
        log_verbose(string.format("Restored audio track #%d (overrode external change)", state.best_aid))
    end
end

local function activate_defense()
    if not state.best_sid and not state.best_aid then return end

    state.defense_active = true
    log_debug(string.format("Defense activated for %d seconds", DEFENSE_DURATION))

    mp.add_timeout(DEFENSE_DURATION, function()
        state.defense_active = false
        log_debug("Defense period ended")
    end)
end

--------------------------------------------------------------------------------
-- 10. EXTERNAL SUBTITLE WATCHING
--------------------------------------------------------------------------------

-- Count subtitle tracks in track-list
local function count_sub_tracks()
    local track_list = mp.get_property_native("track-list") or {}
    local count = 0
    for _, track in ipairs(track_list) do
        if track.type == "sub" then
            count = count + 1
        end
    end
    return count
end

-- Check if the selected subtitle has a preferred language
local function selection_has_preferred_lang()
    if not state.best_sid then return false end
    
    local track_list = mp.get_property_native("track-list") or {}
    local cfg = parse_config()["sub"]
    if not cfg or #cfg.preferred_langs == 0 then return true end  -- No prefs = satisfied
    
    for _, track in ipairs(track_list) do
        if track.id == state.best_sid and track.type == "sub" then
            local lang = track.lang or ""
            for _, pref_lang in ipairs(cfg.preferred_langs) do
                if contains_keyword(lang, pref_lang) then
                    return true
                end
            end
            break
        end
    end
    return false
end

-- Handle track-list changes during watch window
local function on_track_list_change()
    -- Only care if watching is active
    if not state.watch_active then return end
    
    -- Debounce rapid changes
    if state.debounce_timer then
        state.debounce_timer:kill()
    end
    
    state.debounce_timer = mp.add_timeout(DEBOUNCE_DELAY, function()
        state.debounce_timer = nil
        
        local current_count = count_sub_tracks()
        
        -- Check if new subs appeared
        if current_count > state.initial_sub_count then
            log_debug(string.format("New subs detected: %d → %d", state.initial_sub_count, current_count))
            
            -- Only re-evaluate if initial selection didn't have preferred language
            if not state.initial_sub_had_lang then
                log_info("Re-evaluating subtitles (external subs loaded)...")
                
                -- Temporarily disable defense to allow change
                local was_defending = state.defense_active
                state.defense_active = false
                
                local new_sid = select_best_track("sub")
                if new_sid and new_sid ~= state.best_sid then
                    state.best_sid = new_sid
                    mp.set_property("sid", state.best_sid)
                    
                    -- Check if new selection has preferred language
                    if selection_has_preferred_lang() then
                        log_info("Found preferred language in external subs!")
                        state.initial_sub_had_lang = true  -- Stop re-evaluating
                    end
                end
                
                -- Restore defense
                state.defense_active = was_defending
            end
            
            -- Update count for next comparison
            state.initial_sub_count = current_count
        end
    end)
end

-- Stop watching for external subs
local function stop_watching()
    if state.watch_active then
        state.watch_active = false
        log_debug("Stopped watching for external subs")
    end
    if state.debounce_timer then
        state.debounce_timer:kill()
        state.debounce_timer = nil
    end
end

--------------------------------------------------------------------------------
-- 11. MAIN ORCHESTRATOR
--------------------------------------------------------------------------------

local function on_file_loaded()
    -- Reset state
    state.best_sid = nil
    state.best_aid = nil
    state.defense_active = false
    state.parsed_config = nil  -- Re-parse config (allows hot-reload of conf file)
    state.initial_sub_count = 0
    state.watch_active = false
    state.initial_sub_had_lang = false
    
    if state.debounce_timer then
        state.debounce_timer:kill()
        state.debounce_timer = nil
    end

    -- Select audio track (audio is usually embedded, no watching needed)
    state.best_aid = select_best_track("audio")
    if state.best_aid then
        mp.set_property("aid", state.best_aid)
    end

    -- Select subtitle track
    state.best_sid = select_best_track("sub")
    if state.best_sid then
        mp.set_property("sid", state.best_sid)
    end
    
    -- Record initial state for external sub watching
    state.initial_sub_count = count_sub_tracks()
    state.initial_sub_had_lang = selection_has_preferred_lang()
    
    log_debug(string.format("Initial: %d subs, preferred_lang=%s", 
        state.initial_sub_count, tostring(state.initial_sub_had_lang)))
    
    -- Start watching for external subs if no preferred language yet
    if not state.initial_sub_had_lang then
        state.watch_active = true
        log_info(string.format("No preferred language found, watching for external subs (%ds)...", WATCH_WINDOW))
        
        -- Stop watching after window expires
        mp.add_timeout(WATCH_WINDOW, stop_watching)
    end

    -- Activate defense
    activate_defense()
end

--------------------------------------------------------------------------------
-- 12. INITIALIZATION & EVENT REGISTRATION
--------------------------------------------------------------------------------

mp.register_event("file-loaded", on_file_loaded)
mp.observe_property("sid", "number", defend_subtitle)
mp.observe_property("aid", "number", defend_audio)
mp.observe_property("track-list", "native", on_track_list_change)

log_info("Smart Track Selector initialized (v1.2.0)")
