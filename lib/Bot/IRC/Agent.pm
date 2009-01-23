package Bot::IRC::Agent;

use Mouse;
use POE::Component::IRC;
use User;

has 'host' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'port' => (
    is      => 'rw',
    isa     => 'Int',
    default => 6667,
);

has 'nick' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'user' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { User->Login },
);

has 'pass' => (
    is  => 'rw',
    isa => 'Str|Undef',
);

has 'charset' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => 'UTF-8',
);

has 'channels' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

has 'event' => (
    is      => 'rw',
    isa     => 'POE::Component::IRC',
    default => sub { POE::Component::IRC->spawn },
    handles => ['yield'],
);

has 'log' => (
    is  => 'rw',
    isa => 'Bot::IRC::Log',
);

has 'plugins' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

sub load_plugins {
    my ($self, $plugins) = @_;
    $self->load_plugin($_) for @$plugins;
}

sub load_plugin {
    my ($self, $config) = @_;

    my $module = delete $config->{module};
    if ($module !~ s/^\+//) {
        $module =~ s/^Bot::IRC::Plugin:://;
        $module = "Bot::IRC::Plugin::$module";
    }

    eval {
        Mouse::load_class($module);
    };
    if ($@) {
        $self->log->error("Failed to load plugin: $module $@");
    }
    else {
        my $plugin = $module->new(
            $config->{config} ? (config => $config->{config}) : (),
        );
        push @{ $self->plugins }, $self->setup_plugin($plugin);
    }
}

{
    my @commands = qw(ctcp mode notice privmsg topic);

    sub setup_plugin {
        my ($self, $plugin) = @_;

        for my $command (@commands) {
            $plugin->meta->add_method($command => sub {
                shift;
                $self->event->yield($command => @_);
            });
        }

        $plugin;
    }
}

sub fire {
    my ($self, $event, @args) = @_;

    $self->log->debug("fire event: $event");

    my $method = "on_${event}";
    for my $plugin (@{ $self->plugins }) {
        if ($plugin->can($method)) {
            $plugin->$method(@args);
        }
    }
}

no Mouse; __PACKAGE__->meta->make_immutable; 1;
