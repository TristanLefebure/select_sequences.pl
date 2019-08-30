#! /usr/bin/perl

#Tristan Lefebure,  2008-01-21, Licenced under the GPL

#2 Jan 2012: greedy option

use warnings;
use strict;

use Bio::SeqIO;
# use Bio::PrimarySeq;
use Getopt::Long;

my $format = 'fasta';
my $help= '';
my $greedy;
my $nolist;
my $col;



GetOptions(
	'help|?' => \$help,
	'format:s'  => \$format,
	'greedy' => \$greedy,
	'nolist' => \$nolist,
	'column=i' => \$col,
);

my $printhelp = "\nUsage: $0 [OPTIONS] <sequence file> <list of ids> <output>\n\nWill select the sequences matching with the list of ids. BioPerl is required.

Options:
	-h: print this help
	-f: give the input and output format (default=fasta)
	-greedy, uses a regular expression /^\$id/
	-nolist, do not use a file of id names, instead gives one id name at the command line
	-col <>, the list is actually a table in tsv format, col specifies the column to use\n";


if ($help or $#ARGV < 2) { 
	print $printhelp;
	exit;
}


my $seqio = Bio::SeqIO->new(-file   => $ARGV[0],
                           -format => $format );
my $seqout = Bio::SeqIO->new(-file   => ">$ARGV[2]",
                           -format => $format );

my %ids;
my @list;

if($nolist) {
    $ids{$ARGV[1]} = 1;
    push @list, $ARGV[1];
}
else {
    open IN, $ARGV[1];
    @list = <IN>;
    chomp @list;
    foreach (@list) {
	    if($col) {
		my @f = split "\t";
		$ids{$f[$col - 1]} = 1;
	    }
	    else { $ids{$_} = 1 }
    }
}

my $n = 0;
while(my $seqo = $seqio->next_seq()) {
	
	if($greedy) {
	    my $id = $seqo->display_id();
	    foreach my $head (@list) {
# 		print "looking for $head in $id\n";
			if($id =~ /^$head/) {
				$seqout->write_seq($seqo);
				++$n;
				++$ids{$seqo->display_id()};
				last;
			}
	    }
	}
	else {
	    if(exists $ids{$seqo->display_id()}) {
		    $seqout->write_seq($seqo);
		    ++$n;
		    ++$ids{$seqo->display_id()};
	    }
	}
}

foreach (sort keys %ids) {
	unless($greedy) { if($ids{$_} == 1) { print "Could not find: $_\n" } }
}


print "$n sequences written to the file $ARGV[2]\n";
