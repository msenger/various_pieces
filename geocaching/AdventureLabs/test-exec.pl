#!/usr/bin/perl

# auto-flush
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

print $ARGV[0] or print "Hello!\n";
my @args = ("perl", "test-exec.pl", "Ahoj!");
system(@args) == 0
        or die "system @args failed: $?";   

