#!/usr/bin/perl -w

use strict;
use Data::Dumper;


use Test::More tests => 4;

use KickstartConfig;


my %hFinishedValues;

$hFinishedValues{"BootDistroName"} = "gentoo";
$hFinishedValues{"BootDistroId"} = "14";
$hFinishedValues{"Architechture"} = "x86_64";
$hFinishedValues{"BS_CONFIG_BASE_DIRECTORY"} = "/var/ks/configs";
$hFinishedValues{"BS_RELATIVE_CONFIG_DIRECTORY"}  = "/configs";
$hFinishedValues{"BS_NFS_BASE_PATH"}              = "/var/ks";
$hFinishedValues{"BS_RELATIVE_IMAGE_DIRECTORY"}              = "/images";
$hFinishedValues{"InstallMedia"} = "http";
$hFinishedValues{"relative_install_image_path"} = "gentoo_28_i386";
ok(GenerateKickstartFile(\%hFinishedValues, "tmpKs_http.cfg"));
unlink("tmpKs_http.cfg");

$hFinishedValues{"--externalcfg"} = "unit_tests/external_ks.cfg";
ok(KscTranslateExternalKsCfgFile(\%hFinishedValues, "tmp_Ks_http_ext.cfg"));
unlink("tmp_Ks_http_ext.cfg");

$hFinishedValues{"InstallMedia"} = "nfs";
ok(GenerateKickstartFile(\%hFinishedValues, "tmpKs_nfs.cfg"));
unlink("tmpKs_nfs.cfg");

ok(KscTranslateExternalKsCfgFile(\%hFinishedValues, "tmp_Ks_nfs_ext.cfg"));
unlink("tmp_Ks_nfs_ext.cfg");




