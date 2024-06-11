#!/bin/bash
grep "OK DOWNLOAD" cdlinux.ftp.log | wc -l | grep "\.iso" | cut -d"\"" -f 2,4 |  sort -u | grep "cdlinux-.*" -o > text.txt
grep "GET" cdlinux.www.log | grep "\.iso" | cut -d" " -f 1,7 | sort -u | cut -d ":" -f 2 | grep "cdlinux-.*" -o >> text.txt
sort text.txt | uniq -c >> output.txt

