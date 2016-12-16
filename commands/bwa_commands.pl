use strict;
use warnings;

if ( scalar @ARGV != 3 )	{	die "(dir containing gzipped fastqs) (path to reference fasta) ([aln|samse])\n";	}

opendir(DIR, $ARGV[0]) or die "cannot open $ARGV[0]\n";
my @fastq = grep(/fastq.gz/,readdir(DIR) );

my $ref = $ARGV[1];
my $type = $ARGV[2];

foreach my $f ( @fastq )	{

	my @fastq_split = split( '\.' , $f );
	pop @fastq_split; pop @fastq_split;	
	my $base = join( "." , @fastq_split );
	
	my $gzipped = "$ARGV[0]"."/".$f;

	my $aln_out = "./bwa_aligned/$base" . ".sai";
	my $aln_log = "./log/".$base."_aln.log";

	my $samse_out = "./bwa_aligned/$base" . ".sam";
	my $samse_log = "./log/$base" . "_samse.log";

	my $bwa_aln = "bwa aln -t 6 $ref $gzipped >$aln_out 2>$aln_log"; 
	my $bwa_samse = "bwa samse $ref $aln_out $gzipped > $samse_out 2>$samse_log";

	if ( $type eq "aln" ){
		print "$bwa_aln\n";
	} elsif( $type eq "samse" ) {
		print "$bwa_samse\n";
	} else { die "third argument needs to be either aln or samse instead of $type\n";	}
}
