use inc::Module::Install;
name 'Bot-IRC';
all_from 'lib/Bot/IRC.pm';

requires 'Mouse' => 0.14;
requires 'MouseX::Log::Dispatch::Config';
requires 'POE';
requires 'POE::Component::IRC';
requires 'POE::Sugar::Args';
requires 'Config::Any';
requires 'Storable';
requires 'User';

tests 't/*.t';
test_requires 'Test::More';
test_requires 'ok';
author_tests 'xt';
use_test_base;

auto_include_deps;
WriteAll;
