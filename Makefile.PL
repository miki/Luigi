use inc::Module::Install;
name 'Luigi';
all_from 'lib/Luigi.pm';

# requires '';

requires 'Class::Accessor::Fast';
requires 'Text::Bayon';
requires 'Scalar::Util';
requires 'List::Util';
requires 'Storable';
requires 'List::PriorityQueue';


tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
