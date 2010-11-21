use strict;
use warnings;
use blib;
use File::Spec;
use FindBin;
use Luigi;
use Lingua::JA::Expand;
use Time::HiRes qw( gettimeofday tv_interval );

my $luigi = Luigi->new;
$luigi->load( File::Spec->catfile( $FindBin::Bin, "data", "save.bin" ) );

my $expander = Lingua::JA::Expand->new( yahoo_api_appid => 'test' );

loop();

sub loop {
    print "Input keyword: ";
    my $keyword = <>;
    chomp $keyword;

    loop() if !$keyword;

    my $t0             = [gettimeofday];
    my $vector         = expand($keyword);
    my $expand_elapsed = tv_interval($t0);

    if ( !$vector ) {
        print "Can't expand keyword. try again.";
        loop();
    }

    my $t1                 = [gettimeofday];
    my $result             = $luigi->find( $vector, 100 );
    my $sim_search_elapsed = tv_interval($t1);

    if ( $result->[0]->similarity < 0.1 ) {
        print "No hit, try again another keyword.\n";
        loop();
    }
    else {
        for (@$result) {
            next if $_->similarity < 0.1;
            print $_->similarity, "\t";
            print $_->leaf,       "\t";
            print "\n";
        }

        print "-" x 100, "\n";

        print "[keyword expand elapsed   ] ", $expand_elapsed,     "\n";
        print "[similarity search elapsed] ", $sim_search_elapsed, "\n";

        print "\n", "-" x 100, "\n";
    }

    loop();
}

sub expand {
    my $keyword      = shift;
    my $bag_of_words = $expander->expand($keyword);
    return $bag_of_words;
}
