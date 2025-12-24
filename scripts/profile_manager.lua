--[[
  @name Profile Manager
  @description Automatically applies mpv profiles based on multi-tiered media analysis
  @version 3.4
  @author allecsc
  
  @changelog
    v3.0 - Initial tiered detection (chapters, fonts, language)
    v3.1 - Added HDR detection and legacy anime profiles
    v3.2 - Added reset-on-next-file integration
    v3.3 - Added Stremio metadata bridge integration
    v3.4 - Removed chapter detection, single-pass track scan, fixed nil logging
  
  @requires
    - Stremio Kai's mpv-bridge.js (sends anime-metadata script-message)
    - mpv.conf profiles: anime-sdr, anime-hdr, anime-old, sdr, hdr
  
  Detection Tiers:
    TIER 0: Stremio DB (MAL/AniList/Kitsu IDs) → 100% accurate
    TIER 1: Japanese Audio + Embedded Fonts/Signs Subs → ~95%
    TIER 2: Japanese/Chinese Audio + Duration <40min → ~80%
--]]

local opts = {
    -- Japanese language codes for anime detection
    -- Korean removed: too many false positives with K-dramas
    japanese_languages = {
        ja = true, jpn = true, jap = true, jp = true -- Japanese only
    },
    -- Chinese is kept separate for Tier 2 fallback (donghua detection)
    chinese_languages = {
        zh = true, zho = true, chi = true, cmn = true, yue = true
    },
    -- Duration threshold in seconds. Default is 2400 (40 minutes).
    duration_threshold_seconds = 2400,

    -- Tier 1: Keywords to look for in subtitle track titles (fansub markers)
    anime_sub_track_keywords = { "signs", "songs" }
}

-- Internal state
local function log(str)
    mp.msg.info("[profile-manager] " .. str)
end

local profile_applied_for_this_file = false
local observer_registered = false
local detection_reason = "None"

-- Stremio metadata bridge (receives anime IDs from mpv-bridge.js)
local stremio_metadata = nil
local utils = require("mp.utils")

mp.register_script_message("anime-metadata", function(json_str)
    stremio_metadata = utils.parse_json(json_str)
    if stremio_metadata then
        log("Received Stremio metadata: is_anime=" .. tostring(stremio_metadata.is_anime) .. 
            ", MAL=" .. tostring(stremio_metadata.mal_id))
    end
end)

-- Enhanced HDR detection function
local function detect_hdr(video_params)
    if not video_params then return false end
    
    local primaries = video_params.primaries
    local gamma = video_params.gamma
    local colormatrix = video_params.colormatrix
    
    -- Log the detected values for debugging
    log("Video params - Primaries: " .. tostring(primaries) .. ", Gamma: " .. tostring(gamma) .. ", Colormatrix: " .. tostring(colormatrix))
    
    -- Check for Dolby Vision profile
    if colormatrix == "dolbyvision" then
        log("Dolby Vision detected")
        return true
    end
    
    -- Check for HDR10/HDR10+ via primaries
    if primaries == "bt.2020" or primaries == "rec2020" then
        log("HDR detected via primaries: " .. tostring(primaries))
        return true
    end
    
    -- Check for HDR via gamma/transfer characteristics
    if gamma == "smpte2084" or gamma == "pq" or gamma == "st2084" then
        log("HDR10 detected via gamma: " .. tostring(gamma))
        return true
    end
    
    if gamma == "arib-std-b67" or gamma == "hlg" then
        log("HLG detected via gamma: " .. tostring(gamma))
        return true
    end
    
    -- Additional checks for HDR indicators
    if colormatrix == "bt.2020-ncl" or colormatrix == "bt.2020-cl" or colormatrix == "rec2020" then
        log("HDR detected via colormatrix: " .. tostring(colormatrix))
        return true
    end
    
    return false
end

function select_and_apply_profile(name, video_params)
    if profile_applied_for_this_file then return end

    -- 1. Gather all necessary data from mpv
    local track_list = mp.get_property_native('track-list')
    local duration = mp.get_property_native('duration')
    local chapter_list = mp.get_property_native('chapter-list')
    local attachments = mp.get_property_native('attachments')

    -- 2. Data Validation: Abort if critical data is not yet available.
    -- We need track-list, duration, and basic video params (height) to proceed.
    if not track_list or #track_list == 0 or not video_params or not video_params.h or not duration then
        return
    end
    
    -- NEW: Wait for video params to be fully loaded (Primaries/Gamma/Matrix)
    -- This is crucial for HDR detection and stream stability.
    local primaries = video_params.primaries
    local gamma = video_params.gamma  
    local colormatrix = video_params.colormatrix
    
    if not primaries or not gamma or not colormatrix then
        return
    end

    log("--- Starting Profile Evaluation (All data available) ---")
    
    -- Extract video info early (needed regardless of anime detection)
    local height = video_params.h
    local width = video_params.w  
    local is_interlaced = video_params.interlaced or false
    local is_hdr = detect_hdr(video_params)
    local is_short_duration = (duration < opts.duration_threshold_seconds)
    
    -- Single-pass track scan for all audio/sub info
    local has_japanese_audio = false
    local has_jp_or_cn_audio = false
    local has_embedded_fonts = false
    local has_signs_songs_subs = false
    local signs_songs_track_title = nil
    
    for _, track in ipairs(track_list) do
        if track.type == 'audio' then
            if opts.japanese_languages[track.lang] then
                has_japanese_audio = true
                has_jp_or_cn_audio = true
            elseif opts.chinese_languages[track.lang] then
                has_jp_or_cn_audio = true
            end
        elseif track.type == 'sub' and track.title and not has_signs_songs_subs then
            local lower_title = track.title:lower()
            for _, keyword in ipairs(opts.anime_sub_track_keywords) do
                if lower_title:find(keyword, 1, true) then
                    has_signs_songs_subs = true
                    signs_songs_track_title = track.title
                    break
                end
            end
        end
    end
    
    -- Check for embedded fonts (separate loop - attachments, not tracks)
    if attachments and #attachments > 0 then
        for _, att in ipairs(attachments) do
            if att.mime_type and att.mime_type:find("font") then
                has_embedded_fonts = true
                break
            end
        end
    end
    
    -- 3. The Decision Logic (Tiered Approach)
    local is_anime = false

    -- TIER 0: Stremio Metadata (Highest Priority - from database MAL/AniList IDs)
    if stremio_metadata and stremio_metadata.is_anime then
        is_anime = true
        detection_reason = "Stremio DB (MAL ID: " .. tostring(stremio_metadata.mal_id) .. ")"
        log("TIER 0 MATCH: " .. detection_reason)
    end

    -- TIER 1: High-Confidence "Fingerprint" Check (Japanese audio + animation markers)
    if not is_anime then
        if has_japanese_audio and has_embedded_fonts then
            is_anime = true
            detection_reason = "Tier 1 (Embedded Fonts + Japanese Audio)"
        elseif has_signs_songs_subs then
            is_anime = true
            detection_reason = "Tier 1 (Subtitle Track: '" .. signs_songs_track_title .. "')"
        end
    end

    -- TIER 2: General Episodic Check (Fallback)
    if not is_anime and has_jp_or_cn_audio and is_short_duration then
        is_anime = true
        detection_reason = "Tier 2 (Japanese/Chinese Audio + Short Duration)"
    end

    -- 4. Profile Selection
    local final_profile = nil
    
    -- Legacy anime detection: Apply deinterlacing profile for SD interlaced anime only
    -- Resolution guard (≤576) prevents missflagged HD content from triggering
    local is_legacy_anime = false
    
    if is_anime and is_interlaced and height <= 576 then
        is_legacy_anime = true
    end

    if is_anime then
        if is_hdr then
            final_profile = "anime-hdr"
        elseif is_legacy_anime then
            final_profile = "anime-old"
            detection_reason = detection_reason .. " + Interlaced"          
        else
            final_profile = "anime-sdr"
        end
    else
        detection_reason = "Default (No Anime Detected)"
        if is_hdr then
            final_profile = "hdr"
        else
            final_profile = "sdr"
        end
    end

    -- 5. Apply the chosen profile (base profiles inherit from default, so reset is automatic)
    if final_profile then
        log("--- FINAL DECISION ---")
        log("Reason: " .. detection_reason)
        log("HDR Status: " .. tostring(is_hdr))
        log("Resolution: " .. tostring(height) .. "p")
        
        log("Applying profile '" .. final_profile .. "'")
        mp.commandv("apply-profile", final_profile)
        
        -- A/V RESYNC: Anime profiles have heavy shaders/VF that cause desync on D3D11
        -- Micro-seek after initialization forces audio/video to resync
        if final_profile == "anime-sdr" or final_profile == "anime-hdr" or final_profile == "anime-old" then
            mp.add_timeout(0.5, function()
                local pos = mp.get_property_number("time-pos")
                if pos and pos > 0.5 then
                    mp.commandv("seek", "-0.1", "relative", "exact")
                    log("A/V resync: micro-seek performed")
                end
            end)
        end
    else
        log("--- No profile matched. Applying defaults only. ---")
        mp.commandv("apply-profile", "default")
    end
    
    profile_applied_for_this_file = true
    
    -- Unregister the observer once the profile is applied to save CPU
    mp.unobserve_property(select_and_apply_profile)
    observer_registered = false
    log("Profile applied and observer unregistered.")
end

-- Use a self-unregistering observer to wait for metadata (crucial for streams)
mp.observe_property('video-params', 'native', select_and_apply_profile)
observer_registered = true

-- Reset the flag when a new file is loaded
mp.register_event('start-file', function()
    -- =======================================================================
    -- LIST CLEARS ONLY: mpv.conf has reset-on-next-file=all for scalar options
    -- Use change-list for lists as failsafe (most reliable method)
    -- =======================================================================
    
    mp.commandv("change-list", "glsl-shaders", "clr", "")
    mp.commandv("change-list", "vf", "clr", "")
    mp.commandv("change-list", "af", "clr", "")
    
    log("Lists cleared. Waiting for profile selection...")
    
    profile_applied_for_this_file = false
    detection_reason = "None"
    -- NOTE: Do NOT reset stremio_metadata here - the script-message arrives BEFORE start-file
    -- and would be wiped. The message is sent per-file anyway, so no stale data risk.
    
    -- Only register if not already registered (prevents observer leak)
    if not observer_registered then
        mp.observe_property('video-params', 'native', select_and_apply_profile)
        observer_registered = true
    end
end)


