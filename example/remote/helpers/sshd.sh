#!/bin/bash

set -e

[ "$EUID" = 0 ] || { echo 'This script must be run as root' >&2; exit 1; }

apt_update_if_old() {
    if [ -z "$(find /var/lib/apt/lists -maxdepth 1 -mmin -60)" ]; then
        apt-get update
    fi
}

################################################################################

dpkg -s openssh-server >/dev/null 2>&1 || {
    apt_update_if_old; apt-get install -y openssh-server
    rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub
}

echo 'Creating sshd service files'

cat << 'EOF' > /etc/supervisor/conf.d/sshd.conf
[program:sshd]
command=/usr/sbin/sshd -De
priority=10
EOF

mkdir -p /var/run/sshd

echo 'Configuring sshd'

sed -Ei /etc/ssh/sshd_config \
    -e 's/^#?AddressFamily.*$/AddressFamily inet/' \
    -e 's/^#?PermitRootLogin.*$/PermitRootLogin no/' \
    -e 's/^#?HostbasedAuthentication.*$/HostbasedAuthentication no/' \
    -e 's/^#?PermitEmptyPasswords.*$/PermitEmptyPasswords no/' \
    -e 's/^#?PasswordAuthentication.*$/PasswordAuthentication no/'

echo 'Setting up 50-ssh-host-keys.sh'

mkdir -p /etc/ssh/host-keys

cat << 'EOF' > /opt/startup-late/50-ssh-host-keys.sh
# Get host keys from the volume
rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub
install -m600 -t/etc/ssh /etc/ssh/host-keys/ssh_host_*_key 2>/dev/null || :
install -m644 -t/etc/ssh /etc/ssh/host-keys/ssh_host_*_key.pub 2>/dev/null || :

# Generate the missing host keys
ssh-keygen -A

# Copy the (previously missing) generated host keys to the volume
cp -n /etc/ssh/ssh_host_*_key /etc/ssh/host-keys/ 2>/dev/null || :
cp -n /etc/ssh/ssh_host_*_key.pub /etc/ssh/host-keys/ 2>/dev/null || :
EOF

echo 'Including 50-ssh-host-keys.sh'

# shellcheck source=/dev/null
. /opt/startup-late/50-ssh-host-keys.sh
