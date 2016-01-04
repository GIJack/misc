#!/bin/bash
# GPLv3
# This script is a small snippet that gives debugging information about
# Connected X displays. it displays virtual and physical sizes, and calculates
# DPI for each attached monitor

MonList=( $(xrandr |grep " connected"|cut -d " " -f 1) )
    for mon in ${MonList[@]};do
        # grep the output of xrandr for info on one monitor.
        xrandr_string=$(xrandr |grep ${mon})
        xr_err=$?
        if [ ${xr_err} -ne 0 ];then
            EXIT+=$xr_err
            continue_with_error "Can't get sizing information for ${mon}"
            continue
        fi

        # resolution in pixels
        res=$(echo $xrandr_string |cut -d " " -f 3|cut -d "+" -f 1)
        res=${res##*( )}
        if [ "$res" == "primary" ];then
            res=$(echo $xrandr_string |cut -d " " -f 4|cut -d "+" -f 1)
            res=${res##*( )}
        fi
        x_res=$(echo $res|cut -d "x" -f 1)
        y_res=$(echo $res|cut -d "x" -f 2)

        # physical size in milimeters
        size=$(echo $xrandr_string |cut -d ")" -f2)
        size=${size##*( )}
        x_size=$(echo $size|cut -d "x" -f 1| sed 's/mm //g')
        y_size=$(echo $size|cut -d "x" -f 2| sed 's/mm//g')
        y_size=${y_size##*( )}
        # millimeters! whats a millimeter? We need to convert this communist
        # horseshit into freedom units:
        x_size=$(($x_size / 25 ))
        y_size=$(($y_size / 25 ))

        # fuck thats done, I need a beer. the ${var##*( )} is how bash strips
        # spaces. At this point its safe to say "easier done in a real lang,
        # where standard functionality is not an esoteric command". Nonsense I
        # say. This is Arch Linux, Bash scripting is a sacred artform. I do
        # bash-fu. In python this is simply string.strip(" ")

        # Now we compute DPI. Special thanks to xionyc for not sucking at math.
        dpi=$(( ( (${x_res}/${x_size}) + (${y_res}/${y_size}) ) / 2 ))

echo "Monitor:${mon}"
echo "resolution:${res}"
echo "x_res:${x_res}"
echo "y_res:${y_res}"
echo "size:$size"
echo "x_size:$x_size"
echo "y_size:$y_size"
echo "dpi:$dpi"
echo ""

    done
