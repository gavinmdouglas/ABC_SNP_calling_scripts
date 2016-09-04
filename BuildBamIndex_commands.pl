use strict;
use warnings;

if ( ! exists $ARGV[0] )	{	die "(dir containing *rg.bam files)\n";	}

opendir(DIR, $ARGV[0]) or die "cannot open $ARGV[0]\n";
my @bam = grep(/\.rg\.bam$/,readdir(DIR) );

foreach my $f ( @bam )	{
	
	print "java -jar -Xms256m -Xmx4g /home/smyles/myles_lab/bin/picard-tools-1.69/BuildBamIndex.jar I=$ARGV[0]/$f\n";

}	
	
