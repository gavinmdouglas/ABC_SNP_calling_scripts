#!/usr/bin/perl

use warnings;
use strict;

if ( scalar @ARGV != 1 )	{	die "usage: (vcf)\n";	}

my $vcf = $ARGV[0];
my $format_marker = 0;
my %format_i = ();

open( 'VCF' , '<' , $vcf ) or die "cant open VCF file $vcf\n";
while (<VCF> )	{
	
	my $first = substr( $_ , 0 , 1 );
	if ( $first eq "#" )	{	print "$_"; next	}
	my @s = split( '[\t\n]' , $_ );

	if ( $format_marker == 0 )	{
		my @format = split( ':' , $s[8] );
		
		my $i = 0;
	
		foreach my $f ( @format )	{
	
			if ( ( $f eq "GT" ) or ($f eq "DP" ) or ( $f eq "AD" ) ) {	
					$format_i{$f} = $i;
			} else {
					if ( ! exists $format_i{"other"} ) {
						my @dummy = ();	
						$format_i{"other"} = \@dummy;
					} else {}
					push( @{$format_i{"other"}} , $i );
			}
			++$i;
		}
		++$format_marker;
	}
	
	my @reorder = ( $format_i{"GT"} , $format_i{"AD"} , $format_i{"DP"} , @{$format_i{"other"}} );

	my @ind_and_format = splice( @s, 8 );
	
	foreach my $ind ( @ind_and_format )	{
		
		my @ind_split = split( ':' , $ind );
		
		my @out = ();
		
		if ( $ind_split[0] eq "./." )	{
		
			push( @out , "./.:0,0:0" );
			
		} else {
		
			foreach my $index ( @reorder )	{
		
				push( @out, $ind_split[$index] );
			}
		}
		
			push( @s , join( ':' , @out ) );
	}
	
	my $line = join( "	" , @s );
	
	print "$line\n";
	
} close('VCF');

