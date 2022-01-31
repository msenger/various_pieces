use warnings;
use strict;

print "Usage: perl summa.pl <coordinates>\n" and exit (0) unless $ARGV[0];
my $input = $ARGV[0];

my $count = 0;
while ($input =~ m{(\d)}g) {
    $count += $1;
}
my $dr = 1 + (($count - 1) % 9);
print "Input:                      $input\n";
print "Digit sum (ciferny soucet): $count\n";
print "Digital root (ciferace):    $dr\n";
