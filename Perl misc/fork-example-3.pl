#!/usr/bin/perl
#
# The same as fork-example-1 but now using Parallel::ForkManager that
# allows to start only pre-defined number of parallel processes and
# then it waits before forking other processes.
#

use warnings;
use strict;
use Parallel::ForkManager;

my $number_of_all_processes = 25;      # this is the number of all child processes I want to start
my $number_of_parallel_processes = 5;  # this is the maximum number of child processes in parallel

my $pm = new Parallel::ForkManager ($number_of_parallel_processes);
foreach my $item (1..$number_of_all_processes) {

    # this does the fork and for the parent branch it continues in the foreach loop
    $pm->start and next;

    # this is the child branch - sleeping for a while
    print "A child process $item started\n";
    my $how_long_to_sleep = int (rand (4)) + 1;   # an interval <1,5>
    sleep $how_long_to_sleep;
    print "A child process $item finished after sleeping for $how_long_to_sleep seconds\n";
    $pm->finish;  # this is a replacement of the regular exit(0)

}

# here the parent branch continue when all child process have been
# started; we need to wait untill all these processes finish -
# otherwise we would create a "zombie" process in out operating
# system
$pm->wait_all_children();
