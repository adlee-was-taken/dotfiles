# Multi-server SSH workspace
# 4 panes for managing multiple servers

# Create 2x2 grid
split-window -h -p 50
split-window -v -p 50
select-pane -t 0
split-window -v -p 50

# Enable pane synchronization (optional - uncomment to enable)
# set-window-option synchronize-panes on

select-pane -t 0
