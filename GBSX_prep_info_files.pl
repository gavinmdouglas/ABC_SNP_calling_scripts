use strict;
use warnings;

use FileHandle;

if ( scalar @ARGV != 1 )	{ die "usage:\nperl GBSX_prep_info_files.pl (key file to use)\n";	}

my $key = $ARGV[0];

my $lc = 0;

my %fh = ();

if ( ! -e "GBSX_info_files" )	{	system( "mkdir GBSX_info_files" )	}

#open ( 'KEY' , '</home/smyles/myles_lab/apple_GBS/Tassel5_realign/keyfiles/20151116_gbs_keyfile_usda_abc_cet_barcode_splitter.txt' ) or die "can't open KEY\n";

open ( 'KEY' , '<' , $key ) or die "can't open KEY $key\n";
while( <KEY> )	{
		
	my @s = split( '[\t\n]' , $_ );
	
	if ( $lc == 0 )	{
		++$lc; 
		next;
	}	

	my $sample = $s[4] . "_" . $s[5] . $s[6] ."_" . $s[3];
	my $barcode = $s[2];
	my $enzyme = $s[$#s];

	if ( $enzyme eq "PstI/EcoT22I" )	{	$enzyme = "PstI-EcoT22I" }

	my $out = "GBSX_info_files/" . $s[0] . "_" . $s[1]."_GBSX_info.txt" ;

	if ( ! exists $fh{$out} )	{
		my $fh = FileHandle->new();
		open( $fh , '>' , $out ) or die "cant create $fh $out\n";
		$fh{$out} = $fh;
	} else {}

	my $fh = $fh{$out};

	print $fh "$sample	$barcode	$enzyme\n";

} close( 'KEY' );

foreach my $fh ( values %fh )	{
	close( $fh );
}
