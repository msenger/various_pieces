#!/usr/bin/env perl
#
# -----------------------------------------------------------------
use warnings;
use strict;

use PPI::Document;
use PPI::Dumper;
use File::Which;

# Load a document
my $Document = PPI::Document->new ($0);

# Dump the dumper
#my $Dumper = PPI::Dumper->new ($Document, whitespace => 0);
#$Dumper->print;

my $comment = $Document->find_first ('PPI::Token::Comment');
chomp $comment;

my $which = which('perl');

print
    "PERL (\$^V): $^V, " . $] . "\n" .
    "PERL (\$^X): $^X\n" .
    "BANG:        $comment\n" .
    "WHICH:       $which\n";
