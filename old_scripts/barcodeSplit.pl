use strict;
use warnings;

use List::Util qw( min );
use FileHandle;

if ( scalar @ARGV != 3 )	{	die "(key) (fastq.gz) (path2bbmap)\n";	}

### this script will output a directory for each flowcell in a keyfile with gzipped fastqs for each well

my $bbmap_dir = $ARGV[2];

my %fh = (); # hash containing all filehandles as values and tmp filenames as keys
my %tmpfile2id = (); # for convenience
my %flow2enzyme = (); # hash of flowcells + lanes as keys to enzymes
my %b = (); # hash of barcodes to id (LibraryPlate_Well_DNASample)
my %h = (); # hash of which column matches which index, in case people switch up the input file
my %oligos = (); # hash of oligos to scan for
# keys is enzyme name (only ApeKI or PstI/EcoT22I atm) value is all possible oligos (no ambiguous bases): full_cutsite1,full_cutsite2,... cutsite_remnant1,cutsite_remnant2,...
# note that the cutsite remnants here are the ones that should immediately follow the barcode (at the 3' end of reads)

$oligos{"ApeKI"} = "GCAGC,GCTGC CAGC,CTGC";
$oligos{"PstI/EcoT22I"} =  "GTGCAG,GTGCAT,TTGCAG,TTGCAT TGCAT,TGCAG";


### counters for reads with messed up barcodes and 3' cut-site remnants
my $missing_cutsite_remnant = 0;
my $missing_known_barcode = 0;

# hash with keys == full location and DNA sample name; values == # of reads with full cut sites (these were removed)
my %chimeras = ();


# hash with keys == full location and DNA sample name; values == # of reads with barcode, first remnant and no full cut site (i.e. prior to bbmap filtering)
my %first_count = ();

# same as above, but count of # of reads after bbmap filtering
my %bbmap_count = ();

my $longest_barcode = 0; # keep track of longest barcode length so that the min number of bases to be scanned at the beginning of each read is clear

my $scan_length; # related to longest_barcode above, will be 5 + longest barcode length (5 because that is the longest cutsite remnant that will be scanned for at the 3' end of reads).

my $lc = 0; # parse header line when == 0

open ( 'KEY' , '<' , $ARGV[0] ) or die "can't open KEY $ARGV[0]\n";
while( <KEY> )	{
		
	my @s = split( '[\t\n]' , $_ );
	
	if ( $lc == 0 )	{
		my $i = 0;
		foreach my $s ( @s )	{	
			$h{$s} = $i;
			++$i;
		}
		my @required_columns = qw(Flowcell Lane Barcode Row Col Enzyme DNASample LibraryPlate);
		my $missing = 0;
		foreach my $c ( @required_columns )	{
			if ( ! exists $h{$c} )	{
				print STDERR "The column $c is missing from the barcode file\n";
				++$missing;
			} 
		}
		if ( $missing > 0 )	{	die "Stopping job due to missing columns in barcode file!\n";	}
		++$lc; 
		next;	
	}	
	
	my $barcode = $s[$h{"Barcode"}];
	###my $location = $s[$h{"Flowcell"}] . "_" . $s[$h{"Lane"}] . "_" . $s[$h{"Row"}] . "_" . $s[$h{"Col"}];
	my $enzyme = $s[$h{"Enzyme"}];
	my $name = $s[$h{"DNASample"}];
	my $flow_lane = $s[$h{"Flowcell"}] . "_" . $s[$h{"Lane"}] ;
	my $library_plate = $s[$h{"LibraryPlate"}];
	my $well = $s[$h{"Row"}] . "_" . $s[$h{"Col"}];
	
	$b{$barcode} = $library_plate."_". $well . "_" . $name;
	$flow2enzyme{$flow_lane} = $enzyme;

	if ( length($barcode) > $longest_barcode )	{
		$longest_barcode = length($barcode);
	}
	
} close( 'KEY' );

$scan_length = 5 + $longest_barcode; # again, 5 because that is the largest cut-site remnant

my $fastq = $ARGV[1];

my @dir_split = split( '\/' , $fastq );
my @fastq_split = split( '_' , $dir_split[$#dir_split] );
my $flow_lane = $fastq_split[0] ."_". $fastq_split[1];
if ( ! exists $flow2enzyme{$flow_lane} )	{	die "\"$flow_lane\" not found in keyfile\n";	}	
my $enzyme = $flow2enzyme{$flow_lane};
if ( ! exists $oligos{$enzyme} )	{	die "Enzyme \"$enzyme\" not found. Only \"ApeKI\" and \"PstI/EcoT22I\" (written exactly like that) are supported\n";	}
my @oligos = split( '\s+' , $oligos{$enzyme} );
my @full_cut = split( ',' , $oligos[0] );
my @first_remnant = split( ',' , $oligos[1] );

open 'FASTQ' , "zcat $fastq | " or die "cant open FASTQ with: zcat $fastq\n";
while( my $read = <FASTQ> . <FASTQ> . <FASTQ> . <FASTQ> )	{ # read in 4 lines at a time due to FASTQ formatting
	my @read = split( '\n' , $read );

	if ( ! exists $read[3] ) { die "odd numbers of lines in file $fastq ?\n";	}

	my $h = $read[0]; # header line
	my $seq = $read[1];
	my $qual = $read[3];
	### note that the 3rd line is always just "+"
	
	my $seq2scan = substr( $seq , 0 , $scan_length);
	
	if ( index( $seq2scan , "N" ) != -1 )	{	next	} # N matched in first part of read, so skip!
	
	my @first_remnant_hits = ();
	foreach my $f ( @first_remnant )	{
		my $hit = index( $seq2scan , $f );
		if ( $hit != -1 )	{	push ( @first_remnant_hits  , $hit )	}
	}
	
	if ( ! exists $first_remnant_hits[0] )	{
		### cutsite remnant not found in first $scan_length bases of read, so skip it
		++$missing_cutsite_remnant;
		next;
	}
	
	my $first_rem_hit = min @first_remnant_hits;
	my $barcode = substr( $seq , 0 , $first_rem_hit );
	
	if ( ! exists $b{$barcode} )	{
		### barcode not found in keyfile, so skip it!
		++$missing_known_barcode;
		next;
	}
	
	my $id = $b{$barcode};
	
	my $full_match_marker = 0; # marker for if full cut-site matches anywhere in sequence (this indicates it could be a chimeric read)

	foreach my $full_cut ( @full_cut )	{
		if ( index( $seq , $full_cut ) != -1 )	{
			++$full_match_marker;
		} else {}
	}

	if ( $full_match_marker > 0 )	{
		if ( ! exists $chimeras{$id} )	{
			$chimeras{$id} = 1;
		} else {	
			$chimeras{$id} += 1;
		}
		next;
	}

	# figure out name of output file:

	my $tmp_out = "$flow_lane/$id"."_TMP.fastq";

	if ( ! exists $first_count{$id} )	{
		$first_count{$id} = 1;
		if ( ! -e $flow_lane )	{	system( "mkdir $flow_lane" )	}
		my $fh = FileHandle->new();
		open( $fh , '>' , $tmp_out ) or die "cant create $fh $tmp_out\n";
		$fh{$tmp_out} = $fh;
		$tmpfile2id{$tmp_out} = $id;
	} else {
		$first_count{$id} += 1;
	}

	$qual = substr( $qual , $first_rem_hit );
	$seq = substr ( $seq , $first_rem_hit );
	
	my $fh = $fh{$tmp_out};
	
	print $fh "$h\n$seq\n+\n$qual\n"; # write passed read with barcode removed
	
} close( 'FASTQ' );

foreach my $tmp_out ( keys %fh )	{

	my $id = $tmpfile2id{$tmp_out};
	
	my $chimeras = $chimeras{$id};
	my $passed = $first_count{$id};
	print "$id	$chimeras	$passed\n";
	
	my $fh = $fh{$tmp_out};
	close( $fh );
}
