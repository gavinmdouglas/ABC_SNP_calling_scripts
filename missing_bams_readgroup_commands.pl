use strict;
use warnings;

if ( ! exists $ARGV[1] )	{	die "(dir containing sams)	(dir containing bams)\n";	}

opendir(DIR, $ARGV[0]) or die "cannot open $ARGV[0]\n";
my @sam = grep(/\.sam$/,readdir(DIR) );

my %ids = ();

foreach my $f ( @sam )	{
	
	my $sam = $f;
	$f =~ s/\.sam//g;	

	$ids{$f} = "missing";
}

closedir( 'DIR');


opendir( DIR , $ARGV[1] ) or die "cannt open $ARGV[1]\n";
my @rg_bam = grep(/\.rg\.bam$/,readdir(DIR));

foreach my $rg ( @rg_bam )	{

	$rg =~ s/\.rg\.bam//g;

	$ids{$rg} = "present";
}
closedir(DIR);

foreach my $id ( keys %ids )	{

	if ( $ids{$id} eq "missing" )	{
		print "$id\n";
	}
}	

