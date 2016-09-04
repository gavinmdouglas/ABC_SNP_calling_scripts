use strict;
use warnings;

if ( scalar @ARGV != 4 )	{

	die "usage: perl bbmap_fastq_trim_commands.pl (directory containing all deconvoluted plates) (keyfile) (out directory) (path to bbduk.sh - bbmap bash script)\n";

}

my $in_dir = $ARGV[0];
my $key = $ARGV[1];
my $out_dir = $ARGV[2];
my $bbmap = $ARGV[3];

my $lc = 0; #line counter

my %full = (); ### full cutsite for each enzyme
$full{"ApeKI"} = "GCWGC";
$full{"PstI/EcoT22I"} = "KTGCAK";

my %info2enzyme = (); ### hash with deconvoluted fastq folder names as keys and enzymes as values

my %indices = (); ### indices of flowcell, lane, plate and enzyme
$indices{"Flowcell"} = undef;
$indices{"LibraryPlate"} = undef;
$indices{"Lane"} = undef;
$indices{"Enzyme"} = undef;

### read in keyfile and figure out indices of the 4 columns above
### then link sequencing info with enzyme
open ( 'KEY' , '<' , $key ) or die "cant open KEY $key\n";
while( <KEY> )	{
		
	my @s = split( '[\t\n]' , $_ );
	
	if ( $lc == 0 )	{
		
		my $i = 0;
		foreach my $s ( @s )	{
			if ( exists $indices{$s} )	{
				$indices{$s} = $i;
			}
			++$i;
		}
		
		++$lc; 
		next;	
	}	
	
	my $flowcell = $s[ $indices{"Flowcell"} ];
	my $lane = $s[ $indices{"Lane"} ];
	my $enzyme = $s[ $indices{"Enzyme"} ];
	my $plate = $s[ $indices{"LibraryPlate"} ];
	
	my $info = $flowcell . "_" . $lane . "_" . $plate ;
	
	$info2enzyme{$info} = $enzyme;

} close( 'KEY' );

if ( ! -e "$out_dir" )	{
		system("mkdir $out_dir");
}

my @plates = keys %info2enzyme;



foreach my $p ( @plates )	{
		
	opendir(DIR, "$in_dir/$p" ) or die "cannot open $in_dir/$p";
	my @f = grep(/.fastq.gz$/,readdir(DIR));
	
	if ( ! -e "$out_dir/$p" )	{
		system("mkdir $out_dir/$p");
	}

	my $enzyme = $info2enzyme{$p};
	my $full = $full{$enzyme};	
	my $full_length = length($full);

	foreach my $f ( @f )	{

		my $trimmed = $f;
		$trimmed =~ s/.R1.fastq.gz/.trimmed.fastq.gz/;	
				
		print "$bbmap -Xmx1g in=$in_dir/$p/$f out=$out_dir/$p/$trimmed k=$full_length literal=\"$full\" rcomp=f copyundefined ktrim=r minlength=30 trimq=20 qtrim=r\n";
	
	}
}

