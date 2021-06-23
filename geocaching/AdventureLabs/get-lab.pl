#!/usr/bin/perl
#
# Author: martin.senger@gmail.com
#
# ABSTRACT: vytáhne popisné informace o LABkách daných sérií
# PODNAME: get-lab.pl
#------------------------------------------

use strict;
use warnings;
use utf8;   
use Text::Unidecode;

our $VERSION = '1.0.2';

#------------------------------------------
# Command-line arguments and script usage
#------------------------------------------
my ($opt_help, $opt_v, $opt_q);
BEGIN {

   sub usage {
	    print STDERR <<"END_OF_USAGE";
Usage:
   $0 [volby] <serie ID> [<serie ID>...]
      vytahne popisna data o vsech LABkach serie definovane svym <serie ID>,
      serii muze byt zadano vice nez jedna, pro kazdou serii se vytvori v
      aktualnim adresari podadresar pojmenovany jmenem serie

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

use JSON;
use LWP::UserAgent;
use File::Path qw(make_path);
use File::Spec;
use Data::Dumper;
use open OUT => ':utf8';

my $ua = LWP::UserAgent->new;
$ua->agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.122 Safari/537.36");
$ua->default_header ('X-Consumer-Key' => "A01A9CA1-29E0-46BD-A270-9D894A527B91");
my $json = JSON->new->utf8->allow_nonref;

# ----------------------------------------------------------------
# Get a serie by its ID (e.g. 11ae0700-3716-4979-acde-0a8977e04271)
# ----------------------------------------------------------------
my $serieIds = [@ARGV];

# for testing
#my $serieIds = ['11ae0700-3716-4979-acde-0a8977e04271'];
#my $serieIds = ['8ee5b3d9-7402-4620-b22b-b33df75bad51'];
#my $serieIds = ['8ee5b3d9-7402-4620-b22b-b33df75bad51'];
   
foreach my $serieId (@{$serieIds}) {
   qmsg $serieId;

   # get and process basic data about the given serie
   my $basicInfo = fetchSwaggerData ("https://labs-api.geocaching.com/Api/Adventures/GetAdventureBasicInfo?id=$serieId");
   my $smartLink = $basicInfo->{SmartLink};
   my $serDesc = $basicInfo->{Description};   $serDesc =~ s{\r\n}{\n}g; $serDesc =~ s{\s*$}{};
   
   # get and process individual LABs data
   my $data = fetchSwaggerData ("https://labs-api.geocaching.com/api/Adventures/$serieId");

   # make a directory according the series name
   my $name = unidecode ($data->{Title});   
   $name =~ s{[:/\\\?\*\|]}{_}g;    # some chars are not suitable for a file name   
   $name =~ s{\x5b\x3f\x5d}{_}ig; # removes U+1F43E (TBD better!)
   $name =~ s{^\s*|\s*$}{}g;      # trailing spaces in a file name does not work well under Windows
   $name =~ s{\.\.}{}g;           # more dots make a wrong file name (on windows)
   $name =~ s{[\. ]+$}{};         # do not end a directory name with a space or a period
   $name =~ s{\"}{_}g;            # double-quotes harm the directory name
   qmsg " [$name] ";
   unless (-d $name) {
      die " Cannot make a directory '$name': [$!]" unless make_path ($name);
   }

   # write general info about the whole serie into a file
   my $serieOutput = "ID:          " . $data->{Id} . "\n";
   $serieOutput   .= "Jméno série: $name\n";
   $serieOutput   .= "Owner:       " . $data->{OwnerUsername} . "\n";
   $serieOutput   .= "Kód země:    " . findCountry ($data->{Location}->{Latitude}, $data->{Location}->{Longitude}) . "\n";
   $serieOutput   .= "Souřadnice:  " . $data->{Location}->{Latitude} . "," . $data->{Location}->{Longitude} . "\n";
   $serieOutput   .= "Smart link:  https://labs.geocaching.com/goto/" . $smartLink . "\n" if $smartLink;  
   $serieOutput   .= "Lineární:    " . ($data->{IsLinear} ? "ano" : "ne") . "\n";
   $serieOutput   .= "\n$serDesc\n";
   
   my $outfile = File::Spec->catfile ($name, "0 - Serie.txt");
   open(FH, '>', $outfile) or die " Cannot write to $outfile: " . $! . "\n";
   print FH "$serieOutput\n";
   close FH;


   # iterate over every LAB cache of this serie
   my $labCount = 0;
   foreach my $lab (@{$data->{GeocacheSummaries}}) {
      $labCount += 1;

      # extract various text information and write it into a file
      my $labName = $lab->{Title};
      my $labDesc = $lab->{Description};    $labDesc =~ s{\r\n}{\n}g; $labDesc =~ s{\s*$}{};
      my $labQuest = $lab->{Question}; 
      my $labAward = '';
      if ($lab->{CompletionAwardMessage}) {
           $labAward = $lab->{CompletionAwardMessage};
      }
      my $labOutput = "[ " . $lab->{Title} . " ]\n$labDesc\n[[ Otazka: ]] $labQuest\n[[ Journal: ]] $labAward\n";

      my $outfile = File::Spec->catfile ($name, "$labCount - Popis.txt");
      open(FH, '>', $outfile) or die " Cannot write to $outfile: " . $! . "\n";
      print FH "$labOutput\n";
      close FH;
         
      # extract images and fetch their image data and store it locally
      extractImage ($labCount, $lab->{KeyImageUrl}, $name, "${labCount}a - IntroImage.jpg");
      extractImage ($labCount, $lab->{AwardImageUrl}, $name, "${labCount}b - JournalImage.jpg");
   }

   qmsgNL ("Done.")
}

# ----------------------------------------------------------------
# Get swagger data using given $url. Convert th respose from JSON 
# and return it. Or die if an error occurs. 
# ----------------------------------------------------------------
sub fetchSwaggerData {
   my ($url) = @_;
   my $req = HTTP::Request->new (GET => "$url");
   my $res = $ua->request ($req);

   #Check the outcome of the response
   if ($res->is_success) {
      # convert JSON into perl structures and return it
      return ($json->decode ($res->content));
   } else {
      die " Received an unexpected result from swagger: " . $res->status_line . "\n" . $res->content;
   }
}
      
# ----------------------------------------------------------------
# Extract an image from the given $url (counted by $labCount and
# store it in a file given by $name. Return true by success.
# ----------------------------------------------------------------
sub extractImage {
   my ($labCount, $url, $dirName, $name) = @_;
   
   if ($url) {
      my $req = HTTP::Request->new (GET => "$url");
      my $res = $ua->request ($req);

      #Check the outcome of the response
      if ($res->is_success) {
         my $outfile = File::Spec->catfile ($dirName, $name);

         unless (open(FH, '>', $outfile)) {
            warn " Cannot write to $outfile: " . $! . "\n";
            return 0;
         }
         
         binmode FH;
         print FH $res->content;
         close FH;
         return 1;
         
      } else {
         warn " Received an unexpected result when fetching images: " . $res->status_line . "\n" . $res->content;   
      }
   }
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
      return ($1 or '??');
   } else {
      # request failed
      return '??';
   }
}


__END__

         if ($lab->{AwardImageUrl}) {
            my $awardUrl = $lab->{AwardImageUrl};
            $req = HTTP::Request->new (GET => "$awardUrl");
            my $res2 = $ua->request ($req);

            #Check the outcome of the response
            if ($res2->is_success) {
               $outfile = File::Spec->catfile ($name, "${labCount}b - JournalImage.jpg");

               open(FH, '>', $outfile) or die " Cannot write to $outfile: " . $! . "\n";
               binmode FH;
               print FH $res2->content;
               close FH;
            }   
         }

# ----------------------------------------------------------------
# Report results to STDOUT and STDERR
# ----------------------------------------------------------------

# report any errors we collected  TBD
foreach my $err (@{$errors}) {
    print STDERR "Error: $err\n";
}   

# report some statistics
my $total_checked = keys %$tested_series;
print STDOUT "$total_checked series checked\n";

# report newly found series
foreach my $serie (@found_series) {
   print STDOUT "New: [" . $serie->{id} . "] [" . $serie->{title} . "] [" . $serie->{lat} . "," . $serie->{lon} . "]\n";
}

# ----------------------------------------------------------------
# Compare with our server and add new ones to global variable
# @found_series and $tested_series; errors to @errors
#
# Input is a perl structures from json sent from swager for
# a given circle.
# ----------------------------------------------------------------
sub add_new_ones {
   my $data = shift;
   print "Number of active series in a circle: " . $data->{TotalCount} . "\n";
   
   # check which series are new
   foreach my $serie (@{$data->{Items}}) {
      my $serie_id = $serie->{Id};
      my $serie_name = $serie->{Title};

      next if ($tested_series->{$serie_id});   # ignore series that were already tested
      $tested_series->{$serie_id} = 1;         # and remember this serie
    
      next if $serie->{IsTest};
      next if $serie->{IsArchived};
      next if serieFound ($serie_id, $serie_name);
         print STDOUT "Possibly new: [$serie_id] [$serie_name] [" . $serie->{Location}->{Latitude} . "," . $serie->{Location}->{Longitude} . "]\n";
      next unless isInCzechia ($serie->{Location}->{Latitude}, $serie->{Location}->{Longitude});

      # okay, we found a new serie
      push (@found_series, {
         title => $serie->{Title},
         lat   => $serie->{Location}->{Latitude},
         lon   => $serie->{Location}->{Longitude},
         id    => $serie->{Id},
         link  => $serie->{SmartLink},
         count => $serie->{StagesTotalCount}
      });      
   }
}

# ----------------------------------------------------------------
# Return true if the given serie was found at our server
# ----------------------------------------------------------------
sub serieFound {
   my $id = shift;
   my $name = shift;

   # first try to find by an ID
   if (exists $series_ids->{$id}) {
       return 1;
   }
   # second try to find by a name
   if (exists $series_names->{$name}) {
       return 1;
   }
   return 0;   
}

# ----------------------------------------------------------------
# Return true if given coordinates are located in Czechia
# ----------------------------------------------------------------
sub isInCzechia {
   my ($lat, $lon) = @_;
   
   $lat = sprintf ("%f", $lat);  # to get rid of the scientific notation
   $lon = sprintf ("%f", $lon);

   my $geonames_url = "http://www.geonames.org/findNearbyPlaceName?lat=$lat&lng=$lon";
   my $res = $ua->get ($geonames_url);
   if ($res->is_success) {
      # got a response from geonames      
      my $response = $res->content;
      return ($response =~ m{<countryCode>CZ</countryCode>});
   } else {
      # request failed
      push (@$errors, "[$lat, $lon] ". $res->status_line);
      return 0;
   }
}

__END__   

