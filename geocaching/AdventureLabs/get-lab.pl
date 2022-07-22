#!/usr/bin/perl
#
# Author: martin.senger@gmail.com
#
# ABSTRACT: vytáhne z LAB_API popisné informace o LABkách daných sérií
# PODNAME: get-lab.pl
#------------------------------------------

use strict;
use warnings;
use utf8;   
use Text::Unidecode;

our $VERSION = '1.2.2';

# 2022/07/22 - added to serie summary:
#  "FirebaseDynamicLink": "https://adventurelab.page.link/QUas",

# 2022/07/22 - added to the individual labs:
#  "MultiChoiceOptions": [
#        {
#          "Text": "poplatek za přepřažení koně",
#          "Order": 0
#        },
#        {
#          "Text": "právo první noci",
#          "Order": 1
#        },
#        {
#          "Text": "celní poplatek",
#          "Order": 2
#        },
#        {
#          "Text": "poplatek za ustájení koně",
#          "Order": 3
#        }
#      ],
#
# 2022/07/22 - added to the individual labs:
#      "Location": {
#        "Latitude": 49.1768666666667,
#        "Longitude": 16.6230833333333,
#        "Altitude": null
#      },

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
         
      Pouziva soubor authfile.txt, ve kterem ocekava ck=<consumer-key>.
        
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
use File::Slurp qw(read_file);
use LWP::UserAgent;
use File::Path qw(make_path);
use File::Spec;
use Data::Dumper;
use open OUT => ':utf8';

# get a consumer key (needed for calls to LAB_API)
my $ck;
my $authfile = 'authfile.txt';   # TBD: this should be changable from the command line
my $credentials = main::read_config ($authfile);
if ($credentials->{'ck'}) {
   $ck = $credentials->{'ck'};
} else {
   die "The file $authfile does not contain the 'ck' property\n."
}

my $ua = LWP::UserAgent->new;
$ua->agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.122 Safari/537.36");
$ua->default_header ('X-Consumer-Key' => $ck);
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
   my $firebaseDynamicLink = $basicInfo->{FirebaseDynamicLink};
   my $serDesc = $basicInfo->{Description};   $serDesc =~ s{\r\n}{\n}g; $serDesc =~ s{\s*$}{};
   
   # get and process individual LABs data
   my $data = fetchSwaggerData ("https://labs-api.geocaching.com/api/Adventures/$serieId");
#   print Dumper ($data);

   # make a directory according the series name
   my $name = unidecode ($data->{Title});   
   $name =~ s{[:/\\\?\*\|]}{_}g;    # some chars are not suitable for a file name   
   $name =~ s{\x5b\x3f\x5d}{_}ig; # removes U+1F43E (TBD better!)
   $name =~ s{^\s*|\s*$}{}g;      # trailing spaces in a file name does not work well under Windows
   $name =~ s{\.\.}{}g;           # more dots make a wrong file name (on windows)
   $name =~ s{[\. ]+$}{};         # do not end a directory name with a space or a period
   $name =~ s{\"}{_}g;            # double-quotes harm the directory name

   my $labid = $data->{Id};
   my $country = findCountry ($data->{Location}->{Latitude}, $data->{Location}->{Longitude});
   my $dirName = "${name}__${labid}__${country}";
   
   qmsg " [$dirName] ";
   unless (-d $dirName) {
      die " Cannot make a directory '$dirName': [$!]" unless make_path ($dirName);
   }

   # write general info about the whole serie into a file
   my $serieOutput = "ID:           $labid\n";
   $serieOutput   .= "Jméno série:  $name\n";
   $serieOutput   .= "Owner:        " . $data->{OwnerUsername} . "\n";
   $serieOutput   .= "Kód země:     $country\n";
   $serieOutput   .= "Souřadnice:   " . $data->{Location}->{Latitude} . "," . $data->{Location}->{Longitude} . "\n";
   $serieOutput   .= "Smart link:   https://labs.geocaching.com/goto/" . $smartLink . "\n" if $smartLink;  
   $serieOutput   .= "Dynamic link: " . $firebaseDynamicLink . "\n" if $firebaseDynamicLink;  
   $serieOutput   .= "Lineární:     " . ($data->{IsLinear} ? "ano" : "ne") . "\n";
   $serieOutput   .= "\n$serDesc\n";
   
   my $outfile = File::Spec->catfile ($dirName, "0 - Serie.txt");
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
      my $labCoords = $lab->{Location}->{Latitude} . "," . $lab->{Location}->{Longitude};
      my $labQuest = $lab->{Question}; 
      my $labMultiQuest = '';
      if ($lab->{MultiChoiceOptions}) {
           my $answerChoices = {};  
           foreach my $choice (@{$lab->{MultiChoiceOptions}}) {
              my $order = $choice->{Order};
              my $text  = $choice->{Text};
              $answerChoices -> {$order} = $text;
           }
           if ($answerChoices) {
              foreach my $choice (sort (keys %$answerChoices)) {
                 $labMultiQuest .= "   " . $choice . ": " . $answerChoices -> {$choice} . "\n"; 
              }
           }
      }
      my $labAward = '';
      if ($lab->{CompletionAwardMessage}) {
           $labAward = $lab->{CompletionAwardMessage};
      }

      my $labOutput = "[ " . $lab->{Title} . " ]\n$labDesc\n[[ Souradnice: ]] $labCoords\n[[ Otazka: ]] $labQuest\n${labMultiQuest}[[ Journal: ]] $labAward\n";

      my $outfile = File::Spec->catfile ($dirName, "$labCount - Popis.txt");
      open(FH, '>', $outfile) or die " Cannot write to $outfile: " . $! . "\n";
      print FH "$labOutput\n";
      close FH;
         
      # extract images and fetch their image data and store it locally
      extractImage ($labCount, $lab->{KeyImageUrl}, $dirName, "${labCount}a - IntroImage.jpg");
      extractImage ($labCount, $lab->{AwardImageUrl}, $dirName, "${labCount}b - JournalImage.jpg");
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
# Extract an image from the given $url (counted by $labCount] and
# store it in a file given by $name in directory $dirName.
# Return true by success.
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

# ----------------------------------------------------------------
# Read a simple config file made of key=value pairs.
# Return a refernce to a hash with found pairs.
# Only a LAB-API's consumer key (ck) is used.
# ----------------------------------------------------------------
sub read_config {
   my $filename = shift;
   my %result = read_file ($filename, err_mode => 'croak') =~ /^(\w+)=(.*)$/mg;
   return \%result;
}

__END__
