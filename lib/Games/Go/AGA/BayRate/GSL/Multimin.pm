#===============================================================================
#     ABSTRACT:  Struct for GSL fdf minimizer (gsl_multimin_function_fdf_struct)
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  05/27/2011 03:56:12 PM
#===============================================================================

use strict;
use warnings;
package Games::Go::AGA::BayRate::GSL::Multimin;

our $VERSION = '0.071'; # VERSION
my $libs;
BEGIN {
    if (not -f 'swigperlrun.h') {
        print "swigperlrun.h not available, attempting to create it:\n",
              "    executing swig -perl -external-runtime\n";
        system "swig -perl -external-runtime";
        if (not -f 'swigperlrun.h') {
            die "Failed to create swigperlrun.h, can't use this module";
        }
        print "You may remove swigperlrun.h when this program completes.\n",
    }

    eval {
        $libs = `pkg-config --libs gsl 2>/dev/null`;
    };
    if (not $libs) {
        eval {
            $libs = `gsl-config --libs 2>/dev/null`;
        }
    };

    chomp $libs;
}

use Inline C => Config =>
        LIBS => $libs,
        INC => '-I../../../../../../../..'; # gets us back to . from deep inside _Inline/
use Inline C => <<'END';

// perl's Math::GSL::Multimin is still a work in progress.
// use this glue/hack in the meantime

// Gnu Scientific Library include files
#include <gsl/gsl_types.h>
#include <gsl/gsl_multimin.h>
#include "swigperlrun.h"

typedef struct {
    gsl_multimin_function_fdf * s_ptr;      // struct defined by GSL
    SV                        * params_SV;  // perl params pointer
    SV                        * f_SV;       // perl function pointers (SV*)
    SV                        * df_SV;
    SV                        * fdf_SV;
} my_minim_struct;

static void *vector_descr = 0;    // pointer to swig type descriptor for gsl_vector *
static void *f_type_descr = 0;    // pointer to swig type descriptor for const gsl_multimin_fminimizer_type *
static void *f_state_descr = 0;   // pointer to swig type descriptor for const gsl_multimin_fminimizer *
static void *fdf_type_descr = 0;  // pointer to swig type descriptor for const gsl_multimin_fdfminimizer_type *
static void *fdf_state_descr = 0; // pointer to swig type descriptor for const gsl_multimin_fdfminimizer *

// initialize the swig type descriptor pointers
void init_swig_type_descriptors() {
    vector_descr = SWIG_TypeQuery("gsl_vector *");
     assert(vector_descr);
    f_type_descr = SWIG_TypeQuery("const gsl_multimin_fminimizer_type *");
     assert(f_type_descr);
    f_state_descr = SWIG_TypeQuery("gsl_multimin_fminimizer *");
     assert(f_state_descr);
    fdf_type_descr = SWIG_TypeQuery("const gsl_multimin_fdfminimizer_type *");
     assert(fdf_type_descr);
    fdf_state_descr = SWIG_TypeQuery("gsl_multimin_fdfminimizer *");
     assert(fdf_state_descr);
}

// SV to gsl converters
gsl_vector *
convert_vector_SV(SV * vector_SV) {
    gsl_vector * vector;
    if (!fdf_type_descr) {
        init_swig_type_descriptors();
    }
    if (SWIG_ConvertPtr(vector_SV, (void **) &vector, vector_descr, 0) != SWIG_OK) {
        abort();
    }
    return vector;
}

const gsl_multimin_fminimizer_type *
convert_f_type_SV(SV * f_type_SV) {
    const gsl_multimin_fminimizer_type * f_type;
    if (!fdf_type_descr) {
        init_swig_type_descriptors();
    }
    if (SWIG_ConvertPtr(f_type_SV, (void **) &f_type, f_type_descr, 0) != SWIG_OK) {
        abort();
    }
    return f_type;
}

gsl_multimin_fminimizer *
convert_f_state_SV(SV * state_SV) {
    gsl_multimin_fminimizer * f_state;
    if (!fdf_type_descr) {
        init_swig_type_descriptors();
    }
    if (SWIG_ConvertPtr(state_SV, (void **) &f_state, f_state_descr, 0) != SWIG_OK) {
        abort();
    }
    return f_state;
}

const gsl_multimin_fdfminimizer_type *
convert_fdf_type_SV(SV * fdf_type_SV) {
    const gsl_multimin_fdfminimizer_type * fdf_type;
    if (!fdf_type_descr) {
        init_swig_type_descriptors();
    }
    if (SWIG_ConvertPtr(fdf_type_SV, (void **) &fdf_type, fdf_type_descr, 0) != SWIG_OK) {
        abort();
    }
    return fdf_type;
}

gsl_multimin_fdfminimizer *
convert_fdf_state_SV(SV * state_SV) {
    gsl_multimin_fdfminimizer * fdf_state;
    if (!fdf_type_descr) {
        init_swig_type_descriptors();
    }
    if (SWIG_ConvertPtr(state_SV, (void **) &fdf_state, fdf_state_descr, 0) != SWIG_OK) {
        abort();
    }
    return fdf_state;
}

// call converters: wrappers to convert C call to perl conventions
// the GSL library will callback to these functions.
double
call_f (const gsl_vector * x, void * params) {
    int count;
    double ret;
    my_minim_struct * self_ptr = params;    // use params to pass instance ptr

    dSP;       // init perl stack pointer
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(SWIG_NewPointerObj(x, vector_descr, 0 | SWIG_SHADOW));
    XPUSHs(self_ptr->params_SV);
    PUTBACK;
    count = call_sv(self_ptr->f_SV, G_EVAL|G_SCALAR);
    SPAGAIN;

    /* Check the eval */
    if (SvTRUE(ERRSV))
        croak ("Uh oh - %s\n", SvPV(ERRSV, PL_na));
    else if (count != 1)
        croak("call to f returned %d items (expecting 1)\n", count);

    ret = POPn;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return ret;
}

void
call_df (const gsl_vector * v, void * params, gsl_vector * df) {

    my_minim_struct * self_ptr = params;    // use params to pass instance ptr

    dSP;       // init perl stack pointer
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(SWIG_NewPointerObj(v, vector_descr, 0 | SWIG_SHADOW));
    XPUSHs(self_ptr->params_SV);
    XPUSHs(SWIG_NewPointerObj(df, vector_descr, 0 | SWIG_SHADOW));
    PUTBACK;

    call_sv(self_ptr->df_SV, G_EVAL|G_SCALAR);
    SPAGAIN;

    /* Check the eval */
    if (SvTRUE(ERRSV))
        croak ("Uh oh - %s\n", SvPV(ERRSV, PL_na));
    PUTBACK;
    FREETMPS;
    LEAVE;

}

void
call_fdf (const gsl_vector * x, void * params, double *f, gsl_vector * df) {

    my_minim_struct * self_ptr = params;    // use params to pass instance ptr

    dSP;       // init perl stack pointer
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(SWIG_NewPointerObj(x, vector_descr, 0 | SWIG_SHADOW));
    XPUSHs(self_ptr->params_SV);
    SV* f_SV = newSV(0);            // create f
    SV* sv_f_ref = newRV_inc(f_SV); // ptr to f so fdf can say *f=...
    XPUSHs(sv_f_ref);
    XPUSHs(SWIG_NewPointerObj(df, vector_descr, 0 | SWIG_SHADOW));
    PUTBACK;

    call_sv(self_ptr->fdf_SV, G_EVAL|G_SCALAR);
    SPAGAIN;

    /* Check the eval */
    if (SvTRUE(ERRSV))
        croak ("Uh oh - %s\n", SvPV(ERRSV, PL_na));
    *f = SvNV(f_SV);
    PUTBACK;
    SvREFCNT_dec(sv_f_ref);

    FREETMPS;
    LEAVE;
}

// combine struct allocation/initialization and minimzer_set
// void my_fminimizer_set (
//     $gsl_multimin_fminimizer_nmsimplex2,    # type
//     \&_my_f,   # gsl_multimin_function . f       function
//     $count,    # gsl_multimin_function . n       number of free variables
//     $self,     # gsl_multimin_function . params  function params passed to f, df, and fdf
//     $x->raw,   # gsl vector
//     $ss->raw); # step size
void my_fminimizer_set (
    SV * f_type_SV,
    SV * f_SV,
    int n,
    SV * params_SV,
    SV * x_vector_SV,
    SV * ss_vector_SV
    ) {
    Inline_Stack_Vars;      // initialize Inline:: stack variables
    const gsl_multimin_fminimizer_type * f_type = convert_f_type_SV(f_type_SV);
    gsl_vector * x_vector  = convert_vector_SV(x_vector_SV);
    gsl_vector * ss_vector = convert_vector_SV(ss_vector_SV);

    f_type = gsl_multimin_fminimizer_nmsimplex2;    // TODO 
    gsl_multimin_fminimizer * f_state = gsl_multimin_fminimizer_alloc(f_type, n);

    my_minim_struct * self_ptr;             // ptr to my_minim_struct
    Newxz(self_ptr, 1, my_minim_struct);    // allocate my_minim_struct BUGBUG: never gets deallocated!

    gsl_multimin_function * f_ptr;
    Newxz(f_ptr, 1, gsl_multimin_function);  // allocate GSL multimin struct BUGBUG: never gets deallocated!

    self_ptr->s_ptr = (gsl_multimin_function_fdf *)f_ptr;   // fake it
    f_ptr->f        = call_f;       // perl call converter
    f_ptr->n        = n;
    f_ptr->params   = self_ptr;     // use params to pass pointer to my_minim_struct
    // GSL calls f, df, and f with params as an argument, so
    //   now our perl-call-converter has access to my_minim_struct.

    self_ptr->f_SV      = newSVsv(f_SV);    // save perl callback addresses
    // put real params here:
    self_ptr->params_SV = newSVsv(params_SV);   // pass GSL param to perl here

    // initialize the minimizer:
    gsl_multimin_fminimizer_set (f_state, f_ptr, x_vector, ss_vector);
    Inline_Stack_Reset;
    Inline_Stack_Push( SWIG_NewPointerObj(f_state, f_state_descr, 0 | SWIG_SHADOW) );
    Inline_Stack_Done;
    Inline_Stack_Return(1);
}

// combine struct allocation/initialization and minimzer_set
// void my_fdfminimizer_set (
//     $gsl_multimin_fdfminimizer_vector_bfgs2,    # type
//     \&_my_f,   # gsl_multimin_function_fdf . f       function
//     \&_my_df,  # gsl_multimin_function_fdf . df      derivative of f
//     \&_my_fdf, # gsl_multimin_function_fdf . fdf     f and df
//     $count,    # gsl_multimin_function_fdf . n       number of free variables
//     $self,     # gsl_multimin_function_fdf . params  function params passed to f, df, and fdf
//     $x->raw,   # gsl vector
//     2.0,       # step size
//     0.1);      # accuracy required (tol?)
void my_fdfminimizer_set (
    SV * fdf_type_SV,
    SV * f_SV,
    SV * df_SV,
    SV * fdf_SV,
    int n,
    SV * params_SV,
    SV * vector_SV,
    double step_size,
    double tol
    ) {
    Inline_Stack_Vars;      // initialize Inline:: stack variables
    const gsl_multimin_fdfminimizer_type * fdf_type = convert_fdf_type_SV(fdf_type_SV);
    gsl_vector * vector = convert_vector_SV(vector_SV);

    gsl_multimin_fdfminimizer * fdf_state = gsl_multimin_fdfminimizer_alloc(fdf_type, n);

    my_minim_struct * self_ptr;             // ptr to my_minim_struct
    Newxz(self_ptr, 1, my_minim_struct);    // allocate my_minim_struct BUGBUG: never gets deallocated!

    gsl_multimin_function_fdf * fdf_ptr;
    Newxz(fdf_ptr, 1, gsl_multimin_function_fdf);  // allocate GSL multimin struct BUGBUG: never gets deallocated!

    self_ptr->s_ptr = fdf_ptr;
    fdf_ptr->f        = call_f;    // perl call converters
    fdf_ptr->df       = call_df;
    fdf_ptr->fdf      = call_fdf;
    fdf_ptr->n        = n;
    fdf_ptr->params = self_ptr;     // use params to pass pointer to my_minim_struct
    // GSL calls f, df, and fdf with params as an argument, so
    //   now our perl-call-converters have access to my_minim_struct.

    self_ptr->f_SV      = newSVsv(f_SV);    // save perl callback addresses
    self_ptr->df_SV     = newSVsv(df_SV);   //    the call converters
    self_ptr->fdf_SV    = newSVsv(fdf_SV);  //    get to perl via these
    // put real params here:
    self_ptr->params_SV = newSVsv(params_SV);   // pass GSL param to perl here

    // initialize the minimizer:
    gsl_multimin_fdfminimizer_set (fdf_state, fdf_ptr, vector, step_size, tol);
    Inline_Stack_Reset;
    Inline_Stack_Push( SWIG_NewPointerObj(fdf_state, fdf_state_descr, 0 | SWIG_SHADOW) );
    Inline_Stack_Done;
    Inline_Stack_Return(1);
}

double
my_fminimizer_fval (SV * f_state_SV) {
    gsl_multimin_fminimizer * f_state = convert_f_state_SV(f_state_SV);
    return f_state->fval;
}

double
my_fdfminimizer_f (SV * fdf_state_SV) {
    gsl_multimin_fdfminimizer * fdf_state = convert_fdf_state_SV(fdf_state_SV);
    return fdf_state->f;
}

//double
//my_minimum (SV * fdf_state_SV) {
//    gsl_multimin_fdfminimizer * fdf_state = convert_fdf_state_SV(fdf_state_SV);
//    return gsl_multimin_fdfminimizer_minimum(fdf_state);
//}
//
void
my_fdfminimizer_gradient (SV * fdf_state_SV) {
    Inline_Stack_Vars;
    gsl_multimin_fdfminimizer * fdf_state = convert_fdf_state_SV(fdf_state_SV);

    Inline_Stack_Reset;
    XPUSHs(SWIG_NewPointerObj(fdf_state->gradient, vector_descr, 0 | SWIG_SHADOW));
    Inline_Stack_Done;
    Inline_Stack_Return(1);
}

int
my_vector_size (SV * vector_SV) {
    gsl_vector * vector = convert_vector_SV(vector_SV);
    return vector->size;
}

END

1;

__END__
