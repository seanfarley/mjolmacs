#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#import "mjolmacs-module.h"
int plugin_is_GPL_compatible;

@implementation MjolmacsEnv

- (id)init {
  self = [super init];
  if (self) {
    funcs = [[NSMutableDictionary alloc] init];
    pipe = nil;
  }

  return self;
}

- (void)hotkeyWithEvent:(NSEvent *)hkEvent object:(id)anObject {
  NSLog(@"Firing -[%@ %@]", NSStringFromClass([self class]),
        NSStringFromSelector(_cmd));
  NSLog(@"Hotkey event: %@", hkEvent);
  NSLog(@"Object: %@", anObject);
}

- (void)openChannel:(emacs_env *)env buffer:(emacs_value)buffer {
  if (!pipe) {
    int fd = env->open_channel(env, buffer);
    pipe = [[NSFileHandle alloc] initWithFileDescriptor:fd];
  }
}

static emacs_value Fmjolmacs_start(emacs_env *env,
                                   __attribute__((unused)) ptrdiff_t nargs,
                                   emacs_value args[],
                                   __attribute__((unused)) void *data) {
  CarbonHotKeyCenter *c = [CarbonHotKeyCenter sharedHotKeyCenter];

  MjolmacsEnv *m = data;
  [m openChannel:env buffer:args[0]];

  emacs_value sym_args[] = {args[1]};

  emacs_value sym =
      env->funcall(env, env->intern(env, "prin1-to-string"), 1, sym_args);

  ptrdiff_t len = 0;
  env->copy_string_contents(env, sym, NULL, &len);

  char *func = malloc(len);
  env->copy_string_contents(env, sym, func, &len);

  NSMutableString *s = [NSMutableString stringWithUTF8String:func];

  NSLog(@"LEEROY: %@", s);

  CarbonHotKeyTask task = ^(NSEvent *hkEvent) {
    NSLog(@"Firing block hotkey");
    NSLog(@"Hotkey event: %@", hkEvent);

    NSRunningApplication *runningApp =
        [[NSWorkspace sharedWorkspace] frontmostApplication];

    NSString *lisp = [NSString
        stringWithFormat:@"(%@ %d)\0", s, [runningApp processIdentifier]];

    [m->pipe writeData:[lisp dataUsingEncoding:NSUTF8StringEncoding]];
  };

  if ([c registerHotKeyWithKeyCode:kVK_ANSI_A
                     modifierFlags:NSEventModifierFlagCommand
                              task:task]) {
    NSLog(@"Registered: %@", [c registeredHotKeys]);
  } else {
    NSLog(@"Unable to register hotkey for emacs example");
  }

  return env->intern(env, "t");
}

static emacs_value Fmjolmacs_focus_pid(emacs_env *env,
                                       __attribute__((unused)) ptrdiff_t nargs,
                                       emacs_value args[],
                                       __attribute__((unused)) void *data) {
  pid_t pid = env->extract_integer(env, args[0]);
  NSLog(@"PID: %d", pid);

  CFIndex appCount =
      [[[NSWorkspace sharedWorkspace] runningApplications] count];
  for (CFIndex j = 0; j < appCount; j++) {
    NSRunningApplication *app =
        [[[NSWorkspace sharedWorkspace] runningApplications] objectAtIndex:j];
    if (pid == [app processIdentifier]) {
      [app activateWithOptions:NSApplicationActivateAllWindows |
                               NSApplicationActivateIgnoringOtherApps];
      break;
    }
  }

  return env->intern(env, "t");
}

/* Bind NAME to FUN.  */
static void bind_function(emacs_env *env, const char *name, emacs_value Sfun) {
  /* Set the function cell of the symbol named NAME to SFUN using
     the 'fset' function.  */

  /* Convert the strings to symbols by interning them */
  emacs_value Qfset = env->intern(env, "fset");
  emacs_value Qsym = env->intern(env, name);

  /* Prepare the arguments array */
  emacs_value args[] = {Qsym, Sfun};

  /* Make the call (2 == nb of arguments) */
  env->funcall(env, Qfset, 2, args);
}

/* Provide FEATURE to Emacs.  */
static void provide(emacs_env *env, const char *feature) {
  /* call 'provide' with FEATURE converted to a symbol */

  emacs_value Qfeat = env->intern(env, feature);
  emacs_value Qprovide = env->intern(env, "provide");
  emacs_value args[] = {Qfeat};

  env->funcall(env, Qprovide, 1, args);
}

int emacs_module_init(struct emacs_runtime *ert) {
  emacs_env *env = ert->get_environment(ert);

  MjolmacsEnv *m = [[MjolmacsEnv alloc] init];

  /* create a lambda (returns an emacs_value) */
  emacs_value fun =
      env->make_function(env, 2,          /* min. number of arguments */
                         2,               /* max. number of arguments */
                         Fmjolmacs_start, /* actual function pointer */
                         "doc",           /* docstring */
                         m                /* user pointer of your choice */
      );
  bind_function(env, "mjolmacs--start", fun);

  /* create a lambda (returns an emacs_value) */
  fun = env->make_function(
      env, 1,              /* min. number of arguments */
      1,                   /* max. number of arguments */
      Fmjolmacs_focus_pid, /* actual function pointer */
      "doc",               /* docstring */
      m /* user pointer of your choice (data param in Fmjolmacs_double) */
  );

  bind_function(env, "mjolmacs--focus-pid", fun);

  provide(env, "mjolmacs-module");

  /* loaded successfully */
  return 0;
}

@end
