package Bot::IRC;

use 5.8.1;
use Mouse;
use User;
use Bot::IRC::ConfigLoader;
use Bot::IRC::Log;
use Bot::IRC::Agent;
use Bot::IRC::Session;

our $VERSION = '0.01';

has 'config' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { +{} },
);

has 'session' => (
    is      => 'rw',
    isa     => 'Bot::IRC::Session',
    handles => ['run'],
);

sub bootstrap {
    my ($class, %args) = @_;

    if (exists $args{config} and -e $args{config} and -r _) {
        $args{config} = Bot::IRC::ConfigLoader->load($args{config});
    }

    my $self = $class->new(%args);
    $self->run;
    $self;
}

sub BUILD {
    my $self = shift;

    my $config = $self->config->{global};

    # log
    my $log = Bot::IRC::Log->new(config => {
        class     => 'Log::Dispatch::Screen',
        min_level => $config->{log}->{level} ||= 'info',
        stderr    => 1,
        format    => '[%d] [%p] %m%n',
    });

    # agent
    my $agent = Bot::IRC::Agent->new(
        host     => $config->{host},
        port     => $config->{port}     ||= 6667,
        nick     => $config->{nick},
        user     => $config->{user}     ||= User->Login,
        pass     => $config->{pass},
        charset  => $config->{charset}  ||= 'UTF-8',
        channels => $config->{channels} ||= [],
    );

    $agent->log($log);
    $agent->load_plugins($self->config->{plugins} ||= []);

    # session
    $self->session( Bot::IRC::Session->new(agent => $agent) );
}

no Mouse; __PACKAGE__->meta->make_immutable; 1;

=head1 NAME

Bot::IRC

=head1 SYNOPSIS

    #!/usr/bin/perl

    use Bot::IRC;

    Bot::IRC->bootstrap(config => '/path/to/config.yaml')->run;

    # config.yaml
    ---
    global:
      host: irc.example.com
      nick: ircbot
      channels:
        - "#bot1"
        - "#bot2"
    plugins:
      - module: Echo

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<POE::Component::IRC>, L<Mouse>

=cut
