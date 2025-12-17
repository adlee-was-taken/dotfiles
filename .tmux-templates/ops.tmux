# Operations workspace
# 4-pane layout for system monitoring

# Create 2x2 grid
split-window -h -p 50
split-window -v -p 50
select-pane -t 0
split-window -v -p 50

# Optional: Auto-start monitoring tools
# send-keys -t 0 'htop' C-m
# send-keys -t 1 'docker ps' C-m
# send-keys -t 2 '' C-m
# send-keys -t 3 'tail -f /var/log/syslog' C-m

select-pane -t 0
