#!/usr/bin/perl
#
# Get Dell device support information by 'service tag' by R.Bruna
#

use strict;
use warnings;
use Net::SNMP;
use LWP::UserAgent;
use Mojo::DOM;

my $oid = [ '1.3.6.1.4.1.674.10892.1.300.10.1.9.1', '1.3.6.1.4.1.674.10892.1.300.10.1.11.1'];
my $url='http://www.dell.com/support/troubleshooting/cz/cs/czbsd1/Servicetag/';

# Get IP address/hostname parametr

if ( @ARGV != 1 ) { print "usage: tagger.pl [IP/hostname]\n"; exit 1 }

# Get SNMP for model/service tag

my ( $session,$error ) = Net::SNMP->session(
	hostname => $ARGV[0],
	community => 'kuk',
);

if ( ! defined $session ) {
	print $error;
	exit 1
}

my $result = $session->get_request( varbindlist => $oid );

if ( ! defined $result ) {
	print $session->error(), "\n";
	$session->close();
	exit 1
}

print "$result->{$oid->[0]} $result->{$oid->[1]}", "\n\n";

# Get Dell warranty site

my $ua = LWP::UserAgent->new;
$ua->agent('Tagger/0.1');

my $req = HTTP::Request->new( GET => $url . $result->{$oid->[1]} );

$req->content_type('application/x-www-form-urlencoded');
$req->header( 'content-length' => '0' );

my $res = $ua->request($req);

if ( not $res->is_success) {
        print $res->status_line, "\n";
	exit 1
}

# Parse HTML result for warranty info

my $dom = Mojo::DOM->new($res->content);

print $dom->attr( class => 'TopTwoWarrantySummaryDiv' )->find('b')->text, "\n";

# exit

exit 0

