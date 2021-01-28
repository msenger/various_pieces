use Modern::Perl;

my $first = 1;
my @headers;
while (<>) {
    chomp;
    if ($first) {
	$first = 0;
	@headers = split (/\t/);
	next;
    }
    my @content = split (/\t/);
    my $len = (@content >= @headers ? @headers : @content);
    for (my $i = 0; $i < $len; $i++) {
	say $headers[$i], "\t", $content[$i];
    }
    say '';
}
