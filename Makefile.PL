
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;


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

    



my %WriteMakefileArgs = (
  "ABSTRACT" => "implementation of AGA BayRate (player ratings) as perl object",
  "AUTHOR" => "Reid Augustin <reid\@hellosix.com>",
  "BUILD_REQUIRES" => {
    "Devel::CheckLib" => 0,
    "English" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Games-Go-AGA-BayRate",
  "EXE_FILES" => [
    "bin/bayrate.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "Games::Go::AGA::BayRate",
  "PREREQ_PM" => {
    "Carp" => 0,
    "DBI" => 0,
    "Date::Parse" => 0,
    "DateTime" => 0,
    "Getopt::Long" => 0,
    "IO::File" => 0,
    "Inline" => 0,
    "Math::GSL::BLAS" => 0,
    "Math::GSL::Const" => 0,
    "Math::GSL::Errno" => 0,
    "Math::GSL::Interp" => 0,
    "Math::GSL::Linalg" => 0,
    "Math::GSL::Matrix" => 0,
    "Math::GSL::Multimin" => 0,
    "Math::GSL::Permutation" => 0,
    "Math::GSL::SF" => 0,
    "Math::GSL::Spline" => 0,
    "Math::GSL::Vector" => 0,
    "Readonly" => 0,
    "Scalar::Util" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.066",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



