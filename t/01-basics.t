#!perl

use 5.010001;
use strict;
use warnings;

use Module::Path qw(module_path pod_path);
use Test::More 0.98;

subtest module_path => sub {
    ok(module_path('strict'));
    ok(module_path('strict.pm'));
    ok(module_path('Module::Path'));
    ok(module_path('Module/Path.pm'));

    # XXX opt: all=>1
    # XXX opt: abs=>1
    # XXX opt: find_pm=>1
    # XXX opt: find_pmc=>1
    # XXX opt: find_pod=>1
};

#subtest pod_path => sub {
#};

DONE_TESTING:
done_testing;
