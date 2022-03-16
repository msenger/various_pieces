#!/usr/bin/perl
#
# Author: martin.senger@gmail.com
#
# ABSTRACT: read STDIN and send it by email
# 
# Usage:
#   TBD perl find-new-labs.pl -nget -q 2>&1 | perl wrap-and-email.pl
#------------------------------------------

use strict;
use warnings;

use MIME::Lite;

#------------------------------------------
# Command-line arguments and script usage
#------------------------------------------
my ($opt_help, $opt_admin);
my ($smtp_host, $smtp_port);
my ($from, $to_normal, $to_admin);

BEGIN {

   sub usage {
	    print STDERR <<"END_OF_USAGE";
Usage:
   $0 [volby] [SMTP specifics] [adresati]
   
      [SMTP specifics] mohou byt:
         -host <SMTP host name>   ... default je smtp.airwaynet.cz
         -port <SMTP port number> ... default je 25
         
      [adresati] mohou byt:
         -tonames <email>
            ... komu emailovat data prectena ze SYSIN,
                default: martin.senger\@gmail.com, Kocmanek\@kvados.cz, jazzlinka\@gmail.com, ami.ivo\@gmail.com
         -toadmin <email>
            ... komu emailovat data, take prectena ze SYSIN, ale jen
                je-li pouzit parameter -admin
                default: martin.senger\@gmail.com, Kocmanek\@kvados.cz
         -from <email>
            ... default: martin.senger\@gmail.com
         
         Ve vsech pripadech jsou <email> napsana stejne jako v emailech,
         tedy bud jednotliva email adresa nebo seznam vice email adres,
         oddelenych carkami 

      [volby] mohou byt:
         -h      ...  vypise tento help text a skonci
         -admin  ...  prectena data ze SYSIN jsou nejspise chybova,
                      takze email se bude posilat na admina,
                      defaultne se posilaji na bezneho zpracovatele
                          
END_OF_USAGE
   }

   use Getopt::Long;
   Getopt::Long::Configure ('no_ignore_case');
   GetOptions ( help         => \$opt_help,
                admin        => \$opt_admin,
                
                'port=i'     => \$smtp_port,
                'host=s'     => \$smtp_host,                
                
                'tonames=s'  => \$to_normal, 
                'toadmin=s'  => \$to_admin,
                'from=s'     => \$from,
                 
   ) or usage() and exit(1);
   usage() and exit(0) if $opt_help;

  #     --- SMTP specifics
  $smtp_host = 'smtp.airwaynet.cz' unless $smtp_host;
  $smtp_port = 25 unless $smtp_port;
  
  #     --- personal specifics
  $from = 'martin.senger@gmail.com' unless $from;
  #$to_normal = 'martin.senger@gmail.com, Kocmanek@kvados.cz, jazzlinka@gmail.com, ami.ivo@gmail.com' unless $to_normal;
  $to_normal = 'martin.senger@gmail.com' unless $to_normal;
  $to_admin = 'martin.senger@gmail.com, Kocmanek@kvados.cz' unless $to_admin; 

}  # end of BEGIN

my $subject_normal = 'AdventureLabs Notification ' . localtime();
my $subject_admin = 'AdventureLabs Notification Error ' . localtime();

# -----------------------------------------

# read STDIN...
my @message = <STDIN>;
my $result = join ("", @message);
exit (0) unless $result;

# ...and email it out, if it's not empty
my ($to, $subject);
if ($opt_admin) {
  $to = $to_admin;
  $subject = $subject_admin; 
} else {
  $to = $to_normal;
  $subject = $subject_normal;
}

my $msg = MIME::Lite->new (
    From     => $from,
    To       => $to,
    Subject  => $subject,
    Data     => $result,
    );
                 
$msg->send ('smtp', $smtp_host, Port=>$smtp_port ) ||
    die ("Failed to sent the email: $!\n");

