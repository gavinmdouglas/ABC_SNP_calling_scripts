use strict;
use warnings;

if ( scalar @ARGV != 6 )	{

	print STDERR "\nusage: perl GBSX_commands.pl (directory containing info files) (directory containing raw FASTQs) (output directory) (GBSX jarfile) (java Xms setting - initial memory allocation) (java Xmx setting - max memory allocation) > (textfile with 1 command to run per line)\n";
	
	print STDERR "\nThis script reads through the GBSX info files and outputs the GBSX deconvolution command to be run for each sequencing plate\n\n";

	die "Example:\nperl GBSX_commands.pl GBSX_info_files raw_fastq /home/gavin/bin/GBSX_v1.2.jar deconvoluted_fastqs 256m 4G >GBSX_commands.txt\n\n";

}
	
### user-specified arguments:
my $info_dir = $ARGV[0];
my $fastq_dir = $ARGV[1];
my $out_dir = $ARGV[2];
my $jar = $ARGV[3];
my $initial = $ARGV[4];
my $max = $ARGV[5];	

if ( ! -e $out_dir )	{
	system("mkdir $out_dir" );
}
	
opendir(DIR, $info_dir ) or die "cannot open DIR $info_dir\n";

my @files = grep(/\.txt$/,readdir(DIR));
	
foreach my $f ( @files )	{
	
	my $flowcell_lane = $f;

	$flowcell_lane =~ s/_GBSX_info.txt//g;
	
	my $fastq = $fastq_dir . "/" . $flowcell_lane . "_fastq.gz";
	
	print "java -jar -Xms$initial -Xmx$max $jar --Demultiplexer -i $info_dir/$f -f1 $fastq -gzip true -o $out_dir/$flowcell_lane" .  " -minsl 30 -mb 0 -me 1\n";

}
