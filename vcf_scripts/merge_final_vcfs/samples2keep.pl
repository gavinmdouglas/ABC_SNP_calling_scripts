#!/usr/bin/perl

use warnings;
use strict;

if ( scalar @ARGV != 3 )	{	die "usage: (samples1) [(samples2) (samples3) ...] > outfile \n";	}

my @f = @ARGV;

my %s = (); ### samples as keys and counts as values

foreach my $f ( @f )	{

	my $lc = 0;

	open( 'TXT' , '<' , $f ) or die "cant open TXT $f\n";
	while( <TXT> )	{
			
		if ( $lc == 0 )	{
			
			my @line = split( '\s+' , $_ );
			my @samples = splice( @line , 9 );
			
			my $num = scalar @samples;
			
			print STDERR "$num samples in $f\n";
			
			foreach my $sample ( @samples )	{
					
				if ( ! exists $s{$sample} )	{	$s{$sample} = 0	}
			
				$s{$sample} += 1;
			
			}			 
			
		}	
			
		++$lc;		
		
	} close( 'TXT' );

}

my @out = ();
my $num_retained = 0;

for my $sample ( sort {$a<=>$b} keys %s ) {

	my $count = $s{$sample};

	if ( $count == scalar( @f ) )	{	
		print "$sample\n";
		++$num_retained;
	} 	
}

print STDERR "$num_retained samples overlap in all ".scalar @f . " input files\n";


