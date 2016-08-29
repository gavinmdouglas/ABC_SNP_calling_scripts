use strict;
use warnings;

use FileHandle;

if ( scalar @ARGV != 2 )	{ 

die "usage:\nperl GBSX_prep_info_files.pl (key file to use) (output folder for GBSX info files)

This script reads in a keyfile and creates 1 new \"info file\" for each plate, as required by GBSX toolkit.
If the specified output folder doesn't exist it will be created.\n"; 
	
}

# User-specified arguments
my $key = $ARGV[0];
my $out_dir = $ARGV[1];


my $lc = 0; # line count (to skip first line)

my %fh = (); # hash with outfile as key and filehandle as value

# check if out directory exists and if not create it:
if ( ! -e $out_dir )	{	system( "mkdir $out_dir" )	}


# read through keyfile, which is assumed to be tab-delimited
# create a new outfile for each plate (keep the name and filehandle in hash)
# print out sample name, barcode and enzyme for each sequenced well
open ( 'KEY' , '<' , $key ) or die "can't open KEY $key\n";
while( <KEY> )	{
		
	my @s = split( '[\t\n]' , $_ );
	
	# skip first line
	if ( $lc == 0 )	{
		++$lc; 
		next;
	}	

	my $sample = $s[4] . "_" . $s[5] . $s[6] ."_" . $s[3];
	my $barcode = $s[2];
	my $enzyme = $s[$#s];

	if ( $enzyme eq "PstI/EcoT22I" )	{	$enzyme = "PstI-EcoT22I" }

	my $out = "$out_dir"."/" . $s[0] . "_" . $s[1]."_GBSX_info.txt" ;

	# if filehandle hasn't been opened for this outfile then open it and add to %fh
	if ( ! exists $fh{$out} )	{
		my $fh = FileHandle->new();
		open( $fh , '>' , $out ) or die "cant create $fh $out\n";
		$fh{$out} = $fh;
	}
	
	my $fh = $fh{$out};

	print $fh "$sample	$barcode	$enzyme\n";

} close( 'KEY' );

foreach my $fh ( values %fh )	{
	close( $fh );
}

