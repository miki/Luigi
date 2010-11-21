package Luigi::Node;
use strict;
use warnings;
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors($_)
    for qw( centroid child_nodes leaf parent similarity );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( {@_} );
    $self->child_nodes( [] );
    return $self;
}

sub add {
    my $self  = shift;
    my $point = shift;
    push @{ $self->child_nodes }, $point;
}

sub is_leaf {
    my $self = shift;
    return $self->child_nodes->[0]->leaf ? 1 : 0;
}

sub siblings {
    my $self     = shift;
    my $siblings = $self->parent->child_nodes;
    return $siblings;
}

sub centroid_words {
    my $self     = shift;
    my $word_num = shift || 5;
    my $centroid = $self->centroid;
    my @array;
    for ( sort { $centroid->{$b} <=> $centroid->{$a} } keys %{$centroid} ) {
        push @array, $_;
        last if @array == $word_num;
    }
    return \@array;
}

1;