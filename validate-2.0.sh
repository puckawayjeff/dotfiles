#!/usr/bin/env bash
# validate-2.0.sh - Comprehensive validation for 2.0.0 release
# Tests all functionality to ensure the release is ready

set -e

# Get script directory and load utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/lib/utils.sh"

# Test counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# Check helper
check_item() {
    local description="$1"
    local command="$2"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    printf "${BLUE}[%02d]${NC} Checking: %s... " "$TOTAL_CHECKS" "$description"
    
    if eval "$command" &>/dev/null; then
        printf "${GREEN}✓${NC}\n"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        printf "${RED}✗${NC}\n"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

# Warning helper
warn_item() {
    local description="$1"
    WARNINGS=$((WARNINGS + 1))
    printf "${YELLOW}${WARNING} Warning: %s${NC}\n" "$description"
}

log_section "Dotfiles 2.0.0 Release Validation" "$ROCKET"
log_info "This script validates the 2.0.0 release is ready for production"
echo ""

# === Core Files ===
log_section "Core Files" "$PACKAGE"
check_item "VERSION file exists" "[ -f '$SCRIPT_DIR/VERSION' ]"
check_item "VERSION is 2.0.0" "grep -q '^2.0.0$' '$SCRIPT_DIR/VERSION'"
check_item "ARCHITECTURE.md exists" "[ -f '$SCRIPT_DIR/ARCHITECTURE.md' ]"
check_item "RELEASE_NOTES.md exists" "[ -f '$SCRIPT_DIR/RELEASE_NOTES.md' ]"
check_item "CHANGELOG.md has 2.0.0 entry" "grep -q '## \[2.0.0\]' '$SCRIPT_DIR/CHANGELOG.md'"
check_item "README.md is streamlined" "test \$(wc -l < '$SCRIPT_DIR/README.md') -lt 300"

# === Library Files ===
log_section "Library Files" "$WRENCH"
check_item "lib/utils.sh exists" "[ -f '$SCRIPT_DIR/lib/utils.sh' ]"
check_item "lib/utils.sh has INFO emoji" "grep -q 'INFO=' '$SCRIPT_DIR/lib/utils.sh'"
check_item "lib/terminal.sh exists" "[ -f '$SCRIPT_DIR/lib/terminal.sh' ]"
check_item "lib/motd.sh exists" "[ -f '$SCRIPT_DIR/lib/motd.sh' ]"
check_item "lib/last-login.sh exists" "[ -f '$SCRIPT_DIR/lib/last-login.sh' ]"

# === Script Files ===
log_section "Script Files" "$COMPUTER"
check_item "join.sh exists" "[ -f '$SCRIPT_DIR/join.sh' ]"
check_item "join.sh has self-contained comment" "grep -q 'Self-Contained Design' '$SCRIPT_DIR/join.sh'"
check_item "sync.sh exists" "[ -f '$SCRIPT_DIR/sync.sh' ]"
check_item "test.sh exists" "[ -f '$SCRIPT_DIR/test.sh' ]"
check_item "package-ssh-keys.sh exists" "[ -f '$SCRIPT_DIR/package-ssh-keys.sh' ]"
check_item "package-ssh-keys.sh uses lib/utils.sh" "grep -q 'source.*lib/utils.sh' '$SCRIPT_DIR/package-ssh-keys.sh'"

# === Configuration Files ===
log_section "Configuration Files" "$PENCIL"
check_item "config/.zshrc exists" "[ -f '$SCRIPT_DIR/config/.zshrc' ]"
check_item "config/functions.zsh exists" "[ -f '$SCRIPT_DIR/config/functions.zsh' ]"
check_item "config/symlinks.conf exists" "[ -f '$SCRIPT_DIR/config/symlinks.conf' ]"
check_item "config/starship.toml exists" "[ -f '$SCRIPT_DIR/config/starship.toml' ]"
check_item "config/tmux.conf exists" "[ -f '$SCRIPT_DIR/config/tmux.conf' ]"

# === Documentation ===
log_section "Documentation" "$BOOK"
check_item "docs/Functions Reference.md exists" "[ -f '$SCRIPT_DIR/docs/Functions Reference.md' ]"
check_item "docs/New Host Deployment.md exists" "[ -f '$SCRIPT_DIR/docs/New Host Deployment.md' ]"
check_item "docs/Examples.md exists" "[ -f '$SCRIPT_DIR/docs/Examples.md' ]"
check_item "docs/Testing Guide.md exists" "[ -f '$SCRIPT_DIR/docs/Testing Guide.md' ]"
check_item "docs/Setup Scripts Reference.md exists" "[ -f '$SCRIPT_DIR/docs/Setup Scripts Reference.md' ]"
check_item "docs/Terminal Font Setup.md exists" "[ -f '$SCRIPT_DIR/docs/Terminal Font Setup.md' ]"

# === Documentation Cross-References ===
log_section "Documentation Cross-References" "$LINK"
check_item "README references ARCHITECTURE" "grep -q 'ARCHITECTURE.md' '$SCRIPT_DIR/README.md'"
check_item "README references PRIVATE_SETUP" "grep -q 'PRIVATE_SETUP.md' '$SCRIPT_DIR/README.md'"
check_item "ARCHITECTURE is comprehensive" "test \$(wc -l < '$SCRIPT_DIR/ARCHITECTURE.md') -gt 200"
check_item "RELEASE_NOTES mentions 2.0.0" "grep -q '2.0.0' '$SCRIPT_DIR/RELEASE_NOTES.md'"

# === Git Repository ===
log_section "Git Repository" "$FOLDER"
check_item "Git repository is valid" "git -C '$SCRIPT_DIR' rev-parse --git-dir"
check_item "Git has no unstaged changes" "git -C '$SCRIPT_DIR' diff-index --quiet HEAD --"
check_item "Git remote exists" "git -C '$SCRIPT_DIR' remote get-url origin"

# === Shell Syntax ===
log_section "Shell Syntax" "$CHECK"
check_item "join.sh syntax valid" "bash -n '$SCRIPT_DIR/join.sh'"
check_item "sync.sh syntax valid" "bash -n '$SCRIPT_DIR/sync.sh'"
check_item "test.sh syntax valid" "bash -n '$SCRIPT_DIR/test.sh'"
check_item "functions.zsh syntax valid" "zsh -n '$SCRIPT_DIR/config/functions.zsh' 2>/dev/null || bash -n '$SCRIPT_DIR/config/functions.zsh'"

# === Test Suite ===
log_section "Test Suite" "$WRENCH"
log_info "Running test.sh..."
if bash "$SCRIPT_DIR/test.sh" >/dev/null 2>&1; then
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    log_success "All test.sh tests passed"
else
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    log_error "test.sh had failures - run ./test.sh for details"
fi

# === Optional Warnings ===
log_section "Optional Components" "$INFO"
if ! command -v zsh &>/dev/null; then
    warn_item "Zsh not installed (will be installed on deployment)"
fi
if ! command -v git &>/dev/null; then
    warn_item "Git not installed (required for deployment)"
fi
if [ ! -f "$HOME/.config/dotfiles/dotfiles.env" ]; then
    warn_item "dotfiles.env not found (enhanced mode not configured - this is optional)"
fi

# === Summary ===
echo ""
log_section "Validation Summary" "$PARTY"
printf "${BLUE}Total Checks:${NC}   %d\n" "$TOTAL_CHECKS"
printf "${GREEN}Passed:${NC}        %d\n" "$PASSED_CHECKS"
printf "${RED}Failed:${NC}        %d\n" "$FAILED_CHECKS"
printf "${YELLOW}Warnings:${NC}      %d\n" "$WARNINGS"
echo ""

if [ $FAILED_CHECKS -eq 0 ]; then
    log_complete "Validation passed! The 2.0.0 release is ready."
    echo ""
    log_info "Next steps:"
    log_substep "1. Review the changes with 'git diff'"
    log_substep "2. Test deployment in a clean VM (see docs/Testing Guide.md)"
    log_substep "3. Commit and push the changes"
    log_substep "4. Create a GitHub release with RELEASE_NOTES.md content"
    echo ""
    exit 0
else
    log_error "Validation failed with $FAILED_CHECKS issue(s)."
    log_info "Please fix the issues above and run this script again."
    echo ""
    exit 1
fi
