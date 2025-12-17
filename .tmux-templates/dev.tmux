# Development workspace
# Usage: tw-create myproject dev

# Split vertically (vim on left 50%, rest on right)
split-window -h -p 50

# Split right pane horizontally (terminal top, logs bottom)
split-window -v -p 50

# Select the first pane (vim)
select-pane -t 0

# Optional: Start vim in first pane
# send-keys -t 0 'vim' C-m

# Optional: Set pane titles
# select-pane -t 0 -T "Editor"
# select-pane -t 1 -T "Terminal"
# select-pane -t 2 -T "Logs"
