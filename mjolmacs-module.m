#import "mjolmacs-module.h"

/* Declare mandatory GPL symbol.  */
int plugin_is_GPL_compatible;

@implementation MjolmacsEnv

- (void) dealloc
{
    NSLog(@"Dealloc called");
    [super dealloc];
}

- (void) hotkeyWithEvent:(NSEvent *)hkEvent object:(id)anObject {
  NSLog(@"Firing -[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
  NSLog(@"Hotkey event: %@", hkEvent);
  NSLog(@"Object: %@", anObject);
}

static int fd;
static char *func;

static emacs_value
Fmjolmacs_show (__attribute__((unused)) emacs_env *env,
                __attribute__((unused)) ptrdiff_t nargs,
                __attribute__((unused)) emacs_value args[],
                void *data)
{
  MjolmacsEnv *m = (MjolmacsEnv *)data;
  [m.window makeKeyAndOrderFront: m.window];

  return env->intern(env, "nil");
}

static emacs_value
Fmjolmacs_close (__attribute__((unused)) emacs_env *env,
                 __attribute__((unused)) ptrdiff_t nargs,
                 __attribute__((unused)) emacs_value args[],
                 void *data)
{
  MjolmacsEnv *m = (MjolmacsEnv *)data;
  [m.window setIsVisible:NO];

  return env->intern(env, "nil");
}

static emacs_value
Fmjolmacs_start (emacs_env *env,
                 __attribute__((unused)) ptrdiff_t nargs,
                 emacs_value args[],
                 __attribute__((unused)) void *data)
{
  CarbonHotKeyCenter *c = [CarbonHotKeyCenter sharedHotKeyCenter];

  fd = env->open_channel(env, args[0]);

  emacs_value sym_args[] = { args[1] };

  /* Make the call (2 == nb of arguments) */
  emacs_value sym = env->funcall (env, env->intern(env, "prin1-to-string"), 1, sym_args);

  ptrdiff_t len = 0;
  env->copy_string_contents(env, sym, NULL, &len);

  func = malloc(len);
  env->copy_string_contents(env, sym, func, &len);

  NSLog(@"LEEROY: %s", func);

  // TODO create a user struct
  // free(kb_buf);

  CarbonHotKeyTask task = ^(NSEvent *hkEvent) {
    NSLog(@"Firing block hotkey");
    NSLog(@"Hotkey event: %@", hkEvent);
    char c1[] = "LEEEEEEROY!!!!!!";
    // char c2[] = "JENNNNNNKINS";
    write(fd, c1, sizeof(c1));
    write(fd, func, len);
    // write(fd, )
  };

  if ([c registerHotKeyWithKeyCode:kVK_ANSI_A
                     modifierFlags:NSEventModifierFlagCommand
                              task:task
  ]) {
    NSLog(@"Registered: %@", [c registeredHotKeys]);
  } else {
    NSLog(@"Unable to register hotkey for emacs example");
  }

  return env->intern(env, "t");
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

  CarbonHotKeyCenter *c = [CarbonHotKeyCenter sharedHotKeyCenter];

  int theAnswer = 42;

  CarbonHotKeyTask task = ^(NSEvent *hkEvent) {
    NSLog(@"Firing block hotkey");
    NSLog(@"Hotkey event: %@", hkEvent);
    NSLog(@"the answer is: %d", theAnswer);
  };

  if ([c registerHotKeyWithKeyCode:kVK_ANSI_A
                     modifierFlags:NSEventModifierFlagCommand
                              task:task]) {
    NSLog(@"Registered: %@", [c registeredHotKeys]);
  } else {
    NSLog(@"Unable to register hotkey for emacs example");
  }

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
              2,               /* min. number of arguments */
              2,               /* max. number of arguments */
              Fmjolmacs_start, /* actual function pointer */
              "doc",           /* docstring */
              (void *)[[MjolmacsEnv alloc] init]             /* user pointer of your choice */
  );
  bind_function (env, "mjolmacs--start", fun);

  /* create a lambda (returns an emacs_value) */
  fun = env->make_function (env,
              2,                  /* min. number of arguments */
              2,                  /* max. number of arguments */
              Fmjolmacs_register, /* actual function pointer */
              "doc",              /* docstring */
              NULL                /* user pointer of your choice (data param in Fmjolmacs_double) */
  );

  bind_function (env, "mjolmacs-register", fun);

  MjolmacsEnv *m = [[MjolmacsEnv alloc] init];
  NSRect frame = NSMakeRect(100, 100, 200, 200);
  NSUInteger styleMask = NSWindowStyleMaskBorderless;
  NSRect rect = [NSWindow contentRectForFrameRect:frame styleMask:styleMask];
  m.window = [[NSWindow alloc] initWithContentRect:rect
                                         styleMask:styleMask
                                           backing:NSBackingStoreBuffered
                                             defer:false];
  [m.window setBackgroundColor:[NSColor colorWithCalibratedRed:0.0
                                                         green:0.0
                                                          blue:1.0
                                                         alpha:0.5]];

  /* create a lambda (returns an emacs_value) */
  fun = env->make_function (env,
                            0,              /* min. number of arguments */
                            0,              /* max. number of arguments */
                            Fmjolmacs_show, /* actual function pointer */
                            "doc",          /* docstring */
                            m               /* user pointer of your choice (data param in Fmjolmacs_double) */
  );

  bind_function (env, "mjolmacs-show", fun);

  /* create a lambda (returns an emacs_value) */
  fun = env->make_function (env,
                            0,              /* min. number of arguments */
                            0,              /* max. number of arguments */
                            Fmjolmacs_close, /* actual function pointer */
                            "doc",          /* docstring */
                            m               /* user pointer of your choice (data param in Fmjolmacs_double) */
  );

  bind_function (env, "mjolmacs-close", fun);

  provide (env, "mjolmacs-module");

  /* loaded successfully */
  return 0;
}

@end
