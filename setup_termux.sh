#!/data/data/com.termux/files/usr/bin/bash
#
# Luau Deobfuscator Pro - Termux Setup Script
# Automated installation for Android devices
#

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║                                                       ║"
    echo "║   Luau Deobfuscator Pro - Setup Script              ║"
    echo "║   Automated installation for Termux                  ║"
    echo "║                                                       ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}[+]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

check_termux() {
    if [ ! -d "/data/data/com.termux" ]; then
        print_error "Not running in Termux environment"
        exit 1
    fi
}

print_banner
check_termux

# Step 1: Update packages
print_step "Updating package lists..."
if pkg update -y > /dev/null 2>&1; then
    print_success "Package lists updated"
else
    print_warning "Package update had warnings (continuing anyway)"
fi

# Step 2: Upgrade existing packages
print_step "Upgrading installed packages..."
pkg upgrade -y > /dev/null 2>&1 || print_warning "Some packages couldn't upgrade"

# Step 3: Install dependencies
print_step "Installing dependencies..."

PACKAGES="lua5.1 python git nano"
for pkg_name in $PACKAGES; do
    if pkg list-installed 2>/dev/null | grep -q "^$pkg_name/"; then
        print_success "$pkg_name already installed"
    else
        print_step "Installing $pkg_name..."
        if pkg install -y "$pkg_name" > /dev/null 2>&1; then
            print_success "$pkg_name installed"
        else
            print_error "Failed to install $pkg_name"
            exit 1
        fi
    fi
done

# Step 4: Setup storage access
print_step "Setting up storage access..."
if [ ! -d "$HOME/storage" ]; then
    print_warning "Storage not configured. Running termux-setup-storage..."
    echo "Please ALLOW storage permissions when prompted!"
    sleep 2
    termux-setup-storage
    if [ -d "$HOME/storage" ]; then
        print_success "Storage access granted"
    else
        print_warning "Storage access not confirmed (you may need to run manually)"
    fi
else
    print_success "Storage already configured"
fi

# Step 5: Verify installations
print_step "Verifying installations..."

# Check Lua
if command -v lua5.1 &> /dev/null; then
    LUA_VERSION=$(lua5.1 -v 2>&1 | head -1)
    print_success "Lua verified: $LUA_VERSION"
elif command -v lua &> /dev/null; then
    LUA_VERSION=$(lua -v 2>&1 | head -1)
    print_success "Lua verified: $LUA_VERSION"
    print_warning "Note: Using 'lua' instead of 'lua5.1'"
else
    print_error "Lua installation failed"
    exit 1
fi

# Check Python
if command -v python &> /dev/null; then
    PYTHON_VERSION=$(python --version 2>&1)
    print_success "Python verified: $PYTHON_VERSION"
else
    print_error "Python installation failed"
    exit 1
fi

# Step 6: Create project directory structure
print_step "Creating project structure..."

PROJECT_DIR="$HOME/luau-deobf-pro"

if [ -d "$PROJECT_DIR" ]; then
    print_warning "Project directory exists. Backing up..."
    mv "$PROJECT_DIR" "${PROJECT_DIR}.backup.$(date +%s)"
fi

mkdir -p "$PROJECT_DIR"/{core,utils,output,test_scripts}
print_success "Directory structure created"

# Step 7: Check if we're in a git repository
print_step "Checking for project files..."

if [ -f "config.lua" ] && [ -f "deobfuscate.py" ]; then
    print_success "Project files found in current directory"
    print_step "Copying files to $PROJECT_DIR..."
    
    cp -r config.lua core/ utils/ deobfuscate.py "$PROJECT_DIR/" 2>/dev/null || true
    
    if [ -f "README.md" ]; then
        cp README.md "$PROJECT_DIR/"
    fi
    
    print_success "Files copied"
else
    print_warning "Project files not found in current directory"
    print_warning "You'll need to download the files manually or use git clone"
fi

# Step 8: Make scripts executable
cd "$PROJECT_DIR"
if [ -f "deobfuscate.py" ]; then
    chmod +x deobfuscate.py
    print_success "Scripts made executable"
fi

# Step 9: Create a test script
print_step "Creating test script..."
cat > "$PROJECT_DIR/test_scripts/simple_test.lua" << 'EOF'
-- Simple obfuscated test script
local code = string.char(112, 114, 105, 110, 116, 40, 34, 72, 101, 108, 108, 111, 34, 41)
loadstring(code)()

-- Second layer
local layer2 = "print('Layer 2 decoded')"
loadstring(layer2)()

-- URL test
local url = "https://example.com/test"
game:HttpGet(url)

print("Test script complete")
EOF
print_success "Test script created"

# Step 10: Run verification test
print_step "Running verification test..."

if python deobfuscate.py test_scripts/simple_test.lua > /dev/null 2>&1; then
    print_success "Verification test passed!"
    
    # Count dumps
    DUMP_COUNT=$(ls workspace/output/dump_*.lua 2>/dev/null | wc -l)
    if [ "$DUMP_COUNT" -gt 0 ]; then
        print_success "Created $DUMP_COUNT dump file(s)"
    fi
else
    print_warning "Verification test had issues (check logs)"
fi

# Final summary
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                       ║${NC}"
echo -e "${GREEN}║   Setup Complete!                                     ║${NC}"
echo -e "${GREEN}║                                                       ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Installation Directory:${NC} $PROJECT_DIR"
echo ""
echo -e "${BLUE}Quick Start:${NC}"
echo "  cd $PROJECT_DIR"
echo "  python deobfuscate.py <your_script.lua>"
echo ""
echo -e "${BLUE}Test with sample:${NC}"
echo "  python deobfuscate.py test_scripts/simple_test.lua"
echo ""
echo -e "${BLUE}Copy script from Downloads:${NC}"
echo "  cp ~/storage/downloads/script.lua ."
echo "  python deobfuscate.py script.lua"
echo ""
echo -e "${BLUE}View results:${NC}"
echo "  ls workspace/output/"
echo "  nano workspace/output/dump_0001_*.lua"
echo ""
echo -e "${BLUE}Read documentation:${NC}"
echo "  nano README.md"
echo ""
echo -e "${YELLOW}Note:${NC} If you encounter issues, check README.md troubleshooting section"
echo ""
