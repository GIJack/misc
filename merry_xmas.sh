#!/bin/bash
#some fun with LED lights
# GI_Jack. License: GPLv3 https://www.gnu.org/licenses/gpl-3.0.html

#Blank the LEDs, and test them three times
setleds -num -caps -scroll
for i in {1..3};do
    setleds +num +caps +scroll
    sleep .33
    setleds -num -caps -scroll
    sleep .33
done

loop=lies
while [ $loop != truth ];do
    setleds +num -caps -scroll
    sleep .33
    setleds -num +caps -scroll
    sleep .33
    setleds -num -caps +scroll
    sleep .33
done
