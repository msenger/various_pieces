#!/usr/bin/perl
#
# The same as fork-example-1, except that the child processes are
# replaced by an external program (again the 'sleep' program).
#

my $number_of_parallel_processes = 5;
my @children = ();
foreach my $item (1..$number_of_parallel_processes) {

    my $pid = fork();

    if ($pid) {
	# this branch is executed in the parent process: we do
	# nothing, except remembering the PID of the newly forked
	# child
	push (@childern, $pid);

    } elsif ($pid == 0) {
	# this branch is executed in the just started child process:
	# we sleep here for a random time
	print "A child process $item started\n";
	my $how_long_to_sleep = int (rand (4)) + 1;   # an interval <1,5>
	exec ("sleep $how_long_to_sleep") or print STDERR "Couldn't exec sleep: $!";

    } else {
	# this branch is executed only when there is an error in the
	# forking, e.g. the system does not allow to fork any more
	# process
	warn "I couldn't fork process $item: $!\n";
    }
}

# show what processes were started
print system ('ps -f');

# here the parent branch continue when all child process have been
# started; we need to wait untill all these processes finish -
# otherwise we would create a "zombie" process in out operating
# system
foreach my $child (@childern) {
    waitpid ($child, 0);
}
