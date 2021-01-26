#!/usr/bin/perl
use MIME::Lite;
 
$to = 'martin.senger@gmail.com';
$from = 'martin.senger@gmail.com';
$subject = 'Notifikace test';
$message = 'Zatím nic...';

$msg = MIME::Lite->new(
                 From     => $from,
                 To       => $to,
                 Subject  => $subject,
                 Data     => $message
                 );
                 
#$msg->send;
$msg->send ('smtp', "smtp.gmail.com", AuthUser=>"martin.senger", AuthPass=>"...", Port=>"587" );
print "Email Sent, Bro!\n";
