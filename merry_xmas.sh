#!/bin/bash
# some fun with LED lights.

# I got bored one long december night and wrote this small script

# GI_Jack. License: GPLv3 https://www.gnu.org/licenses/gpl-3.0.html

trap_escape() {
    echo "fuck this, get some work done"
    exit
}
trap "trap_escape" SIGTERM SIGINT

# Blank the LEDs, and test them three times
setleds -num -caps -scroll
for i in {1..3};do
    setleds +num +caps +scroll
    sleep .33
    setleds -num -caps -scroll
    sleep .33
done

loop=false
while [ $loop != true ];do
    setleds +num -caps -scroll
    sleep .33
    setleds -num +caps -scroll
    sleep .33
    setleds -num -caps +scroll
    sleep .33
done
