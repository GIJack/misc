#!/usr/bin/env bash

# I wrote this doing hackerrank exceriszes where rounding precision on math
# equations, and decimal precision between bc and whatever they used left
# something to be desired. This rounds up so you can pass the test. Does a math
# equation with bc, but rounds up.

# Fill this out
equation="" #Put your math equation here.
scale=4 # should be one greater than you need. Gets the next digit to compute
        # Rounding
# /options

number=$(echo "scale=${scale};${equation}"| bc -l)
i=$((${#number}-1))
last_digit=${number:$i:1}

i=$(( $i - 1))
second_last_digit=${number:$i:1}

number=${number:0:$i}

ext=""
if [ $last_digit -ge 5 ];then
  ext=$((${second_last_digit} + 1))
 elif [ $last_digit -lt 5 ];then
  ext=${second_last_digit}
fi
number="${number}${ext}"

echo $number
