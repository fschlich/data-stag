package Data::Stag::ChainHandler;

=head1 NAME

  Data::Stag::ChainHandler

=head1 SYNOPSIS


=cut

=head1 DESCRIPTION


=head1 PUBLIC METHODS -

=cut

use strict;
use base qw(Data::Stag::Base Data::Stag::Writer);

use vars qw($VERSION);
$VERSION="0.07";

sub init {
    my $self = shift;
    return;
}

sub subhandlers {
    my $self = shift;
    $self->{_subhandlers} = shift if @_;
    return $self->{_subhandlers};
}

sub blocked_event {
    my $self = shift;
    if (@_) {
        my $e = shift;
        $self->{_blocked_event} = $e;
        unless (ref($e)) {
            $e = [$e];
        }
        my %h = map {$_=>1} @$e;
        $self->blocked_event_h(\%h);
    }
    return $self->{_blocked_event};
}

sub blocked_event_h {
    my $self = shift;
    $self->{_blocked_event_h} = shift if @_;
    return $self->{_blocked_event_h};
}

sub is_blocked {
    my $self = shift;
    my $e = shift;
    my $is = $self->blocked_event_h->{$e};
    return $is;
}

sub start_event {
    my $self = shift;
    my $ev = shift;
    my $stack = $self->elt_stack;
    push(@$stack, $ev);

    my $sh = $self->subhandlers;
    my $is_blocked = grep {$self->is_blocked($_)} @$stack;
    if ($is_blocked) {
        $sh->[0]->start_event($ev);
    }
    else {
        foreach (@$sh) {
            $_->start_event($ev);
        }
    }
}

sub evbody {
    my $self = shift;
    my $ev = shift;
    my @args = @_;

    my $stack = $self->elt_stack;

    my $sh = $self->subhandlers;
    if (grep {$self->is_blocked($_)} @$stack) {
        $sh->[0]->evbody($ev, @args);
    }
    else {
        foreach (@$sh) {
            $_->evbody($ev, @args);
        }
    }
    
    return;
}

sub event {
    my $self = shift;
    my $ev = shift;
    my @args = @_;
    my $stack = $self->elt_stack;

    my $sh = $self->subhandlers;

    my $is_blocked = grep {$self->is_blocked($_)} @$stack;
    if ($is_blocked) {
        $sh->[0]->event($ev, @args);
    }
    else {
        foreach (@$sh) {
            $_->event($ev, @args);
        }
    }
}

sub end_event {
    my $self = shift;
    my $ev = shift;

    my $stack = $self->elt_stack;
    pop @$stack;

    my $sh = $self->subhandlers;

    my $is_blocked = grep {$self->is_blocked($_)} @$stack;
    if ($self->is_blocked($ev) &&
	!$is_blocked) {

	# condition:
	# end of a blocked event, and we are 
	# not inside another blocked event
        my ($h, @rest) = @$sh;

        my @R = $h->end_event($ev);
        foreach my $handler (@rest) {
#            my $tree = $h->tree;
            #$handler->event(@$tree) if $tree->[0];
	    if (@R) {
		$handler->event(@$_) foreach @R;
		$_->free foreach @R;
	    }
        }
#        use Data::Dumper;
#        print Dumper $node->[-1];
#        die;
#        @$topnode = ();
        my $tree = $h->tree;
        $tree->free;
#        $h->tree([]);
    }
    else {

        if (grep {$self->is_blocked($_)} @$stack) {
            $sh->[0]->end_event($ev);
        }
        else {
            foreach (@$sh) {
                $_->end_event($ev);
            }
        }
    }
}

1;
