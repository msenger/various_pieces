#!/usr/bin/perl

use warnings;
use strict;

use LWP::UserAgent;
use Data::Dumper;

my $ua = LWP::UserAgent->new;
$ua->agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.122 Safari/537.36");

#$ua->add_handler( request_prepare => \&request_prepare, 'm_scheme' => 'http');

#my $lat = '49.7051666666667';
#my $lon = '17.0759666666667';

my $lat = '49.90135';
my $lon = '13.5351166666667';

my $country = findCountry ($lat, $lon);
print "COUNTRY ($lat, $lon): [$country]\n";

sub request_prepare {
   my ($request, $ua, $handler) = @_;
   print Dumper ($request);
}

# ----------------------------------------------------------------
# Return a country code where the given coordinates belong to
# or '??' if not found or failed
# ----------------------------------------------------------------
sub findCountry {
   my ($lat, $lon) = @_;
   
   $lat = sprintf ("%f", $lat);  # to get rid of the scientific notation
   $lon = sprintf ("%f", $lon);

   my $geonames_url = "http://www.geonames.org/findNearbyPlaceName?lat=$lat&lng=$lon";
   my $res = $ua->get ($geonames_url);
   if ($res->is_success) {
      # got a response from geonames      
      my $response = $res->content;
      $response =~ m{<countryCode>(\w{2})</countryCode>};
      print "Response successful: " . Dumper ($res);
      return ($1 or '??');
   } else {
      # request failed
      print "Request failed: " . Dumper ($res);
      return '??';
   }
}

__END__

# ----------------------------------------------------------------
# Return true if given coordinates are located in Czechia
# ----------------------------------------------------------------
sub isInCzechia {
   my ($lat, $lon) = @_;
   
   $lat = sprintf ("%f", $lat);  # to get rid of the scientific notation
   $lon = sprintf ("%f", $lon);
   my $geonames_url = "http://www.geonames.org/findNearbyPlaceName?lat=$lat&lng=$lon";

#   my $req = HTTP::Request->new (GET => $geonames_url);
#   $req->content ('{"profile":"compute","osVersion":"6","name":"centos6stateless","hypervisor":0,"architecture":"x86_64","osName":"centos","osType":"linux","type":"stateless"}');
#   $req->content ('{"profile":"compute","osVersion":"6","name":"centos6stateless","hypervisor":0,"architecture":"x86_64","osName":"centos","osType":"linux","type":"stateless"}');

#   my $res = $ua->request ($req);






   my $res = $ua->get ($geonames_url);
   if ($res->is_success) {
      # got a response from geonames      
      my $response = $res->content;
      print "[\n$response\n]";
      return ($response =~ m{<countryCode>CZ</countryCode>});
   } else {
      # request failed
      #push (@$errors, "[$lat, $lon] ". $res->status_line);
      print "[$lat, $lon] ". $res->status_line;
      return 0;
   }
}

__END__

my $response = <<'END_MESSAGE';
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<geonames>
    <geoname>
        <toponymName>Litovel</toponymName>
        <name>Litovel</name>
        <lat>49.70121</lat>
        <lng>17.07615</lng>
        <geonameId>3071669</geonameId>
        <countryCode>CZ</countryCode>
        <countryName>Czechia</countryName>
        <fcl>P</fcl>
        <fcode>PPL</fcode>
        <distance>0.4402</distance>
    </geoname>
</geonames>
END_MESSAGE

print "RES: " . ($response =~ m{<countryCode>CZ</countryCode>}) . "\n";
