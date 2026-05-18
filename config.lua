-- config.lua - Configuration for Luau Deobfuscator
return {
    -- Output settings
    output_dir = "output",
    max_filename_length = 50,
    include_timestamps = true,
    
    -- Dumping behavior
    dump_all_loadstring = true,
    dump_getfenv_access = true,
    track_http_requests = true,
    decode_string_char = true,
    
    -- Analysis features
    detect_vm_patterns = true,
    extract_constants = true,
    find_suspicious_patterns = true,
    
    -- Roblox environment mocking
    mock_game_methods = true,
    mock_executor_functions = true,
    
    -- Safety limits (prevent memory issues on Android)
    max_chunk_size = 5 * 1024 * 1024,  -- 5MB
    max_dumps_per_run = 500,
    
    -- Verbosity
    verbose = true,
    show_stack_traces = false
}
