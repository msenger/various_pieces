#!/usr/bin/perl
#
# Author: martin.senger@gmail.com
#
# ABSTRACT: read STDIN and send it by email
# PODNAME: wrap-and-email.pl
#
# Usage:
#   perl find-new-labs.pl -nget -q 2>&1 | perl wrap-and-email.pl
#------------------------------------------


use strict;
use warnings;

use MIME::Lite;

# -----------------------------------------
# Configuration
# -----------------------------------------

#     --- SMTP specifics)
my $smtp_host = 'smtp.airwaynet.cz';
my $smtp_port = 25;

#     --- personal specifics
my $to = 'martin.senger@gmail.com';
my $from = 'martin.senger@gmail.com';
my $subject = 'AdventureLabs Notification ' . localtime();

# -----------------------------------------

# read STDIN...
my @message = <STDIN>;
my $result = join ("", @message);
exit (0) unless $result;

# ...and email it out
my $msg = MIME::Lite->new (
    From     => $from,
    To       => $to,
    Subject  => $subject,
    Data     => $result,
    );
                 
$msg->send ('smtp', $smtp_host, Port=>$smtp_port ) ||
    die ("Failed to sent the email: $!\n");

