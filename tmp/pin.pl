#!/usr/bin/perl
#
# Author: martin.senger@gmail.com
#
# ABSTRACT: test 2100010006
# PODNAME: pin.pl
#------------------------------------------

use strict;
use warnings;

use Data::Dumper;

select (STDOUT); $| = 1;
print "\n";

my $start = 2000999999;  # 0000000000;
my $stop  = 2200000000;  # 9999999999;
my $all_count = $stop - $start;
my @idx_pin = (1, 2, 3, 4, 5, 6, 7, 8, 9, 0);  # what mean the positions in the pin

MAIN: foreach my $num ($start..$stop) {

    # just to show how far we got so far
    if ($num % 1000 == 0) {
	my $proc = ($num - $start) * 100 / $all_count;
	print sprintf ("\r%.2f %%\r", $proc);
    }

    # make an array of all digits
    my @digits = split (//, sprintf ("%.10d", $num));

    # only cases when the sum of all ddigits is equal 10
    my $sum = 0;
    foreach my $digit (@digits) {
	$sum += $digit;
	next MAIN if $sum > 10;
    }
    next MAIN unless $sum == 10;

    # make a hash where keys are digits in the PIN and values are frequencies of these digits
    my $freq = {
	'1' => 0, '2' => 0, '3' => 0, '4' => 0, '5' => 0,
	'6' => 0, '7' => 0, '8' => 0, '9' => 0, '0' => 0,
    };
    foreach my $digit (@digits) {
	$freq->{$digit}++;
    }

    # now test the rules for each digit in the PIN
    for (my $i = 0; $i <= $#digits; $i++) {
	
        # next if a digit appears in the PIN but not in the wanted amount
	next MAIN unless $freq->{$idx_pin[$i]} == $digits[$i];

    }

    print "\r$num\n";
#    print Dumper \@digits;
#    print Dumper $freq;
#    exit 0;
    
}



