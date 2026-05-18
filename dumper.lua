-- core/dumper.lua - Enhanced Luau deobfuscator with multi-layer support

-- Load configuration
local config = {}
local config_loaded, config_data = pcall(dofile, "config.lua")
if config_loaded then config = config_data else
    print("[WARNING] Could not load config.lua, using defaults")
    config = { output_dir = "output", max_dumps_per_run = 500, verbose = true }
end

-- Load string decoder utilities
local decoder = {}
local decoder_loaded, decoder_module = pcall(dofile, "utils/string_decoder.lua")
if decoder_loaded then decoder = decoder_module end

-- State tracking
local state = {
    counter = 0,
    urls_found = {},
    decoded_strings = {},
    chunks_dumped = {},
    vm_detected = false,
    start_time = os.time()
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function ensure_dir(dir)
    os.execute("mkdir -p " .. dir .. " 2>/dev/null")
end

local function safe_filename(name)
    name = name:gsub("[^%w_%-]", "_")
    if #name > config.max_filename_length then
        name = name:sub(1, config.max_filename_length)
    end
    return name
end

local function log(level, message)
    local prefix = string.format("[%s]", level)
    if config.include_timestamps then
        prefix = string.format("[%s %s]", os.date("%H:%M:%S"), level)
    end
    print(prefix .. " " .. message)
end

local function analyze_chunk(code, name)
    local analysis = {
        size = #code,
        lines = 0,
        urls = {},
        strings = {},
        patterns = {},
        constants = {}
    }
    
    -- Count lines
    for _ in code:gmatch("\n") do
        analysis.lines = analysis.lines + 1
    end
    
    -- Decode obfuscated strings
    if decoder.decode_char_sequence then
        analysis.strings = decoder.decode_char_sequence(code)
    end
    
    -- Extract URLs
    if decoder.extract_urls then
        analysis.urls = decoder.extract_urls(code)
    end
    
    -- Detect VM patterns
    if decoder.detect_vm_patterns then
        analysis.patterns = decoder.detect_vm_patterns(code)
    end
    
    -- Extract constants
    if decoder.extract_constants then
        analysis.constants = decoder.extract_constants(code)
    end
    
    return analysis
end

-- ============================================================================
-- DUMPING FUNCTIONS
-- ============================================================================

local function write_dump(name, code, analysis)
    if state.counter >= config.max_dumps_per_run then
        log("WARNING", "Max dumps reached, skipping further output")
        return false
    end
    
    state.counter = state.counter + 1
    local fname = string.format("dump_%04d_%s.lua", state.counter, safe_filename(name))
    local fpath = config.output_dir .. "/" .. fname
    
    local f = io.open(fpath, "w")
    if not f then
        log("ERROR", "Failed to write: " .. fpath)
        return false
    end
    
    -- Write header with metadata
    f:write("--[[\n")
    f:write("  Captured from: " .. name .. "\n")
    f:write("  Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
    f:write("  Size: " .. analysis.size .. " bytes (" .. analysis.lines .. " lines)\n")
    
    if #analysis.strings > 0 then
        f:write("\n  Decoded strings found:\n")
        for i, str in ipairs(analysis.strings) do
            if i > 10 then f:write("  ... and " .. (#analysis.strings - 10) .. " more\n") break end
            f:write("    - " .. str:sub(1, 100) .. "\n")
        end
    end
    
    if next(analysis.urls) then
        f:write("\n  URLs found:\n")
        for url in pairs(analysis.urls) do
            f:write("    - " .. url .. "\n")
            state.urls_found[url] = true
        end
    end
    
    if next(analysis.patterns) then
        f:write("\n  VM Patterns detected:\n")
        for pattern, detected in pairs(analysis.patterns) do
            if detected then
                f:write("    - " .. pattern .. "\n")
                state.vm_detected = true
            end
        end
    end
    
    f:write("--]]\n\n")
    
    -- Write actual code
    f:write(code)
    f:close()
    
    if config.verbose then
        log("DUMP", string.format("#%d -> %s (%d bytes)", state.counter, fname, analysis.size))
    end
    
    return true
end

-- ============================================================================
-- HOOK INSTALLATION
-- ============================================================================

-- Save original functions
local real_loadstring = loadstring
local real_load = load

-- Hook loadstring
loadstring = function(chunk, chunkname)
    chunkname = chunkname or "unnamed_chunk"
    
    if type(chunk) == "string" then
        -- Check size limit
        if #chunk > config.max_chunk_size then
            log("WARNING", "Chunk too large, truncating: " .. chunkname)
            chunk = chunk:sub(1, config.max_chunk_size) .. "\n-- [TRUNCATED]"
        end
        
        -- Analyze and dump
        local analysis = analyze_chunk(chunk, chunkname)
        write_dump(chunkname, chunk, analysis)
        
        table.insert(state.chunks_dumped, {
            name = chunkname,
            size = #chunk,
            time = os.time()
        })
    end
    
    return real_loadstring(chunk, chunkname)
end

-- Hook load (Lua 5.1 also has this)
if real_load then
    load = function(chunk, chunkname)
        if type(chunk) == "string" then
            chunkname = chunkname or "load_chunk"
            local analysis = analyze_chunk(chunk, chunkname)
            write_dump(chunkname, chunk, analysis)
        end
        return real_load(chunk, chunkname)
    end
end

-- Track getfenv if requested
if config.dump_getfenv_access then
    local real_getfenv = getfenv
    getfenv = function(level)
        log("TRACE", "getfenv accessed at level: " .. tostring(level))
        return real_getfenv(level)
    end
end

-- ============================================================================
-- ROBLOX ENVIRONMENT MOCKING
-- ============================================================================

-- Comprehensive game object mock
game = setmetatable({
    HttpGet = function(self, url)
        log("HTTP", "GET request: " .. tostring(url))
        state.urls_found[url] = true
        return ""  -- Return empty to prevent actual execution
    end,
    
    HttpPost = function(self, url, data)
        log("HTTP", "POST request: " .. tostring(url))
        state.urls_found[url] = true
        return ""
    end,
    
    GetService = function(self, service)
        log("TRACE", "GetService: " .. tostring(service))
        return game
    end
}, {
    __index = function(t, k)
        return setmetatable({}, {__index = function() return function() end end})
    end
})

workspace = game
script = {Parent = workspace, Name = "DumpScript"}
owner = {Name = "DumpOwner"}

-- Common executor functions
getgenv = function() return _G end
getrenv = function() return _G end
getrawmetatable = function(obj) return getmetatable(obj) end
setreadonly = function() end
isreadonly = function() return false end
identifyexecutor = function() return "TermuxDeobfuscator", "1.0" end
getexecutorname = function() return "TermuxDeobfuscator" end

-- Filesystem mocks (common in executor scripts)
readfile = function(path)
    log("FS", "readfile: " .. tostring(path))
    return ""
end

writefile = function(path, content)
    log("FS", "writefile: " .. tostring(path) .. " (" .. #content .. " bytes)")
end

isfile = function() return false end
isfolder = function() return false end
makefolder = function(path)
    log("FS", "makefolder: " .. tostring(path))
end

-- Drawing library mock
Drawing = {new = function() return {} end}

-- ============================================================================
-- MAIN EXECUTION
-- ============================================================================

ensure_dir(config.output_dir)

log("INFO", "Luau Deobfuscator initialized")
log("INFO", "Output directory: " .. config.output_dir)
log("INFO", "Max dumps: " .. config.max_dumps_per_run)

-- Execute target script
if arg and arg[1] then
    log("INFO", "Loading target: " .. arg[1])
    local success, err = pcall(dofile, arg[1])
    if not success then
        log("ERROR", "Execution failed: " .. tostring(err))
    end
else
    log("ERROR", "No target file specified")
    log("INFO", "Usage: lua5.1 core/dumper.lua <target.lua>")
end

-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================

local function print_summary()
    local elapsed = os.time() - state.start_time
    
    print("\n" .. string.rep("=", 60))
    print("DEOBFUSCATION SUMMARY")
    print(string.rep("=", 60))
    local url_count = 0
    for _ in pairs(state.urls_found) do url_count = url_count + 1 end
    
    print(string.format("Chunks dumped: %d", state.counter))
    print(string.format("URLs discovered: %d", url_count))
    print(string.format("VM detected: %s", state.vm_detected and "YES" or "NO"))
    print(string.format("Time elapsed: %ds", elapsed))
    print(string.rep("=", 60))
    
    if next(state.urls_found) then
        print("\nUnique URLs found:")
        for url in pairs(state.urls_found) do
            print("  - " .. url)
        end
    end
    
    print("\nOutput location: " .. config.output_dir .. "/")
    print("Use 'nano " .. config.output_dir .. "/dump_*.lua' to inspect dumps")
    print(string.rep("=", 60) .. "\n")
end

-- Register cleanup handler
local function cleanup()
    print_summary()
end

-- Try to catch exit (works differently in different Lua versions)
if os.exit then
    local old_exit = os.exit
    os.exit = function(...)
        cleanup()
        old_exit(...)
    end
end
