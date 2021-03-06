#!/bin/bash
# bash is needed for proper handling of password prompt.

# this script is now called at the end of the
# OS bootup procedure (getty)

set -e
LIVE_SCRIPTS_DIR=/opt/debootstick
INIT_SCRIPTS_DIR=$LIVE_SCRIPTS_DIR/init
. /dbstck.conf                  # for config values
. $LIVE_SCRIPTS_DIR/tools.sh    # for functions

# if error, run a shell
trap '[ "$?" -eq 0 ] || fallback_sh' EXIT

# ask and set the root password if needed
if [ "$ASK_ROOT_PASSWORD_ON_FIRST_BOOT" = "1" ]
then
    ask_and_set_pass
fi

# run initialization script
$INIT_SCRIPTS_DIR/occupy-space.sh

# restore the lvm config as it was in the
# initial chroot environment
restore_lvm_conf
