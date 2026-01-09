# config/zsh/options.zsh

# ===== History Options =====
setopt EXTENDED_HISTORY          # Write timestamps to history
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicates first when trimming
setopt HIST_IGNORE_ALL_DUPS      # Remove all duplicates, not just consecutive
setopt HIST_IGNORE_DUPS          # Don't record duplicate entries
setopt HIST_IGNORE_SPACE         # Don't record entries starting with space
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks from commands
setopt HIST_VERIFY               # Don't execute immediately upon history expansion
setopt SHARE_HISTORY             # Share history between all sessions

# ===== Directory Navigation =====
setopt AUTO_CD                   # Type directory name to cd
setopt AUTO_PUSHD                # Push directories onto stack
setopt PUSHD_IGNORE_DUPS         # Don't push duplicates
setopt PUSHD_SILENT              # Don't print directory stack

# ===== Completion System =====
setopt COMPLETE_IN_WORD          # Complete from cursor position
setopt ALWAYS_TO_END             # Move cursor to end after completion
setopt AUTO_MENU                 # Show completion menu on tab
setopt AUTO_LIST                 # List choices on ambiguous completion
setopt INTERACTIVE_COMMENTS      # Safely ignore pasted comment lines
