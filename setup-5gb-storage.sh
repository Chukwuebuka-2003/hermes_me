#!/usr/bin/env bash
# ==============================================================================
# Setup a Hard 5GB Storage Quota for Hermes Data on Hetzner VPS
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_IMG="${SCRIPT_DIR}/hermes_data_5g.img"
MOUNT_DIR="${SCRIPT_DIR}/data"

echo "==> Configuring 5GB hard storage limit for Hermes Agent..."

# 1. Create a 5GB sparse image file (consumes minimal space initially, maxes out at 5GB)
if [ ! -f "${DATA_IMG}" ]; then
  echo "==> Creating 5GB sparse disk image file: ${DATA_IMG}..."
  truncate -s 5G "${DATA_IMG}"
  mkfs.ext4 -F -q "${DATA_IMG}"
else
  echo "==> Existing disk image found at ${DATA_IMG}."
fi

# 2. Ensure mount point directory exists
mkdir -p "${MOUNT_DIR}"

# 3. Mount as loop device if not already mounted
if mountpoint -q "${MOUNT_DIR}"; then
  echo "==> ${MOUNT_DIR} is already mounted."
else
  echo "==> Mounting 5GB image to ${MOUNT_DIR}..."
  sudo mount -o loop,defaults "${DATA_IMG}" "${MOUNT_DIR}"
fi

# 4. Set permissions to match host user
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)
sudo chown -R "${CURRENT_UID}:${CURRENT_GID}" "${MOUNT_DIR}"

# 5. Optionally add to /etc/fstab for reboot persistence
FSTAB_LINE="${DATA_IMG} ${MOUNT_DIR} ext4 loop,defaults,nofail 0 0"
if ! grep -Fq "${DATA_IMG}" /etc/fstab 2>/dev/null; then
  echo "==> Adding mount to /etc/fstab for automatic persistence across reboots..."
  echo "${FSTAB_LINE}" | sudo tee -a /etc/fstab >/dev/null
fi

echo "==> Done! Storage successfully capped at 5GB."
df -h "${MOUNT_DIR}"
