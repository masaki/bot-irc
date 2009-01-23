package Bot::IRC::Session;

use Mouse;
use POE::Sugar::Args;
use POE::Kernel;
use POE::Session;

has 'agent' => (
    is  => 'rw',
    isa => 'Bot::IRC::Agent',
);

sub run {
    my $self = shift;

    POE::Session->create(
        object_states => [
            $self => {
                _start           => 'handle_start',
                connect          => 'handle_connect',
                irc_001          => 'handle_connected',
                irc_433          => 'handle_nick_taken',
                irc_public       => 'handle_public',
                irc_msg          => 'handle_msg',
                irc_disconnected => 'handle_reconnect',
                irc_error        => 'handle_reconnect',
                irc_socketerr    => 'handle_reconnect',
                autoping         => 'handle_autoping',
            },
        ],
    );

    POE::Kernel->sig(INT => sub { POE::Kernel->stop });
    POE::Kernel->run;
}

sub handle_start {
    my $poe = sweet_args;

    $poe->object->agent->yield(register => 'all');
    $poe->kernel->yield('connect');
}

sub handle_connect {
    my $agent = sweet_args->object->agent;

    $agent->yield(connect => {
        Server   => $agent->host,
        Port     => $agent->port,
        Nick     => $agent->nick,
        Ircname  => $agent->nick,
        Username => $agent->user,
        Password => $agent->pass,
    });
}

sub handle_connected {
    my $agent = sweet_args->object->agent;

    $agent->yield(charset => $agent->charset);
    for my $channel (@{ $agent->channels }) {
        $agent->yield(join => $channel);
    }
}

sub handle_nick_taken {
    my $agent = sweet_args->object->agent;

    $agent->nick($agent->nick . '_');
    $agent->log->info("nick taken, trying new nick " . $agent->nick);
    $agent->yield(nick => $agent->nick);
}

sub handle_public {
    my $poe   = sweet_args;
    my $agent = $poe->object->agent;

    my ($who, $where, $what) = @{ $poe->args };
    eval { $agent->fire(msg => [ split /!/, $who ]->[0], $where->[0], $what) };
}

sub handle_msg {
    my $poe   = sweet_args;
    my $agent = $poe->object->agent;

    my ($who, $where, $what) = @{ $poe->args };
    eval { $agent->fire(talk => [ split /!/, $who ]->[0], $what) };
}

sub handle_reconnect {
    my $poe = sweet_args;

    $poe->object->agent->log->info("reconnect: " . $poe->arg->[0]);
    $poe->kernel->delay(autoping => undef);
    $poe->kernel->delay(connect => 60);
};

sub handle_autoping {
    my $poe   = sweet_args;
    my $agent = $poe->object->agent;

    $agent->yield(userhost => $agent->nick);
    $poe->kernel->delay(autoping => 300);
}

no Mouse; __PACKAGE__->meta->make_immutable; 1;
