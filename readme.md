# Firewall Configuration Automation Script

  

A bash script that automates UFW firewall configuration across multiple Linux servers over SSH.

  

### How It Works

The script reads a list of server IPs from **servers.txt**, connects to each through SSH, uploads a temporary firewall configuration script, Runs it, then cleans up. LAstly it creates a log in firewall_setup.log.

  

Requirements

Linux operating system with UFW installed

  

Setup

#### 1. Add a Common User to Every Remote Server

Every server in your list must have the same username. the script is set to automation but can be modified to anything as long as they match.

  

On each remote server, create the user:

``bashsudo adduser automation``

  

Grant the user passwordless sudo:

``bashsudo visudo``

Add this line at the bottom:

``automation ALL=(ALL) NOPASSWD: ALL``

  
  

#### 2. Generate an SSH Key on Your Local Machine

``bashssh-keygen -t ed25519 -C "automation" -f ~/.ssh/automation_key``

  

#### 3. Copy the Key to Every Remote Server

  

``bashssh-copy-id -i ~/.ssh/automation_key.pub automation@192.168.x.x``

  
  

#### 4. Add Your Servers

Create servers.txt in the same directory as the script, one IP per line:

  
  

#### 5. Run the script

  

Resets UFW to a clean state

Sets default policy: deny incoming, allow outgoing

Allows configured ports over TCP (default: 22, 80, 443)

Enables UFW

Prints the full UFW status

  
  

### Cleanup

To remove the automation user from a server when no longer needed:

``sudo deluser --remove-home automation``

  

``bashsudo visudo``

Delet this line at the bottom:

``automation ALL=(ALL) NOPASSWD: ALL``

  

### Security Notes

  

**NOPASSWD: ALL grants full root access**

  

The temporary script is deleted from /tmp immediately after execution
