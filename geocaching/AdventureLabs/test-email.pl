#!/usr/bin/perl

use strict;
use warnings;

use MIME::Lite;
#use Email::Stuffer;

my $to = 'martin.senger@gmail.com';
my $from = 'martin.senger@gmail.com';
my $subject = 'Notifikace test';
my $message = 'Zatím nic...';


#Email::Stuffer->to($to)
#              ->from($from)
#              ->text_body($message)
#              ->send;

##__END__

my $msg = MIME::Lite->new(
    From     => $from,
    To       => $to,
    Subject  => $subject,
    Data     => $message
    );
                 
#$msg->send;
#$msg->send ('smtp', "smtp.airwaynet.cz", AuthUser=>"martin.senger", AuthPass=>"...", Port=>"587" );
$msg->send ('smtp', "smtp.airwaynet.cz", Port=>"25" );
print "Email Sent, Bro!\n";
