package Bot::IRC::Plugin::Karma;

use Bot::IRC::Plugin;
use MouseX::Types::Path::Class;
use Path::Class::File;
use YAML;

has 'datafile' => (
    is      => 'rw',
    isa     => 'Path::Class::File',
    lazy    => 1,
    default => sub { Path::Class::File->new('plusplus.yaml') },
    coerce  => 1,
);

sub BUILD {
    my $self = shift;

    unless (-f $self->datafile) {
        $self->datafile->openw;
    }
}

hook 'PRIVMSG' => sub {
    my ($self, $bot, $from, $channel, $body) = @_;

    my $re;
    $re = qr/\([^()]*(?:(??{$re})[^()]*)*\)/;

    no warnings 'uninitialized';

    if ($body =~ /^karma\:\s+(\S+)/i) {
        my $nick = $self->trim($1);
        $self->notice($bot, $nick, $channel);
    }
    elsif ($body =~ /^($re|\S+)(\+\+|--)/) {
        my ($nick, $op) = ($self->trim($1), $2);

        my $karma = YAML::LoadFile($self->datafile);
        ($karma->{$channel}->{$nick} ||= { '++' => 0, '--' => 0 })->{$op}++;
        YAML::DumpFile($self->datafile, $karma);

        $self->notice($bot, $nick, $channel);
    }
};

sub notice {
    my ($self, $bot, $nick, $channel) = @_;

    my $karma = YAML::LoadFile($self->datafile);

    my $plus  = $karma->{$channel}->{$nick}->{'++'} || 0;
    my $minus = $karma->{$channel}->{$nick}->{'--'} || 0;

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
