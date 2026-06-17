#!/bin/bash
# ============================================
# Firewall Configuration Automation Script
# ============================================

# Set the remote username the script will SSH into
USERNAME="automation"

# Path to the file containing list of server IPs (one per line)
SERVER_LIST="servers.txt"

# Path to the log file where all output will be recorded
LOG_FILE="firewall_setup.log"

# Array of TCP ports to allow through the firewall
ALLOWED_PORTS=(22 80 443)

# Truncate (clear) the log file at the start of each run
> "$LOG_FILE"

# Define a reusable log function that prints to terminal and appends to log file
log() { echo "$1" | tee -a "$LOG_FILE"; }

# Print opening banner to log and terminal
log "==================================="

# Log the script start event
log "Firewall Automation Started"

# Log the current date and time
log "Date: $(date)"

# Print closing banner line
log "==================================="

# Check if the server list file exists before proceeding
if [[ ! -f "$SERVER_LIST" ]]; then
    # Log an error and exit if the server list file is missing
    log "[ERROR] Server list '$SERVER_LIST' not found."
    # Exit with a non-zero status to indicate failure
    exit 1
fi

# Expand the ALLOWED_PORTS array into a space-separated string for use in the remote script
PORT_LIST="${ALLOWED_PORTS[*]}"

# Begin reading the server list file line by line
# IFS= prevents trimming of whitespace, -r prevents backslash interpretation
# The || [[ -n "$SERVER" ]] handles the last line if it has no trailing newline
while IFS= read -r SERVER || [[ -n "$SERVER" ]]; do

    # Skip any lines that are empty or start with # (comments)
    [[ -z "$SERVER" || "$SERVER" == \#* ]] && continue

    # Log which server is being processed
    log ""
    log "Connecting to $SERVER..."

    # Create a temporary file on the local machine to hold the remote script
    REMOTE_SCRIPT=$(mktemp)

    # Write the firewall configuration script into the local temp file
    # EOF heredoc expands local variables like $PORT_LIST before writing
    cat > "$REMOTE_SCRIPT" <<EOF
#!/bin/bash
# Print the hostname of the remote machine for confirmation
echo "Updating firewall rules on \$(hostname)"

# Reset UFW to a clean default state, suppressing the confirmation prompt
ufw --force reset

# Set default policy to block all incoming connections
ufw default deny incoming

# Set default policy to allow all outgoing connections
ufw default allow outgoing

# Loop through each port in the list and allow it over TCP
for PORT in $PORT_LIST; do
    ufw allow \$PORT/tcp
done

# Enable UFW without prompting for confirmation
ufw --force enable

# Print the full UFW status to confirm rules were applied
ufw status verbose
EOF

    # Copy the temp script from local machine to the remote server's /tmp directory
    scp -i ~/.ssh/automation_key -o StrictHostKeyChecking=accept-new "$REMOTE_SCRIPT" "$USERNAME@$SERVER:/tmp/fw_setup.sh"

    # SSH into the remote server, run the script as root, then delete it when done
    ssh -i ~/.ssh/automation_key -o StrictHostKeyChecking=accept-new "$USERNAME@$SERVER" "sudo bash /tmp/fw_setup.sh && sudo rm /tmp/fw_setup.sh"

    # Capture the exit code of the SSH command immediately before anything else can overwrite it
    SSH_STATUS=$?

    # Delete the local temp script file now that it has been used
    rm -f "$REMOTE_SCRIPT"

    # Check if the SSH command succeeded (exit code 0 means success)
    if [[ $SSH_STATUS -eq 0 ]]; then
        # Log a success message for this server
        log "[SUCCESS] Firewall configured on $SERVER"
    else
        # Log a failure message along with the exit code for debugging
        log "[FAILED]  Firewall failed on $SERVER (exit code: $SSH_STATUS)"
    fi

# End of the while loop, reading from the server list file
done < "$SERVER_LIST"

# Print a blank line for readability
log ""

# Log that the script has finished processing all servers
log "Automation Complete."
