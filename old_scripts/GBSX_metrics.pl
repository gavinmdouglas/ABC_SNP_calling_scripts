use strict;
use warnings;

my %flow2plate = ();
my %plate2flow = ();
my %abc_flows = ();
my %cet_flows = ();
my %flow_enzymes = ();

my $lc = 0;

open ( 'KEY' , '<../Tassel5_realign/20151116_gbs_keyfile_usda_abc_cet.txt' ) or die "can't open KEY 20151116_gbs_keyfile_usda_abc_cet.txt\n";
while( <KEY> )	{
		
	my @s = split( '[\t\n]' , $_ );
	
	if ( $lc == 0 )	{
		++$lc; 
		next;	
	}	
	
	my $flow = $s[0] . "_" . $s[1] ;
	my $plate = $s[4];
	my $apple_id = $s[$#s-2];
	my $enzyme = $s[9];
	
	$flow2plate{$flow} = $plate;
	$plate2flow{$plate} = $flow;
	
	if ( exists $flow_enzymes{$flow} )	{
		if ( $flow_enzymes{$flow} ne $enzyme )	{	die "2 different enzymes for $flow\n";	}
	} else {
		$flow_enzymes{$flow} = $enzyme;
	}
	
	if ( ( $apple_id ne "NA" ) and ( $apple_id =~ m/\S/g ) )	{
		$abc_flows{$flow} = "";
	}	
	
} close( 'KEY' );

$lc = 0;
open ( 'CET' , '<../Tassel5_realign/keyfiles/20160112_cetkeyfile4kendra.txt' ) or die "can't open CET ../Tassel5_realign/keyfiles/20160112_cetkeyfile4kendra.txt\n";
while( <CET> )	{
	my @s = split( '[\t\n]' , $_ );
	
	if ( $lc == 0 )	{
		++$lc; 
		next;	
	}	
	
	my $flow = $s[0] . "_" . $s[1] ;
	if ( ! exists $flow2plate{$flow} )	{	die "missing $flow in KEY\n";	}
	
	my $plate = $s[4];
	my $enzyme = $s[9];
	if ( $flow_enzymes{$flow} ne $enzyme )	{	die "2 different enzymes for $flow\n";	}
	$cet_flows{$flow} = "";
	
} close( 'CET' );

my @header = qw(flowcell plate enzyme	ABC?	CET?	\#reads	\#illuminaY	\#match10bpAdapter	\#barcodeTagMatched	\#AfterQualTrim);

my %t = ();

opendir(DIR, "original_plate_counts" ) or die "cannot open original_plate_counts";
my @f = grep(/fastq.gz_stats.sh.o/,readdir(DIR));
foreach my $f ( @f )	{
	my @file_info = split( '_' , $f );
	my $flow = $file_info[0] . "_" . $file_info[1];
	if ( ! exists $flow2plate{$flow} )	{	next	}
	open( 'COUNTS' , '<' , "original_plate_counts/".$f ) or die "cant open COUNTS original_plate_counts/$f\n";
	while( my $line = <COUNTS> .  <COUNTS> .  <COUNTS> .  <COUNTS> )	{
		my @lines = split( '\n' , $line );
		my @line_count = split('\s+' , $lines[1] );
		my @failures = split( '\s+' , $lines[2] );
		my @adapter = split( '\s+' , $lines[3] );
		$line_count[$#line_count] = $line_count[$#line_count]/4;
		$t{$flow} = "$line_count[$#line_count]	$failures[$#failures]	$adapter[$#adapter]";
		last;
	} close( 'COUNTS' );
}
my %plate_sums = ();
foreach my $p ( %plate2flow )	{
	$plate_sums{$p} = {};
	$plate_sums{$p}{"gbsx"} = 0;
	$plate_sums{$p}{"bbmap"} = 0;
}

$lc = 0;
open( 'GBSX_LOG' , '<gbsDemultiplex.stats.txt' ) or die "cant open GBSX_LOG\n";
while( <GBSX_LOG> )	{
	my @s = split( '[\t\n]' , $_ );
	
	if ( $lc == 0 )	{
		++$lc; 
		next;	
	}	

	my @info = split( '_' , $s[0] );	
	pop @info;
	my $plate = join( '_' , @info );
	while ( ! exists $plate2flow{$plate} )	{
		pop(@info );
		$plate = join( '_' , @info );
	}
	$plate_sums{$plate}{"gbsx"} += $s[3];
} close( 'GBSX_LOG');

open( 'bbmap_LOG' , '<bbmap_fastqs_file_sizes.txt' ) or die "cant open bbmap_LOG\n";
while( <bbmap_LOG> )	{
	my @s = split( '[\t\n]' , $_ );
	
	if ( $lc == 0 )	{
		++$lc; 
		next;	
	}	
	my @info = split( '_' , $s[0] );	
	pop @info;
	my $plate = join( '_' , @info );
	while ( ! exists $plate2flow{$plate} )	{
		pop(@info );
		$plate = join( '_' , @info );
	}
			
	$plate_sums{$plate}{"bbmap"} += $s[1];
} close( 'bbmap_LOG');

foreach my $flow ( keys %t )	{

	my $plate = $flow2plate{$flow};
	my $abc = "N";
	my $cet = "N";
	my $enzyme = $flow_enzymes{$flow};
	
	if ( exists $abc_flows{$flow} )	{	$abc = "Y"	}
	if ( exists $cet_flows{$flow} )	{	$cet = "Y"	}
	
	my @counts = split( '\s+' , $t{$flow}	);
	
	my $gbsx_count = $plate_sums{$plate}{"gbsx"};
	my $bbmap_count = $plate_sums{$plate}{"bbmap"};
	
	push( @counts, ( $gbsx_count , $bbmap_count ) );
	my $counts = join( "	" , @counts );
	
	print "$flow	$plate	$enzyme	$abc	$cet	$counts\n";
	
}