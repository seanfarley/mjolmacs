#include "mjolmacs-utils.h"

void bind_function(emacs_env *env, const char *name, ptrdiff_t min_arity,
                   ptrdiff_t max_arity,
                   emacs_value (*func)(emacs_env *env, ptrdiff_t nargs,
                                       emacs_value *args, void *data),
                   const char *docstring, void *data) {

  emacs_value Sfun =
      env->make_function(env, min_arity, max_arity, func, docstring, data);

  emacs_value Qfset = env->intern(env, "fset");
  emacs_value Qsym = env->intern(env, name);

  emacs_value args[] = {Qsym, Sfun};

  env->funcall(env, Qfset, 2, args);
}
