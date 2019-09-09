#!/usr/bin/perl -w
# linbo-update-ips.pl
# if found: update ip, wlanip in workstations file
# otherwise create line
# workstation line: serverraum;cpqgymhim12;ipadmax;48:F1:7F:8F:F2:6E;10.0.22.68;;;;classroom-studentcomputer;;1;

use strict;
use JSON::XS;

my $workstations = "/etc/linbo/workstations";
my $temp = `mktemp /tmp/linbo-update-ipsXXXXXXXX`;
chomp $temp;
my %host = ();
my $IP = 4;
my $WLANIP = 6;
my $found = 0;

while(<STDIN>){
    chomp;
    my ($name, $value) = split /:/,$_,2;
    next if(not defined $name or not defined $value);
    $name =~ s/^\s+|\s+$//g;
    $value =~ s/^\s+|\s+$//g;
    $host{$name} = $value;
}

open(WORKSTATIONS, "<$workstations");
open(TEMP, ">$temp");
while(<WORKSTATIONS>){
    chomp;
    if(/^[^;]*;$host{'name'};.*$/){
        my (@line) = split /;/,$_,-1;
        $line[$IP] = $host{'ip'};
        $line[$WLANIP] = $host{'wlanIp'} if defined $host{'wlanIp'};
        $_ = join ';', @line;
        $found = 1;
    }
    print TEMP "$_\n";
}
if( not $found and defined $host{'name'} and defined $host{'hwconf'} and defined $host{'mac'} and defined $host{'ip'} ){
    my $result = `/usr/sbin/oss_api.sh get devices/byName/$host{'name'}`;
    $result = eval { decode_json($result) };
    if ($@){
        print "decode_json failed, invalid json. error:$@\n";
    } else {
        $result = `/usr/sbin/oss_api.sh get rooms/$result->{'roomId'}`;
        $result = eval { decode_json($result) };
        if ($@){
            print "decode_json failed, invalid json. error:$@\n";
        } elsif( defined $result->{'name'} ){
            print TEMP $result->{'name'}.";".$host{'name'}.";".$host{'hwconf'}.";".$host{'mac'}.";".$host{'ip'}.";".$host{'wlanMac'}.";".$host{'wlanIp'}.";;classroom-studentcomputer;;1;\n";
        }
    }
}
close(TEMP);
close(WORKSTATIONS);

system("rm -f $workstations");
system("mv $temp $workstations");
system("chown root:root $workstations");
system("chmod 644 $workstations");
