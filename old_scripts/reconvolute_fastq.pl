use strict;
use warnings;

if ( scalar @ARGV != 2 )	{	die "This script takes in two arguments 1 keyfile and the directory containing deconvoluted FASTQs\n";	} 

my $lc = 0;

my %p = ();

open ( 'KEY' , '<' , $ARGV[0] ) or die "can't open KEY $ARGV[0]\n";
while( <KEY> )	{
		
	my @s = split( '[\t\n]' , $_ );
	
	if ( $lc == 0 )	{
		++$lc; 
	}	
	
	my $plate_well = $s[4] . "_" . $s[10];
	$p{$plate_well} = $s[2];
} close( 'KEY' );

opendir(DIR, $ARGV[1] ) or die "cannot open DIR $ARGV[1]\n";
my @f = grep(/fastq\.gz/,readdir(DIR));

foreach my $f ( @f )	{
	
	my @info = split( '_' , $f );
		
	pop @info;
	my $plate_well = join( '_' , @info );
	
	if ( ! exists $p{$plate_well} )	{	die "no info for $plate_well\n";	}
	
	my $barcode = $p{$plate_well};
	my $qual = "";

	for ( my $i = 0; $i < length( $barcode ); ++$i )	{
		$qual = $qual . "J"; # this quality score will correspond to barcode, which has already been matched, so can give it highest quality
	}
		
	open 'FASTQ', "zcat $ARGV[1]/$f | " or die "cant open zcat $ARGV[0]/$f\n";
	while( my $read = <FASTQ> . <FASTQ> . <FASTQ> . <FASTQ> )       { # read in 4 lines at a time due to FASTQ formatting
		
		my @read = split( '\n' , $read );
		
		if ( ! exists $read[3] ) { die "odd numbers of lines in file $f ?\n";       }
		
		$read[1] = $barcode . $read[1];
		$read[3] = $qual . $read[3];		
		
		my $tmp = 100 - length( $read[1] );

		for ( my $i = 0; $i < $tmp  ; ++$i )	{
			$read[1]  = $read[1] . "N";					
			$read[3]  = $read[3] . "#";					
		}		
		
		print "$read[0]\n$read[1]\n$read[2]\n$read[3]\n";
		
	} close( 'FASTQ' ); 
}		
