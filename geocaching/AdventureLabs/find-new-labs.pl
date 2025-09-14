#!/usr/bin/perl
#
# Author: martin.senger@gmail.com
#
# ABSTRACT: najde v zadaném okruhu série LABek, které ještě nejsou na
#           našem serveru
# PODNAME: find-new-labs.pl
# ----------------------------------------------------------------
use utf8;
use strict;
use warnings;

our $VERSION = '4.4.0';

#------------------------------------------
# Command-line arguments and script usage
#------------------------------------------
my ($opt_help, $opt_v, $opt_q, $opt_vv);
my ($opt_lat, $opt_lon, $opt_rad);
my ($czechia, $slovakia, $opt_w, $opt_n);
my ($csv, $czfile);
my ($user, $pass, $ck);
my $authfile;    # default value 'authfile.txt'
my $conflogfile; # default value 'logging.conf'
my $arch = 0;  # by default do not check whether series should be archived
my $logger;
my $cmdline;

BEGIN {

   sub usage {
	    print STDERR <<"END_OF_USAGE";
Usage:
   $0 [volby] [rozsah] [auth]

   $0 [volby] [rozsah] [auth] -csv
      zapise na STDOUT labId, jmeno a uvodni souradnice kazde serie z daneho rozsahu
      (jinak nedela nic jineho), z [auth] potrebuje jen consumer key
   
   [volby] mohou byt:
      -h[elp]     ...  vypise tento help text a skonci
      -vers[ion]  ...  vypise verzi tohoto skriptu a skonci
      -verb[ose]  ...  vypisuje podrobnosti o prubehu (verbose)
      -q[uiet]    ...  nebude vypisovat informace o prubehu (quiet)
      -w[arnings] ...  nezrusi warnings z volaneho modulu
      -n[get]     ...  nespusti na konci get-lab.pl
      -conflogfile <filename>  ... soubor s konfiguraci, jak se bude logovat,
                                   default je soubor 'logging.conf', pouzije se,
                                   jen pokud neni zadan parameter -conflogfile

   [rozsah] urcuje oblast, ve ktere se serie hledaji, muze to byt:
      [-lat <latitude> -lon <longitude> -rad <radius>]
         hleda serie od stredu <latitude>,<longitude> v kruhu o polomeru <radius>,
         souradnice jsou float number, radius je integer v kilometrech
      
      [-cesko] | [-slovensko]
         hleda serie jen v Cesku nebo jen na Slovensku (a v blizkem okoli))

      [-czfile <filename>]
         pri zadnem zadani se hleda v Cesku a Slovensku (a blizkem okoli),
         je-li zadan soubor <filename>, pak se jeho obsahem prepisi interni
         hodnoty definujici rozsahy pro Cesko

      Ve vsech pripadech (krome -csv) se ignoruji serie, ktere jiz jsou na nasem serveru.

      
   [auth] authentikuje pristup na nas server, tedy urcuje username a heslo,
          a urcuje consumer key pro pristup k LAB-API
      -user <username>     ... username
      -pass <heslo>        ... heslo
      -ck <consumer-key>   ... consumer key
      -authfile <filename> ... soubor se jmenem uzivatele, heslem a ck
                               default je 'authfile.txt',
                               pouzije se, jen pokud neni zadano -user a -pass
                               a -ck                             
                             
END_OF_USAGE
   }

   # auto-flush
   select(STDERR); $| = 1;
   select(STDOUT); $| = 1;

   binmode(STDOUT, "encoding(UTF-8)");
   binmode(STDERR, "encoding(UTF-8)");

   # command-line must be saved here, before calling Getopt::Long->GetOptions
   $cmdline = join (" ", $0, @ARGV);
   
   use Getopt::Long;
   Getopt::Long::Configure ('no_ignore_case');
   GetOptions ( help               => \$opt_help,
                version            => \$opt_v,
                verbose            => \$opt_vv,
                quiet              => \$opt_q,
                warnings           => \$opt_w,
                nget               => \$opt_n,
                
                'lat=f'            => \$opt_lat,
                'lon=f'            => \$opt_lon,
                'rad=i'            => \$opt_rad,
                cesko              => \$czechia,
                slovensko          => \$slovakia,
                csv                => \$csv,
                'czfile=s'         => \$czfile,
                
                'authfile=s'       => \$authfile,     
                'user=s'           => \$user,
                'pass=s'           => \$pass,
                'ck=s'             => \$ck,

		'conflogfile=s'    => \$conflogfile,
                 
   ) or usage() and exit(1);
   usage() and exit(0) if $opt_help;

   sub qmsg    { my $mess = shift; $logger->info ($mess); print STDERR $mess unless $opt_q; }   
   sub verbose { my $mess = shift; $logger->info ($mess); print STDOUT $mess if $opt_vv}
   sub stdout  { my $mess = shift; $logger->info ($mess); print STDOUT $mess}

   $authfile = 'authfile.txt' unless $authfile;
   $conflogfile  = 'logging.conf' unless $conflogfile;
   
}  # end of BEGIN

# -------------------- Show version and exit ----------------------
if ($opt_v) {
    print "$VERSION\n";
    exit(0);
}

# -------------------- Prepare logging ---------------------------
use Log::Log4perl qw(get_logger);
Log::Log4perl->init ("$conflogfile");
$logger = get_logger ();  # singleton

# --- finally, let's start ---
my $datestring = localtime();
$logger->debug ("Starting (version used: $VERSION) -------------------------------------------");
$logger->info  ("   with the command line: $cmdline");
qmsg ($datestring . " - ") unless $csv;
      
use JSON;
use Data::Dumper;
use Text::CSV;
use File::Slurp qw(read_file);

# ----------------------------------------------------------------
# This is how to set basic authentication for a user agent.
#    It should be done better, e.g. in an external file
#    but I could not manage use lib 'lib''; under Windows' perl.
# ----------------------------------------------------------------
package My::LWPClient;
use base 'LWP::UserAgent';
 
sub get_basic_credentials {
    my ($self, $realm, $url) = @_;
    if ($user && $pass && $ck) {
	main::log_credentials ($user, $pass, $ck);
        return $user, $pass;
    } else {
        my $credentials = main::read_config ($authfile);
	$credentials->{'user'} = $user if $user;
	$credentials->{'pass'} = $pass if $pass;
        if ($credentials->{'user'} && $credentials->{'pass'}) {
           $ck = $credentials->{'ck'} unless $ck;
	   main::log_credentials ($credentials->{'user'}, $credentials->{'pass'}, $ck);
           return $credentials->{'user'}, $credentials->{'pass'};
        } else {
	   $logger->logdie ("Missing 'user' and/or 'pass' properties");
        }
    }
}
package main;

binmode(STDOUT, "encoding(UTF-8)");

# ----------------------------------------------------------------
# Global variables (used in the subroutines)
# ----------------------------------------------------------------
my $series_ids = {};     # all IDs known to our server
my $errors = [];         # add here all errors that happened
my @found_series = ();   # newly found series
my $tested_series = {};  # series already tested for existence in labgpx
my $to_be_archived = {}; # series that remain in this hash should be archived

my $labgpx_admin_url = 'https://labgpx.cz/Admin/lab.php';  

# ----------------------------------------------------------------
# Get all known series from our server (labgpx.cz/Admin)
# where a basic authentication is needed.
# There is no need to contact labgpx.cz when only an csv is wanted.
# ----------------------------------------------------------------
if ($csv) {
    My::LWPClient->get_basic_credentials();  # this fills $ck, otherwise we do not need any credentials    
} else {
    my $uaa = My::LWPClient->new;
    my $header = ['Content-Type' => 'multipart/form-data; charset=UTF-8'];
    my $params = {f=>'getIdGcCoordList', format=>'json', sender=>'martin'};
    my $res;

    $logger->debug ("Obtaining all series from $labgpx_admin_url." .
		    " Header: " . nicedump ($header) .
		    ", Params " . nicedump ($params));

    if ($opt_w) {
	$res = $uaa->post ($labgpx_admin_url, $params, $header);
    } else {   
	# trying to disable these warnings:
	#    Use of uninitialized value $v in concatenation (.) or string at C:/Strawberry/perl/vendor/lib/Net/HTTP/Methods.pm line 161 
	local $SIG{__WARN__} = sub {
	    while (my $w = shift) {
		next if $w =~ m{Use of uninitialized value \$v in concatenation};
		# ...but keep other possible warnings enabled
		$logger->logwarn ($w);  
	    } 
	};
	$res = $uaa->post ($labgpx_admin_url, $params, $header);
    }

   if ($res->is_success) {
      # json: {"series":[{"gc":"GC8C6NH", "name":", "bArchiv":1...]}
      my $json = JSON->new->utf8->allow_nonref;
      my $data = $json->decode ($res->content);
      qmsg ("Number of series obtained from $labgpx_admin_url: " . scalar @{$data->{series}} . "\n");
      foreach my $serie (@{$data->{series}}) {
          if ($serie->{labId}) {
             $series_ids->{$serie->{labId}} = $serie->{bArchiv};   # 0 or 1
             if ($serie->{bArchiv} == 0) {
                # interested only in non archived series at our server
                if ($serie->{country} eq "Czechia" || $serie->{country} eq "Slovakia") { 
                   #...AND only in Czech or Slovak series
                   $to_be_archived->{$serie->{labId}} = $serie->{name};
                }
             }
          } else {
             qmsg ("Found a series without any labid: " . $serie->{name} . "\n");
          }  
      }
   } else {
      $logger->logdie ("Unable to connect to $labgpx_admin_url: " . $res->status_line);
   }
}

# ----------------------------------------------------------------

# prepare an agent for getting data (both from swagger and from geonames)
# (a global variable used in subroutines)
my $ua = LWP::UserAgent->new;
$ua->agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.122 Safari/537.36");
$ua->default_header ('X-Consumer-Key' => $ck);
$logger->debug ("Agent used for swagger - headers: " . nicedump ($ua->{def_headers}));

# ----------------------------------------------------------------
# Get all available series in the vicinity (from swagger))
# ----------------------------------------------------------------

# input parameters
my $skippedLS = 0;  # number of skipped series in one call
my $maxLS = 500;    # maximum number of fetched series in one call

# predefined regions
my $circles;
my $circles_CZ = [

    # verze 4
    {'start_lat' => 50.057135,
     'start_lon' => 14.554138,
     'radiusKm'  => 22.000},
    {'start_lat' => 50.663288,
     'start_lon' => 14.71344,
     'radiusKm'  => 54.000},
    {'start_lat' => 49.848593,
     'start_lon' => 15.188599,
     'radiusKm'  => 47.000},
    {'start_lat' => 50.394497,
     'start_lon' => 15.814819,
     'radiusKm'  => 53.000},
    {'start_lat' => 49.678234,
     'start_lon' => 16.589355,
     'radiusKm'  => 63.000},
    {'start_lat' => 49.211769,
     'start_lon' => 15.595093,
     'radiusKm'  => 46.000},
    {'start_lat' => 49.617854,
     'start_lon' => 13.980103,
     'radiusKm'  => 48.000},
    {'start_lat' => 50.201547,
     'start_lon' => 14.029541,
     'radiusKm'  => 27.000},
    {'start_lat' => 50.162826,
     'start_lon' => 12.939148,
     'radiusKm'  => 62.000},
    {'start_lat' => 50.602414,
     'start_lon' => 13.793335,
     'radiusKm'  => 27.000},
    {'start_lat' => 48.974484,
     'start_lon' => 14.397583,
     'radiusKm'  => 50.000},
    {'start_lat' => 49.419376,
     'start_lon' => 14.820557,
     'radiusKm'  => 25.000},
    {'start_lat' => 49.509159,
     'start_lon' => 12.913055,
     'radiusKm'  => 34.000},
    {'start_lat' => 49.201438,
     'start_lon' => 13.471985,
     'radiusKm'  => 28.000},
    {'start_lat' => 48.942351,
     'start_lon' => 13.687592,
     'radiusKm'  => 8.000},
    {'start_lat' => 49.654682,
     'start_lon' => 18.143921,
     'radiusKm'  => 54.000},
    {'start_lat' => 50.155804,
     'start_lon' => 17.234802,
     'radiusKm'  => 40.000},
    {'start_lat' => 49.151165,
     'start_lon' => 17.558899,
     'radiusKm'  => 42.000},
    {'start_lat' => 48.891824,
     'start_lon' => 16.850281,
     'radiusKm'  => 32.000},
    {'start_lat' => 48.939646,
     'start_lon' => 16.273499,
     'radiusKm'  => 29.000},
   ];

if ($czfile) {
   # replace Czech ranges from a file
   $circles_CZ = csvfile2perl ($czfile);
   #print Dumper ($circles_CZ);
}

my $circles_SK = [
    {'start_lat' => 48.7886550,
     'start_lon' => 19.2350258,
     'radiusKm'  => 100},
    {'start_lat' => 48.3635666,
     'start_lon' => 18.0329166,
     'radiusKm'  => 86},
    {'start_lat' => 48.9059,
     'start_lon' => 21.7826,
     'radiusKm'  => 63},
    {'start_lat' => 48.9941914,
     'start_lon' => 20.6956100,
     'radiusKm'  => 75}
   ];

# what region to chesk?
if ($czechia) {
   # only for Czechia
   $circles = $circles_CZ;
   
} elsif ($slovakia) {
   # only for Slovakia
   $circles = $circles_SK;
   
} elsif (defined $opt_lat and defined $opt_lon and defined $opt_rad) {
   # given by three parameters
   $circles = [{'start_lat' => $opt_lat,
                'start_lon' => $opt_lon,
                'radiusKm'  => $opt_rad}];
} else {
   # both Czechia and Slovakia
   $arch = 1;   # test series whether archive to archive them
   $circles = $circles_CZ;
   push (@$circles, @$circles_SK);
}
#print Dumper ($circles);

my $first_circle = 1;
foreach my $circle (@{$circles}) {
   my $radiusMeters = $circle->{radiusKm} * 1000;
   my $lat = $circle->{start_lat};
   my $lon = $circle->{start_lon};

   my $get = "https://labs-api.geocaching.com/Api/Adventures/SearchV3?radiusMeters=$radiusMeters&skip=$skippedLS&take=$maxLS&origin.latitude=$lat&origin.longitude=$lon";
   if ($first_circle) {
       $first_circle = 0;
       $logger->debug ("Getting a circle from swagger: $get");
   }
   my $req = HTTP::Request->new (GET => $get);
   my $res = $ua->request ($req);
 
   # Check the outcome of the response
   if ($res->is_success) {
      # convert JSON into perl structures
      my $json = JSON->new->utf8->allow_nonref;
      if ($csv) {
         add_to_csv ($json->decode ($res->content));
      } else {
         process_new_ones ($circle, $json->decode ($res->content));
      }
   } else {
      $logger->logdie ("Received an unexpected result from swagger: " . $res->status_line . "\n" . $res->content);
   }
}

# ----------------------------------------------------------------
# Report results to STDOUT and STDERR
# ----------------------------------------------------------------

# for CSV just report and exit
if ($csv) {
   my $total_checked = keys %$tested_series;
   qmsg ("Created $total_checked CSV values.\n");
   exit (0);
}

# report any errors we collected
foreach my $err (@{$errors}) {
    $logger->error ($err);
    print STDERR "Error: $err\n";
}   

# there may be some serie at our server that should be archived because
# they were not reported by swagger
if ($arch) {
    verbose ("Checking whether there are series to be archived\n");
    foreach my $key (keys %$to_be_archived) {
        my $serie_name = $to_be_archived->{$key};
        stdout ("To be archived: [$key] [$serie_name]\n");
    }
}

# report some statistics
my $total_checked = keys %$tested_series;
verbose ("$total_checked different series checked\n");

# call get-lab.pl for all found series (if any))
if (@found_series > 0) {
   unless ($opt_n) {
      my @prog = ("perl", "get-lab.pl");
      my @series = ();
      foreach my $serie (@found_series) {
         push (@series, $serie->{id});
      } 
      verbose "Subprocess: " . join (" ", @prog, @series) . "\n"; 
      system (@prog, @series) == 0
         or $logger->logdie ("Calling a subprocess @prog @series failed: $?");
   }
}

# ----------------------------------------------------------------
# Process series from swagger:
#   - they may be new ones (not existing at our server) =>
#     add them to global variable @found_series and $tested_series; errors to @errors
#   - they may be archived at our server =>
#     make a note that they should be DEarchivated
# 
# $data is a perl structures created from JSON sent from swagger for a given circle.
# $circle is the currently processed circle (used only in verbose messages)).
# ----------------------------------------------------------------
sub process_new_ones {
   my ($circle, $data) = @_;;

   my $radiusMeters = $circle->{radiusKm} * 1000;
   my $lat = $circle->{start_lat};
   my $lon = $circle->{start_lon};
   verbose ("Number of existing series in the circle ($lat, $lon, $radiusMeters): " . $data->{TotalCount} . "\n");
   
   foreach my $serie (@{$data->{Items}}) {
      my $serie_id = $serie->{Id};
      my $serie_name = $serie->{Title};
      my $visibility = $serie->{Visibility}; 

      next if ($tested_series->{$serie_id});   # ignore overlapping series in more circles
      $tested_series->{$serie_id} = 1;         # and remember this serie    
      next if $serie->{IsTest};                # ignore special series (what's that?)
      next if $serie->{IsArchived};            # ignore archived series (usually false, anyway)

      # this serie is active in swagger, therefore, we remove it from the $to_be_archived
      delete $to_be_archived->{$serie_id};
      
      # check which series are on our server
      if (serieFound ($serie_id)) {
         # this serie exists at our server
         if (serieArchived ($serie_id) && $visibility == 2) {     # TBD: probably the visibility is always 2
            # this serie is marked as archived AND is is fully enabled in swagger => mark it for DEarchiving
            stdout ("To be enabled: [$serie_id] [$serie_name]\n");
         } else {
            next; # go for the next serie 
         }
      } else {
         # okay, we found a new serie
         my $countryCode = findCountry ($serie->{Location}->{Latitude}, $serie->{Location}->{Longitude});
         stdout ("New: [$countryCode] [$serie_id] [$serie_name] [" . $serie->{Location}->{Latitude} . "," . $serie->{Location}->{Longitude} . "]\n");
         push (@found_series, {
            country => $countryCode,
            title   => $serie->{Title},
            lat     => $serie->{Location}->{Latitude},
            lon     => $serie->{Location}->{Longitude},
            id      => $serie->{Id},
            link    => $serie->{SmartLink},
            count   => $serie->{StagesTotalCount}
            });
      }
   }
}

# ----------------------------------------------------------------
# Return true if the given serie was found at our server
# ----------------------------------------------------------------
sub serieFound {
   my $id = shift;
   return (exists $series_ids->{$id});
}

# ----------------------------------------------------------------
# Return true if the given serie was found at our server AND is
# there archived
# ----------------------------------------------------------------
sub serieArchived {
   my $id = shift;
   return (serieFound ($id) && $series_ids->{$id} == 1);
}

# ----------------------------------------------------------------
# Return a country code where the given coordinates belong to
# or '??' if not found
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
      #print Dumper ($response);
      $response =~ m{<countryCode>(\w{2})</countryCode>};
      return ($1 or '??');
   } else {
      # request failed
      push (@$errors, "[$lat, $lon] ". $res->status_line . "\n" . $res->content);
      return 0;
   }
}

# ----------------------------------------------------------------
# Write most of the found series into STDOUT
#
# Input is a perl structures from json sent from swager for
# a given circle.
# ----------------------------------------------------------------
sub add_to_csv {
   my $data = shift;
   
   # check which series are wanted to put in the CSV file
   foreach my $serie (@{$data->{Items}}) {
      my $serie_id = $serie->{Id};
      my $serie_name = $serie->{Title};
      my $lat = $serie->{Location}->{Latitude};
      my $lon = $serie->{Location}->{Longitude};

      next if ($tested_series->{$serie_id});   # ignore overlapping series in more circles
      $tested_series->{$serie_id} = 1;         # and remember this series    
      next if $serie->{IsTest};                # ignore special series (what's that?)
      next if $serie->{IsArchived};            # ignore archived series (usually false, anyway)

      # okay, we found a wanted serie
      print STDOUT "$serie_id ($serie_name)\t$lat\t$lon\n";
   }
}

# ----------------------------------------------------------------
# Convert csv file to perl structures and return it. An example of such file
# (columns are separated by tabs):
# latitude	longitude	name	circle_radius
# 49.239377	17.83098	1	95.000km
# 49.951479	15.677718	2	96.000km
# 50.709436	14.666214	3	57.000km
# 49.040161	15.42437	4	25.000km
# 49.126383	14.072364	5	81.000km
# 50.079635	13.247868	6	87.000km
# 50.276444	17.314134	7	39.000km
# 48.924842	16.247881	8	44.000km 
# ----------------------------------------------------------------
sub csvfile2perl {
   my $file = shift;
   my $result = [];
   $logger->debug ("Converting the file '$file' with circles into perl");

   my $csv = Text::CSV->new({ sep_char => "\t" });
   open (my $data, '<', $file) or $logger->logdie ("Could not open '$file' $!\n");
   my $header = <$data>;   # ignore the first line
   while (my $line = <$data>) {
      chomp $line;
      next if $line =~ m{^\s*$};
      if ($csv->parse ($line)) { 
         my @fields = $csv->fields();
         $fields[3] =~ s{km$}{};
         push (@$result,
             {'start_lat' => $fields[0],
              'start_lon' => $fields[1],
              'radiusKm'  => $fields[3]} );
      } else {
         $logger->logwarn ("Line could not be parsed: $line\n");
      }
   }
   return $result;   
}   

# ----------------------------------------------------------------
# Read a simple config file made of key=value pairs.
# Return a reference to a hash with found pairs.
# ----------------------------------------------------------------
sub read_config {
    my $filename = shift;
    my %result = read_file ($filename, err_mode => 'croak') =~ /^(\w+)=(.*)$/mg;
    return \%result;
}


# ----------------------------------------------------------------
# Log given credentials (if needed).
# Parameters are user, pass and ck.
# ----------------------------------------------------------------
sub log_credentials {
    if ($logger->is_debug()) {
	my $u = shift;  # user name
	my $p = shift;  # password
	my $c = shift;  # consumer key
	$logger->debug ("Using user: $u");
	$logger->debug ("Using pass: $p");
	$logger->debug ("Using ck:   $c");
    }
}

# ----------------------------------------------------------------
# Return a bit more nicer form of a perl structured data
# (used mainly for logging, therefore the result is a one-liner)
# ----------------------------------------------------------------
sub nicedump {
    my $data = shift;
    my $d = Data::Dumper->new ([$data]);
    $d->Indent (0);
    $d->Terse (1);
    return $d->Dump;
}

__END__   


# for testing from a file without calling swagger
my $input = do { local $/; <> }; 
 
   # ask labgpx.cz for a serie with given title
#   my $labgpx_url = 'https://labgpx.cz/lab_search.php';
#   my $header = ['Content-Type' => 'multipart/form-data; charset=UTF-8'];
#   my $res = $ua->post ($labgpx_url, {f=>'search', name=>$title}, $header);
#   if ($res->is_success) {
#      # got a response from labgpx.cz      
#      my $response = $res->content;
#      if ($response =~ m{<p>Zobrazeno\s+(\d+)}) {
#         # the response is as expected
#         return $1; # $1 is 0 if the series was not found 
#      } else {
#         # the response is not what was expected
#         push (@$errors, "[$title] Received an unexpected result from labgpx.cz.");
#      }
#   } else {
#      # http request failed
#      push (@$errors, "[$title] ". $res->status_line);
#   }
#   # all other cases
#   return 1;  # in order not to be considered as found

#if ($res->is_success) {
#    # GC kod | name | latitude | longitude | ID | SmartLink
#    foreach my $line (split(/\n/, $res->content)) {
#        my ($gc, $name, $lat, $lon, $id, $smart) = split ('\|', $line);
#        if ($id) {
#            $series_ids->{$id} = 1;
#        } else {
#            $series_names->{$name} = 1 if $name; 
#        }  
#    }
#} else {
#    die "Unable to contact labgpx.cz: " . $res->status_line, "\n";
#}

