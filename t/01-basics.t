#!perl

use 5.010001;
use strict;
use warnings;

use File::Temp qw(tempdir tempfile);
use Module::Path::More qw(module_path pod_path);
use Test::More 0.98;

subtest module_path => sub {
    ok(module_path(module=>'strict'));
    ok(module_path(module=>'strict.pm'));
    ok(module_path(module=>'Module::Path::More'));
    ok(module_path(module=>'Module/Path/More.pm'));

    # XXX opt: all
    # XXX opt: abs
    # XXX opt: find_pm
    # XXX opt: find_pmc
    # XXX opt: find_pod

    subtest "opt: find_prefix" => sub {
        ok(!module_path(module=>'Module'));
        ok( module_path(module=>'Module', find_prefix=>1));
    };

    {
        local @INC;

        my ($fh, $filename) = tempfile();
        my $dir = tempdir(CLEANUP => 1);

        # we're fine (don't die) when an entry in @INC doesn't exist
        @INC = ("$dir/1");
        ok(!module_path(module=>'strict'));

        # we're fine (don't die) when an entry in @INC is not a dir
        @INC = ($filename);
        ok(!module_path(module=>'strict'));

        # we're fine (don't die) when an entry in @INC is not readable
        mkdir "$dir/2", ; chmod 0111, "$dir/2";
        @INC = ("$dir/2");
        ok(!module_path(module=>'strict'));

        # we're fine (don't die) when an entry in @INC is not accessible (-x)
        mkdir "$dir/3", ; chmod 0, "$dir/3";
        @INC = ("$dir/3");
        ok(!module_path(module=>'strict'));
    }
};

#subtest pod_path => sub {
#};

DONE_TESTING:
done_testing;
