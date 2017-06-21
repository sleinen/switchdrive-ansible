alias mntdf="df /mnt/*| sort -nk 4"
alias mntNumUsers='for dir in `ls /mnt/ ` ; do echo -n /mnt/$dir:; cd /mnt/$dir; find . -maxdepth 1 -type d | wc -l;done'
