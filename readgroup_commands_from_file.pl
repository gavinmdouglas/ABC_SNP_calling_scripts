use strict;
use warnings;

if ( ! exists $ARGV[0] )	{	die "(file containing IDs)\n";	}

my @ids = ();
open( 'FILE' , '<' , $ARGV[0] ) or die "cant open FILE $ARGV[0]\n";
while( <FILE> )	{
	my @s = split( '\s+', $_ );
	push ( @ids , $s[0] );
}close( 'FILE' );

foreach my $f ( @ids )	{

	my $sam = "$f".".sam";
	my $bam = "$f".".bam";
	my $rg = "$f".".rg.bam";
	
	my $base = $f;

	my $view = "/home/smyles/myles_lab/bin/samtools-bcftools-htslib-1.0_x64-linux/bin/samtools view -bS bwa_aligned/$sam >bams/$bam 2> log/$bam.log";
	
	my $readgroup = "java -jar -Xms256m -Xmx4g /home/smyles/myles_lab/bin/picard-tools-1.69/AddOrReplaceReadGroups.jar I=bams/$bam SO=coordinate RGID=$base RGLB=$base RGPL=illumina RGPU=$base RGSM=$base O=bams/$rg VALIDATION_STRINGENCY=SILENT 2>log/$rg.log";
	
#	print "$view\n";
	print "$readgroup\n";
}	
	
