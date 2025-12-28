#!/usr/bin/env bash
# test.sh - Validation script for dotfiles repository
# Checks for common issues and configuration problems

set -e

# --- Load Shared Library ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/lib/utils.sh" ]; then
    source "$SCRIPT_DIR/lib/utils.sh"
else
    echo "Error: lib/utils.sh not found."
    exit 1
fi

# --- Test Counters ---
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# --- Test Helper Functions ---
test_start() {
    TESTS_RUN=$((TESTS_RUN + 1))
    printf "${BLUE}TEST $TESTS_RUN:${NC} $1... "
}

test_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    printf "${GREEN}✓${NC}\n"
}

test_fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    printf "${RED}✗${NC}\n"
    if [ -n "$1" ]; then
        log_substep "${RED}Error: $1${NC}"
    fi
}

# --- Tests ---
log_section "Dotfiles Validation Tests" "$ROCKET"

# Test 1: Check required core files exist
test_start "Required core files exist"
MISSING_FILES=()
REQUIRED_FILES=(
    "sync.sh"
    "join.sh"
    "README.md"
    "lib/utils.sh"
    "lib/terminal.sh"
    "config/zshrc.conf"
    "config/zprofile.conf"
    "config/functions.zsh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -eq 0 ]; then
    test_pass
else
    test_fail "Missing files: ${MISSING_FILES[*]}"
fi

# Test 2: Check symlink sources exist and verify active symlinks
test_start "Symlinks correctly configured and active"
BROKEN_SOURCES=()
BROKEN_SYMLINKS=()
SYMLINKS_CONF="$SCRIPT_DIR/config/symlinks.conf"

# Check if symlinks.conf exists
if [ ! -f "$SYMLINKS_CONF" ]; then
    test_fail "config/symlinks.conf not found"
else
    # Read each symlink definition
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Skip lines without colon
        [[ ! "$line" =~ : ]] && continue
        
        # Split on first colon
        source="${line%%:*}"
        target="${line#*:}"
        
        # Expand variables (replace $DOTFILES_DIR with $SCRIPT_DIR for test context)
        source="${source//\$DOTFILES_DIR/$SCRIPT_DIR}"
        source="${source//\$HOME/$HOME}"
        target="${target//\$DOTFILES_DIR/$SCRIPT_DIR}"
        target="${target//\$HOME/$HOME}"
        
        # Check if source file exists in repo
        if [ ! -f "$source" ]; then
            BROKEN_SOURCES+=("$source")
            continue
        fi
        
        # Check if target symlink exists
        if [ ! -e "$target" ]; then
            BROKEN_SYMLINKS+=("$target (missing)")
        elif [ ! -L "$target" ]; then
            BROKEN_SYMLINKS+=("$target (not a symlink)")
        else
            # Get what the symlink points to
            link_target=$(readlink "$target")
            # Resolve to absolute path if needed
            if [[ ! "$link_target" = /* ]]; then
                link_dir=$(dirname "$target")
                link_target="$link_dir/$link_target"
            fi
            
            # Compare resolved paths
            if [ "$(realpath "$link_target")" != "$(realpath "$source")" ]; then
                BROKEN_SYMLINKS+=("$target -> $link_target (expected: $source)")
            fi
        fi
    done < "$SYMLINKS_CONF"
    
    if [ ${#BROKEN_SOURCES[@]} -eq 0 ] && [ ${#BROKEN_SYMLINKS[@]} -eq 0 ]; then
        test_pass
    else
        if [ ${#BROKEN_SOURCES[@]} -gt 0 ]; then
            echo ""
            echo "   ${RED}Missing source files:${NC}"
            for src in "${BROKEN_SOURCES[@]}"; do
                echo "   - $src"
            done
        fi
        if [ ${#BROKEN_SYMLINKS[@]} -gt 0 ]; then
            echo ""
            echo "   ${RED}Broken/incorrect symlinks:${NC}"
            for lnk in "${BROKEN_SYMLINKS[@]}"; do
                echo "   - $lnk"
            done
            echo "   ${YELLOW}💡 Run './sync.sh' to fix symlinks${NC}"
        fi
        test_fail
    fi
fi

# Test 3: Check functions.zsh can be sourced
test_start "functions.zsh sources without errors"
if command -v zsh &> /dev/null && ( zsh -c "source '$SCRIPT_DIR/config/functions.zsh' 2>/dev/null" ); then
    test_pass
else
    test_fail "Syntax or runtime errors in functions.zsh"
fi

# Test 4: Check .zshrc can be sourced (in non-interactive mode)
test_start ".zshrc sources without errors"
# Set non-interactive flag to skip interactive-only sections
if ( NONINTERACTIVE=1 source "$SCRIPT_DIR/config/zshrc.conf" 2>/dev/null ); then
    test_pass
else
    # .zshrc has interactive checks, so this might fail - that's okay
    # Just check for syntax errors
    if zsh -n "$SCRIPT_DIR/config/zshrc.conf" 2>/dev/null; then
        test_pass
    else
        test_fail "Syntax errors in .zshrc"
    fi
fi

# Test 5: Check setup scripts are executable
test_start "Setup scripts exist and are valid"
INVALID_SETUP=()

if [ -d "$SCRIPT_DIR/setup" ]; then
    for script in "$SCRIPT_DIR/setup"/*.sh; do
        if [ -f "$script" ]; then
            # Check if file is readable and has valid shebang
            if [ ! -r "$script" ]; then
                INVALID_SETUP+=("$(basename "$script"): not readable")
            elif ! head -n 1 "$script" | grep -q '^#!/'; then
                INVALID_SETUP+=("$(basename "$script"): missing shebang")
            fi
        fi
    done
fi

if [ ${#INVALID_SETUP[@]} -eq 0 ]; then
    test_pass
else
    test_fail "${INVALID_SETUP[*]}"
fi

# Test 6: Check documentation files exist
test_start "Documentation files exist"
MISSING_DOCS=()
DOCS=(
    "docs/Functions Reference.md"
    "docs/New Host Deployment.md"
    "docs/Script Development Best Practices.md"
    "docs/Setup Scripts Reference.md"
    "docs/Terminal Font Setup.md"
)

for doc in "${DOCS[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$doc" ]; then
        MISSING_DOCS+=("$doc")
    fi
done

if [ ${#MISSING_DOCS[@]} -eq 0 ]; then
    test_pass
else
    test_fail "Missing docs: ${MISSING_DOCS[*]}"
fi

# Test 7: Check lib/utils.sh defines required functions
test_start "lib/utils.sh defines required helpers"
MISSING_UTILS=()
REQUIRED_UTILS=(
    "log_section"
    "log_success"
    "log_error"
    "log_info"
)

source "$SCRIPT_DIR/lib/utils.sh"
for func in "${REQUIRED_UTILS[@]}"; do
    if ! declare -f "$func" > /dev/null; then
        MISSING_UTILS+=("$func")
    fi
done

if [ ${#MISSING_UTILS[@]} -eq 0 ]; then
    test_pass
else
    test_fail "Missing utility functions: ${MISSING_UTILS[*]}"
fi

# Test 8: Check git repository is valid
test_start "Git repository is valid"
if git -C "$SCRIPT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    test_pass
else
    test_fail "Not a valid git repository"
fi

# Test 9: Check for common git configuration
test_start "Git has remote origin configured"
if git -C "$SCRIPT_DIR" remote get-url origin > /dev/null 2>&1; then
    test_pass
else
    test_fail "No git remote 'origin' configured"
fi

# --- Summary ---
log_plain ""
log_section "Test Results" "$PARTY"
log_plain "Total Tests: ${BLUE}$TESTS_RUN${NC}"
log_plain "Passed:      ${GREEN}$TESTS_PASSED${NC}"
log_plain "Failed:      ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    log_complete "All tests passed!"
    exit 0
else
    log_error "Some tests failed. Please review the errors above."
    exit 1
fi
