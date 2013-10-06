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
use Devel::CheckLib;    # to check for GSL library

$| = 1; # make STDOUT 'hot'
print "Checking for GNU Scientific Library (GSL)...";
check_lib_or_exit(
    lib => 'gsl',
    header => [
        'gsl/gsl_blas.h',
        'gsl/gsl_interp.h',
        'gsl/gsl_linalg.h',
        'gsl/gsl_matrix_double.h',
        'gsl/gsl_multimin.h',
        'gsl/gsl_permutation.h',
        'gsl/gsl_spline.h',
        'gsl/gsl_types.h',
        'gsl/gsl_vector_double.h',
    ],

    function => '
        gsl_interp_accel *          _accel;
        gsl_permutation*            _perm;
        gsl_spline *                _spline;
        gsl_vector *                _vector;
        gsl_matrix *                _matrix;
        gsl_multimin_fminimizer *   f_minimizer;
        gsl_multimin_fdfminimizer * fdf_minimizer;
        double                      _xa[] = {1.0, 2.0, 3.0};
        double                      _xb[] = {1.1, 2.2, 3.3};

        _accel = gsl_interp_accel_alloc();

        _perm = gsl_permutation_alloc(4);
        gsl_permutation_get(_perm, 2);

        _spline = gsl_spline_alloc(gsl_interp_linear, 3);
        gsl_spline_init (_spline, _xa, _xb, 3);
        gsl_spline_eval(_spline, 2.5, _accel);

        _vector = gsl_vector_alloc(4);
        gsl_vector_set_zero(_vector);
        gsl_vector_set_all(_vector, 2.2);
        gsl_vector_set(_vector, 1, 3.3);
        gsl_vector_scale(_vector, -1);
        if (gsl_vector_get(_vector, 2) != -2.2) return 1;
        gsl_blas_dnrm2(_vector);
        gsl_multimin_test_gradient(_vector, 3.3);

        _matrix = gsl_matrix_calloc (4, 4);
        gsl_matrix_set_all(_matrix, 4.4);
        gsl_matrix_set(_matrix, 2, 3, 4.5);
        if (gsl_matrix_get(_matrix, 3, 2) != 4.4) return 1;
        // The commented functions are used by Games::Go::AGA::BayRate.
        //   They take a bit more work to test, but if everything
        //   else links and runs OK, we can assume these will work too.
        //gsl_linalg_LU_decomp(_matrix, _perm, &_int);
        gsl_linalg_LU_invert(_matrix, _perm, _matrix);

        fdf_minimizer = gsl_multimin_fdfminimizer_alloc(gsl_multimin_fdfminimizer_steepest_descent, 4);
        //gsl_multimin_fdfminimizer_set(fdf_minimizer, (gsl_multimin_function_fdf *)NULL, vector, 5.5, 6.6);
        //gsl_multimin_fdfminimizer_iterate(fdf_minimizer);
        //gsl_multimin_fdfminimizer_minimum(fdf_minimizer);
        //gsl_multimin_fdfminimizer_gradient(fdf_minimizer);

        f_minimizer = gsl_multimin_fminimizer_alloc (gsl_multimin_fminimizer_nmsimplex, 4);
        //gsl_multimin_fminimizer_set(_f_minimizer, (gsl_multimin_function *)NULL, vector, vector);
        //gsl_multimin_fminimizer_iterate(_f_minimizer);
        //gsl_multimin_fminimizer_minimum(_f_minimizer);
        //gsl_multimin_fminimizer_size(_f_minimizer);

        gsl_matrix_free(_matrix);
        gsl_multimin_fdfminimizer_free(fdf_minimizer);
        gsl_multimin_fminimizer_free(f_minimizer);
        gsl_vector_free(_vector);
        gsl_spline_free(_spline);
        gsl_permutation_free(_perm);
        gsl_interp_accel_free(_accel);
        return 0;
    ',
);
print "OK\n";
    };

    $content =~ s/^(use ExtUtils::MakeMaker[^\n]*)/$1\n$add/sm;

    # $content =~ s/("NAME"\s*=>\s*"Games:[^\n]*)/$1\n$add/sm;

    write_file($filename, $content);
}


