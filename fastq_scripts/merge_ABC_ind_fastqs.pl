use strict;
use warnings;

if ( scalar @ARGV != 3 )	{	

	die "usage: perl merge_ABC_ind_fastqs.pl (directory with trimmed fastqs) (keyfile) (output directory)\n";
	
}

my $in_dir = $ARGV[0];
my $key = $ARGV[1];
my $out_dir = $ARGV[2];

if ( ! -e $out_dir )	{	system( "mkdir $out_dir" )	}

my $lc = 0;

my %apple_id = ();

# indices of columns of interest, figured out by parsing header line
my %indices = ();
$indices{"DNASample"} = undef;
$indices{"LibraryPlate"} = undef;
$indices{"Row"} = undef;
$indices{"Col"} = undef;
$indices{"Flowcell"} = undef;
$indices{"Lane"} = undef;
$indices{"apple_id"} = undef;

open ( 'KEY' , '<' , $key ) or die "can't open KEY $key\n";
while( <KEY> )	{
		
	my @s = split( '[\t\n]' , $_ );
	
	# skip first line
	if ( $lc == 0 )	{
		++$lc; 
		
		### header line, which can be used to figure out indices of interest
		my $i = 0;
		
		foreach my $s ( @s )	{		

			if ( exists $indices{$s} )	{
				$indices{$s} = $i;
			} else {}

			++$i;
		}	

		next;
	}	

	my $plate = $s[ $indices{"LibraryPlate"} ] ;
	my $Row = $s[ $indices{"Row"} ] ;
	my $Col = $s[ $indices{"Col"} ] ;

	
	my $DNASample = $s[ $indices{"DNASample"} ] ;

	my $flowcell = $s[ $indices{"Flowcell"} ] ;
	my $lane = $s[ $indices{"Lane"} ] ;

	### make sure that Col is 2 characters (so add 0 if only one digit)
	if ( length( $Col ) == 1 )	{	$Col = "0" . $Col 	} 
	my $well = $Row . $Col;
	
	my $fastq = "$in_dir/$flowcell"."_"."$lane"."/".$plate."_".$well."_".$DNASample.".trimmed.fastq.gz";
	
	
	my $apple_id = $s[ $indices{"apple_id"} ];

	if ( ( $apple_id =~ m/\S/ ) and ( $apple_id ne "NA" ) )	{
		
		if ( ! exists $apple_id{$apple_id} )	{
			$apple_id{$apple_id} = {};
		}
		
		$apple_id{$apple_id}{$fastq} = ""
		
	} 
	
} close( 'KEY' );

	
foreach my $id ( keys %apple_id )	{

	my @fastqs = keys %{$apple_id{$id}};

	print "cat @fastqs > $out_dir/$id".".fastq.gz\n";

}

