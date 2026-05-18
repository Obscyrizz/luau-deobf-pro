#!/usr/bin/env python3
"""
Luau Deobfuscator - Main orchestrator
Professional-grade Lua/Luau deobfuscation toolkit for Termux
"""

import subprocess
import sys
import pathlib
import shutil
import json
import time
from typing import Dict, List, Optional

# ANSI color codes for terminal output
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'

def print_banner():
    """Display tool banner"""
    banner = f"""
{Colors.CYAN}╔═══════════════════════════════════════════════════════╗
║                                                       ║
║   Luau Deobfuscator Pro - Termux Edition            ║
║   Multi-layer script analysis & dumping              ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝{Colors.END}
"""
    print(banner)

def check_dependencies() -> Dict[str, bool]:
    """Check if required tools are available"""
    deps = {}
    
    # Check for lua5.1 or lua
    lua_variants = ['lua5.1', 'lua']
    lua_found = None
    for variant in lua_variants:
        try:
            result = subprocess.run([variant, '-v'], capture_output=True, timeout=2)
            if result.returncode == 0:
                lua_found = variant
                break
        except (FileNotFoundError, subprocess.TimeoutExpired):
            continue
    
    deps['lua'] = lua_found
    deps['python'] = sys.version_info >= (3, 6)
    
    return deps

def validate_target(target_path: pathlib.Path) -> tuple[bool, Optional[str]]:
    """Validate the target file"""
    if not target_path.exists():
        return False, f"File not found: {target_path}"
    
    if not target_path.is_file():
        return False, f"Not a file: {target_path}"
    
    if target_path.suffix.lower() not in ['.lua', '.luau', '.txt']:
        return False, f"Unexpected file type: {target_path.suffix} (expected .lua/.luau/.txt)"
    
    # Check file size (warn if very large)
    size_mb = target_path.stat().st_size / (1024 * 1024)
    if size_mb > 50:
        return False, f"File too large ({size_mb:.1f}MB). Maximum recommended: 50MB on Termux"
    
    return True, None

def setup_workspace(target: pathlib.Path, work_dir: pathlib.Path) -> bool:
    """Prepare workspace for analysis"""
    try:
        # Create fresh workspace
        if work_dir.exists():
            shutil.rmtree(work_dir)
        work_dir.mkdir(parents=True)
        
        # Copy required files
        script_dir = pathlib.Path(__file__).parent
        
        files_to_copy = [
            'config.lua',
            'core/dumper.lua',
            'utils/string_decoder.lua'
        ]
        
        for file_rel in files_to_copy:
            src = script_dir / file_rel
            dst = work_dir / file_rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            
            if src.exists():
                shutil.copy2(src, dst)
            else:
                print(f"{Colors.YELLOW}[WARNING]{Colors.END} Missing file: {src}")
        
        # Copy target file
        target_copy = work_dir / target.name
        shutil.copy2(target, target_copy)
        
        # Create output directory
        (work_dir / 'output').mkdir(exist_ok=True)
        
        return True
        
    except Exception as e:
        print(f"{Colors.RED}[ERROR]{Colors.END} Workspace setup failed: {e}")
        return False

def run_deobfuscation(target_name: str, work_dir: pathlib.Path, lua_cmd: str) -> Dict:
    """Execute the deobfuscation process"""
    results = {
        'success': False,
        'dumps_created': 0,
        'urls_found': [],
        'execution_time': 0,
        'stdout': '',
        'stderr': ''
    }
    
    start_time = time.time()
    
    try:
        cmd = [lua_cmd, 'core/dumper.lua', target_name]
        
        print(f"\n{Colors.BLUE}[+]{Colors.END} Running analysis...")
        print(f"    Command: {' '.join(cmd)}")
        print(f"    Working directory: {work_dir}")
        print(f"\n{Colors.CYAN}{'─' * 60}{Colors.END}")
        
        proc = subprocess.run(
            cmd,
            cwd=work_dir,
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout
        )
        
        results['stdout'] = proc.stdout
        results['stderr'] = proc.stderr
        results['execution_time'] = time.time() - start_time
        
        # Print live output
        if proc.stdout:
            print(proc.stdout)
        if proc.stderr:
            print(f"{Colors.YELLOW}[STDERR]{Colors.END}")
            print(proc.stderr)
        
        print(f"{Colors.CYAN}{'─' * 60}{Colors.END}\n")
        
        # Count dumps created
        output_dir = work_dir / 'output'
        if output_dir.exists():
            dumps = list(output_dir.glob('dump_*.lua'))
            results['dumps_created'] = len(dumps)
        
        # Extract URLs from output
        for line in proc.stdout.split('\n'):
            if '[HTTP]' in line or 'http://' in line or 'https://' in line:
                # Simple URL extraction
                for word in line.split():
                    if word.startswith('http://') or word.startswith('https://'):
                        results['urls_found'].append(word.strip('()[]'))
        
        results['success'] = proc.returncode == 0 or results['dumps_created'] > 0
        
    except subprocess.TimeoutExpired:
        print(f"{Colors.RED}[ERROR]{Colors.END} Process timed out after 5 minutes")
        results['stderr'] = "Process timeout"
    except Exception as e:
        print(f"{Colors.RED}[ERROR]{Colors.END} Execution failed: {e}")
        results['stderr'] = str(e)
    
    return results

def generate_report(results: Dict, work_dir: pathlib.Path, target: pathlib.Path):
    """Generate analysis report"""
    report_path = work_dir / 'ANALYSIS_REPORT.txt'
    
    with open(report_path, 'w') as f:
        f.write("=" * 70 + "\n")
        f.write("LUAU DEOBFUSCATION ANALYSIS REPORT\n")
        f.write("=" * 70 + "\n\n")
        
        f.write(f"Target File: {target.name}\n")
        f.write(f"File Size: {target.stat().st_size:,} bytes\n")
        f.write(f"Analysis Time: {results['execution_time']:.2f} seconds\n")
        f.write(f"Status: {'SUCCESS' if results['success'] else 'FAILED'}\n\n")
        
        f.write(f"Dumps Created: {results['dumps_created']}\n")
        f.write(f"URLs Found: {len(results['urls_found'])}\n\n")
        
        if results['urls_found']:
            f.write("Discovered URLs:\n")
            for url in set(results['urls_found']):
                f.write(f"  - {url}\n")
            f.write("\n")
        
        f.write("=" * 70 + "\n")
        f.write("FULL OUTPUT LOG\n")
        f.write("=" * 70 + "\n\n")
        f.write(results['stdout'])
        
        if results['stderr']:
            f.write("\n" + "=" * 70 + "\n")
            f.write("STDERR OUTPUT\n")
            f.write("=" * 70 + "\n\n")
            f.write(results['stderr'])
    
    print(f"{Colors.GREEN}[✓]{Colors.END} Report saved: {report_path}")

def print_summary(results: Dict, work_dir: pathlib.Path):
    """Print execution summary"""
    status_color = Colors.GREEN if results['success'] else Colors.RED
    status_text = "SUCCESS" if results['success'] else "FAILED"
    
    print(f"\n{Colors.BOLD}Analysis Complete{Colors.END}")
    print(f"Status: {status_color}{status_text}{Colors.END}")
    print(f"Time: {results['execution_time']:.2f}s")
    print(f"Dumps: {results['dumps_created']}")
    
    if results['urls_found']:
        print(f"\n{Colors.YELLOW}[!]{Colors.END} Found {len(set(results['urls_found']))} unique URL(s):")
        for url in sorted(set(results['urls_found']))[:10]:  # Show first 10
            print(f"    {url}")
        if len(set(results['urls_found'])) > 10:
            print(f"    ... and {len(set(results['urls_found'])) - 10} more")
    
    if results['dumps_created'] > 0:
        output_dir = work_dir / 'output'
        print(f"\n{Colors.GREEN}[✓]{Colors.END} Output location: {output_dir}/")
        print(f"    View dumps: ls -lh {output_dir}/")
        print(f"    Read first: nano {output_dir}/dump_0001_*.lua")

def main():
    """Main entry point"""
    print_banner()
    
    # Check command line arguments
    if len(sys.argv) < 2:
        print(f"{Colors.RED}[ERROR]{Colors.END} No target file specified\n")
        print(f"Usage: python {sys.argv[0]} <obfuscated.lua>")
        print(f"\nExample:")
        print(f"  python {sys.argv[0]} ~/storage/downloads/script.lua")
        print(f"  python {sys.argv[0]} malicious.luau")
        sys.exit(1)
    
    # Check dependencies
    print(f"{Colors.BLUE}[+]{Colors.END} Checking dependencies...")
    deps = check_dependencies()
    
    if not deps['lua']:
        print(f"{Colors.RED}[ERROR]{Colors.END} Lua not found. Install with: pkg install lua5.1")
        sys.exit(1)
    
    print(f"{Colors.GREEN}[✓]{Colors.END} Lua found: {deps['lua']}")
    
    # Validate target file
    target_path = pathlib.Path(sys.argv[1]).resolve()
    print(f"\n{Colors.BLUE}[+]{Colors.END} Validating target: {target_path.name}")
    
    valid, error = validate_target(target_path)
    if not valid:
        print(f"{Colors.RED}[ERROR]{Colors.END} {error}")
        sys.exit(1)
    
    file_size = target_path.stat().st_size
    print(f"{Colors.GREEN}[✓]{Colors.END} Valid target ({file_size:,} bytes)")
    
    # Setup workspace
    script_dir = pathlib.Path(__file__).parent
    work_dir = script_dir / 'workspace'
    
    print(f"\n{Colors.BLUE}[+]{Colors.END} Setting up workspace...")
    if not setup_workspace(target_path, work_dir):
        sys.exit(1)
    
    print(f"{Colors.GREEN}[✓]{Colors.END} Workspace ready")
    
    # Run deobfuscation
    results = run_deobfuscation(target_path.name, work_dir, deps['lua'])
    
    # Generate report
    generate_report(results, work_dir, target_path)
    
    # Print summary
    print_summary(results, work_dir)
    
    # Exit with appropriate code
    sys.exit(0 if results['success'] else 1)

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n\n{Colors.YELLOW}[!]{Colors.END} Interrupted by user")
        sys.exit(130)
    except Exception as e:
        print(f"\n{Colors.RED}[FATAL]{Colors.END} Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
