# SSH Setup Guide

Based on: [Brandon Rohrer's SSH at Home Guide](https://brandonrohrer.com/ssh_at_home.html)

This guide covers setting up SSH for secure remote access between machines, particularly useful for home laptop-to-laptop connections, home servers, wireless devices, and robotics experiments.
---
## Table of Contents

- [Prerequisites](#prerequisites)
- [Checking SSH Installation](#checking-ssh-installation)
- [Installing SSH](#installing-ssh)
- [Starting SSH Server](#starting-ssh-server)
- [Generating SSH Keys](#generating-ssh-keys)
- [Copying Keys to Remote Host](#copying-keys-to-remote-host)
- [Configuring SSH Server](#configuring-ssh-server)
- [Security Measures](#security-measures)
- [Testing Your Setup](#testing-your-setup)
- [Resources](#resources)
---
## Checking SSH Installation

### Check if SSH Client is Installed

Test whether you have the capability to open a secure shell with an SSH-capable machine:

```bash
file /etc/ssh/ssh_config
```

**Expected output if installed:**
```
/etc/ssh/ssh_config: ASCII text
```

**If not installed:**
```
No such file or directory
```

### Check if SSH Server (sshd) is Installed

Test whether you have the capability to be an SSH server (host an SSH connection, run SSH daemon):

```bash
file /etc/ssh/sshd_config
```

**Expected output if installed:**
```
/etc/ssh/sshd_config: ASCII text
```
---
## Installing SSH

### On Ubuntu/Debian

**Install SSH Client:**
```bash
sudo apt install openssh-client
```

**Install SSH Server:**
```bash
sudo apt install openssh-server
```
---

## Starting SSH Server

Enable and start the SSH server:

```bash
sudo systemctl enable --now sshd
```

To restart after configuration changes:

```bash
sudo systemctl restart sshd
```
---

## Generating SSH Keys

### Create a 4096-bit RSA Key Pair

On the **client machine** (the one you'll SSH from):

```bash
ssh-keygen -t rsa -b 4096
```

This creates a 4096-bit [RSA](https://en.wikipedia.org/wiki/RSA_%28cryptosystem%29)-encrypted public/private key pair.

**During the process:**
- You will be prompted for a passphrase
- **Choose one** - this is a critical security measure!

**Default locations:**
- Private key: `~/.ssh/id_rsa`
- Public key: `~/.ssh/id_rsa.pub`

You can choose a different name or create multiple RSA keys as needed.

---

## Copying Keys to Remote Host

### Using ssh-copy-id

Copy the public key to the remote host and append it to `~/.ssh/authorized_keys`:

```bash
ssh-copy-id -i <PUBLIC_KEY_PATH> <USERNAME_ON_HOST>@<HOST_IP>
```

**Example:**
```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub brohrer@192.168.1.10
```

### Manual Method

If `ssh-copy-id` is not available:

1. Copy the contents of your public key:
   ```bash
   cat ~/.ssh/id_rsa.pub
   ```

2. SSH into the remote host (using password):
   ```bash
   ssh username@hostname
   ```

3. Append the key to authorized_keys:
   ```bash
   mkdir -p ~/.ssh
   echo "YOUR_PUBLIC_KEY_CONTENT" >> ~/.ssh/authorized_keys
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```
---
## Configuring SSH Server

### Backup Configuration File

Before making changes, **always backup** the original configuration:

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
```

This gives you a reset button when you make a misstep.

### Testing Configuration

After making changes, run an extended test on the config file:

```bash
sudo sshd -T -f /etc/ssh/sshd_config
```

This validates your configuration before applying it.

### Restart SSH Service

Every time you make a change to the config, restart is necessary for it to take effect:
```bash
sudo systemctl restart sshd
```
---

## Security Measures

### Overview

Seven key security practices to protect your SSH setup:

1. ✅ Use SSH keys instead of passwords
2. ✅ Use a passphrase with your SSH key
3. ✅ Use a non-typical port
4. ✅ Use an allow list for IP addresses
5. ✅ Disallow root login
6. ✅ Enable verbose logging
7. ✅ Keep SSH updated

---

### 1. Use SSH Keys

SSH keys are more secure than passwords. Follow the [Generating SSH Keys](#generating-ssh-keys) section above.

---

### 2. Disable Password Authentication

**After** you have successfully copied your SSH key to the remote host, enforce the use of SSH keys by disabling password authentication.

Edit `/etc/ssh/sshd_config`:

```bash
PasswordAuthentication no
```

**⚠️ Warning:** Only do this after confirming you can SSH in with your key! Otherwise, you might lock yourself out.

---

### 3. Choose a Non-Typical Port

By default, SSH operates on port 22. To make your SSH setup slightly harder to find, use a different port.

Edit `/etc/ssh/sshd_config`:

Uncomment and modify:
```bash
#Port 22
```

Change to:
```bash
Port 43689
```

Use any [randomly generated port](https://www.convertsimple.com/random-port-generator/) between 1024-65535.

**Connecting with custom port:**
```bash
ssh -p 43689 username@hostname
```

---

### 4. Use an Allow List

Explicitly list the IP addresses that may connect to your SSH server.

Edit `/etc/ssh/sshd_config`:

Uncomment and modify the `ListenAddress` lines:

```bash
ListenAddress 0.0.0.0
ListenAddress 192.168.1.10
ListenAddress 192.168.1.11
```

**Note:** If your devices have dynamically-allocated addresses (DHCP), configure them to use static IP addresses in their wireless settings.

---

### 5. Disallow Root Login

This protects you from SSH'ing in as root and potentially causing damage. You can still use `sudo` for administrative tasks.

Edit `/etc/ssh/sshd_config`:

```bash
PermitRootLogin no
```

This is good security hygiene.

---

### 6. Enable Verbose Logging

Set logging level to INFO to monitor connection attempts and potential security issues.

Edit `/etc/ssh/sshd_config`:

```bash
LogLevel INFO
```

**View logs:**
```bash
sudo cat /var/log/auth.log
```

Or for systemd-based systems:
```bash
sudo journalctl -u sshd
```

---

### 7. Keep SSH Updated

Regularly update OpenSSH to get security patches:

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install openssh-server
```

**macOS:**
```bash
brew update
brew upgrade openssh
```

---

## Testing Your Setup

### Test SSH Connection Locally

On the server machine:

```bash
ssh localhost
```

### Test Remote Connection

From the client machine:

```bash
ssh username@server_ip
```

Or with custom port:

```bash
ssh -p 43689 username@server_ip
```

### Find Your IP Address

**Linux:**
```bash
ip addr show
```
or
```bash
hostname -I
```

**macOS:**
```bash
ifconfig | grep "inet "
```
or
```bash
ipconfig getifaddr en0
```

---

## SSH Client Configuration

### Create ~/.ssh/config

For easier connections, create a client-side config file:

```bash
touch ~/.ssh/config
chmod 600 ~/.ssh/config
```

**Example configuration:**

```
# Home server
Host homeserver
    HostName 192.168.1.10
    User myusername
    Port 22
    IdentityFile ~/.ssh/id_rsa

# Work machine
Host work
    HostName 192.168.1.20
    User workuser
    Port 43689
    IdentityFile ~/.ssh/id_rsa
```

**Connect using alias:**
```bash
ssh homeserver
```

---

## Common Commands Reference

### SSH Basics

| Command | Description |
|---------|-------------|
| `ssh user@host` | Connect to remote host |
| `ssh -p PORT user@host` | Connect using specific port |
| `ssh-keygen -t rsa -b 4096` | Generate RSA key pair |
| `ssh-copy-id -i ~/.ssh/id_rsa.pub user@host` | Copy public key to remote host |
| `ssh-add ~/.ssh/id_rsa` | Add key to SSH agent |

### Server Management

| Command | Description |
|---------|-------------|
| `sudo systemctl status sshd` | Check SSH server status |
| `sudo systemctl start sshd` | Start SSH server |
| `sudo systemctl stop sshd` | Stop SSH server |
| `sudo systemctl restart sshd` | Restart SSH server |
| `sudo systemctl enable sshd` | Enable SSH on boot |
| `sudo sshd -t` | Test SSH configuration |

---

## Troubleshooting

### Can't Connect

1. **Check if SSH server is running:**
   ```bash
   sudo systemctl status sshd
   ```

2. **Check firewall settings:**
   ```bash
   sudo ufw status
   sudo ufw allow 22/tcp  # or your custom port
   ```

3. **Verify IP address:**
   ```bash
   ip addr show
   ```

4. **Check logs for errors:**
   ```bash
   sudo cat /var/log/auth.log | grep sshd
   ```

### Permission Denied

1. **Check file permissions:**
   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/id_rsa
   chmod 644 ~/.ssh/id_rsa.pub
   chmod 600 ~/.ssh/authorized_keys
   ```

2. **Verify key is in authorized_keys:**
   ```bash
   cat ~/.ssh/authorized_keys
   ```

3. **Check SSH config allows key authentication:**
   ```bash
   sudo grep -i "PubkeyAuthentication" /etc/ssh/sshd_config
   ```

### Connection Timeout

1. **Check network connectivity:**
   ```bash
   ping server_ip
   ```

2. **Verify correct port:**
   ```bash
   sudo netstat -tlnp | grep sshd
   ```

3. **Check if firewall is blocking:**
   ```bash
   sudo iptables -L -n | grep 22
   ```
---

## Quick Start Checklist

- [ ] Check if SSH client is installed (`file /etc/ssh/ssh_config`)
- [ ] Check if SSH server is installed (`file /etc/ssh/sshd_config`)
- [ ] Install SSH client/server if needed
- [ ] Generate SSH key pair (`ssh-keygen -t rsa -b 4096`)
- [ ] Use a strong passphrase for your key
- [ ] Copy public key to remote host (`ssh-copy-id`)
- [ ] Test connection works
- [ ] Backup SSH server config (`sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak`)
- [ ] Disable password authentication
- [ ] Change default SSH port (optional)
- [ ] Disable root login
- [ ] Enable verbose logging
- [ ] Test configuration (`sudo sshd -t`)
- [ ] Restart SSH service
- [ ] Test connection again
- [ ] Set up regular updates

---

*Last updated: October 17, 2025*

*Based on Brandon Rohrer's guide: https://brandonrohrer.com/ssh_at_home.html*
