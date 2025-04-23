#!/bin/bash

# Script to install SSH, TFTP, and NFS servers and clients on Ubuntu 24.04

# Update package lists
sudo apt update

echo "Updating package lists..."

# Install SSH server
echo "Installing SSH server..."
sudo apt install -y openssh-server

# Enable and start SSH service
sudo systemctl enable --now ssh
echo "SSH server installed, enabled, and started."

# Install TFTP server and client
echo "Installing TFTP server and client..."
sudo apt install -y tftpd-hpa tftp-hpa

# Configure TFTP server (adjust directory as needed)
TFTP_DIR="/srv/tftp"
sudo mkdir -p "$TFTP_DIR"
sudo chown nobody:nogroup "$TFTP_DIR"
sudo chmod 777 "$TFTP_DIR" # Adjust permissions as needed for your environment

# Modify TFTP server configuration file
sudo sed -i "s/^#TFTP_DIRECTORY=\"\/srv\/tftp\"/TFTP_DIRECTORY=\"$TFTP_DIR\"/" /etc/default/tftpd-hpa
sudo sed -i "s/^TFTP_OPTIONS=\"-l -s\"/TFTP_OPTIONS=\"-l -s -c\"/" /etc/default/tftpd-hpa # Enable file creation

# Restart TFTP service
sudo systemctl restart tftpd-hpa
echo "TFTP server installed and configured. TFTP root directory: $TFTP_DIR"

# Install NFS server and client
echo "Installing NFS server and client..."
sudo apt install -y nfs-kernel-server nfs-common

# Create NFS export directory (adjust as needed)
NFS_SHARE="/srv/nfs"
sudo mkdir -p "$NFS_SHARE"
sudo chown nobody:nogroup "$NFS_SHARE"
# Adjust permissions as needed. Example: read/write for everyone
sudo chmod 777 "$NFS_SHARE"

# Configure NFS exports (adjust IP range and options as needed)
echo "$NFS_SHARE *(rw,sync,no_subtree_check,no_root_squash,insecure)" | sudo tee -a /etc/exports

# Export the NFS shares
sudo exportfs -arv
echo ======================================================================
echo "NFS server installed and configured. NFS share directory: $NFS_SHARE"
echo "TFTP server installed and configured. TFTP root directory: $TFTP_DIR"