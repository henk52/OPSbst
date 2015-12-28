#!/bin/bash


rsync -vaH --filter=". fedora_filters_22.txt"  --numeric-ids --delete rsync://dl.fedoraproject.org/fedora-enchilada /var/ks/mirrors/f22
