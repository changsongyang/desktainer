#!/bin/bash

set -e

# TODO move everything from this script to the new one

############################## mainuser: desktop ###############################

install -d -omainuser -gmainuser ~mainuser/.config

install -omainuser -gmainuser -m644 /dev/stdin \
    ~mainuser/.config/mimeapps.list << 'EOF'
[Added Associations]
text/plain=org.xfce.mousepad.desktop
EOF

install -omainuser -gmainuser -m644 /dev/stdin \
    ~mainuser/.config/initial.dconf << 'EOF'
[org/xfce/mousepad/preferences/view]
show-line-numbers=true

show-right-margin=true
right-margin-position=80

highlight-current-line=true
match-braces=true
word-wrap=true

color-scheme='oblivion'

tab-width=4
insert-spaces=true

auto-indent=true

[org/xfce/mousepad/preferences/window]
statusbar-visible=true
toolbar-visible=true
EOF

install -d -omainuser -gmainuser ~mainuser/.config/autostart

install -omainuser -gmainuser -m644 /dev/stdin \
    ~mainuser/.config/autostart/dconf-load.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=dconf-load
Exec=/bin/sh -ec '/usr/bin/dconf load / < ~/.config/initial.dconf'
NoDisplay=true
EOF

install -omainuser -gmainuser -m644 /dev/stdin \
    ~mainuser/.config/autostart/xrandr-fb.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=xrandr-fb
Exec=/usr/bin/xrandr --fb 1920x900
NoDisplay=true
EOF

install -d -omainuser -gmainuser ~mainuser/.config/pcmanfm{,/LXDE}
install -omainuser -gmainuser -m644 /dev/stdin \
    ~mainuser/.config/pcmanfm/LXDE/pcmanfm.conf << 'EOF'
[ui]
show_hidden=1
EOF

install -omainuser -gmainuser -m644 /dev/stdin \
     ~mainuser/.config/pcmanfm/LXDE/desktop-items-0.conf << 'EOF'
[*]
wallpaper_mode=color
desktop_bg=#3a6ea5
EOF

install -d -omainuser -gmainuser ~mainuser/Desktop

ln -s /data/mainuser ~mainuser/Desktop/persistent
chown -h mainuser:mainuser ~mainuser/Desktop/persistent

############################# mainuser: screenrec ##############################

# cat << 'EOF' > /etc/supervisor/conf.d/screenrec.conf
# [program:screenrec]
# command=/bin/bash /opt/screenrec.sh
# priority=30
# user=mainuser
# EOF

install -omainuser -gmainuser -m700 /dev/stdin /opt/screenrec.sh << 'EOF'
#!/bin/bash

set -e

DATA_DIR=/data/mainuser/screenrec

mkdir -p "$DATA_DIR"

sleep 10

while :; do
    ffmpeg -framerate 3 -f x11grab -i :0.0 \
        -c:v libx265 -crf 40 -preset slow \
        -vf 'scale=iw*2/3:ih*2/3' -t 60 \
        "$DATA_DIR/$(date -u +%Y-%m-%d-%H%M%S).mp4"
done
EOF

################################# USER: alice ##################################

useradd -Ums/bin/bash alice

cat << 'EOF' > /etc/ssh/sshd_config.d/alice.conf
Match User alice
    AllowAgentForwarding no
    AllowTcpForwarding yes
    GatewayPorts no
    X11Forwarding no
    PermitTunnel no
    PermitListen 8001 8002 8003 8004 8005
    PermitOpen any
    PermitTTY no
    ForceCommand echo "This account can only be used for port forwarding"
EOF
install -d -oalice -galice -m700 ~alice/.ssh
appownmod ~alice/.ssh/authorized_keys alice:alice 600 << 'EOF'
(put-public-ssh-key-here)
EOF

################################# USER: bob ##################################

useradd -Ums/bin/bash bob

cat << 'EOF' > /etc/ssh/sshd_config.d/bob.conf
Match User bob
    AllowAgentForwarding no
    AllowTcpForwarding local
    GatewayPorts no
    X11Forwarding no
    PermitTunnel no
    PermitListen none
    PermitOpen 127.0.0.1:8001 127.0.0.1:8002
    PermitTTY no
    ForceCommand echo "This account can only be used for port forwarding"
EOF
install -d -obob -gbob -m700 ~bob/.ssh
appownmod ~bob/.ssh/authorized_keys bob:bob 600 << 'EOF'
(put-public-ssh-key-here)
EOF
