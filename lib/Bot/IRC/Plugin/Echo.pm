package Bot::IRC::Plugin::Echo;

use Bot::IRC::Plugin;

sub on_privmsg {
    my ($self, $from, $channel, $body) = @_;

    my $message = sprintf "%s said: %s", $from, $body;
    $self->notice($channel => $message);
}

sub on_talk {
    my ($self, $from, $body) = @_;

    my $message = sprintf "%s told: %s", $from, $body;
    $self->notice($from => $message);
}

1;
