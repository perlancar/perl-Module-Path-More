package Module::Path::More;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::Util qw(gen_modified_sub);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(module_path pod_path);

my $SEPARATOR;

our %SPEC;

BEGIN {
    if ($^O =~ /^(dos|os2)/i) {
        $SEPARATOR = '\\';
    } elsif ($^O =~ /^MacOS/i) {
        $SEPARATOR = ':';
    } else {
        $SEPARATOR = '/';
    }
}

$SPEC{module_path} = {
    v => 1.1,
    summary => 'Get path to locally installed Perl module',
    description => <<'_',

Search `@INC` (reference entries are skipped) and return path(s) to Perl module
files with the requested name.

This function is like the one from `Module::Path`, except with a different
interface and more options (finding all matches instead of the first, the option
of not absolutizing paths, finding `.pmc` & `.pod` files, finding module
prefixes).

_
    args => {
        module => {
            summary => 'Module name to search',
            schema  => 'str*',
            req     => 1,
            pos     => 0,
        },
        find_pm => {
            summary => 'Whether to find .pm files',
            schema  => 'bool',
            default => 1,
        },
        find_pmc => {
            summary => 'Whether to find .pmc files',
            schema  => 'bool',
            default => 1,
        },
        find_pod => {
            summary => 'Whether to find .pod files',
            schema  => 'bool',
            default => 0,
        },
        find_prefix => {
            summary => 'Whether to find module prefixes',
            schema  => 'bool',
            default => 0,
        },
        all => {
            summary => 'Return all results instead of just the first',
            schema  => 'bool',
            default => 0,
        },
        abs => {
            summary => 'Whether to return absolute paths',
            schema  => 'bool',
            default => 0,
        },
    },
    result => {
        schema => ['any' => of => ['str*', ['array*' => of => 'str*']]],
    },
    result_naked => 1,
};
sub module_path {
    my %args = @_;

    my $module = $args{module} or die "Please specify module";

    $args{abs}         //= 0;
    $args{all}         //= 0;
    $args{find_pm}     //= 1;
    $args{find_pmc}    //= 1;
    $args{find_pod}    //= 0;
    $args{find_prefix} //= 0;

    require Cwd if $args{abs};

    my @res;
    my $add = sub { push @res, $args{abs} ? Cwd::abs_path($_[0]) : $_[0] };

    my $relpath;

    ($relpath = $module) =~ s/::/$SEPARATOR/g;
    $relpath =~ s/\.(pm|pmc|pod)\z//i;

    foreach my $dir (@INC) {
        next if not defined($dir);
        next if ref($dir);

        my $prefix = $dir . $SEPARATOR . $relpath;
        if ($args{find_pmc}) {
            my $file = $prefix . ".pmc";
            if (-f $file) {
                $add->($file);
                last unless $args{all};
            }
        }
        if ($args{find_pm}) {
            my $file = $prefix . ".pm";
            if (-f $file) {
                $add->($file);
                last unless $args{all};
            }
        }
        if ($args{find_pod}) {
            my $file = $prefix . ".pod";
            if (-f $file) {
                $add->($file);
                last unless $args{all};
            }
        }
        if ($args{find_prefix}) {
            if (-d $prefix) {
                $add->($prefix);
                last unless $args{all};
            }
        }
    }

    if ($args{all}) {
        return \@res;
    } else {
        return @res ? $res[0] : undef;
    }
}

gen_modified_sub(
    output_name => 'pod_path',
    base_name   => 'module_path',
    summary     => 'Find path to Perl POD files',
    description => <<'_',

Shortcut for `module_path(..., find_pm=>0, find_pmc=>0, find_pod=>1,
find_prefix=>1, )`.

_
    remove_args => [qw/find_pm find_pmc find_pod find_prefix/],
    output_code => sub {
        my %args = @_;
        module_path(
            %args, find_pm=>0, find_pmc=>0, find_pod=>1, find_prefix=>0);
    },
);

1;
# ABSTRACT: Get path to locally installed Perl module

=head1 SYNOPSIS

 use Module::Path::More qw(module_path pod_path);

 $path = module_path(module=>'Test::More');
 if (defined($path)) {
   print "Test::More found at $path\n";
 } else {
   print "Danger Will Robinson!\n";
 }

 # find all found modules, as well as .pmc and .pod files
 @path = module_path(module=>'Foo::Bar', all=>1, find_pmc=>1, find_pod=>1);

 # just a shortcut for module_path(module=>'Foo',
 #                                 find_pm=>0, find_pmc=>0, find_pod=>1);
 $path = pod_path(module=>'Foo');


=head1 DESCRIPTION

Module::Path::More provides a function, C<module_path()>, which will find where
a module (or module prefix, or .pod file) is installed locally. (There is also
another function C<pod_path()> which is just a convenience wrapper.)

It works by looking in all the directories in @INC for an appropriately named
file. If module is C<Foo::Bar>, will search for C<Foo/Bar.pm>, C<Foo/Bar.pmc>
(if C<find_pmc> argument is true), C<Foo/Bar> directory (if C<find_prefix>
argument is true), or C<Foo/Bar.pod> (if C<find_pod> argument is true).

Caveats: Obviously this only works where the module you're after has its own
C<.pm> file. If a file defines multiple packages, this won't work. This also
won't find any modules that are being loaded in some special way, for example
using a code reference in C<@INC>, as described in C<require> in L<perlfunc>.


=head1 SEE ALSO

L<Module::Path>. Module::Path::More is actually a fork of Module::Path.
Module::Path::More contains features that are not (or have not been accepted) in
the original module, namely: finding all matches instead of the first found
match, and finding C<.pmc/.pod> in addition to .pm files. B<Note that the
interface is different> (Module::Path::More accepts hash/named arguments) so the
two modules are not drop-in replacements for each other. Also, note that by
default Module::Path::More does B<not> do an C<abs_path()> to each file it
finds. I think this module's choice (not doing abs_path) is a more sensible
default, because doing abs_path() or resolving symlinks will sometimes fail or
expose filesystem quirks that we might not want to deal with at all. However, if
you want to do abs_path, you can do so by setting C<abs> option to true.

Command-like utility is not included in this distribution, unlike L<mpath> in
C<Module-Path>. However, you can use L<pmpath> from C<App-PMUtils> which uses
this module.

References:

=over

=item * L<https://github.com/neilbowers/Module-Path/issues/6>

=item * L<https://github.com/neilbowers/Module-Path/issues/7>

=item * L<https://github.com/neilbowers/Module-Path/issues/10>

=back
