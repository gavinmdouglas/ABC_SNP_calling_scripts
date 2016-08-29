use strict;
use warnings;
	
	
opendir(DIR, "GBSX_info_files") or die "cannot open DIR GBSX_info_files\n";
my @files = grep(/\.txt$/,readdir(DIR));
	
foreach my $f ( @files )	{
	
	my $plate;

	open( 'TMP' , '<' , "GBSX_info_files/$f" ) or die "cant open TMP GBSX_info_files/$f\n";
	while ( <TMP> )	{
		my @s = split( '[\t\n]' , $_ );
		my @name = split( '_' , $s[0] );
		pop( @name ); pop( @name );
		$plate = join( '_' , @name );
		last;
	} close( 'TMP' );

	my $fastq = $f;
	$fastq =~ s/_GBSX_info.txt//g;
	$fastq = "/home/smyles/myles_lab/apple_GBS/Tassel5_realign/fastq/" . $fastq . "_fastq.gz";
	
	print "java -jar -Xms256m -Xmx4g /home/smyles/myles_lab/bin/GBSX-master/releases/latest/GBSX_v1.2.jar --Demultiplexer -i GBSX_info_files/$f -f1 $fastq -gzip true -o $plate -minsl 30 -mb 0 -me 1\n";
	
}
