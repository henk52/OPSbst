#!/usr/bin/perl -w
use strict;


my $f_szPkgListName = "missing_packages_from_fedora_20.txt";

my $f_szDestinationDir = "erepo";

if ( ! -d $f_szDestinationDir ) {
  `mkdir $f_szDestinationDir`;
}

open(PKG_LIST, "<$f_szPkgListName") || die("!!! Unable to open file for read - $f_szPkgListName: $!");

while(<PKG_LIST>) {
  chomp;

my $szCmd = "yumdownloader --destdir $f_szDestinationDir --resolve $_";
  print "III execute: $szCmd\n";
  `$szCmd`;
  print "!!! Failed to download '$_'\n" unless($? == 0);
}

`tar -zcvf fedora_20_extra_repo.tgz $f_szDestinationDir`;

close(PKG_LIST);


