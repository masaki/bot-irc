package MouseX::Object::Hookable;

use 5.8.1;
use Mouse::Role;

our $VERSION = '0.01';

has _mousex_object_hookable_hooks => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { +{} },
);

sub register_hook {
    my ($self, $trigger, @args) = @_;

    while (my ($point, $callback) = splice @args, 0, 2) {
        $self->_mousex_object_hookable_hooks->{$point} ||= [];
        push @{ $self->_mousex_object_hookable_hooks->{$point} }, +{
            trigger  => $trigger,
            callback => $callback,
        };
    }
}

sub clear_hooks {
    my ($self, @points) = @_;

    for my $point (@points) {
        if (exists $self->_mouse_object_hookable_hooks->{$point}) {
            delete $self->_mouse_object_hookable_hooks->{$point};
        }
    }
}

sub run_hook {
    my ($self, $point, @args) = @_;

    my @results;
    for my $hook (@{ $self->_mousex_object_hookable_hooks->{$point} || [] }) {
        push @results, $self->_run_hook($hook, @args);
    }

    return @results;
}

sub run_hook_first {
    my ($self, $point, @args) = @_;

    for my $hook (@{ $self->_mousex_object_hookable_hooks->{$point} || [] }) {
        if (my $res = $self->_run_hook($hook, @args)) {
            return $res;
        }
    }

    return;
}

sub _run_hook {
    my ($self, $hook, @args) = @_;
    return $hook->{callback}->($hook->{trigger}, $self, @args);
}

no Mouse::Role; 1;
