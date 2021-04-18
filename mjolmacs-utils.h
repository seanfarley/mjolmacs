#ifndef MJOLMACS_UTILS_H_
#define MJOLMACS_UTILS_H_

#include <emacs-module.h>

emacs_value Qnil;
emacs_value Qt;

void bind_function(emacs_env *env, const char *name, ptrdiff_t min_arity,
                   ptrdiff_t max_arity,
                   emacs_value (*func)(emacs_env *env, ptrdiff_t nargs,
                                       emacs_value *args, void *data),
                   const char *docstring, void *data);

#endif // MJOLMACS_UTILS_H_
