#!/usr/bin/perl -w
# linbo-[add|delete|modify]-dhcpd.pl
#
# Update dhcpd database entries for host after add/modify/delete device
#
use strict;
use JSON::XS;

my $result;
my $device_id;
my $tool;
my %host;
my $operation = $0;
$operation =~ s/.*linbo-([a-zA-Z]+)-dhcpd.pl$/$1/;
my $USE_DB = '0';
my $LOGFILE = '/root/linbo-'.$operation.'-dhcpd.pl.log';
my $DEBUG = '1';

sub get_bootfilename($)
{
    my $gruppe = shift || 'netbook';

    open(CONF,"</srv/tftp/start.conf.$gruppe");
    my $systemtype = 'bios';
    while(<CONF>){
        chomp;
        my ( $type ) = lc($_) =~ /^systemtype\s=\s(bios|bios64|efi32|efi64)/;
        if( defined $type ){
                $systemtype = $type;
                last;
        }
    }
    
    if( $systemtype =~ /bios64/ )
    {
        return "boot/grub/i386-pc/core.0";
    } elsif( $systemtype =~ /efi32/ )
    {
        return "boot/grub/i386-efi/core.efi";
    } elsif( $systemtype =~ /efi64/ )
    {
        return "boot/grub/x86_64-efi/core.efi";
    } else {
        return "boot/grub/i386-pc/core.0";
    }
}

sub write_file($$) {
  my $file = shift;
  my $out  = shift;
  local *F;
  open F, ">$file" || die "Couldn't open file '$file' for writing: $!; aborting";
  binmode F, ':encoding(utf8)';
  local $/ unless wantarray;
  print F $out;
  close F;
}

open(LOG,">>$LOGFILE") if $DEBUG;
print LOG "=============================\n" if $DEBUG;

while(<STDIN>){
    chomp;
    my ($name, $value) = split /:/,$_,2;
    next if(not defined $name or not defined $value);
    $name =~ s/^\s+|\s+$//g;
    $value =~ s/^\s+|\s+$//g;
    $host{$name} = $value;
    print LOG "INPUT: $name = $value\n" if $DEBUG;
}

if( not defined $host{'hwconf'} or not defined $host{'hwconfid'} or not defined $host{'name'} ){
    exit(0);
}

# Linbo host ?
$tool = '';
my $str = `/usr/sbin/crx_api_text.sh GET clonetool/$host{'hwconfid'}/partitions`;
print LOG "partitions: $str\n" if $DEBUG;
my @a = split / /,$str;
for my $p (@a){
    $result = `/usr/sbin/crx_api_text.sh GET clonetool/$host{'hwconfid'}/$p/ITOOL`;
    print LOG "partition: $p tool: $result\n" if $DEBUG;
    if( $result eq 'Linbo' ){
        $tool = $result;
        last;
    }
}

if( $tool ne 'Linbo' and $operation ne 'modify' ){
    exit(0);
}

# Device id?
$result = `/usr/sbin/crx_api.sh GET devices/byName/$host{'name'}`;
$result = eval { decode_json($result) };
if ($@) {
    die( "decode_json failed, invalid json. error:$@\n" );
}
$device_id = $result->{'id'};

my $bootfile = get_bootfilename($host{'hwconf'});

if( $operation eq 'modify' or $operation eq 'delete' ){
    $result = `/usr/sbin/crx_api.sh GET devices/$device_id/dhcp`;
    print LOG "old dhcp entries: $result\n" if $DEBUG;
    $result  = eval { decode_json($result) };
    for my $entry (@{$result}){
        my $r = `/usr/sbin/crx_api.sh DELETE devices/$device_id/dhcp/$entry->{'id'}`;
    }
    `/usr/sbin/crx_api.sh PUT devices/refreshConfig` if $operation eq 'delete' or $tool ne 'Linbo';
    print "old dhcp entries for $host{'name'} deleted.\n";
}

if( $tool ne 'Linbo' ){
    exit(0);
}

if( $operation eq 'add' or $operation eq 'modify'){
    my $file = `mktemp /tmp/linbo_write_dhcpdXXXX.txt`;
    my $dhcppath;
    my $dhcpboot;
    if( $USE_DB ){
        $dhcppath = {"objectType" => "Device", "objectId" => $device_id, "keyword" => "dhcpStatements", "value" => "option extensions-path \\\"$host{'hwconf'}\\\""};
        $dhcpboot = {"objectType" => "Device", "objectId" => $device_id, "keyword" => "dhcpStatements", "value" => "filename \\\"$bootfile\\\""};
    } else {
        $dhcppath = {"objectType" => "Device", "objectId" => $device_id, "keyword" => "dhcpStatements", "value" => "option extensions-path \"$host{'hwconf'}\""};
        $dhcpboot = {"objectType" => "Device", "objectId" => $device_id, "keyword" => "dhcpStatements", "value" => "filename \"$bootfile\""};
    }
    write_file("$file", encode_json($dhcppath));
    if( $USE_DB eq '1' ){
        `echo "INSERT INTO OSSMConfig(objectType,objectId,keyword,value,creator_id) VALUES('Device',$device_id,'dhcpStatements','$dhcppath->{value}',1);" |mysql OSS`;
        print LOG "INSERT INTO OSSMConfig(objectType,objectId,keyword,value,creator_id) VALUES('Device',$device_id,'dhcpStatements','$dhcppath->{value}',1);\n" if $DEBUG;
        $result = "OK";
    } else {
        $result = `/usr/sbin/crx_api_post_file.sh devices/$device_id/dhcp $file\n`;
        print LOG "ADD dhcppath: $result\n" if $DEBUG;
        $result = eval { decode_json($result) };
        if ($@) {
            die( "decode_json failed, invalid json. error:$@\n" );
        }
        $result = "OK" if( $result->{"code"} eq "OK" );
    }
    write_file("$file", encode_json($dhcpboot));
    if( $USE_DB eq '1' ){
        `echo "INSERT INTO OSSMConfig(objectType,objectId,keyword,value,creator_id) VALUES('Device',$device_id,'dhcpStatements','$dhcpboot->{value}',1);" |mysql OSS`;
        print LOG "INSERT INTO OSSMConfig(objectType,objectId,keyword,value,creator_id) VALUES('Device',$device_id,'dhcpStatements','$dhcpboot->{value}',1);\n" if $DEBUG;
        $result = "OK";
    } else {
        $result = `/usr/sbin/crx_api_post_file.sh devices/$device_id/dhcp $file\n`;
        print LOG "ADD dhcpboot: $result\n" if $DEBUG;
        $result = eval { decode_json($result) };
        if ($@) {
            die( "decode_json failed, invalid json. error:$@\n" );
        }
        $result = "OK" if $result->{"code"} eq "OK";
    }
    `/usr/sbin/crx_api.sh PUT devices/refreshConfig` if $USE_DB eq '1';
    `rm -f $file`;
    print "new dhcp entries for $host{'name'} created.\n";
    close(LOG) if $DEBUG;
}

