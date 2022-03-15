use warnings;
use strict;

my $word = $ARGV[0] || "Sluncova";
my $clean_word = $word; $clean_word =~ s{[^a-zA-Z]}{}g;

my @letters = split (//, $clean_word);
my @numbers = map { ord (uc ($_)) - 64 } @letters;
print join ('|', @numbers), "\n";
my $total = 0;
$total += $_ foreach @numbers;
print "$word: $total\n";
print "Letters: " . (0+@letters) . "\n";