#!/usr/bin/perl

use warnings;
use strict;

# directions of matched words
use constant {
    HOR_FORW => '--> (1)',
    HOR_BACK => '<-- (2)',
    VER_FORW => '|   (3)',
    VER_BACK => '^   (4)',
    SE_FORW  => '\,  (5)',
    SE_BACK  => '\'\\  (6)',
    SW_FORW  => '\'/  (7)',
    SW_BACK  => ',/  (8)',

    # ...and this is returned if the plugin cannot be started
    RETURN_FATAL    => -1,
};

# some globals
my $grid_orig = [];
my $grid_solved = [];
my $grid_rows;
my $grid_cols;

# read the puzzle definition
my @words = ();
my $in_words = 1;
while (my $line = <>) {
    chomp ($line);
    $line =~ s{^\s*|\s*$}{}g;   # trim whitespaces
    next unless $line;          # ignore empty lines
    next if $line =~ m{^#};     # ignore comments
    if ($line =~ m{^=}) {
	$in_words = 0;
	next;
    }
    if ($in_words) {
	push (@words, split (/\s*,\s*/, $line));
    } else {
	push (@$grid_orig, [ split (//, $line) ] );
	push (@$grid_solved, [ split (//, $line) ] );
    }
}
my @sorted_words = sort {length $b <=> length $a} @words;
#my @sorted_words = sort {$b <=> $a} @words;
##fisher_yates_shuffle (\@sorted_words);   # randomizing
my $max_word_len = length $sorted_words[0];
my $format_placed = "'%-${max_word_len}s' placed at [%2d,%2d] %s\n";
my $format_not_placed = "'%-${max_word_len}s' was not placed\n";

$grid_rows = @$grid_orig;
# TBD: make sure that the grid is not empty (without any filled rows)
# TBD: make sure that the grid is a rectangle by adding spaces where needed
$grid_cols = @{ $grid_orig->[0] };

# print the puzzle definition
print STDOUT title ("Words:");
print join ("\n", @sorted_words) . "\n";
print "\n";

print STDOUT title ("Grid [$grid_rows x $grid_cols]:");
foreach my $row (@$grid_orig) {
    print join (' ', @$row) . "\n";
}
print "\n";

# solve the puzzle
print STDOUT title ("Solved placements:");
foreach my $word (@sorted_words) {
    my $found = find_matching_position ($word);
    if ($found) {
	printf ($format_placed, $word, @$found);
    } else {
	printf ($format_not_placed, $word);
    }
}
print "\n";

# show solution
print STDOUT title ("Remaining characters:");
foreach my $row (@$grid_solved) {
    print join (' ', @$row) . "\n";
}
print "\n";
my $msg = '';
foreach my $row (@$grid_solved) {
    $msg .= join ('', @$row);
}
$msg =~ s{\s}{}g;
print "$msg\n";


sub find_matching_position {
    my @word = map { uc($_) } split (//, shift);
    my @reverse_word = reverse @word;
    my $word_len = @word;
    for (my $r = 0; $r < $grid_rows; $r++) {
	for (my $c = 0; $c < $grid_cols; $c++) {
	    
	    if ($r + $word_len <= $grid_rows) {
		# try vertical direction
		return [$r, $c, VER_FORW]             if matched_vertically (\@word, $r, $c);
		return [$r+$word_len-1, $c, VER_BACK] if matched_vertically (\@reverse_word, $r, $c);
		if ($c - $word_len >= -1) {
		    # try south-west diagonal direction
		    return [$r, $c, SW_FORW]                         if matched_sw_diagonally (\@word, $r, $c);
		    return [$r+$word_len-1, $c-$word_len+1, SW_BACK] if matched_sw_diagonally (\@reverse_word, $r, $c);
		}
	    }

	    if ($c + $word_len <= $grid_cols) {
		# try horizontal direction
		return [$r, $c, HOR_FORW]             if matched_horizontally (\@word, $r, $c);
		return [$r, $c+$word_len-1, HOR_BACK] if matched_horizontally (\@reverse_word, $r, $c);
		if ($r + $word_len <= $grid_rows) {
		    # try south-east diagonal direction
		    return [$r, $c, SE_FORW]                         if matched_se_diagonally (\@word, $r, $c);
		    return [$r+$word_len-1, $c+$word_len-1, SE_BACK] if matched_se_diagonally (\@reverse_word, $r, $c);
		}
	    }
#	    if ($r + $word_len <= $grid_rows) {
#		# try vertical direction
#		return [$r, $c, VER_FORW]             if matched_vertically (\@word, $r, $c);
#		return [$r+$word_len-1, $c, VER_BACK] if matched_vertically (\@reverse_word, $r, $c);
#		if ($c - $word_len >= -1) {
#		    # try south-west diagonal direction
#		    return [$r, $c, SW_FORW]                         if matched_sw_diagonally (\@word, $r, $c);
#		    return [$r+$word_len-1, $c-$word_len+1, SW_BACK] if matched_sw_diagonally (\@reverse_word, $r, $c);
#		}
#	    }
	}
    }
    return undef;
}

# try horizontal direction (no need to check that the word is not too long)
sub matched_horizontally {
    my ($word, $r, $c) = @_;
    my $word_placed = 1;
    for (my $i = 0; $i < @$word; $i++) {
	if ($word->[$i] ne $grid_orig->[$r]->[$c+$i]) {
	    $word_placed = 0;
	    last;
	}
    }
    if ($word_placed) {
	# erase matching word - unless already fully erased
	my $already_erased = 1;
	for (my $i = 0; $i < @$word; $i++) {
	    $already_erased = 0 if $grid_solved->[$r]->[$c+$i] ne ' ';
	    $grid_solved->[$r]->[$c+$i] = ' ';
	}
	return 0 if $already_erased;
    }
    return $word_placed;
}

# try vertical direction (no need to check that the word is not too long)
sub matched_vertically {
    my ($word, $r, $c) = @_;
    my $word_placed = 1;
    for (my $i = 0; $i < @$word; $i++) {
	if ($word->[$i] ne $grid_orig->[$r+$i]->[$c]) {
	    $word_placed = 0;
	    last;
	}
    }
    if ($word_placed) {
	# erase matching word - unless already fully erased
	my $already_erased = 1;
	for (my $i = 0; $i < @$word; $i++) {
	    $already_erased = 0 if $grid_solved->[$r+$i]->[$c] ne ' ';
	    $grid_solved->[$r+$i]->[$c] = ' ';
	}
	return 0 if $already_erased;
    }
    return $word_placed;
}

# try south-east diagonal direction (no need to check that the word is not too long)
sub matched_se_diagonally {
    my ($word, $r, $c) = @_;
    my $word_placed = 1;
    for (my $i = 0; $i < @$word; $i++) {
	if ($word->[$i] ne $grid_orig->[$r+$i]->[$c+$i]) {
	    $word_placed = 0;
	    last;
	}
    }
    if ($word_placed) {
	# erase matching word - unless already fully erased
	my $already_erased = 1;
	for (my $i = 0; $i < @$word; $i++) {
	    $already_erased = 0 if $grid_solved->[$r+$i]->[$c+$i] ne ' ';
	    $grid_solved->[$r+$i]->[$c+$i] = ' ';
	}
	return 0 if $already_erased;
    }
    return $word_placed;
}

# try south-west diagonal direction (no need to check that the word is not too long)
sub matched_sw_diagonally {
    my ($word, $r, $c) = @_;
    my $word_placed = 1;
    for (my $i = 0; $i < @$word; $i++) {
	if ($word->[$i] ne $grid_orig->[$r+$i]->[$c-$i]) {
	    $word_placed = 0;
	    last;
	}
    }
    if ($word_placed) {
	# erase matching word - unless already fully erased
	my $already_erased = 1;
	for (my $i = 0; $i < @$word; $i++) {
	    $already_erased = 0 if $grid_solved->[$r+$i]->[$c-$i] ne ' ';
	    $grid_solved->[$r+$i]->[$c-$i] = ' ';
	}
	return 0 if $already_erased;
    }
    return $word_placed;
}

sub title {
    my $msg = shift;
    $msg . "\n" . ('-' x length $msg) . "\n";
}

sub fisher_yates_shuffle {
    my $array = shift;
    my $i;
    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i,$j] = @$array[$j,$i];
    }
}
__END__

word
word, word
...

=whateever
abgdftr....
gfgfg......
...........

E.g.:
-----
syr, kra
kroksun
pranyr
rak, mor  ,  makro
=
kroksun
pranyra
cmakrom

    TODO:
* erasing by something else than a space
* upcase also for the grid
* more checking
* some command-line arguments?
