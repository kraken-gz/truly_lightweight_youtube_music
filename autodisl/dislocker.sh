#!/bin/bash
part=""
i=0
drives=( $(sudo blkid | awk '{print substr($1, 0, length($1) - 1)}') )

for drive in "${drives[@]}"; do
    sudo dd if=$drive bs=128 count=1 status=none | hexdump -C | grep -q FVE-FS && bl[$i]=${drive} && ((i++))
done

if [[ ${#bl[@]} == 0 ]]; then
    echo "Bitlocker drive not found."
    exit
elif [[ ${#bl[@]} == 1 ]]; then
    read -n 1 -p "Unlock ${bl[0]}? [Y/n] " conf
    if [ "$conf" != "" ]; then echo; fi
    if [ "$conf" = "${conf#[Nn]}" ]; then
        part=${bl[0]}
    fi
else
    echo "Available drives:"
    i=0
    for d in "${bl[@]}"; do
        echo "$((i+1)). $d"
        ((i++))
    done
    read -n 1 -p "Drive to unlock [1-${#bl[@]}] " ans
    if [ "$ans" != "" ]; then echo; fi
    part=${bl[$((ans-1))]}
fi
if [[ $part != "" ]]; then
    echo -n "User password for $part:"
    echo
    read -s pass
    sudo dislocker $part -u$pass -- /media/bitlocker
    sudo mount -o loop /media/bitlocker/dislocker-file /media/bitlockermount
    echo "$part unlocked."
    xdg-open /media/bitlockermount
else
    echo "Nothing done."
fi