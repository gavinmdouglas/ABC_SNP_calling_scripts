use strict;
use warnings;

if ( ! exists $ARGV[0] )	{	die "(dir containing gzipped fastqs)\n";	}

opendir(DIR, $ARGV[0]) or die "cannot open $ARGV[0]\n";
my @fastq = grep(/fastq.gz/,readdir(DIR) );


foreach my $f ( @fastq )	{

	my @fastq_split = split( '\.' , $f );
	pop @fastq_split; pop @fastq_split;	
	my $base = join( "." , @fastq_split );
	
	my $gzipped = "$ARGV[0]"."/".$f;

	my $aln_out = "./bwa_aligned/$base" . ".sai";
	my $aln_log = "./log/".$base."_aln.log";

	my $samse_out = "./bwa_aligned/$base" . ".sam";
	my $samse_log = "./log/$base" . "_samse.log";

	my $bwa_aln = "bwa aln -t 6 /home/smyles/myles_lab/apple_GBS/MalDom_1.0/GDR_MalDom_1.0/Malus_x_domestica.v1.0-primary.pseudo_plus_Unass_UI.fa $gzipped >$aln_out 2>$aln_log"; 
	my $bwa_samse = "bwa samse /home/smyles/myles_lab/apple_GBS/MalDom_1.0/GDR_MalDom_1.0/Malus_x_domestica.v1.0-primary.pseudo_plus_Unass_UI.fa $aln_out $gzipped > $samse_out 2>$samse_log";

#	print "echo \"$bwa_aln\"\n";
#	print "$bwa_aln\n";

	#print "echo \"$bwa_samse\"\n";
	print "$bwa_samse\n";

#	print "\n\n\n";
}
