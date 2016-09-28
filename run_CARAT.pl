#!/usr/bin/perl

use warnings;
use strict;

use File::Basename;
use Getopt::Long;
use Pod::Usage;

my $help; 
my $version_marker;
my $version = "0.1";

my $prefix = "CARAT";
my $out_dir = "CARAT_output";

my $carat_bin  = undef;
my $pheno_list = undef;
my $covariates = undef;
my $geno = undef; ### plink prefix
my $grm_geno = undef;
my $pheno = undef;
my $maf = 0.01;

my %cov = (); ### array of covariates per sample
my %pheno2keep = (); ### hash of all phenotypes to keep (optional)
my %p = (); ### hash of phenotypes as keys, with values that are a deeper hash which has all the samples as the keys and the observed phenotypes as the values
my @carat_cmds = ();
my %missing_covariates = (); ### which samples are missing covariates
my $res = GetOptions(

		         "prefix=s"=>\$prefix,
		         "carat=s"=>\$carat_bin,
		         "covariates=s"=>\$covariates,
		         "pheno_list=s"=>\$pheno_list,
				 "output=s"=>\$out_dir,
				 "pheno=s"=>\$pheno,
				 "geno=s"=>\$geno,
				 "grm_geno=s"=>\$grm_geno,
				 "maf=f"=>\$maf,

		         "help|h"=>\$help,
		         "version|v"=>\$version_marker,
		        
	  )	or pod2usage(2);

pod2usage(-verbose=>2) if $help;

if ( $version_marker )	{	print "version $version\n";	exit	}

### check for the required inputs:

if ( ! $carat_bin )	{ die "you need to specify the CARAT binary with the --carat parameter. Type \"./run_CARAT.pl -h\" for help.\n";	}

if ( ! -e $carat_bin )	{ die "the specified CARAT binary at $carat_bin is not found, please check your command\n";	}

if ( ! $pheno_list )	{ print STDERR "\nno --pheno_list option set, so will run CARAT on all phenotypes in the phenotype file\n\n";	}
	
if ( ! $pheno ) { die "you need to specify a table of phenotypes with the --pheno flag. Type \"./run_CARAT.pl -h\" for help.\n";	}

if ( ! $geno ) { die "you need to specify the prefix of the plink files you want to associate with the phenotypes with the --geno flag. Type \"./run_CARAT.pl -h\" for help.\n";	}

if ( ! $grm_geno ) { die "you need to specify the prefix of the plink files you want to use to build the grm matrix with the --grm_geno flag. Type \"./run_CARAT.pl -h\" for help.\n";	}
	
print STDERR "intermediate and output files will be output to the directory called $out_dir\n\n";

system("mkdir -p $out_dir/log"); ### "-p" makes parent directories as needed

my $lc = 0; # line count to skip header lines

if ( defined $covariates )	{ 

	open( 'COV' , '<' , $covariates ) or die "cant open COV $covariates\n";
	while( <COV> )	{
		if ( $lc == 0 )	{	++$lc;	next	}
		my @s = split( '\s+' , $_ );
		my $sample = shift @s;
		$cov{$sample} = \@s;
	} close( 'COV' );
	
} else { 
	print STDERR "no covariates file specified, will run CARAT without them\n\n";	
}

### now read in pheno_list and add as keys to %pheno2keep hash (if set)
if ( $pheno_list )	{
	open( 'PHENO_LIST' , '<' , $pheno_list ) or die "cant open PHENO_LIST $pheno_list\n";
	while( <PHENO_LIST> )	{
		my @s = split( '\s+' , $_ );
		if ( ! exists $s[0] )	{	next	} ### skip blank lines
		$pheno2keep{$s[0]} = {}; ### initalize all phenotypes in %p hash:
	} close( 'PHENO_LIST' );
}

$lc = 0;
my %pheno_i = (); # column indices of phenos of interest
open( 'PHENO' , '<' , $pheno ) or die "cant open PHENO $pheno\n";
while( <PHENO> )	{
	
	### tassel headers can have "<" and ">" characters in them, so remove them first
	$_ =~ s/>//g;
	$_ =~ s/<//g;

	my @s = split( '\s+' , $_ );
	if ( $lc == 0 )	{
		shift @s;
		my $i = 1;
		foreach my $s ( @s )	{
			if ( ( ! $pheno_list ) or ( exists $pheno2keep{$s} ) )	{	
				$p{$s} = {}; ### initialize empty hash for each phenotype
				$pheno_i{$s} = $i; ### get column index of each phenotype
			} 
			++$i;
		}	
		if ( (keys %p) != (keys %pheno_i ) )	{	die "Stopping job: not all phenotypes in pheno_list are found in the pheno file.\n"	}
		++$lc;
		next;
	}

	my $id = $s[0];
	
	foreach my $phenotype ( keys %pheno_i )	{	
	
		my $ind_value = $s[$pheno_i{$phenotype}];
	
		if ( ( $ind_value ne "1" ) and ( $ind_value ne "0" ) )	{ next	}	### skip all observations that aren't exactly 0 or 1.
	
		$p{$phenotype}{$id} = $ind_value;
		
	}
	
} close( 'PHENO');

foreach my $phenotype ( keys %p )	{

	### file to output IDs with non-missing phenotype data
	my $keep_out = $out_dir . "/" . $phenotype ."_ids2keep.txt";
	open( 'KEEP' , '>' , $keep_out ) or die "cant create KEEP $keep_out\n";

	my %p_out = ();

	foreach my $ind ( keys %{$p{$phenotype}} )	{
	
		my $ind_value = $p{$phenotype}{$ind};
		### note that all family IDs are set to 1 arbitrarily
		my $out = "1 $ind 0 0 0 $ind_value";
	
		if ( defined $covariates )	{
			
			if ( ! exists $cov{$ind} )	{	
			
				$missing_covariates{$ind} = "";	
				
			} else {
	
				### add covariants to end of line:
	
				$out = $out . " " . join( " " , @{$cov{$ind}} );
	
			}
		}

		$p_out{$ind} = "$out";

		print KEEP "$ind	$ind\n";
		
	}

	close( 'KEEP' );

	### output file to be used as pheno input to CARAT
	my $pheno_out = $out_dir . "/" . $phenotype . "_pheno_input.txt";
	open( 'PHENO_OUT' , '>', $pheno_out ) or die "cant create PHENO_OUT $pheno_out\n";

	my $pheno_log = $out_dir."/log/$phenotype"."_log.txt";

	my $geno_convert_cmd = "plink --file $geno --noweb --transpose --recode12 --keep $keep_out --maf $maf --out $out_dir/" . basename($geno) ."_$phenotype >> $pheno_log 2>>$pheno_log";
	print STDERR "Running:\n$geno_convert_cmd\n\n";
	
	system( $geno_convert_cmd );
	
	&make_Tped_header("$out_dir/".basename($geno)."_$phenotype" , $phenotype ); ### call to subroutine at end, which makes new tped file, but with header
	
	if ( $geno ne $grm_geno )	{
	
		my $grm_geno_convert_cmd = "plink --file $grm_geno --noweb --transpose --recode12 --keep $keep_out --maf $maf --out $out_dir/". basename($grm_geno)."_$phenotype >> $pheno_log 2>>$pheno_log";
		print STDERR "Running:\n$grm_geno_convert_cmd\n\n";
	
		system( $grm_geno_convert_cmd );
		
		&make_Tped_header("$out_dir/".basename($grm_geno)."_$phenotype" , $phenotype ); ### call to subroutine at end, which makes new tped file, but with header
			
	}
	
	my $tped_in = "$out_dir/".basename($geno)."_$phenotype" . "_header.tped";
	my $grm_tped = "$out_dir/".basename($grm_geno). "_$phenotype" . "_header.tped";
	
	my $prefix_out = "$out_dir/".basename($prefix)."_$phenotype";
	my $carat_cmd = "$carat_bin -p $pheno_out -g $tped_in -G $grm_tped -o $prefix_out 2>>$pheno_log";
	### make sure IDs are in same order as in tped:
	open( 'TPED_IN' , '<' , $tped_in ) or die "cant open TPED_IN $tped_in\n";
	while( <TPED_IN> )	{
		my @s = split( '\s+' , $_ );
		my @order = splice(  @s , 4 );
		
		foreach my $order ( @order )	{
			my $line = $p_out{$order};
			if ( exists $missing_covariates{$order} )	{	die "missing covariates for ind $order\n";	}
			print PHENO_OUT "$line\n";
		}
		last;
	} close('TPED_IN');

	close('PHENO_OUT' );

	print STDERR "\n\nRunning $carat_cmd\n\n";
	system( $carat_cmd );
	
}


sub make_Tped_header {

	my $tfam = $_[0] . ".tfam";
	my $phenotype = $_[1];
	
	my @ids = ();
	open( 'TFAM' , '<' , $tfam );
	while( <TFAM> ) {
        my @s = split( '\s+' , $_ );
        push ( @ids , $s[0] );
	} close( 'TFAM' );
	
	my $header_out = "$_[0]" . "_header.txt";
	open( 'HEAD_OUT' , '>' , $header_out ) or die "cant create HEAD_OUT\n";
	
	my $ids = join( " " , @ids );
	print HEAD_OUT "Chr SNP cm bp $ids\n";

	close('HEAD_OUT');

	my $new_tped = $_[0]  . "_header.tped";
	my $old_tped = $_[0] . ".tped";
	
	print STDERR "Running:\ncat $header_out $old_tped > $new_tped\n\n";
	system( "cat $header_out $old_tped > $new_tped" ); 	

}


__END__

=head1 Name

run_CARAT.pl - wrapper to run binary GWAS with CARAT.

=head1 USAGE

run_CARAT.pl [ --prefix <string> --output <out_dir> --help --version --covariates <file> --pheno_list <file> --maf <float>] --carat <PATH to binary> --pheno <file> --geno <plink prefix> --grm_geno <plink prefix>


=head1 OPTIONS

=over 4

=item B<-h, --help>

Displays the entire help documentation.

=item B<-v, --version>

Displays script version and exits.

=item B<-o, --output <file>>

Output directory for intermediate files and CARAT output (default: "CARAT_output").

=item B<--prefix <string>>

Prefix for output files (default: "CARAT").

=item B<--covariates <textfile>>

Optional file that contains covariates for each sample to include in model.

Needs to be whitespace delimited file that has a header (the actual name of columns doesn't matter though).

The 1st column needs to be the sample names while all other columns will be included as covariates.

For example:

	Taxa    covariate1     covariate2     covariate3 					
	sample1       -0.17818819     15.747446       -4.0947742 		
	sample2        -29.861116      -15.339654      5.7414823  		
 	sample3         8.937294        0.14481565      3.955948  		
 	sample4        -33.976486      -13.577191      10.548095  	
		

=item B<--carat <PATH to CARAT binary>>

Required. The exact PATH to the CARAT binary you want to use. 

For example:
/home/smyles/myles_lab/bin/CARAT_v1.3/bin/CARAT



=item B<--pheno_list <textfile>>

Optional. A textfile with all the phenotypes you want to include (1 per line). 


=item B<--pheno <textfile>>

Required. A whitespace-delimited table with sample names as the first column and the traits as the remaining columns. The first line is assumed to be a header and will be ignored. All values besides 0 and 1 will be ignored (that sample will be removed from the GWAS for that trait).

For example:

	Taxa trait1 trait2 trait3  
	sample1 0 1 0  
	sample2 1 1 1  
	sample3 0 NA 1  
	sample4 1 0 NA  


=item B<--geno <plink prefix>>

Required. Plink prefix for the .ped and .map files that contain the markers that should be used for the association analysis (they will be prepped for input for each trait separately).

=item B<--grm_geno <plink prefix>>

Required. Plink prefix for the .ped and .map files that should be used to build the GRM for all phenotypes. This can be the same file as used for --geno.

=item B<--maf <float>>

Optional. Option for minimum minor allele frequency after removing samples with missing phenotype data (default is 0.01).

=back

=head1 DESCRIPTION

B<run_CARAT.pl> This script wraps CARAT to run GWAS on binary traits.

This script performs these steps:

	- reads in covariates, if set
	- reads in subset of phenotypes to keep, if set
	- reads in all phenotypes and keeps track of the values for all or a subset of them.
	- preps the CARAT input file for each phenotype.
	- converts plink files to CARAT input format (.tped with header).
	- wraps CARAT to calculate GRM once and uses this GRM for all phenotypes.
	- wraps CARAT on each phenotype
	
Note that the "plink" binary must be in your PATH. 

Also the samples in the .ped files must have the same family and sample IDs. You can replace all family IDs by the sample IDs with this command:

awk '{ $1=$2; print $0 }' IN.ped > OUT.ped 

	
CARAT citation:
Jiang D., Zhong S., McPeek M. S. (2016). Retrospective Binary-Trait Association Test Elucidates Genetic Architecture of Crohn Disease. The American Journal of Human Genetics 98:243-255

CARAT website: 
http://www.stat.uchicago.edu/~mcpeek/software/CARAT/


=head1 AUTHOR

Gavin Douglas <gavin.douglas@dal.ca> 

=cut


