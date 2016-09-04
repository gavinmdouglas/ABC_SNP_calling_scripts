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
	
	foreach my $sorted ( @sorted )	{
		$groups{$sorted} = $overlaps; 
	}
}

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
	
	if ( exists $remove{$base} )	{	next	}
	
	if ( exists $groups{$base} )	{
		$base = $groups{$base};
	}
	
	my $view = "/home/smyles/myles_lab/bin/samtools-bcftools-htslib-1.0_x64-linux/bin/samtools view -bS $ARGV[0]/$sam >bams/$bam 2> log/$bam.log";
	
	my $readgroup = "java -jar /home/smyles/myles_lab/bin/picard-tools-1.69/AddOrReplaceReadGroups.jar I=bams/$bam SO=coordinate RGID=$base RGLB=$base RGPL=illumina RGPU=$base RGSM=$base O=bams/$rg 2>log/$rg.log";
	
#	print "$view\n";
	print "$readgroup\n";
}	