package Bot::IRC::Plugin::Karma;

use Bot::IRC::Plugin;

my $re = '(\([^\)]+?\)|\S+?)';
my $karma = {};

hook 'PRIVMSG' => sub {
    my ($self, $bot, $from, $channel, $body) = @_;

    if ($body =~ /karma for $re/i) {
        my $nick = $self->trim($1);
        $self->notice($bot, $nick, $channel);
    }
    elsif ($body =~ /$re(\+\+|--)/i) {
        my ($nick, $op) = ($self->trim($1), $2);

        ($karma->{$nick} ||= { '++' => 0, '--' => 0 })->{$op}++;
        $self->notice($bot, $nick, $channel);
    }
};

sub notice {
    my ($self, $bot, $nick, $channel) = @_;

    my $plus  = $karma->{$nick}->{'++'} || 0;
    my $minus = $karma->{$nick}->{'--'} || 0;

    my $message = sprintf '%s: %d (%d++ %d--)', $nick, ($plus - $minus), $plus, $minus;
    $bot->notice($channel => $message);
}

sub trim {
    my $self = shift;

    local $_ = shift;
    if (/^\(/ and /\)$/) {
        s/^\(//;
        s/\)$//;
    }

    $_;
}

1;
