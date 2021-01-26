#!/usr/bin/perl

my $msg = "Bylo zbytecne sem chodit :-). Ale bylo to osvezujici, vcetne zbytecneho cteni hexiku. Velke diky, pripomelo mi to Vanoce.";
$msg =~ s{(.)}{sprintf '%02x ', ord $1}seg;
print "$msg\n";

