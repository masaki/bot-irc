package Bot::IRC::Plugin;

use Mouse;
use parent qw(Exporter);

our @EXPORT = qw(hook register);

{
    my $hooks = {};

    sub hook {
        my ($hook, $code) = @_;
        push @{ $hooks->{caller(0)} }, { name => $hook, code => $code };
    }

    sub register {
        my ($self, $context) = @_;
        for my $hook (@{ $hooks->{blessed $self} || [] }) {
            $context->register_hook($hook->{name}, $self, $hook->{code});
        }
    }
}

sub import {
    __PACKAGE__->export_to_level(1);
    goto &Mouse::import;
}

no Mouse; __PACKAGE__->meta->make_immutable; 1;
