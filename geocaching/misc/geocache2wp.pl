#!/usr/bin/perl
#
# getcache.pl by Stefan 'tommie' Tomanek <stefan@pico.ruhr.de>
#
# Retrieve geocache waypoints around a given location
# and insert them into the mysql database
#
# Usage:
#     getcache.pl <latitude> <longitude>
#
# Changelog:
#
# 01.07.2004
#  * initial release via gpsdrive mailinglist
# 04.07.2004
#  * Now we also fetch the long description, not storing it right now.
# 05.05.2005
#  * Updated to fit new geocaching.com structure

# MS: For Saffron Walden: ./geocache2wp.pl 52.0245 0.2402
#

use WWW::Mechanize;
use HTML::Entities;
use Unicode::String qw(utf8 latin1);
use DBI();

sub connect_db {
    my $host = "localhost";
    my $user = "geoinfo";
    my $password = "geoinfo";
    my $database = "geoinfo";
    return DBI->connect("DBI:mysql:database=$database;host=$host", $user, $password, {'RaiseError' => 1});
}

sub insert_wp($$) {
    my ($db, $wp) = @_;
    
    my $sth = $db->prepare('DELETE FROM waypoints WHERE comment=? AND type="GEOCACHE"');
    
    $sth->execute($wp->{uid});
    $sth->finish();
    
    my $sth2 = $db->prepare( 'INSERT INTO waypoints (name, type, lat, lon, comment) VALUES (?, "GEOCACHE", ?, ?, ?);' );
    $sth2->execute($wp->{name}, $wp->{lat}, $wp->{long}, $wp->{uid});
    print "Adding '".$wp->{name}."' (".$wp->{uid}.") @ ".$wp->{lat}."/".$wp->{long}."\n";
    $sth2->finish();
}

sub get_caches($$) {
    my ($lat, $long) = @_;
    
    my $db = connect_db();
    my $mech = WWW::Mechanize->new();
    my $url = "http://www.geocaching.com/seek/";
    $mech->get( $url );
    
    $mech->submit_form(
	form_number => 5,
	fields      => {
			origin_lat    => $lat,
			origin_long   => $long
			}
	);
    my $page = $mech->content();
    my @caches = ();
    foreach (split /\n/, $page) {
	# <a href="../seek/cache_details.aspx?guid=fa945818-f519-45bd-8e4d-54c80e258811">STAHLBARONE</a>
	## if (/<a href="(http:\/\/www\.geocaching\.com\/seek\/cache_details\.aspx\?guid=.+?)">(.*?)<\/a>/) {
	if (/<a href="\.\.\/seek\/cache_details\.aspx\?guid=(.+?)">(.*?)<\/a>/) {
	    my $guid = $1;
	    my $url = "http://www.geocaching.com/seek/cache_details.aspx?guid=".$guid;
	    my $name = decode_entities($2);
	    $name =~ s/<.*?>//g;
	    my $utf = latin1($name)->utf8();
	    my %cache = ( uid => $url, name => $name );
	    $cache{name} =~ s/ /_/g;
	    push @caches, \%cache;
	    my $pos = get_pos($mech, $cache{uid});
	    $cache{lat} = $pos->{lat};
	    $cache{long} = $pos->{long};
	    $cache{descr} = $pos->{descr};
	    print $cache{name}."    ".$cache{lat}."    ".$cache{long}."   GEOCACHE\n";
	    # print STDERR $cache{descr}."\n";
	    insert_wp($db, \%cache);
	} 
    }
    $db->disconnect();
    return @caches;
}

sub get_pos($$) {
    my ($mech, $guid) = @_;
    $mech->get($guid);
    my $page = $mech->content();
    my %pos;
    print $mech->uri()."\n";
    #foreach (split /\n/, $page) {
    {
	$_ = $page;
	if (/http:\/\/www\.jeeep\.com\/details\/coord\/translate\.cgi\?datum=.*?&amp;lat=(.*?)&amp;lon=(.*?)&amp;detail=1/) {
	    $pos{lat} = $1;
	    $pos{long} = $2;
	}
	if (/<BLOCKQUOTE><span id="LongDescription">(.*?)<\/span><\/BLOCKQUOTE>/s) {
	    my $descr = decode_entities($1);
	    $descr =~ s/<.*?>//g;
	    $pos{descr} = $descr;
	}
    }
    return \%pos;
}

if (defined $ARGV[0] && $ARGV[1]) {
    get_caches($ARGV[0], $ARGV[1]);
#    get_caches($ARGV[0], $ARGV[1]);
} else {
    print STDERR 'getcache.pl by Stefan "tommie" Tomanek <stefan@pico.ruhr.de>'."\n";
    print STDERR "Usage:\n";
    print STDERR "    getcache.pl 51.3858 6.751083\n";
}

