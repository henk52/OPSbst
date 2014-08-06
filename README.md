# Introduction

## Purpose
This tools set is used for administrating a linux bootserver.

# Installation

# Usage

* Associate boot installation configuration to MAC address.
* Import ISOs for boot repos.
* 

## Importing a Distro image.
* clear; sudo ./importiso.pl --distro fedora --release 20 /vagrant/isos/Fedora-20-x86_64-DVD.iso
* clear; sudo ./bootmgmt.pl add --mac 080027346180  --distro fedora --release 19 --arch x86_64 --media nfs

## Creating a youmdownload configuration:
clear; sudo ./bootmgmt.pl update --mac 080027600349  --distro fedora --release 20  --arch x86_64  --media nfs --role yumdownload


## Running the YumDownloader to get e.g. puppet.
1. Set-up the default boot env:
    * clear; sudo ./bootmgmt.pl add --mac 080027346180  --distro fedora --release 19 --arch x86_64 --media nfs
2. boot the VirtualBox with netboot.
3. Shutdown the virtualbox, when done.
4. Change the network to NAT
    * (I have nic0 disabled when net-booting
    * Then disabling nic1 (for boot server)
    * :w
and enabling nic0
5. Boot up virtualbox.
6. Login as root
7. set PROXY (if needed)
    * export http_proxy=http...
    * export https_proxy=http...
8. mkdir repo
9. yumdownloader --destdir erepo --resolve puppet
    * yumdownloader --destdir erepo --resolve --archlist=x86_64
10. yumdownloader --destdir erepo --resolve erlang
11. tar -zcvf fedora_20_extra_repo.tgz erepo
12. shutdown -h now
13. shift the nics around so that the VirtualBox can connect to the boot server again.
14. power up the virtualbox
15. ping bootserver
16. scp fedora_20_extra_repo.tgz admAccount@bootserver:/tmp
17. login to bootserver 
18. cd /tmp
19.  tar -zxvf f20_extra_repo.tgz
20.  cd /opt/OPSbst/bin/
21. sudo ./repoimport.pl  --distro fedora --release 20 --srcdir /tmp/erepo
 
:old_method:
mkdir fedora_20_x86_64
cp /var/ks/images/fedora_20_x86_64/repodata/*filelists.xml.gz .
gzip -d *filelists.xml.gz
cp /tmp/fedora_20_extra_repo.tgz .
tar -zxf fedora_20_extra_repo.tgz

# Extra packages

For Vagrant:
* puppet
* augeas
* dkms
 

For erlang:
* erlang

For SW router:
* quagga

