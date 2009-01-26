package Bot::IRC::Plugin::Echo;

use Bot::IRC::Plugin;

hook 'PRIVMSG' => sub {
    my ($self, $from, $channel, $body) = @_;

    my $message = sprintf "%s said: %s", $from, $body;
    $self->notice($channel => $message);
};

hook 'TALK' => sub {
    my ($self, $from, $body) = @_;

    my $message = sprintf "%s told: %s", $from, $body;
    $self->notice($from => $message);
};

1;
