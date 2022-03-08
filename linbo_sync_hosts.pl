#!/usr/bin/perl -w
# 2017-2021 Copyright Frank Schütte <fschuett@gymhim.de>
# sync hosts with workstations file
# add missing hosts
#

use strict;
use Data::Dumper;
use JSON::XS;
use Encode qw(encode decode);
binmode STDIN, ":encoding(UTF-8)";
binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";
use utf8;
use POSIX qw(strftime);

# Global variable
my $date = strftime "%Y-%m-%d", localtime;
my $config       = "/etc/sysconfig/cranix";
my $tempfile     = 0;
my $result       = 0;

sub close_on_error
{
    my $a = shift;
    print STDERR $a."\n";
	print "$a";
    exit 1;
}

sub hash_to_json($) {
    my $hash = shift;
    my $json = '{';
    foreach my $key ( keys %{$hash} ) {
	my $value = $hash->{$key};
        $json .= '"'.$key.'":';
	if( not defined $value ) {
        $json .= 'null,';
	} elsif( $value eq 'true' ) {
       $json .= 'true,';
	} elsif ( $value eq 'false' ) {
       $json .= 'false,';
	} elsif ( $value =~ /^\d+$/ ) {
       $json .= $value.',';
	} else {
		$value =~ s/"/\\"/g;
		$json .= '"'.$value.'",';
	}
    }
    $json =~ s/,$//;
    $json .= '}';
}

if( $> )
{
    die "Only root may start this programm!\n";
}

my @toadd = ();
my %osshosts = ();

print "Reading Devices...\n";
$result = `/usr/sbin/crx_api.sh GET devices/all`;
$result = eval { decode_json($result) };
if ($@)
{
    close_on_error( "decode_json failed, invalid json. error:$@\n" );
}
foreach my $d (@{$result}) {
	$osshosts{$d->{'name'}} = 1;
}

print "Reading ".$ARGV[0]."...\n";
open(WORKSTATIONS,"<$ARGV[0]");
while(<WORKSTATIONS>){
    chomp;
    if($_ =~ /^#/){
        next;
    }
    my ( $raum, $rechner, $gruppe, $mac, $ip, $r1, $r2, $r3, $r4, $r5, $pxe ) = split /;/;
    my $owner = $rechner;
    $owner =~ s/^cpq//;
    $owner =~ s/^lap//;
    $owner = "" if $owner eq $rechner;
    my %temp = (
			room => "$raum",
            name => "$rechner",
            owner => "$owner",
            hwconf => "$gruppe",
            MAC => "$mac",
            IP => "$ip",
            r1 => "$r1", r2 => "$r2", r3 => "$r3", r4 => "$r4", r5 => "$r5",
            pxe => "$pxe",
    );
    if(not defined $osshosts{$rechner}){
		push @toadd, \%temp;
	}
}
close(WORKSTATIONS);

if( scalar(@toadd) ){
	print scalar(@toadd)." host(s) will be added to the system.\n";
	$tempfile = "/tmp/import_hosts.csv.$date";
	open(IMPORTFILE, ">$tempfile");
	print IMPORTFILE "Room;MAC;HWConf;Owner;Name\n";
	for my $host (@toadd) {
		print IMPORTFILE "$host->{'room'};$host->{'MAC'};$host->{'hwconf'};$host->{'owner'};$host->{'name'}\n";
	}
	close(IMPORTFILE);
	$result = `/usr/sbin/crx_api_upload_file.sh devices/import $tempfile`;
	$result = eval { decode_json($result) };
	if ($@)
	{
		close_on_error( "decode_json failed, invalid json. error:$@\n" );
	}
	if( $result->[0]{"code"} eq "OK" )
	{
		print "  new hosts added\n";
	} else {
		print "  modification of hosts failed: $result->[0]{'value'}\n";
	}
} else {
	print "No new hosts to import.\n";
}
