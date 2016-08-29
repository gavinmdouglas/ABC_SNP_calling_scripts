use strict;
use warnings;

my $lc = 0;

my %plate2enzyme = ();

open ( 'KEY' , '<../Tassel5_realign/keyfiles/20151116_gbs_keyfile_usda_abc_cet_barcode_splitter.txt' ) or die "can't open KEY 20151116_gbs_keyfile_usda_abc_cet_barcode_splitter.txt\n";
while( <KEY> )	{
		
	my @s = split( '[\t\n]' , $_ );
	
	if ( $lc == 0 )	{
		
		++$lc; 
		next;	
	}	
	
	$plate2enzyme{$s[4]} = $s[9];

} close( 'KEY' );

my @plates = keys %plate2enzyme;

foreach my $p ( @plates )	{
		
	opendir(DIR, "GBSX_fastqs_trimmed/$p" ) or die "cannot open GBSX_fastqs_trimmed/$p";
	my @f = grep(/.fastq.gz$/,readdir(DIR));
	
	foreach my $f ( @f )	{

		my $length = (split('\s+' , `zcat GBSX_fastqs_trimmed/$p/$f | wc -l`))[0];
		$length = $length / 4;

		print "$f	$length\n";

	}
}

