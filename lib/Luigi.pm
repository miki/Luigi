package Luigi;
use strict;
use warnings;
use Luigi::Node;
use Luigi::VectorTool;
use Text::Bayon;
use Scalar::Util qw(blessed refaddr);
use Storable qw(nstore retrieve);
use List::PriorityQueue;
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors($_) for qw( tree vector_tool priority_queue );

our $VERSION = '0.00001_00';

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    $self->vector_tool( Luigi::VectorTool->new );
    return $self;
}

sub build {
    my $self    = shift;
    my $vectors = shift;
    my @node_array;
    for my $id ( keys %$vectors ) {
        my $node = Luigi::Node->new();
        $node->leaf($id);
        $node->centroid( $vectors->{$id} );
        push @node_array, $node;
    }
    my $tree = $self->_stack_loop( \@node_array, 0 );
    $self->tree($tree);
    return $tree;
}

sub save {
    my $self = shift;
    my $save_file_name = shift || "store.bin";
    nstore( $self->tree, $save_file_name );
}

sub load {
    my $self           = shift;
    my $save_file_name = shift || "store.bin";
    my $tree           = retrieve($save_file_name);
    $self->tree($tree);
    return $tree;
}

sub find {
    my $self   = shift;
    my $vector = shift;
    my $num    = shift;

    $self->vector_tool->unit_length($vector);
    my $queue = $self->priority_queue || sub {
        $self->priority_queue( List::PriorityQueue->new );
        }
        ->();

    # Rootノードをキューにいれておく
    for my $node ( @{ $self->tree } ) {
        my $sim = $self->vector_tool->cosine_similarity( $vector,
            $node->centroid );
        $queue->insert( $node, 1 / ( $sim + 0.0000001 ) );
    }

    $self->{result} = [];
    my ( $result, $n ) = $self->_traverse( $vector, $num );

    # queueをきれいにしておく
    $queue->{prios} = {};
    $queue->{queue} = [];

    return $result;
}

sub _stack_loop {
    my $self           = shift;
    my $node_array_ref = shift;
    my $count          = shift || 0;
    $count++;

    ## node_array_refからあらたにクラスタリング対象となるベクトルを作る
    ## 作ったベクトルをbayon でクラスタリング
    my $bayon_in;
    my $word_counter;
    for ( my $i = 0; $i < int @$node_array_ref; $i++ ) {
        my $node   = $node_array_ref->[$i];
        my $vector = $node->centroid;
        $bayon_in->{$i} = $vector;
        for ( keys %$vector ) {
            $word_counter->{$_}++;
        }
    }
    my $word_num = int keys %$word_counter;
    $word_num = 100;    #?
    my ( $cluster, $clvector )
        = Text::Bayon->new->clustering( $bayon_in,
        { idf => 1, l => 1.5, clvector => 1, clvector_size => $word_num } );

    ## クラスタリング結果からあらたなノードのセットを作る
    my @new_node_array;
    while ( my ( $c_id, $points ) = each %$cluster ) {
        my %centroid = @{ $clvector->{$c_id} };
        my $new_node = Luigi::Node->new();
        $new_node->centroid( \%centroid );
        for my $p_id (@$points) {
            my $child_node = $node_array_ref->[$p_id];
            $child_node->parent($new_node);
            $new_node->add($child_node);
        }
        push @new_node_array, $new_node;
    }

    ## あらたなノードセットたちを引数としてstack_loopを再起呼び出し
    if ( int @new_node_array > 10 ) {
        $self->_stack_loop( \@new_node_array, $count );
    }
    else {
        return \@new_node_array;
    }
}

sub _traverse {
    my $self    = shift;
    my $wordset = shift;
    my $num     = shift || 20;

    my $result   = $self->{result};
    my $vec_tool = $self->vector_tool;
    my $queue    = $self->priority_queue;

    my %similarities;

    # queueをループ
    my @array;
LABEL:
    while ( @{ $queue->{queue} } > 0 ) {

        my $node = $queue->pop;
        if ( $node->is_leaf ) {
            last LABEL if @$result > $num;
            for ( @{ $node->child_nodes } ) {
                push @$result, $_;
            }
        }
        else {
            push @array, $node;
            last if @array == 2;
        }
    }

    if ( @$result > $num ) {

        for (@$result) {
            my $sim = $self->vector_tool->cosine_similarity( $wordset,
                $_->centroid );
            $_->similarity($sim);
        }

        @$result = sort { $b->similarity <=> $a->similarity } @$result;
        return $result;
    }
    else {
        for my $node (@array) {
            my $child_nodes = $node->child_nodes;
            for my $child_node (@$child_nodes) {
                my $sim = $self->vector_tool->cosine_similarity( $wordset,
                    $child_node->centroid );
                $queue->insert( $child_node, 1 / ( $sim + 0.0000001 ) );
            }
        }

        $self->_traverse( $wordset, $num );
    }
}

1;
__END__

=head1 NAME

Luigi -

=head1 SYNOPSIS

  use Luigi;

=head1 DESCRIPTION

Luigi is

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
