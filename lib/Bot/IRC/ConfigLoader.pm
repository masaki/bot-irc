package Bot::IRC::ConfigLoader;

use Mouse;
use Config::Any;
use Storable qw(dclone);

sub load {
    my ($class, $stuff) = @_;

    return +{}            unless defined $stuff;
    return dclone($stuff) if ref($stuff) and ref($stuff) eq 'HASH';

    my $config = Config::Any->load_files({
        files       => [ $stuff ],
        use_ext     => 1,
        driver_args => { General => { -LowerCaseNames => 1 } }
    });

    return $config->[0]->{$stuff} || +{};
}

no Mouse; __PACKAGE__->meta->make_immutable; 1;
