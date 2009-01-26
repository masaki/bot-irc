package Bot::IRC::Plugin::Karma;

use Bot::IRC::Plugin;
use YAML;

my $karma = {};

sub on_privmsg {
    my ($self, $from, $channel, $body) = @_;

    my $re = '(\([^\)]+?\)|\S+?)';

    if ($body =~ /karma for $re/i) {
        my $nick = $self->trim($1);
        $self->notice_karma_for($nick, $channel);
    }
    elsif ($body =~ /$re(\+\+|--)/i) {
        my ($nick, $op) = ($self->trim($1), $2);

        ($karma->{$nick} ||= { '++' => 0, '--' => 0 })->{$op}++;
        $self->notice_karma_for($nick, $channel);
    }
}

sub notice_karma_for {
    my ($self, $nick, $channel) = @_;

    my $plus  = $karma->{$nick}->{'++'} || 0;
    my $minus = $karma->{$nick}->{'--'} || 0;

    my $message = sprintf '%s: %d (%d++ %d--)', $nick, ($plus - $minus), $plus, $minus;
    $self->notice($channel => $message);
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
