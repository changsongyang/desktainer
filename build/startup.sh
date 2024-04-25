#!/bin/bash

set -e

################################## VARIABLES ###################################

resolution=${RESOLUTION:-1920x1080}

mainuser_name=${MAINUSER_NAME:-mainuser}
mainuser_pass=${MAINUSER_PASS:-mainuser}
unset MAINUSER_PASS

vnc_pass=${VNC_PASS:-}
unset VNC_PASS
vnc_port=${VNC_PORT:-5901}
novnc_port=${NOVNC_PORT:-6901}

################### INCLUDE SCRIPTS FROM /opt/startup-early ####################

for i in /opt/startup-early/*.sh; do
    [ -f "$i" ] || continue
    # shellcheck source=/dev/null
    . "$i"
done

################################## MAIN USER ###################################

if [ "$mainuser_name" = root ]; then
    echo 'The main user is root'
    mainuser_home=/root
else
    mainuser_home=/home/$mainuser_name

    # If the user already exists
    if id "$mainuser_name" >/dev/null 2>&1; then
        echo "User $mainuser_name already exists"

        if [ ! -d "$mainuser_home" ]; then
            echo "Creating home directory $mainuser_home"
            install -d -o"$mainuser_name" -g"$mainuser_name" "$mainuser_home"
        fi
    else
        echo "Creating user $mainuser_name"
        useradd -UGsudo -ms/bin/bash "$mainuser_name"

        echo "Setting the main user's password"
        echo "$mainuser_name:$mainuser_pass" | chpasswd
    fi
fi

##################### SUPERVISORD CONFIG MAIN REPLACEMENTS #####################

sed -i "s/%vnc_port%/$vnc_port/g" /etc/supervisor/supervisord.conf
echo "VNC port set to $vnc_port"

sed -i "s/%novnc_port%/$novnc_port/g" /etc/supervisor/supervisord.conf
echo "noVNC port set to $novnc_port"

sed -i "s/%resolution%/$resolution/g" /etc/supervisor/supervisord.conf
echo "Resolution set to $resolution"

# Note: we use the pipe character as delimiter in the expression #2 because the
# $mainuser_home variable contains slashes
sed -i "s/%mainuser_name%/$mainuser_name/g;s|%mainuser_home%|$mainuser_home|g" \
    /etc/supervisor/supervisord.conf

############################# VNC SERVER PASSWORD ##############################

if [ -n "$vnc_pass" ]; then
    if [ ! -f "$mainuser_home/.vnc/passwd" ]; then
        echo "Storing the VNC password into $mainuser_home/.vnc/passwd"

        install -d -o"$mainuser_name" -g"$mainuser_name" "$mainuser_home/.vnc"

        # Store the password encrypted and with 400 permissions
        x11vnc -storepasswd "$vnc_pass" "$mainuser_home/.vnc/passwd"
        chown "$mainuser_name:$mainuser_name" "$mainuser_home/.vnc/passwd"
        chmod 400 "$mainuser_home/.vnc/passwd"
    fi

    sed -i "s/%vncpwoption%/-usepw/" /etc/supervisor/supervisord.conf
    echo 'VNC password set'
else
    sed -i "s/%vncpwoption%/-nopw/" /etc/supervisor/supervisord.conf
    echo 'VNC password disabled'
fi

############################# CLEAR Xvfb LOCK FILE #############################

rm -f /tmp/.X0-lock

#################### INCLUDE SCRIPTS FROM /opt/startup-late ####################

for i in /opt/startup-late/*.sh; do
    [ -f "$i" ] || continue
    # shellcheck source=/dev/null
    . "$i"
done

############################## START SUPERVISORD ###############################

# Start supervisord with "exec" to let it become the PID 1 process. This ensures
# it receives all the stop signals correctly and reaps all the zombie processes
# inside the container
echo 'Starting supervisord'
exec /usr/bin/supervisord -nc /etc/supervisor/supervisord.conf
