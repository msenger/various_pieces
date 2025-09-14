#!/usr/bin/perl

use strict;
use warnings;

#------------------------------------------
# Command-line arguments and script usage
#------------------------------------------
my ($opt_help, $opt_stdout, $opt_stderr);

BEGIN {

   sub usage {
	    print STDERR <<"END_OF_USAGE";
Usage:
   $0 [volby]

      [volby] mohou byt:
         -h      ...  vypise tento help text a skonci
         -stdout ...  napise neco na STDOUT
         -stderr ...  napise neco na STDERR    
                 
END_OF_USAGE
   }

   # auto-flush
   select(STDERR); $| = 1;
   select(STDOUT); $| = 1;

   use Getopt::Long;
   Getopt::Long::Configure ('no_ignore_case');
   GetOptions ( help    => \$opt_help,
                stdout  => \$opt_stdout,
                stderr  => \$opt_stderr,
                 
   ) or usage() and exit(1);
   usage() and exit(0) if $opt_help;

}  # end of BEGIN

print STDOUT "Tohle pisi na STDOUT\n" if $opt_stdout;
print STDERR "Tohle pisi na STDERR\n" if $opt_stderr;

__END__
