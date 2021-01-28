#!/usr/bin/env perl
#
# Usage: zipcrack password.list zip.file   TBD
#
# December 2012
# Martin Senger <martin.senger@gmail.com>
# --------------------------------------------

use warnings;
use strict;
use File::Slurp qw{ read_file };
use File::Temp qw{ tempdir };
use File::Path qw{ remove_tree };

my $dictfile = $ARGV[0];
my @pass = read_file ($dictfile);
die "Error reading '$dictfile'\n"
    if @pass == 1 and $pass[0] eq undef;

my $zipfile = $ARGV[1];
my $result_dir = tempdir ( CLEANUP => 1 );

my @args = ('unzip', '-qq', '-d', $result_dir, '-P');
my $count = 0;
foreach my $passwd (@pass) {
    $count++;
    chomp $passwd;
    my $exit = system (@args, $passwd, $zipfile);
    if ($exit == 0) {
	print "BINGO (count: $count): $passwd\n";
	exit (0);
    }
    remove_tree ($result_dir, {keep_root => 1});
}
print "Tried unsuccessfully $count passwords (taken from '$dictfile').\n";
