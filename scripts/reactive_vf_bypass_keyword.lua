-- reactive_vf_bypass.lua
-- Reactive VF bypass for MPV - validates reality vs expectations
-- Only manages SVP-containing VF chains

local mp = require "mp"

-- State variables
local stored_vf = ""
local vf_detected = false
local is_restoring = false
local restore_timer = nil
local script_cleared_vf = false
local paused = false
local expected_state = "normal"  -- Track script phases: "normal", "cleared_for_seek", "restoring"
local last_seek_time = 0  -- For debouncing rapid seek events to prevent infinite loops
local DEBOUNCE_THRESHOLD = 0.2  -- Ignore seeks within 200ms of previous (prevents loop during pause+seek)

-- Configuration (keywords from file, delay hardcoded for safety)
local config = {
    svp_keywords = {"SVP", "vapoursynth"},
    restore_delay = 3.0  -- Hardcoded - For optimal safety use 3s delay after seeks
}

mp.msg.info("Reactive VF Bypass FIXED script loaded")

-- Load configuration file (only keywords, delay is hardcoded)
local function load_config()
    local config_path = mp.command_native({"expand-path", "~~/script-opts/vf_bypass.conf"})
    local file = io.open(config_path, "r")
    
    if not file then
        mp.msg.info("No config file found at " .. config_path .. ", using defaults")
        return
    end
    
    mp.msg.info("Loading config from: " .. config_path)
    
    for line in file:lines() do
        line = line:match("^%s*(.-)%s*$") -- trim whitespace
        if line ~= "" and not line:match("^#") then -- skip empty lines and comments
            local key, value = line:match("^([^=]+)=(.+)$")
            if key and value then
                key = key:match("^%s*(.-)%s*$") -- trim key
                value = value:match("^%s*(.-)%s*$") -- trim value
                
                if key == "svp_keywords" then
                    config.svp_keywords = {}
                    for keyword in value:gmatch("([^,]+)") do
                        keyword = keyword:match("^%s*(.-)%s*$") -- trim each keyword
                        table.insert(config.svp_keywords, keyword)
                    end
                    mp.msg.info("Loaded SVP keywords: " .. table.concat(config.svp_keywords, ", "))
                end
                -- Note: restore_delay is hardcoded and not loaded from config to prevent user breakage
            end
        end
    end
    
    file:close()
end

-- Extract the SVP-containing filter from a VF chain
local function extract_svp_filter(vf_chain)
    if not vf_chain or vf_chain == "" or vf_chain == "NONE" then
        return nil
    end
    
    -- Split the chain by commas to get individual filters
    for filter in vf_chain:gmatch("([^,]+)") do
        filter = filter:match("^%s*(.-)%s*$") -- trim whitespace
        -- Check if this individual filter contains SVP keywords
        for _, keyword in ipairs(config.svp_keywords) do
            if filter:find(keyword) then
                return filter
            end
        end
    end
    
    return nil
end

-- Normalize VF property value
local function norm_vf(v)
    if not v or v == "NONE" then return "" end
    return tostring(v)
end

-- Cancel any pending restore operation (don't reset is_restoring here - let timer handle it)
local function cancel_pending_restore(reason)
    if restore_timer then
        restore_timer:kill()
        restore_timer = nil
    end
    script_cleared_vf = false
    mp.msg.verbose("Pending restore cancelled: " .. (reason or "unknown"))
end

-- Reset all state
local function reset_state(reason)
    stored_vf = ""
    vf_detected = false
    cancel_pending_restore("state reset")
    mp.msg.verbose("VF bypass state reset: " .. (reason or "unknown"))
end

-- Context-specific validation functions (Step 2: Fix core validation bug)

-- Validate before seek: Ensure current VF matches stored before clearing (skip strict check if paused)
local function validate_before_seek()
    local current_vf = norm_vf(mp.get_property("vf"))
    
    mp.msg.verbose("[SEEK PHASE] Validating before seek:")
    mp.msg.verbose("  Current VF: '" .. (current_vf ~= "" and current_vf or "<empty>") .. "'")
    mp.msg.verbose("  Stored VF:  '" .. (stored_vf ~= "" and stored_vf or "<empty>") .. "'")
    mp.msg.verbose("  Paused: " .. tostring(paused))
    mp.msg.verbose("  Expected state: " .. expected_state)
    
    if stored_vf == "" then
        mp.msg.verbose("[SEEK PHASE] No stored VF, nothing to validate")
        return true
    end
    
    if paused then
        mp.msg.verbose("[SEEK PHASE] Paused - skipping strict VF match validation, assuming stored is valid")
        return true
    end
    
    local current_svp = extract_svp_filter(current_vf)
    if current_svp == stored_vf then
        mp.msg.verbose("[SEEK PHASE] Validation passed: Current SVP matches stored")
        return true
    else
        mp.msg.info("[SEEK PHASE] Validation failed: Current SVP doesn't match stored before seek")
        mp.msg.info("  Expected: " .. (stored_vf or "<none>"))
        mp.msg.info("  Found:    " .. (current_svp or "<none>"))
        return false
    end
end

-- Validate before restore: Check if stored VF is still valid (unchanged since clear), ignore current emptiness
local function validate_before_restore()
    local current_vf = norm_vf(mp.get_property("vf"))
    
    mp.msg.verbose("[RESTORE PHASE] Validating before restore:")
    mp.msg.verbose("  Current VF: '" .. (current_vf ~= "" and current_vf or "<empty>") .. "'")
    mp.msg.verbose("  Stored VF:  '" .. (stored_vf ~= "" and stored_vf or "<empty>") .. "'")
    mp.msg.verbose("  Expected state: " .. expected_state)
    mp.msg.verbose("  Note: After toggle off, current may not contain SVP filter")
    
    if stored_vf == "" then
        mp.msg.verbose("[RESTORE PHASE] No stored VF, skipping restore")
        return false
    end
    
    if expected_state ~= "cleared_for_seek" then
        mp.msg.warn("[RESTORE PHASE] Unexpected state for restore: " .. expected_state)
        -- Don't fail here - just warn and continue
    end
    
    -- After toggle off, the current VF chain should NOT contain the SVP filter
    -- This is expected behavior - we toggled it off, now we want to toggle it back on
    local current_svp = extract_svp_filter(current_vf)
    
    if current_svp == nil then
        -- Perfect - SVP filter is not in the chain (we toggled it off), ready to restore
        mp.msg.verbose("[RESTORE PHASE] Validation passed: SVP filter not in current chain (toggled off), ready to restore")
        return true
    elseif current_svp == stored_vf then
        -- SVP filter is already back somehow - no need to restore
        mp.msg.verbose("[RESTORE PHASE] Validation passed: SVP filter already present (no need to restore)")
        return true
    else
        -- Different SVP filter present - external change during restore window
        mp.msg.info("[RESTORE PHASE] External SVP change during restore window, updating stored")
        mp.msg.info("  Stored: " .. stored_vf)
        mp.msg.info("  New:    " .. current_svp)
        stored_vf = current_svp
        vf_detected = true
        return true
    end
end

-- Validate on resume from pause: Detect external changes during pause and react (Step 4: Distinguish script vs external actions)
local function validate_on_resume()
    local current_vf = norm_vf(mp.get_property("vf"))
    
    mp.msg.verbose("[RESUME PHASE] Validating on resume from pause:")
    mp.msg.verbose("  Current VF: '" .. (current_vf ~= "" and current_vf or "<empty>") .. "'")
    mp.msg.verbose("  Stored VF:  '" .. (stored_vf ~= "" and stored_vf or "<empty>") .. "'")
    mp.msg.verbose("  Expected state: " .. expected_state .. ", script_cleared_vf=" .. tostring(script_cleared_vf))
    
    if stored_vf == "" then
        mp.msg.verbose("[RESUME PHASE] No stored VF, nothing to validate")
        return true
    end
    
    local current_svp = extract_svp_filter(current_vf)
    
    if current_svp == stored_vf then
        mp.msg.verbose("[RESUME PHASE] Validation passed: Current SVP matches stored")
        return true
    end
    
    -- Mismatch: Check if this is a script action vs true external change
    if current_svp == nil then
        -- No SVP filter in current chain
        if expected_state == "cleared_for_seek" or script_cleared_vf then
            mp.msg.verbose("[RESUME PHASE] Expected missing SVP due to script clear during pause, preserving stored_vf")
            return true  -- Script's own action during pause, don't reset - let timer restore
        else
            mp.msg.info("[RESUME PHASE] External SVP removal detected during pause, resetting state")
            reset_state("external SVP removal during pause")
            cancel_pending_restore("external change during pause")
            return false
        end
    elseif current_svp then
        -- Different SVP filter present
        mp.msg.info("[RESUME PHASE] External SVP change detected during pause, updating stored VF")
        stored_vf = current_svp
        vf_detected = true
        mp.msg.info("  Updated to: " .. stored_vf)
        cancel_pending_restore("external change during pause")  -- Cancel any pending, as state changed
        expected_state = "normal"
        return true
    end
    
    -- Fallback - should not reach here
    mp.msg.verbose("[RESUME PHASE] Validation completed")
    return true
end

-- Handle file loading
mp.register_event("file-loaded", function()
    load_config() -- Reload config for each file
    reset_state("file loaded")
    
    -- Check if initial VF contains SVP
    local current_vf = norm_vf(mp.get_property("vf"))
    local svp_filter = extract_svp_filter(current_vf)
    if svp_filter then
        stored_vf = svp_filter
        vf_detected = true
        mp.msg.info("Initial SVP filter detected and stored: " .. stored_vf)
    else
        mp.msg.verbose("No SVP filter on file load, script inactive")
    end
end)

mp.register_event("end-file", function()
    reset_state("file ended")
end)

-- Track pause state and validate on resume
mp.observe_property("pause", "bool", function(_, val)
    local was_paused = paused
    paused = not not val
    
    if was_paused and not paused then
        -- Resuming from pause - validate our stored state
        mp.msg.verbose("Resumed from pause - validating stored VF")
        validate_on_resume()
    end
end)

-- Monitor VF changes
mp.observe_property("vf", "string", function(_, value)
    local current_vf = norm_vf(value)
    mp.msg.verbose("VF changed to: '" .. (current_vf ~= "" and current_vf or "<empty>") .. "'")
    
    -- If this change happened while we expect script control, validate it
    if script_cleared_vf or (is_restoring and expected_state == "cleared_for_seek") then
        -- During clear phase (script_cleared_vf true), expect empty VF
        if script_cleared_vf then
            local current_vf = norm_vf(value)
            if current_vf == "" then
                mp.msg.verbose("[CLEAR PHASE] VF empty as expected after script clear")
            else
                mp.msg.info("[CLEAR PHASE] Unexpected VF during clear: " .. current_vf)
                -- External change during clear - update if SVP
                if extract_svp_filter(current_vf) then
                    stored_vf = current_vf
                    vf_detected = true
                    mp.msg.info("Updated stored VF during clear: " .. stored_vf)
                end
            end
        -- During restore phase, expect empty or the restored chain
        elseif is_restoring then
            validate_before_restore()
        end
        return
    end
    
    -- External VF change - update our state accordingly
    local svp_filter = extract_svp_filter(current_vf)
    if svp_filter then
        if svp_filter ~= stored_vf then
            stored_vf = svp_filter
            vf_detected = true
            mp.msg.info("External SVP filter change detected, updated stored VF: " .. stored_vf)
        end
    else
        -- No SVP in current chain
        if stored_vf ~= "" then
            mp.msg.info("SVP filter removed externally, clearing stored VF")
            reset_state("external SVP removal")
        end
    end
end)

-- Handle seek events (Step 3: Multiple seeks with debouncing to prevent infinite loops during pause+seek)
mp.register_event("seek", function()
    local current_time = mp.get_time()
    
    -- Debounce: Ignore rapid successive seeks to prevent infinite loops
    if current_time - last_seek_time < DEBOUNCE_THRESHOLD then
        mp.msg.verbose("[SEEK PHASE] Seek debounced - too soon after previous (" .. string.format("%.3f", current_time - last_seek_time) .. "s)")
        return
    end
    last_seek_time = current_time
    
    -- Only act if we have an SVP chain stored
    if not vf_detected or stored_vf == "" then
        mp.msg.verbose("Seek ignored - no SVP chain stored")
        return
    end
    
    -- If already restoring, just restart the timer (handle multiple seeks)
    if is_restoring then
        mp.msg.verbose("[SEEK PHASE] Multiple seek detected - restarting restore timer")
        cancel_pending_restore("multiple seek - restarting timer")
    end
    
    -- Check if SVP filter is currently active - only clear if it's there
    local current_vf = norm_vf(mp.get_property("vf"))
    local current_svp = extract_svp_filter(current_vf)
    local need_clear = (current_svp == stored_vf) and (current_svp ~= nil)
    
    if need_clear then
        -- Validate before clearing (skip if paused)
        if expected_state == "normal" and not paused then
            if not validate_before_seek() then
                mp.msg.info("[SEEK PHASE] Pre-seek validation failed, aborting seek optimization")
                return
            end
        elseif paused then
            mp.msg.verbose("[SEEK PHASE] Seek during pause detected - skipping strict validation, proceeding with clear")
        end
        
        mp.msg.verbose("[SEEK PHASE] Seek detected - temporarily clearing SVP chain for performance" .. (paused and " (while paused)" or ""))
        expected_state = "cleared_for_seek"
        script_cleared_vf = true
        mp.commandv("vf", "toggle", stored_vf)
        mp.msg.info("[SEEK PHASE] Toggled SVP filter: " .. stored_vf)
    else
        mp.msg.verbose("[SEEK PHASE] Already cleared or no need to clear, just restarting timer")
    end
    
    -- Ensure is_restoring is true for the timer
    is_restoring = true
    
    -- Create/restart timer for this seek
    restore_timer = mp.add_timeout(config.restore_delay, function()
        restore_timer = nil
        script_cleared_vf = false
        
        mp.msg.verbose("[RESTORE PHASE] Timer fired - debug state: is_restoring=" .. tostring(is_restoring) .. ", stored_vf='" .. (stored_vf ~= "" and stored_vf or "<empty>") .. "', expected_state=" .. expected_state .. ", paused=" .. tostring(paused))
        
        -- Always attempt restore if we have stored VF (timer only set during seek)
        if stored_vf ~= "" then
            if validate_before_restore() then
                mp.msg.verbose("[RESTORE PHASE] Restoring SVP chain after seek: " .. stored_vf)
                mp.commandv("vf", "toggle", stored_vf)
                mp.msg.info("[RESTORE PHASE] Toggled SVP filter back on: " .. stored_vf)
                expected_state = "normal"
            else
                mp.msg.info("[RESTORE PHASE] Pre-restore validation failed, skipping restore")
                expected_state = "normal"
            end
            is_restoring = false
        else
            mp.msg.verbose("[RESTORE PHASE] Restore skipped - no stored VF (debug: how did stored_vf get cleared?)")
            expected_state = "normal"
            is_restoring = false
        end
    end)
end)