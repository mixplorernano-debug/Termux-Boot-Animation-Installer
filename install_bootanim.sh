#!/data/data/com.termux/files/usr/bin/bash

# Termux Boot Animation Installer
SOURCE="/mnt/product/media/Bear Boot Animation.zip"
TARGET="/product/media/bootanimation.zip"
BACKUP_DIR="/sdcard/bootanimation_backups"

echo "[*] Termux Boot Animation Installer"
echo "[*] Source: $SOURCE"
echo ""

# Check root access
if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] This script requires root access!"
    echo "Run with: tsu"
    exit 1
fi

# Check if source exists
if [ ! -f "$SOURCE" ]; then
    echo "[ERROR] Cannot find source file: $SOURCE"
    echo "Available files in /mnt/product/media/:"
    ls -la /mnt/product/media/ 2>/dev/null || echo "(Cannot list directory)"
    exit 1
fi

# Check file size (avoid copying empty/corrupt files)
SOURCE_SIZE=$(stat -c%s "$SOURCE" 2>/dev/null || wc -c < "$SOURCE")
if [ "$SOURCE_SIZE" -lt 1000 ]; then
    echo "[WARNING] Source file is very small ($SOURCE_SIZE bytes). Might be corrupt?"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

# Try to remount /product as read-write
echo "[*] Attempting to remount /product as read-write..."
if mount -o rw,remount /product 2>/dev/null; then
    echo "[+] /product remounted successfully"
else
    echo "[!] Could not remount /product. Trying alternative..."
    # Try alternative mount point
    if [ -d "/system/product" ]; then
        TARGET="/system/product/media/bootanimation.zip"
        echo "[*] Using alternative target: $TARGET"
        mount -o rw,remount /system 2>/dev/null
    else
        echo "[WARNING] /product is read-only. Installation may fail."
    fi
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup original if exists
if [ -f "$TARGET" ]; then
    BACKUP_NAME="bootanimation_$(date +%Y%m%d_%H%M%S).zip"
    BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
    
    echo "[*] Backing up original..."
    if cp "$TARGET" "$BACKUP_PATH"; then
        echo "[+] Backup saved: $BACKUP_PATH"
        echo "   Size: $(stat -c%s "$BACKUP_PATH") bytes"
        echo "   MD5: $(md5sum "$BACKUP_PATH" | cut -d' ' -f1)"
    else
        echo "[ERROR] Failed to create backup!"
        exit 1
    fi
fi

# Install new animation
echo "[*] Installing new boot animation..."
if cp "$SOURCE" "$TARGET"; then
    chmod 644 "$TARGET"
    chown root:root "$TARGET" 2>/dev/null
    
    # Verify installation
    if [ -f "$TARGET" ]; then
        TARGET_SIZE=$(stat -c%s "$TARGET" 2>/dev/null || wc -c < "$TARGET")
        echo "[+] Success! File installed to: $TARGET"
        echo "   Size: $TARGET_SIZE bytes"
        echo "   Permissions: $(stat -c%A "$TARGET")"
        
        echo ""
        echo "=== Installation Summary ==="
        echo "Source size: $SOURCE_SIZE bytes"
        echo "Target size: $TARGET_SIZE bytes"
        
        if [ "$SOURCE_SIZE" -eq "$TARGET_SIZE" ]; then
            echo "✓ File copy verified (sizes match)"
        else
            echo "⚠️ Warning: Source and target sizes differ!"
        fi
        
        echo ""
        echo "Next steps:"
        echo "1. Reboot to see animation:"
        echo "   Type 'reboot' or restart your phone"
        echo ""
        echo "2. To restore from backup:"
        echo "   cp '$BACKUP_PATH' '$TARGET'"
        echo "   chmod 700 '$TARGET'"
        echo "   reboot"
    else
        echo "[ERROR] Installation verification failed!"
    fi
else
    echo "[ERROR] Installation failed!"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check if /product is read-write:"
    echo "   mount | grep product"
    echo ""
    echo "2. Try manual remount:"
    echo "   mount -o rw,remount /product"
    echo ""
    echo "3. Alternative locations (if available):"
    echo "   /system/media/bootanimation.zip"
    echo "   /oem/media/bootanimation.zip"
fi

# Debug information
echo ""
echo "=== Debug Information ==="
echo "Product mount status:"
mount | grep product || echo "No product mount found"
echo ""
echo "System mount status:"
mount | grep system || echo "No system mount found"
echo ""
echo "Target file info (if exists):"
ls -la "$TARGET" 2>/dev/null || echo "Target not found"