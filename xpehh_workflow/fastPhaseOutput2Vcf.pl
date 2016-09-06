#!/usr/bin/perl

use warnings;
use strict;
use Data::Alias;

if ( scalar @ARGV != 5 )	{	die "usage: perl fastPhaseOutput2Vcf.pl (chromosome) (original VCF) (table of 2 groups of sample IDs split by column) (fastphase input) (fastphase output)\n";	}

my $chr = $ARGV[0];
my $VCF = $ARGV[1];
my $table = $ARGV[2];
my $fastphaseIn = $ARGV[3];
my $fastphaseOut = $ARGV[4];

my %b = ();
my @groups = ();
my @g1 = ();
my @g2 = ();
my @pos = ();
my %ids = ();

my %pos_taxa = ();

open( 'VCF' , '<' , $VCF ) or die "cant open VCF $VCF\n";
while (<VCF> )	{
	my $first = substr ( $_ , 0 , 1 );
	if ( $first eq "#" )	{	next	}
	my @s = split( '[\t\n]' , $_ );
	if  ($s[0] eq $chr )	{
		$b{$s[1]} = "$s[3] $s[4]";
	}
} close( 'VCF' );

open( 'FASTPHASEIN' , '<' , $fastphaseIn ) or die "cant open FASTPHASEIN $fastphaseIn\n";
while (<FASTPHASEIN> )	{
	my @s = split( '\s+' , $_ );
	if ( $s[0] eq "#" )	{	$pos_taxa{$s[1]} = "" 	}
} close( 'FASTPHASEIN' );


### read through ID_TABLE to figure out groups
my %g_tmp = ();
my %cult2g = ();
my $lc = 0;
open( 'ID_TABLE' , '<' , $table ) or die "cant open ID_TABLE $table\n";
while (<ID_TABLE> )	{
	my @s = split( '\s+' , $_ );
	if ( $lc == 0 )	{
		++$lc;
		next;
	}
	$g_tmp{$s[1]} = ();
	$cult2g{$s[0]} = $s[1];
} close( 'ID_TABLE' );

@groups = keys %g_tmp;
my $num_g = scalar @groups;
if ( $num_g != 2 )	{	die "there are $num_g groups in $table, expected 2\n";	}

foreach my $c ( keys %cult2g )	{
	my $g = $cult2g{$c};
	if ( $g eq $groups[0] )	{
		push ( @g1 , $c );
	} elsif ( $g eq $groups[1] )	{
		push ( @g2 , $c );
	} else { die "what is group of cultivar $c\n";	}
}

my %g1 = ();
my %g2 = ();
foreach my $g1 ( @g1 )	{	$g1{$g1} = ""; $ids{$g1} = {};	}
foreach my $g2 ( @g2 )	{	$g2{$g2} = "";	$ids{$g2} = {}; }
foreach my $g ( keys %g1 )	{	if ( exists $g2{$g} )	{	die "$g found in both groups\n"	}	}

open( 'FASTPHASEIN' , '<' , $fastphaseIn ) or die "cant open FASTPHASEIN $fastphaseIn\n";
while (<FASTPHASEIN> )	{
	my @s = split( '\s+' , $_ );
	if ( $s[0] eq "P" )	{
		shift( @s );
		@pos = @s;
	}
} close( 'FASTPHASEIN' );

my %ig = (); #ignore
my $next = 0;
my $cultivar;
open( 'FASTPHASEOUT' , '<' , $fastphaseOut ) or die "cant open FASTPHASEOUT $fastphaseOut\n";
while (<FASTPHASEOUT> )	{
	my @s = split( '\s+' , $_ );
	if ( ! exists $s[0] )	{	next	}
	if ( $s[0] eq "#" )	{
		if ( exists $ids{$s[1]} )	{
			$next = 1;
			$cultivar = $s[1];
		} else {
			$next = 0;
		}
	} elsif ( ( scalar @s > 5 ) and ( $next == 1 ) )	{
		if ( exists $ids{$cultivar}{"1"} )	{
			$ids{$cultivar}{"2"} = \@s;
		} else {
			$ids{$cultivar}{"1"} = \@s;
		}
	} 
} close( 'FASTPHASEOUT' );

for ( my $i = 0; $i < 2; ++$i )	{

	my @c = ();
	if ( $i == 0 )	{	@c = @g1	}
	if ( $i == 1 )	{	@c = @g2	}

	my $out = "chr"."$chr"."_".$groups[$i] ."_fastphase_selscaninput.vcf";
	open( 'OUT' , '>' , $out ) or die "cant create OUT $out\n";

	print OUT "##fileformat=VCFv4.0\n";
	my @h = ( "#CHROM" , qw(POS     ID      REF     ALT     QUAL    FILTER  INFO    FORMAT) );
	push ( @h , @c );
	my $h = join( "	" , @h );
	print OUT "$h\n";

	my $p_i = 0;
	foreach my $p ( @pos )	{
	
		my @b = split( '\s+' , $b{$p} );
		my $ref = $b[0];
		my $alt = $b[1];
		if ( $alt =~ m/,/g )	{	++$p_i;	$ig{$p} = ""; next; 	}
		my $coor_id = "S"."$chr"."_"."$p";
		
		print OUT "$chr	$p	$coor_id	$ref	$alt	.	PASS	.	GT";

		foreach my $c ( @c )	{

			alias my @hap1 = @{$ids{$c}{"1"}};
			alias my @hap2 = @{$ids{$c}{"2"}};
			
			my $b1 = $hap1[$p_i];
			my $b2 = $hap2[$p_i];
		
			my $code1; my $code2;
			if ( $b1 eq $ref )	{
					$code1 = 0;
			} elsif ( $b1 eq $alt )	{
					$code1 = 1;
			} else { die "base $b1 at position $p index $p_i of $#pos  doesnt make sense for $c\n"; 	}
			
			if ( $b2 eq $ref )	{
					$code2 = 0;
			} elsif ( $b2 eq $alt )	{
					$code2 = 1;
			} else { die "base $b2 at position $p index $p_i of $#pos doesnt make sense\n";	}
			
			print OUT "	$code1"."|"."$code2";
		}
		print OUT "\n";
		++$p_i;
	}
	close('OUT');
}

my $grouping = join( "_" , @groups );
open( 'MAP' , '>' , "chr".$chr . "_" . $grouping . ".map" ) or die "cant create MAP\n";
foreach my $p ( @pos )	{
	if ( exists $ig{$p} )	{	next	}
	my $gen_pos = $p / 10000000;
	print MAP "$chr	S"."$chr"."_$p	$gen_pos	$p\n";
} close( 'MAP' );
