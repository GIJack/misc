#!/bin/bash
#
# Simple script to stream your desktop to a fake webcam.
# adapted from here https://unix.stackexchange.com/questions/5452/manipulating-dev-video
# GI_Jack. GPLv3

##CONFIG
RESOLUTION="1920x1080"
DEVICE="/dev/video1"
FRAMERATE=15
##END CONFIG

exit_with_error() {
    echo "stream_desktop.sh: $(tput bold;tput setaf 1)ERROR:$(tput sgr0) $2"
    exit $1
}

#Lets check if the module loads correctly.
sudo moprobe v4l2loopback
declare -i module_status=$?

case $module_status in
    0)
      true
      ;;
    *)
      exit_with_error 1 "cannot probe v4l2loopback module make sure its installed"
      
esac

ffmpeg -f x11grab -r $FRAMERATE -s $RESOLUTION -i ${DISPLAY}+0,0 -vcodec rawvideo -pix_fmt yuv420p -threads 0 -f v4l2 $DEVICE

