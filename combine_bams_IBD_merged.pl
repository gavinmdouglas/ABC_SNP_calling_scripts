use strict;
use warnings;

my $lc = 0;

my %remove = ();
$remove{"226"} = ""; # apple id of Rome Beauty Law, which I removed since it was most related with the delicious sports

my %ids = (); # each key is a different id and the value is a hash with all of the overlapping apple ids as keys

my %groups = (); # keys is apple id and value is all of the apple ids that should be merged (i.e. the new name)

open ( 'IBD' , '</home/smyles/myles_lab/apple_GBS/Tassel5_realign/90IBD_cultivars.txt'  ) or die "can't open IBD /home/smyles/myles_lab/apple_GBS/Tassel5_realign/90IBD_cultivars.txt\n";
while( <IBD> )	{
	my @s = split( '[\t\n]' , $_ );
	
	
	if ( $lc == 0 )	{
		++$lc;
		next;
	}
	
	if ( ( $s[2] eq "Rome Beauty Law" ) or ( $s[3] eq "Rome Beauty Law" ) ) {
			next;
	}
	
	my @ids = ( $s[0] , $s[1] );
	
	foreach my $id ( @ids )	{
		if ( ! exists $ids{$id} )	{
				$ids{$id} = {};
		}
	}
	
	$ids{$s[0]}{$s[1]} = "";
	$ids{$s[1]}{$s[0]} = "";
	
	
} close( 'IBD' );

my %full = ();

foreach my $id ( keys %ids )	{
	my @all_ids = ();
	my @overlaps = keys %{$ids{$id}};	
	push( @all_ids , @overlaps);
	
	foreach my $over ( @overlaps )	{
		my @additional = keys %{$ids{$over}};
		push( @all_ids , @additional );
	}
	
	my %all_ids = ();
	foreach my $all_id ( @all_ids )	{
		$all_ids{$all_id} = "";
	}

	my @sorted = ();
	for my $key ( sort {$a<=>$b} keys %all_ids) {
		push( @sorted, $key );
	}
	my $overlaps = join( '_' , @sorted );
	
	$full{$overlaps} = "";
	
	foreach my $sorted ( @sorted )	{
		$groups{$sorted} = $overlaps; 
	}

}


foreach my $g ( keys %full )	{

	my @ids = split( '_' , $g );
	
	my @bams = ();
	
	foreach my $id ( @ids )	{
	
#		system("mv bams_rg/$id".".rg.bam bams2merge");

		push ( @bams , "INPUT=bams2merge/$id".".rg.bam" );
	
	}


	print "java -Xms15G -Xmx15G -jar /home/smyles/myles_lab/bin/picard-tools-1.69/MergeSamFiles.jar @bams SORT_ORDER=coordinate OUTPUT=bams_rg/$g".".rg.bam\n";
#	print "/home/smyles/myles_lab/bin/samtools-bcftools-htslib-1.0_x64-linux/bin/samtools merge bams_rg/$g".".rg.bam @bams\n";	
	
}	
