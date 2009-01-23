package Bot::IRC::Plugin;

use Mouse::Role;

has 'config' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { +{} },
);

sub import {
    require Mouse;
    goto &Mouse::import;
    __PACKAGE__->meta->apply(caller->meta);
}

no Mouse::Role; 1;
