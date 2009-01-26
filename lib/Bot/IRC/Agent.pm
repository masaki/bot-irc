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

# FIXME: MouseX::Plaggerize, MouseX::Trigger
has 'hooks' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { +{} },
);

has 'log' => (
    is  => 'rw',
    isa => 'Bot::IRC::Log',
);

sub load_plugins {
    my ($self, $args) = @_;
    for my $config (@{ $args || [] }) {
        $self->load_plugin($config);
    }
}

sub load_plugin {
    my ($self, $args) = @_;

    $args = { module => $args } unless ref $args;

    my $module = $args->{module};
    $module = $self->resolve_plugin($module, 'Bot::IRC');

    eval {
        Mouse::load_class($module);
    };
    if ($@) {
        $self->log->error("Failed to load plugin: $module $@");
    }
    else {
        my $plugin = $module->new(%{ $args->{config} || {} });
        $plugin->register($self);
    }
}

sub resolve_plugin {
    my ($self, $module, $base) = @_;

    $base ||= blessed $self; # TODO: _plugin_app_ns ?
    my $plugin_ns = 'Plugin'; # TODO: _plugin_ns ?

    return ($module =~ /^\+(.*)$/) ? $1 : "${base}::${plugin_ns}::${module}";
}

sub register_hook {
    my ($self, @hooks) = @_;

    while (my ($hook, $plugin, $code) = splice @hooks, 0, 3) {
        $self->hooks->{$hook} ||= [];
        push @{ $self->hooks->{$hook} }, +{
            plugin => $plugin,
            code   => $code,
        };
    }
}

sub run_hook {
    my ($self, $hook, @args) = @_;

    return unless my $hooks = $self->hooks->{$hook};

    for my $hook (@$hooks) {
        $hook->{code}->($hook->{plugin}, $self, @args);
    }
}

{
    my @commands = qw(ctcp mode notice privmsg topic);

    for my $command (@commands) {
        __PACKAGE__->meta->add_method($command, sub {
            my ($self, @args) = @_;
            $self->yield($command, @args);
        });
    }
}

no Mouse; __PACKAGE__->meta->make_immutable; 1;
