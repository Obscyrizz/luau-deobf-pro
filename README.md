# Luau Deobfuscator Pro - Termux Edition

**Professional-grade Lua/Luau deobfuscation toolkit optimized for Android via Termux**

A comprehensive multi-layer script analysis tool for reverse-engineering obfuscated Lua scripts, particularly those from Roblox executors and game scripts.

---

## 🚀 Features

### Core Capabilities
- ✅ **Multi-layer loadstring hooking** - Captures all dynamically loaded code
- ✅ **Automatic string deobfuscation** - Decodes `string.char()`, escape sequences, and table-based encoding
- ✅ **URL extraction** - Finds all HTTP/HTTPS endpoints including URL-encoded variants
- ✅ **VM detection** - Identifies bytecode interpreters and stack-based VMs
- ✅ **Base64 detection** - Locates potential encoded payloads
- ✅ **Constant extraction** - Finds encryption keys and magic numbers
- ✅ **Comprehensive Roblox mocking** - Prevents actual execution while capturing behavior
- ✅ **Memory-safe** - Configurable limits prevent crashes on low-RAM devices

### Android/Termux Optimizations
- ⚡ Lightweight dependencies (only Lua 5.1 + Python 3)
- ⚡ Efficient memory usage with size limits
- ⚡ Works entirely offline
- ⚡ Storage integration for easy file access

---

## 📋 Prerequisites

**Required:**
- Termux app (get from **F-Droid**, NOT Play Store)
- ~50MB free storage
- Android 7.0+ recommended

**Optional:**
- Termux:API for enhanced features
- Text editor (nano included in setup)

---

## 🛠️ Installation

### Option 1: Automated Setup (Recommended)

```bash
# Download and run setup script
curl -O https://raw.githubusercontent.com/yourusername/luau-deobf-pro/main/setup_termux.sh
bash setup_termux.sh
```

### Option 2: Manual Installation

#### Step 1: Update Termux and Install Dependencies

```bash
# Update package lists
pkg update -y && pkg upgrade -y

# Install required packages
pkg install lua5.1 python git nano -y

# Enable storage access (required for Downloads folder)
termux-setup-storage
```

**Note:** When prompted, grant Termux storage permissions.

#### Step 2: Clone or Download the Tool

**Option A: Using Git**
```bash
cd ~
git clone https://github.com/yourusername/luau-deobf-pro.git
cd luau-deobf-pro
```

**Option B: Manual Download**
```bash
cd ~
mkdir luau-deobf-pro
cd luau-deobf-pro

# Download files individually (if you have them locally)
# Or use the manual file creation method below
```

#### Step 3: Make Scripts Executable

```bash
chmod +x deobfuscate.py
chmod +x setup_termux.sh  # if using setup script
```

#### Step 4: Verify Installation

```bash
python deobfuscate.py --help
```

You should see the tool banner and usage instructions.

---

## 📖 Usage

### Basic Usage

```bash
# Deobfuscate a script
python deobfuscate.py script.lua

# From Downloads folder
python deobfuscate.py ~/storage/downloads/obfuscated.lua

# From current directory
python deobfuscate.py ./suspicious_script.luau
```

### What Happens

1. **Workspace Setup** - Creates isolated analysis environment
2. **Environment Mocking** - Sets up fake Roblox/executor APIs
3. **Hook Installation** - Intercepts all `loadstring()` calls
4. **Execution** - Runs the script safely
5. **Analysis** - Decodes strings, extracts URLs, detects patterns
6. **Output Generation** - Creates numbered dump files + report

### Output Structure

```
workspace/
├── output/
│   ├── dump_0001_main_chunk.lua      # First decoded layer
│   ├── dump_0002_http_loader.lua     # Second layer
│   ├── dump_0003_payload.lua         # Final payload
│   └── ...
├── ANALYSIS_REPORT.txt               # Full analysis summary
└── config.lua                        # Configuration used
```

### Reading Output Files

Each dump file includes:
- **Header**: Metadata (timestamp, size, URLs found)
- **Decoded strings**: Automatically deobfuscated content
- **VM patterns**: Detected obfuscation techniques
- **Source code**: The actual decoded script

```bash
# View first dump
nano workspace/output/dump_0001_*.lua

# List all dumps by size
ls -lhS workspace/output/

# Search for specific strings across all dumps
grep -r "loadstring" workspace/output/

# Count total dumps
ls workspace/output/dump_*.lua | wc -l
```

---

## ⚙️ Configuration

Edit `config.lua` to customize behavior:

```lua
-- config.lua
return {
    -- Output settings
    output_dir = "output",              -- Where dumps are saved
    max_filename_length = 50,           -- Truncate long names
    include_timestamps = true,          -- Add timestamps to logs
    
    -- Dumping behavior
    dump_all_loadstring = true,         -- Capture every loadstring call
    decode_string_char = true,          -- Auto-decode string.char()
    track_http_requests = true,         -- Log all HTTP attempts
    
    -- Safety limits (Android optimization)
    max_chunk_size = 5 * 1024 * 1024,  -- 5MB per chunk
    max_dumps_per_run = 500,            -- Stop after 500 dumps
    
    -- Verbosity
    verbose = true,                     -- Detailed logging
    show_stack_traces = false           -- Debug mode
}
```

**Memory-constrained device?** Reduce limits:
```lua
max_chunk_size = 1 * 1024 * 1024,  -- 1MB
max_dumps_per_run = 100,            -- 100 dumps
```

---

## 🎯 Advanced Features

### 1. String Deobfuscation

Automatically decodes:

```lua
-- Pattern 1: string.char
string.char(104, 116, 116, 112, 115)  → "https"

-- Pattern 2: Escape sequences  
"\104\116\116\112\115"                → "https"

-- Pattern 3: Table-based
{104, 116, 116, 112, 115}            → "https"
```

### 2. VM Detection

Identifies:
- Bytecode interpreters
- Stack-based VMs
- Instruction decoders
- Constants tables
- Function wrappers

### 3. URL Discovery

Finds:
- Standard URLs: `http://example.com`
- URL-encoded: `%68%74%74%70`
- Hidden in strings: `string.char(104,116,116,112)..".com"`

### 4. Multi-layer Analysis

```
Layer 1: Outer obfuscator
   ↓
Layer 2: String decoder
   ↓
Layer 3: HTTP loader
   ↓
Layer 4: Final payload
```

Each layer is dumped separately with analysis.

---

## 🔍 Example Scenarios

### Scenario 1: Simple Obfuscated Script

```bash
$ python deobfuscate.py simple_script.lua

Analysis Complete
Status: SUCCESS
Time: 1.23s
Dumps: 3

[✓] Output location: workspace/output/
    View dumps: ls -lh workspace/output/
    Read first: nano workspace/output/dump_0001_main.lua
```

### Scenario 2: Multi-Stage Loader

```bash
$ python deobfuscate.py loader.lua

Analysis Complete
Status: SUCCESS
Time: 4.56s
Dumps: 12

[!] Found 3 unique URL(s):
    https://pastebin.com/raw/abc123
    https://raw.githubusercontent.com/user/repo/script.lua
    https://api.example.com/v1/payload
```

### Scenario 3: VM-Protected Script

```bash
$ python deobfuscate.py protected.lua

Analysis Complete
Status: SUCCESS
Time: 8.91s
Dumps: 45

VM Patterns detected:
  - bytecode_vm
  - stack_based
  - instruction_decode
  - constants_table
```

---

## 🐛 Troubleshooting

### Issue: "Lua not found"

**Solution:**
```bash
# Try lua instead of lua5.1
pkg install lua -y

# Verify installation
lua -v
```

### Issue: "File not found" for target

**Solution:**
```bash
# Check file exists
ls -la ~/storage/downloads/

# Use absolute path
python deobfuscate.py ~/storage/downloads/script.lua

# Or copy to working directory
cp ~/storage/downloads/script.lua .
python deobfuscate.py script.lua
```

### Issue: Out of memory / Termux crashes

**Solution:**
```bash
# Edit config.lua and reduce limits
nano config.lua

# Change to:
max_chunk_size = 1 * 1024 * 1024,  -- 1MB instead of 5MB
max_dumps_per_run = 50,             -- 50 instead of 500

# Close other apps before running
```

### Issue: "Module not found" errors

**Solution:**
```bash
# Ensure correct directory structure
cd ~/luau-deobf-pro
ls -la

# Should see:
# config.lua
# deobfuscate.py
# core/
# utils/

# Re-run from project root
python deobfuscate.py target.lua
```

### Issue: No dumps created but script ran

**Possible causes:**
1. Script doesn't use `loadstring()` - some scripts are just plain Lua
2. Script detected analysis environment - try modifying Roblox mocks
3. Syntax error in target - check stderr output

**Solutions:**
```bash
# Check if it's even obfuscated
file target.lua
head -20 target.lua

# Look for stderr output
cat workspace/ANALYSIS_REPORT.txt

# Try verbose mode
nano config.lua  # Set verbose = true
```

### Issue: Permission denied

**Solution:**
```bash
# Make scripts executable
chmod +x deobfuscate.py

# Fix workspace permissions
chmod -R 755 workspace/

# If storage issues
termux-setup-storage
```

---

## 🛡️ Safety & Ethics

### This Tool is For:
✅ Security research on scripts you own/have permission to analyze  
✅ Educational purposes to learn obfuscation techniques  
✅ Malware analysis in controlled environments  
✅ Recovering your own obfuscated code  

### This Tool is NOT For:
❌ Analyzing scripts without permission  
❌ Bypassing copy protection on software you don't own  
❌ Creating malware or exploits  
❌ Violating terms of service  

### Safety Features:
- **No actual HTTP requests** - All network calls are intercepted and logged only
- **Filesystem mocks** - No real file operations occur
- **Sandboxed execution** - Scripts run in isolated Lua environment
- **Size limits** - Prevents memory exhaustion

**⚠️ Warning:** Always analyze untrusted scripts in a secure environment. While this tool prevents most malicious actions, it cannot guarantee 100% safety.

---

## 📚 Understanding Output

### Dump File Headers

```lua
--[[
  Captured from: main_chunk
  Timestamp: 2025-05-18 14:30:45
  Size: 15823 bytes (342 lines)

  Decoded strings found:
    - https://pastebin.com/raw/abc123
    - game:HttpGet
    - loadstring

  URLs found:
    - https://pastebin.com/raw/abc123

  VM Patterns detected:
    - bytecode_vm
--]]
```

### Analysis Report Structure

```
═══════════════════════════════════════════════
LUAU DEOBFUSCATION ANALYSIS REPORT
═══════════════════════════════════════════════

Target File: obfuscated.lua
File Size: 45,231 bytes
Analysis Time: 3.21 seconds
Status: SUCCESS

Dumps Created: 8
URLs Found: 2

Discovered URLs:
  - https://pastebin.com/raw/abc123
  - https://example.com/payload.txt

═══════════════════════════════════════════════
FULL OUTPUT LOG
═══════════════════════════════════════════════
[INFO] Luau Deobfuscator initialized
[DUMP] #1 -> dump_0001_main.lua (12843 bytes)
...
```

---

## 🔄 Workflow Examples

### Standard Analysis Workflow

```bash
# 1. Copy script to analyze
cp ~/storage/downloads/script.lua ~/luau-deobf-pro/

# 2. Run deobfuscation
cd ~/luau-deobf-pro
python deobfuscate.py script.lua

# 3. Review analysis report
cat workspace/ANALYSIS_REPORT.txt

# 4. Examine dumps
ls workspace/output/
nano workspace/output/dump_0001_*.lua

# 5. Search for specific patterns
grep -r "http" workspace/output/
grep -r "loadstring" workspace/output/

# 6. Clean up for next run
rm -rf workspace/
```

### Batch Processing Multiple Scripts

```bash
# Process all scripts in a folder
for script in ~/storage/downloads/*.lua; do
    echo "Processing: $script"
    python deobfuscate.py "$script"
    mv workspace/output "results_$(basename $script .lua)"
    rm -rf workspace/
done
```

### Finding Malicious Indicators

```bash
# After running deobfuscation:

# Find all URLs
grep -rh "https\?://" workspace/output/ | sort | uniq

# Find executor-specific calls
grep -r "getgenv\|getrenv\|getrawmetatable" workspace/output/

# Find filesystem access attempts
grep -r "readfile\|writefile\|makefolder" workspace/output/

# Find suspicious function names
grep -r "bypass\|exploit\|hack\|steal\|admin" workspace/output/
```

---

## 🎓 Tips & Best Practices

### Performance Tips

1. **Close other apps** before analyzing large scripts
2. **Use smaller size limits** in config.lua for stability
3. **Process one script at a time** on low-RAM devices
4. **Keep Termux updated**: `pkg upgrade`

### Analysis Tips

1. **Start with dump_0001** - usually the most readable
2. **Look for URLs first** - often reveal payload sources
3. **Check for VM patterns** - indicates multiple layers
4. **Compare consecutive dumps** - shows deobfuscation progress
5. **Search for strings like "loadstring"** - finds recursive loaders

### Organizing Results

```bash
# Create organized output structure
mkdir -p ~/analysis/{malicious,benign,unknown}

# Move analyzed results
mv workspace/output ~/analysis/malicious/script_20250518/

# Keep notes
echo "Found keylogger payload" > ~/analysis/malicious/script_20250518/NOTES.txt
```

---

## 🆘 Getting Help

### Quick Reference

```bash
# Show help
python deobfuscate.py --help

# Check Lua version
lua5.1 -v

# Verify project structure
ls -R ~/luau-deobf-pro

# View recent errors
cat workspace/ANALYSIS_REPORT.txt | grep ERROR

# Test with minimal script
echo 'print("test")' > test.lua
python deobfuscate.py test.lua
```

### Common Commands

```bash
# Install missing packages
pkg install lua5.1 python git -y

# Fix permissions
chmod +x deobfuscate.py
chmod -R 755 workspace/

# Clean workspace
rm -rf workspace/

# Update tool (if using git)
git pull origin main
```

---

## 📝 Technical Details

### Architecture

```
deobfuscate.py (Orchestrator)
    ↓
core/dumper.lua (Hook Engine)
    ↓
utils/string_decoder.lua (Pattern Analysis)
    ↓
config.lua (User Settings)
    ↓
workspace/output/ (Results)
```

### How It Works

1. **Hook Installation**: Replaces global `loadstring()` and `load()`
2. **Environment Mocking**: Creates fake Roblox/executor APIs
3. **Execution**: Runs target script in controlled environment
4. **Interception**: Captures all dynamically loaded code
5. **Analysis**: Decodes strings, extracts metadata
6. **Output**: Saves each layer as separate file

### Supported Obfuscation Types

- ✅ String concatenation
- ✅ Character code encoding (`string.char`)
- ✅ Escape sequences (`\104\116...`)
- ✅ Table-based encoding
- ✅ Base64 encoding
- ✅ Multi-stage loaders
- ✅ VM-based protection (partial)
- ✅ Metamethod abuse
- ✅ Environment manipulation

### Limitations

- ❌ Cannot fully reverse bytecode VMs (captures output only)
- ❌ Some control flow obfuscation remains intact
- ❌ Heavily-metamethod-based protection may need manual analysis
- ❌ Very large scripts (>50MB) may crash on low-RAM devices

---

## 🤝 Contributing

Found a bug or want to add features? Contributions welcome!

```bash
# Fork the repo and clone
git clone https://github.com/yourusername/luau-deobf-pro.git

# Create feature branch
git checkout -b feature/amazing-feature

# Make changes and test
python deobfuscate.py test_scripts/sample.lua

# Commit and push
git commit -m "Add amazing feature"
git push origin feature/amazing-feature

# Open pull request
```

---

## 📄 License

MIT License - see LICENSE file for details

---

## 🙏 Credits

- Lua 5.1 Community
- Termux Project
- Roblox Security Researchers
- Open Source Contributors

---

## 📞 Support

**Issues:** https://github.com/yourusername/luau-deobf-pro/issues  
**Discussions:** https://github.com/yourusername/luau-deobf-pro/discussions  

---

**Made with ❤️ for Android reverse engineers**

*Last updated: 2025-05-18*
