use strict;
use warnings;

if ( ! exists $ARGV[0] )	{	die "(dir containing sams)\n";	}

opendir(DIR, $ARGV[0]) or die "cannot open $ARGV[0]\n";
my @sam = grep(/\.sam$/,readdir(DIR) );

foreach my $f ( @sam )	{
	
	my $sam = $f;
	
	my $bam = $sam;
	my $rg = $sam;
	$bam =~ s/\.sam$/.bam/;
	$rg =~ s/\.sam/.rg.bam/;		
	
	my $base = $sam;
	$base =~ s/\.sam$//g;
	
	my $view = "/home/smyles/myles_lab/bin/samtools-bcftools-htslib-1.0_x64-linux/bin/samtools view -bS $ARGV[0]/$sam >bams/$bam 2> log/$bam.log";
	
	my $readgroup = "java -jar -Xms256m -Xmx4g /home/smyles/myles_lab/bin/picard-tools-1.69/AddOrReplaceReadGroups.jar I=bams/$bam SO=coordinate RGID=$base RGLB=$base RGPL=illumina RGPU=$base RGSM=$base O=bams/$rg VALIDATION_STRINGENCY=SILENT 2>log/$rg.log";
	
#	print "$view\n";
	print "$readgroup\n";
}	
	
