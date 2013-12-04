#!/usr/bin/perl
#===============================================================================
#
#  DESCRIPTION:  Modify Makefile.PL after Dist::Zilla is finished
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  07/28/2011 03:40:36 PM
#===============================================================================

use strict;
use warnings;
use Carp;
use File::Spec;
use File::Slurp;

my $dir = $ARGV[0] or die "Need build directory";

fix_makefile($dir);
exit 0;

sub fix_makefile {
    my ($dir) = @_;

    my $filename = File::Spec->catfile($dir, 'Makefile.PL');

    my $content = read_file($filename);

    my $add = q{

print "Checking for GNU Scientific Library (GSL)...";

my $libpath;

eval {
    $libpath = `pkg-config --libs gsl 2>/dev/null`;
};
if (not $libpath) {
    eval {
        $libpath = `gsl-config --libs 2>/dev/null`;
    }
};

if (not $libpath) {
    die("I can't seem to find the GSL library (via pkg-config or gsl-config).\n"
      . "Please install the GSL library (using your package manager,\n"
      . "'cpanm Alien::GSL', or compile from source), and try again\n"
    );
}

    };

    $content =~ s/^(use ExtUtils::MakeMaker[^\n]*)/$1\n$add/sm;

    # $content =~ s/("NAME"\s*=>\s*"Games:[^\n]*)/$1\n$add/sm;

    write_file($filename, $content);
}


