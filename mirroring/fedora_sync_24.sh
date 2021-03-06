#!/bin/bash

# http://superuser.com/questions/156664/what-are-the-differences-between-the-rsync-delete-options
# --delete-after: Receiver deletes after transfer, not before...If some other part of the rsync moved extra files elsewhere, you'd want this instead of --delete-delay, because --delete-delay decides what it's going to delete in the middle of transfer, whereas --delete-after checks the directory for files that should be deleted AFTER everything is finished.

rsync -vaH --filter=". fedora_filters_24.txt"  --numeric-ids --delete-after rsync://dl.fedoraproject.org/fedora-enchilada /var/ks/mirrors/fedora24
