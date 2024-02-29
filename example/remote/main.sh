#!/bin/bash

set -e

cd "$(dirname "$0")"

[ "$EUID" = 0 ] || { echo 'This script must be run as root' >&2; exit 1; }

apt_update_if_old() {
    if [ -z "$(find /var/lib/apt/lists -maxdepth 1 -mmin -60)" ]; then
        apt-get update
    fi
}

################################################################################

# TODOEND remember that everything must be idempotent
# TODOEND remove appownmod from everywhere!
# TODOEND check that you always check with grep before using ">>"
# TODOEND check that you always run scripts from /opt/startup-late after creating them
# TODOEND disable lognot and portmap, as in the old script

dpkg -s curl >/dev/null 2>&1 || {
    apt_update_if_old; apt-get install -y \
        git nano tmux tree wget zip curl socat procps jq yq \
        iputils-ping iproute2 firefox-esr dirmngr
}

# TODO packages that should be closer to their config (using "command -v" to be faster): ffmpeg dconf-cli

################################################################################

fetch_and_check() { # Src: https://github.com/dmotte/misc
    local c s; c=$(curl -fsSL "$1"; echo x) && \
    s=$(echo -n "${c%x}" | sha256sum | cut -d' ' -f1) && \
    if [ "$s" = "$2" ]; then echo -n "${c%x}"
    else echo "Checksum verification failed for $1: got $s, expected $2" >&2
    return 1; fi
}

script_lognot=$(fetch_and_check \
    'https://raw.githubusercontent.com/dmotte/misc/main/scripts/provisioning/lognot.sh' \
    'f84b6c3ecf726c2d7605164770ccef7c725731ea3897aad2d6d70d7ae6cfb31f')
setup_lognot() { bash <(echo "$script_lognot") "$@"; }
script_portmap=$(fetch_and_check \
    'https://raw.githubusercontent.com/dmotte/misc/main/scripts/provisioning/portmap.sh' \
    'fd5b05aae3a11bc2898970424b316afb373f2c93480098428f8d3cec1b8963f4')
setup_portmap() { bash <(echo "$script_portmap") "$@"; }

################################################################################

bash helpers/hardening.sh
bash helpers/supervisorctl.sh

# shellcheck disable=SC2016
setup_lognot -b'(put-bot-token-here)' -c'(put-chat-id-here)' \
    'bash /opt/lognot/get.sh | while read -r i; do echo "$HOSTNAME: $i"; done'
install -m700 lognot-get.sh /opt/lognot/get.sh

bash helpers/sshd.sh

bash helpers/shellinabox.sh

################################################################################

echo 'Performing basic mainuser setup'

install -m440 <(echo 'mainuser ALL=(ALL) NOPASSWD: ALL') \
    /etc/sudoers.d/mainuser-nopassword

install -d -omainuser -gmainuser -m700 ~mainuser/.ssh
install -omainuser -gmainuser -m600 authorized-keys-mainuser.txt \
    ~mainuser/.ssh/authorized_keys

install -d -omainuser -gmainuser -m700 /data/mainuser

################################################################################

[ -e ~mainuser/.ssh/known_hosts ] || \
    install -omainuser -gmainuser -m600 /dev/null ~mainuser/.ssh/known_hosts

if ! grep '^myserver\.example\.com ' \
    ~mainuser/.ssh/known_hosts >/dev/null 2>&1; then
    cat << 'EOF' >> ~mainuser/.ssh/known_hosts
myserver.example.com (put-public-ssh-host-key-here)
EOF
fi

install -omainuser -gmainuser -m600 portmap-ssh.pem ~mainuser/.ssh/

setup_portmap -nssh -rmainuser -- '-i ~/.ssh/portmap-ssh.pem' \
    'myuser@myserver.example.com -NvR12345:127.0.0.1:22'

################################################################################

if [ "$SUPERVISOR_RELOAD" = 'true' ]; then
    echo 'Sending SIGHUP to supervisord (pid 1)'
    kill -sHUP 1
fi

if [ "$SUPERVISOR_UPDATE" = 'true' ]; then
    echo 'Running supervisorctl update'
    supervisorctl update
fi

if [ "$SUPERVISOR_SHUTDOWN" = 'true' ]; then
    echo 'Shutting down supervisor'
    # The container will restart if its restart policy is set that way
    kill 1
fi
