#!/usr/bin/perl
# Usage: ./make-word-find.pl <number-of-columns> <space-separated-list-of -word>
#
# Martin Senger, martin.senger@gmail.com
# November 2011
# ------------------------------------------------------------------------------
use warnings;
use strict;
use Games::WordFind;

my $cols = $ARGV[0] || 10;
my @words = split (/\s+/, $ARGV[1] || '');
@words = qw(perl camel llama linux great) unless @words;

my $puzzle = Games::WordFind->new ( {cols     => $cols,
				     intersect => 1} );
$puzzle->create_puzzle (@words);
die "Cannot create a puzzle with the given data.\n"
    unless $puzzle->{success};

#
# STDOUT - an input to the word-find.pl solver
#
print STDOUT "# Created: " . localtime() . "\n";
my @dropped = sort keys %{ $puzzle->{dropped} };
print STDOUT "# Warning - dropped words: " . join (', ', @dropped) . "\n"
    if @dropped;
print STDOUT join ("\n", map { s{^\s*|\s*$}{}g; $_ } @{ $puzzle->{words} }) . "\n";
print "=\n";

foreach my $row (@{ $puzzle->{puzzle} }) {
    print STDOUT join ('', @$row) . "\n";
}

#
# STDERR - a plain definition
#
print STDERR $puzzle->get_plain();
print STDERR "\n";

#
# STDERR - a plain solution
#
print STDERR "                Solution:\n";
print STDERR "                ---------\n";
foreach my $row (@{ $puzzle->{lattice} }) {
    print STDERR join (' ', @$row) . "\n";
}
