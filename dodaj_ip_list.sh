#!/bin/bash

# Utworzenie pliku ip_list.txt z zakresem adresów IP
for i in {0..1}
do
    for j in {1..254}
    do
        echo "192.168.$i.$j:IP_$i_$j" >> ip_list.txt
    done
done