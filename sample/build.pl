use strict;
use warnings;
use FindBin;
use File::Spec;
use Luigi;

print "Now building index file. please wait.\n";

my $gzip_file = File::Spec->catfile( $FindBin::Bin, "data", "sample.txt.gz" );
`gzip -d $gzip_file` if -e $gzip_file;

my $bag_of_words;
open FILE, "<", File::Spec->catfile( $FindBin::Bin, "data", "sample.txt" );
while (<FILE>) {
    chomp $_;
    my @f      = split "\t", $_;
    my $label  = shift @f;
    my %vector = @f;
    $bag_of_words->{$label} = \%vector;
}
close(FILE);

my $luigi = Luigi->new;
$luigi->build($bag_of_words);
$luigi->save( File::Spec->catfile( $FindBin::Bin, "data", "save.bin" ) );

print "Done!\n";
