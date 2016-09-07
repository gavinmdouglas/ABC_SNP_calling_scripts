use strict;
use warnings;

if ( scalar @ARGV != 2 )	{	die "This script takes in two arguments 1 keyfile and a list of keyfiles(comma-delimited) that should be added to the first one. Note that if columns aren't found in the listed keyfiles then the program will add in \"NA\"\nusage: (keyfile) (keyfile,keyfile,...) >output\n"; }

my $lc = 0;
my @head = ();

open ( 'KEY' , '<' , $ARGV[0] ) or die "can't open KEY $ARGV[0]\n";
while( <KEY> )	{
		
	my @s = split( '[\t\n]' , $_ );
	
	if ( $lc == 0 )	{
		++$lc; 
		@head = @s;
	}	

	print "$_";	

} close( 'KEY' );

my @keys = split( ',' , $ARGV[1] );
foreach my $k ( @keys )	{

	$lc = 0;	

	my %head2index = ();
	my %missing = ();

	open( 'K' , '<' , $k ) or die "cant open keyfile $k\n";
	while (<K>) {
		
		my @s = split( '[\t\n]' , $_ );
		
		if ( $lc == 0 )	{
			my $i = 0;
			foreach my $s ( @s )	{
				$head2index{$s} = $i;
				++$i;
			}		
			++$lc;
			next;
		}	
		
		my @line = ();		

		foreach my $h ( @head )	{
			if( ! exists $head2index{$h} )	{
				$missing{$h} = "";
				push( @line, "NA" );
			} else {
				push( @line, $s[$head2index{$h}] );				
			}
		}
		
		my $out = join( '	' , @line );
		print "$out\n";
		
	} close( 'K' );

	my @missing = keys %missing;

	if ( scalar @missing >= 1 )	{
		print STDERR "These columns are missing from $k:\n @missing\n";			
	}
}
