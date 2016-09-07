#!/usr/bin/perl

use warnings;
use strict;

if ( scalar @ARGV != 1 )	{	die "usage: (vcf)\n";	}

my $vcf = $ARGV[0];
open( 'VCF' , '<' , $vcf ) or die "cant open VCF file $vcf\n";

while( <VCF> )	{

	my $first = substr( $_ , 0 , 1 );

	if ( $first eq "#" )	{	print "$_"; next	}

	my @s = split( '[\t\n]' , $_ );

	$s[2] = "$s[0],$s[1]";

	my $out = join( "	" , @s );
	
	print "$out\n";

} close( 'VCF' );

