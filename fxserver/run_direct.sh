#!/bin/bash

# save the script directory
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

# run server without txAdmin 
exec $SCRIPTPATH/alpine/opt/cfx-server/ld-musl-x86_64.so.1 \
    --library-path "$SCRIPTPATH/alpine/usr/lib/v8/:$SCRIPTPATH/alpine/lib/:$SCRIPTPATH/alpine/usr/lib/" -- \
    $SCRIPTPATH/alpine/opt/cfx-server/FXServer +set citizen_dir $SCRIPTPATH/alpine/opt/cfx-server/citizen/ +set sv_licenseKey cfxk_2CoIidtbhW6hqrOmN2OZ_MIwa8 +exec /workspaces/fivem/server-data/server.cfg +set gamename gta5 $*