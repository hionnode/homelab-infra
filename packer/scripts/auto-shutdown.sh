#!/bin/bash

# Auto-shutdown configuration
IDLE_TIME=${IDLE_TIME:-600}  # 10 minutes default
CHECK_INTERVAL=60            # Check every minute

echo "Auto-shutdown enabled: will shutdown after ${IDLE_TIME} seconds of inactivity"

while true; do
    sleep $CHECK_INTERVAL
    
    # Check if any jobs are running
    if pgrep -f "Runner.Worker" > /dev/null; then
        echo "Active job detected, resetting idle timer"
        continue
    fi
    
    # Check if runner process is still active but idle
    if pgrep -f "Runner.Listener" > /dev/null; then
        # Check system load and network activity as additional indicators
        LOAD=$(uptime | awk '{print $10}' | sed 's/,//')
        
        # If load is very low, consider shutting down
        if (( $(echo "$LOAD < 0.1" | bc -l) )); then
            echo "System appears idle (load: $LOAD), starting shutdown countdown"
            
            # Wait additional time to be sure
            sleep $IDLE_TIME
            
            # Final check
            if ! pgrep -f "Runner.Worker" > /dev/null; then
                echo "No active jobs found after idle period, shutting down..."
                
                # Gracefully stop the runner
                if [ -f /opt/actions-runner/.runner ]; then
                    cd /opt/actions-runner
                    ./config.sh remove --token $(cat token 2>/dev/null || echo "dummy") 2>/dev/null || true
                fi
                
                # Shutdown the container
                shutdown -h now
            fi
        fi
    else
        echo "Runner process not found, shutting down..."
        shutdown -h now
    fi
done