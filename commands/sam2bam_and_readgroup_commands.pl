use strict;
use warnings;

if ( scalar @ARGV != 5 )	{	die "(input dir containing sams) (path to samtools) (path to picardtools AddOrReplaceReadGroups) (output directory) ([sam2bam|readgroup] --- which commands to output)\n";	}

my $in_dir = $ARGV[0];
my $samtools = $ARGV[1];
my $picard_jarfile = $ARGV[2];
my $out_dir = $ARGV[3];
my $type = $ARGV[4];

opendir( DIR, $in_dir ) or die "cannot open $in_dir\n";
my @sam = grep(/\.sam$/,readdir(DIR) );

foreach my $f ( @sam )	{
	
	my $sam = $f;
	
	my $bam = $sam;
	my $rg = $sam;
	$bam =~ s/\.sam$/.bam/;
	$rg =~ s/\.sam/.rg.bam/;		
	
	my $base = $sam;
	$base =~ s/\.sam$//g;
	
	my $view = "$samtools view -bS $ARGV[0]/$sam >$out_dir/$bam 2> log/$bam.log";
	
	my $readgroup = "java -jar -Xms256m -Xmx4g $picard_jarfile I=$out_dir/$bam SO=coordinate RGID=$base RGLB=$base RGPL=illumina RGPU=$base RGSM=$base O=$out_dir/$rg VALIDATION_STRINGENCY=SILENT 2>log/$rg.log";
	
	if ( $type eq "sam2bam" )	{

		print "$view\n";

	} elsif ( $type eq "readgroup" )	{

		print "$readgroup\n";
	} else {

		die "last argument needs to be either sam2bam or readgroup\n";	
	}
}	
	
