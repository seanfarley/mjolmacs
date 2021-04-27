#import "mjolmacs-constants.h"
#import "mjolmacs-ctx.h"
#import "mjolmacs-utils.h"

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

int plugin_is_GPL_compatible;

static emacs_value Fmjolmacs_start(emacs_env *env,
                                   __attribute__((unused)) ptrdiff_t nargs,
                                   emacs_value args[], void *data) {
  MjolmacsCtx *m = data;

  int fd = env->open_channel(env, args[0]);
  [m openChannel:fd];

  // only here to silence emacs-lisp linting
  NSString *lisp = @"(define-key mjolmacs-mode-map "
                   @"  (kbd \"ESC\") #'mjolmacs-keypress-close)";
  [m runLisp:lisp];

  return Qt;
}

static emacs_value Fmjolmacs_register(emacs_env *env,
                                      __attribute__((unused)) ptrdiff_t nargs,
                                      emacs_value args[], void *data) {

  NSArray *keys = emacs_parse_keys(env, args[0]);
  NSLog(@"parsed keys: %@", keys);

  // check number of keys in hotkey; currently, can only be one combo
  // ptrdiff_t key_vec_size = env->vec_size(env, args[0]);
  if ([keys count] > 1) {
    emacs_error(env, env->intern(env, "too-many-keys"),
                @"mjolmacs can only bind to a single key press");
    return Qnil;
  }

  if (!keys || ![keys count]) {
    // error happened in emacs_parse_key
    return Qnil;
  }

  CarbonHotKeyCenter *c = [CarbonHotKeyCenter sharedHotKeyCenter];
  MjolmacsCtx *m = data;

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
        stringWithFormat:@"(%@ %d)", s, [runningApp processIdentifier]];

    [m runLisp:lisp];
  };

  MjolmacsKey *mk = [keys firstObject];
  if ([c registerHotKeyWithKeyCode:mk.key modifierFlags:mk.flags task:task]) {
    NSLog(@"Registered: %@", [c registeredHotKeys]);
  } else {
    NSLog(@"Unable to register hotkey for emacs example");
  }

  return Qt;
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

  return Qt;
}

int emacs_module_init(struct emacs_runtime *ert) {
  emacs_env *env = ert->get_environment(ert);

  // initialize common variables
  init_common(env);

  MjolmacsCtx *m = [[MjolmacsCtx alloc] init];

  bind_function(env, "mjolmacs--start", 1, 1, Fmjolmacs_start,
                "Private C function for starting mjolmacs process", m);

  bind_function(env, "mjolmacs--focus-pid", 1, 1, Fmjolmacs_focus_pid,
                "Private C function used solely the previous app that was in "
                "focus before a mjolmacs popup frame was focused.",
                m);

  bind_function(env, "mjolmacs-register", 2, 2, Fmjolmacs_register,
                "Register global key binding to function", m);

  emacs_value Qfeat = env->intern(env, "mjolmacs-module");
  emacs_value Qprovide = env->intern(env, "provide");
  emacs_value args[] = {Qfeat};

  env->funcall(env, Qprovide, 1, args);

  return 0;
}
