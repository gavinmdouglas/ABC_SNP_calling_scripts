use strict;
use warnings;

my $lc = 0;

my %full = ();
$full{"ApeKI"} = "GCWGC";
$full{"PstI/EcoT22I"} = "KTGCAK";

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
		
	opendir(DIR, "GBSX_fastqs/$p" ) or die "cannot open GBSX_fastqs/$p";
	my @f = grep(/.fastq.gz$/,readdir(DIR));
	
	if ( -e "GBSX_fastqs_trimmed/$p" )	{
	} else {
		system("mkdir GBSX_fastqs_trimmed/$p");
	}

	my $enzyme = $plate2enzyme{$p};

	my $full = $full{$enzyme};	

	my $full_length = length($full);

	foreach my $f ( @f )	{

		my $trimmed = $f;
		$trimmed =~ s/.R1.fastq.gz/.trimmed.fastq.gz/;	
				
		print "/home/smyles/myles_lab/bin/bbmap_35.82/bbduk.sh -Xmx1g in=GBSX_fastqs/$p/$f out=GBSX_fastqs_trimmed/$p/$trimmed k=$full_length literal=\"$full\" rcomp=f copyundefined ktrim=r minlength=30 trimq=20 qtrim=r\n";
	
	}
}

