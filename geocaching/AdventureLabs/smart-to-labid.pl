#!/usr/bin/perl
#
# Author: martin.senger@gmail.com
#
# ABSTRACT: convert SmartLink to labid
# PODNAME: smart-to-labid.pl
#------------------------------------------

use strict;
use warnings;

our $VERSION = '1.0.0';

#------------------------------------------
# Command-line arguments and script usage
#------------------------------------------
my ($opt_help, $opt_v, $opt_q);
BEGIN {

   sub usage {
	    print STDERR <<"END_OF_USAGE";
Usage:
   $0 [volby] <smartLink> [<smartLink>...]
      prevede zadany <smartLink> na labid teze serie a vypise ho na STDOUT,
      muze tuto cinnost opakovat pro vice smartlink

      [volby] mohou byt:
         -h  ...  vypise tento help text a skonci
         -v  ...  vypise verzi tohoto skriptu a skonci
         -q  ...  nebude vypisovat informace o prubehu (quiet))      
END_OF_USAGE
   }

   # auto-flush
   select(STDERR); $| = 1;
   select(STDOUT); $| = 1;

   binmode(STDOUT, "encoding(UTF-8)");
   binmode(STDERR, "encoding(UTF-8)");

   use Getopt::Long;
   Getopt::Long::Configure ('no_ignore_case');
   GetOptions ( help               => \$opt_help,
                version            => \$opt_v,
                quiet              => \$opt_q,
                 
   ) or usage() and exit(1);
   usage() and exit(0) if $opt_help;

   sub qmsgNL { print STDERR shift, "\n" unless $opt_q; }
   sub qmsg   { print STDERR shift       unless $opt_q; }

}  # end of BEGIN

# -------------------- Show version and exit ----------------------
if ($opt_v) {
   print "$VERSION\n";
   exit(0);
}

# -------------------- From HERE do the real things ---------------
use LWP::UserAgent;
use open OUT => ':utf8';
my $ua = LWP::UserAgent->new;
$ua->agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.122 Safari/537.36");

# ----------------------------------------------------------------
# Get a serie by its SmartLink (e.g. https://labs.geocaching.com/goto/stredokluky)
# ----------------------------------------------------------------

my $smart_links = [@ARGV];
foreach my $smart_link (@{$smart_links}) {
   qmsg "$smart_link: ";

   # get and process individual LABs data
   my $data = fetchSwaggerData ("https://labs-api.geocaching.com/Api/Adventures/GetAdventureIdBySmartLink", $smart_link);
   $data =~ s{^\"}{}; $data =~ s{\"$}{};  # remove surrounding double quotes
   if ($data eq '1a7b8bd4-b9ae-4cad-9d27-8ffe6bbc9ade') {
      print STDERR "Chybny SmartLink (nejspise obsahuje diakritiku)\n";
   } else {
      print STDOUT "$data\n";
   }   
}

# ----------------------------------------------------------------
# Get swagger data using POST and a given $url and a $smartlink.
# $martlink cound be a simple value (e.g. stredokluky) or the full
# URL (e.g. https://labs.geocaching.com/goto/stredokluky).
# Return a response - which is a labid. Or die if an error occurs. 
# ----------------------------------------------------------------
sub fetchSwaggerData {
   my ($url, $smartlink) = @_;

   # extract a simple value from the $smartlink
   $smartlink =~ s{.*/([^/]+)$}{$1};
   
   # Create a request
   my $req = HTTP::Request->new(POST => $url);
   $req->content_type ('application/json');
   $req->content("\"$smartlink\"");

   # call the swagger
   my $res = $ua->request ($req);

   #Check the outcome of the response
   if ($res->is_success) {
      return ($res->content);
   } else {
      die " Received an unexpected result from swagger: " . $res->status_line . "\n" . $res->content;
   }
}
      
