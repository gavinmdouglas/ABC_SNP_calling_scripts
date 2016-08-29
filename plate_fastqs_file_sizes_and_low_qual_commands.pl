use strict;
use warnings;

	
opendir(DIR, "../Tassel5_realign/fastq" ) or die "cannot open ../Tassel5_realign/fastq";
my @f = grep(/.fastq.gz$/,readdir(DIR));

foreach my $f ( @f )	{

	my $out = $f."_stats.sh";
	open( 'OUT' , '>' , $out ) or die "cant open OUT $out\n";

print OUT "#\$ -cwd
#\$ -j y
#\$ -l h_rt=47:00:00
#\$ -l h_vmem=2G

echo Job beginning at `date`
echo -n \"../Tassel5_realign/fastq/$f line count: \"
zcat ../Tassel5_realign/fastq/$f | wc -l
echo -n \"../Tassel5_realign/fastq/$f # lines with :Y: \"
zcat ../Tassel5_realign/fastq/$f | grep -c \":Y:\"
echo -n \"../Tassel5_realign/fastq/$f # lines with first 10 bases of adapter \";
zcat ../Tassel5_realign/fastq/$f | grep -c \"AGATCGGAAG\"
echo Job ending at `date`\n";

close('OUT');

}

