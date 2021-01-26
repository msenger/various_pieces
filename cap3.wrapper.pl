#!/usr/bin/perl -w 
#
# Martin Senger <martin.senger@gmail.com>
# ---------------------------------------

use strict;
use Getopt::Std;
use vars qw/ $opt_H $opt_I $opt_q $opt_C $opt_A $opt_G $opt_Q $opt_L $opt_F $opt_S $opt_R /;

$Getopt::Std::STANDARD_HELP_VERSION = 'true';
getopts ('HI:q:C:A:G:Q:L:F:S:R:');

sub HELP_MESSAGE() {
    print STDOUT <<'END_OF_USAGE';
cap3 seq [cap3-options]
     other (optional) inputs:
seq.qual
seq.con
     outputs:
standard output
seq.cap.ace
seq.cap.contigs
seq.cap.contigs.qual
seq.cap.contigs.links
seq.cap.info
seq.cap.singlets
seq.con.cap.results

cap3_wrapper
     -I seq
     -q seq.qual
     -C seq.con

     -A seq.cap.ace
     -G seq.cap.contigs
     -Q seq.cap.contigs.qual
     -L seq.cap.contigs.links
     -F seq.cap.info
     -S seq.cap.singlets
     -R seq.con.cap.results

Other:
-H ... help
END_OF_USAGE
    exit (0);
}

HELP_MESSAGE() if $opt_H;

# -----------------------------------------------------------

# -- change the input arguments
die "Required input file (option -I) is missing\n" unless defined $opt_I;
#my @cmdline = ('/home/senger/Software/CAP3/cap3', $opt_I);
my @cmdline = ('cap3', $opt_I);
push (@cmdline, @ARGV);

my $inp_qual = $opt_I . '.qual';
`cp $opt_q $inp_qual` if defined $opt_q && -e $opt_q;
my $inp_con = $opt_I . '.con';
`cp $opt_C $inp_con` if defined $opt_C && -e $opt_C;

# -- call the real cap3
system (@cmdline) == 0
    or die "Calling cap3 with the command line [" . join (" ", @cmdline) . "] failed: $?\n";

# -- rename cap3's outputs
my $out_ace = $opt_I . '.cap.ace';
`mv $out_ace $opt_A` if -e $out_ace && defined $opt_A;
my $out_contigs = $opt_I . '.cap.contigs';
`mv $out_contigs $opt_G` if -e $out_contigs && defined $opt_G;
my $out_qual = $opt_I . '.cap.contigs.qual';
`mv $out_qual $opt_Q` if -e $out_qual && defined $opt_Q;
my $out_links = $opt_I . '.cap.contigs.links';
`mv $out_links $opt_L` if -e $out_links && defined $opt_L;
my $out_info = $opt_I . '.cap.info';
`mv $out_info $opt_F` if -e $out_info && defined $opt_F;
my $out_singlets = $opt_I . '.cap.singlets';
`mv $out_singlets $opt_S` if -e $out_singlets && defined $opt_S;
my $out_results = $opt_I . '.con.cap.results';
`mv $out_results $opt_R` if -e $out_results && defined $opt_R;
