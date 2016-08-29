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

print "flow_lane	plate	enzyme	abc	cet	sample	reads\n";

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
			
	my $flow = $plate2flow{$plate};
	my $enzyme = $flow_enzymes{$flow};
	my $abc = "N";
	my $cet = "N";
	if ( exists $abc_flows{$flow} )	{	$abc = "Y";	}
	if ( exists $cet_flows{$flow} )	{	$cet = "Y";	}
	$s[0] =~ s/.trimmed.fastq.gz//g;
	print "$flow	$plate	$enzyme	$abc	$cet	$s[0]	$s[1]\n";		
			
} close( 'bbmap_LOG');
