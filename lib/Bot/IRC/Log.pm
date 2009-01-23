package Bot::IRC::Log;

use Mouse;

with 'MouseX::Log::Dispatch::Config';

no Mouse; __PACKAGE__->meta->make_immutable; 1;
