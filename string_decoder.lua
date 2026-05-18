-- utils/string_decoder.lua - Advanced string deobfuscation utilities

local M = {}

-- Decode string.char(104, 116, 116, 112, ...) patterns
function M.decode_char_sequence(code)
    local decoded_strings = {}
    
    -- Pattern 1: string.char(num, num, num, ...)
    for match in code:gmatch("string%.char%s*%(([%d,%s]+)%)") do
        local chars = {}
        for num in match:gmatch("%d+") do
            table.insert(chars, string.char(tonumber(num)))
        end
        if #chars > 0 then
            table.insert(decoded_strings, table.concat(chars))
        end
    end
    
    -- Pattern 2: ("\104\116\116\112...") escape sequences
    for match in code:gmatch('"([\\%d]+)"') do
        local chars = {}
        for num in match:gmatch("\\(%d+)") do
            table.insert(chars, string.char(tonumber(num)))
        end
        if #chars > 0 then
            table.insert(decoded_strings, table.concat(chars))
        end
    end
    
    -- Pattern 3: table-based char arrays {104, 116, 116, 112}
    for match in code:gmatch("{([%d,%s]+)}") do
        local chars = {}
        for num in match:gmatch("%d+") do
            table.insert(chars, string.char(tonumber(num)))
        end
        if #chars > 3 then  -- Only report meaningful sequences
            table.insert(decoded_strings, table.concat(chars))
        end
    end
    
    return decoded_strings
end

-- Extract all URLs from code
function M.extract_urls(code)
    local urls = {}
    local patterns = {
        "https?://[%w%-%._~:/?#%[%]@!$&'()*+,;=%%]+",
        'https?://[^"\'%s]+',
        "%%68%%74%%74%%70[^%s]*"  -- URL-encoded http
    }
    
    for _, pattern in ipairs(patterns) do
        for url in code:gmatch(pattern) do
            -- Decode URL encoding if present
            url = url:gsub("%%(%x%x)", function(hex)
                return string.char(tonumber(hex, 16))
            end)
            urls[url] = true
        end
    end
    
    return urls
end

-- Find base64 strings (common in obfuscated scripts)
function M.find_base64(code)
    local b64_strings = {}
    -- Look for long alphanumeric strings with +/= (base64 alphabet)
    for match in code:gmatch("[A-Za-z0-9+/]+={0,2}") do
        if #match >= 20 and #match % 4 == 0 then
            table.insert(b64_strings, match)
        end
    end
    return b64_strings
end

-- Detect common VM/interpreter patterns
function M.detect_vm_patterns(code)
    local patterns = {
        bytecode_vm = code:match("opcode") or code:match("OPCODE"),
        stack_based = code:match("stack%s*%[") or code:match("Stack"),
        instruction_decode = code:match("decode") or code:match("DECODE"),
        constants_table = code:match("constants%s*=") or code:match("CONSTANTS"),
        wrapped_functions = code:match("wrap") or code:match("WRAP")
    }
    return patterns
end

-- Extract numeric constants (potential encryption keys, magic numbers)
function M.extract_constants(code)
    local constants = {}
    -- Look for large numeric literals
    for num in code:gmatch("0x%x+") do
        if #num > 4 then table.insert(constants, num) end
    end
    for num in code:gmatch("%d%d%d%d%d+") do
        table.insert(constants, num)
    end
    return constants
end

return M
