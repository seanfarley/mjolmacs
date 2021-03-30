#import <emacs-module.h>

#import "edda/edda-Swift.h"

/* Declare mandatory GPL symbol.  */
int plugin_is_GPL_compatible;

/* New emacs lisp function. All function exposed to Emacs must have this prototype. */
static emacs_value
Fmjolmacs_double (emacs_env *env,
                  __attribute__((unused)) ptrdiff_t nargs,
                  emacs_value args[],
                  __attribute__((unused)) void *data)
{
  NSInteger x = env->extract_integer(env, args[0]);
  return env->make_integer (env, mjDouble(x));
}

static emacs_value
Fmjolmacs_register (emacs_env *env,
                    __attribute__((unused)) ptrdiff_t nargs,
                    emacs_value args[],
                    __attribute__((unused)) void *data)
{
  ptrdiff_t len = 0;
  env->copy_string_contents(env, args[0], NULL, &len);

  // TODO handle NULL
  char *kb_buf = malloc(len);
  env->copy_string_contents(env, args[0], kb_buf, &len);

  mjRegisterKeybind(kb_buf);
  free(kb_buf);

  return env->intern(env, "t");
}

/* Bind NAME to FUN.  */
static void
bind_function (emacs_env *env, const char *name, emacs_value Sfun)
{
  /* Set the function cell of the symbol named NAME to SFUN using
     the 'fset' function.  */

  /* Convert the strings to symbols by interning them */
  emacs_value Qfset = env->intern (env, "fset");
  emacs_value Qsym = env->intern (env, name);

  /* Prepare the arguments array */
  emacs_value args[] = { Qsym, Sfun };

  /* Make the call (2 == nb of arguments) */
  env->funcall (env, Qfset, 2, args);
}

/* Provide FEATURE to Emacs.  */
static void
provide (emacs_env *env, const char *feature)
{
  /* call 'provide' with FEATURE converted to a symbol */

  emacs_value Qfeat = env->intern (env, feature);
  emacs_value Qprovide = env->intern (env, "provide");
  emacs_value args[] = { Qfeat };

  env->funcall (env, Qprovide, 1, args);
}

int
emacs_module_init (struct emacs_runtime *ert)
{
  emacs_env *env = ert->get_environment (ert);

  /* create a lambda (returns an emacs_value) */
  emacs_value fun = env->make_function (env,
              1,                /* min. number of arguments */
              1,                /* max. number of arguments */
              Fmjolmacs_double, /* actual function pointer */
              "doc",            /* docstring */
              NULL              /* user pointer of your choice (data param in Fmjolmacs_double) */
  );
  bind_function (env, "mjolmacs-double", fun);

  /* create a lambda (returns an emacs_value) */
  fun = env->make_function (env,
              1,                  /* min. number of arguments */
              1,                  /* max. number of arguments */
              Fmjolmacs_register, /* actual function pointer */
              "doc",              /* docstring */
              NULL                /* user pointer of your choice (data param in Fmjolmacs_double) */
  );

  bind_function (env, "mjolmacs-register", fun);
  provide (env, "mjolmacs");

  /* loaded successfully */
  return 0;
}
