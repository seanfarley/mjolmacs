#import "mjolmacs-constants.h"
#import "mjolmacs-ctx.h"
#import "mjolmacs-utils.h"
#include <MacTypes.h>

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#import <UserNotifications/UserNotifications.h>

int plugin_is_GPL_compatible;

static emacs_value
Fmjolmacs_authorized_accessibility_p(__attribute__((unused)) emacs_env *env,
                                     __attribute__((unused)) ptrdiff_t nargs,
                                     __attribute__((unused)) emacs_value args[],
                                     __attribute__((unused)) void *data) {
  MjolmacsCtx *m = data;

  if (!m.isMacApp) {
    // emacs needs to be run as a .app application; main bundle was not found
    return env->intern(env, "nil");
  }

  NSDictionary *options = @{(id)kAXTrustedCheckOptionPrompt : @NO};
  BOOL accessibilityEnabled =
      AXIsProcessTrustedWithOptions((CFDictionaryRef)options);

  emacs_value auth_status = env->intern(env, "nil");

  if (accessibilityEnabled) {
    auth_status = env->intern(env, "t");
  }

  return auth_status;
}

static emacs_value
Fmjolmacs_authorize_accessibility(__attribute__((unused)) emacs_env *env,
                                  __attribute__((unused)) ptrdiff_t nargs,
                                  __attribute__((unused)) emacs_value args[],
                                  __attribute__((unused)) void *data) {
  MjolmacsCtx *m = data;

  if (!m.isMacApp) {
    // emacs needs to be run as a .app application; main bundle was not found
    return env->intern(env, "nil");
  }

  NSDictionary *options = @{(id)kAXTrustedCheckOptionPrompt : @YES};
  BOOL accessibilityEnabled =
      AXIsProcessTrustedWithOptions((CFDictionaryRef)options);

  emacs_value auth_status = env->intern(env, "nil");

  if (accessibilityEnabled) {
    auth_status = env->intern(env, "t");
  }

  return auth_status;
}

static emacs_value
Fmjolmacs_authorized_notif_p(__attribute__((unused)) emacs_env *env,
                             __attribute__((unused)) ptrdiff_t nargs,
                             __attribute__((unused)) emacs_value args[],
                             __attribute__((unused)) void *data) {
  MjolmacsCtx *m = data;

  if (!m.isMacApp) {
    // emacs needs to be run as a .app application; main bundle was not found
    return env->intern(env, "nil");
  }

  UNUserNotificationCenter *center =
      [UNUserNotificationCenter currentNotificationCenter];

  __block NSInteger auth = 0;

  // force macos calls to be synchronous
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

  [center getNotificationSettingsWithCompletionHandler:^(
              UNNotificationSettings *settings) {
    auth = settings.authorizationStatus;
    dispatch_semaphore_signal(semaphore);
  }];

  dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

  emacs_value auth_status = env->intern(env, "nil");

  switch (auth) {
  case UNAuthorizationStatusNotDetermined:
    auth_status = env->intern(env, "not-determined");
    break;
  case UNAuthorizationStatusProvisional:
    // fallthrough to granted
  case UNAuthorizationStatusAuthorized:
    auth_status = env->intern(env, "granted");
    break;

  default:
    auth_status = env->intern(env, "denied");
  }

  return auth_status;
}

static emacs_value Fmjolmacs_resize_left(__attribute__((unused)) emacs_env *env,
                                         __attribute__((unused))
                                         ptrdiff_t nargs,
                                         __attribute__((unused))
                                         emacs_value args[],
                                         __attribute__((unused)) void *data) {
  intmax_t pid = env->extract_integer(env, args[0]);

  AXUIElementRef app = AXUIElementCreateApplication(pid);
  AXUIElementRef win;

  AXError ax_error = AXUIElementCopyAttributeValue(app, kAXMainWindowAttribute,
                                                   (CFTypeRef *)&win);

  if (ax_error != kAXErrorSuccess) {
    emacs_error(env, env->intern(env, "mjolmacs-axuielementcopy-error"),
                @"unknown error");
    return env->intern(env, "nil");
  }

  // ignoring other displays for now; this is just a proof of concept

  // NSLog(@"NSScreen.mainScreen.w = %f", NSScreen.mainScreen.frame.size.width);
  // NSLog(@"NSScreen.mainScreen.h = %f",
  // NSScreen.mainScreen.frame.size.height);

  CGSize windowSize;
  CGPoint windowPosition;
  AXValueRef temp;

  windowPosition.x = 0;
  windowPosition.y = 0;
  temp = AXValueCreate(kAXValueCGPointType, &windowPosition);
  AXUIElementSetAttributeValue(win, kAXPositionAttribute, temp);

  windowSize.width = NSScreen.mainScreen.frame.size.width / 2;
  windowSize.height = NSScreen.mainScreen.frame.size.height;
  temp = AXValueCreate(kAXValueCGSizeType, &windowSize);
  AXUIElementSetAttributeValue(win, kAXSizeAttribute, temp);

  CFRelease(temp);
  CFRelease(win);

  return env->intern(env, "t");
}

static emacs_value
Fmjolmacs_resize_right(__attribute__((unused)) emacs_env *env,
                       __attribute__((unused)) ptrdiff_t nargs,
                       __attribute__((unused)) emacs_value args[],
                       __attribute__((unused)) void *data) {
  intmax_t pid = env->extract_integer(env, args[0]);

  AXUIElementRef app = AXUIElementCreateApplication(pid);
  AXUIElementRef win;

  AXError ax_error = AXUIElementCopyAttributeValue(app, kAXMainWindowAttribute,
                                                   (CFTypeRef *)&win);

  if (ax_error != kAXErrorSuccess) {
    emacs_error(env, env->intern(env, "mjolmacs-axuielementcopy-error"),
                @"unknown error");
    return env->intern(env, "nil");
  }

  // ignoring other displays for now; this is just a proof of concept

  CGSize windowSize;
  CGPoint windowPosition;
  AXValueRef temp;

  windowPosition.x = NSScreen.mainScreen.frame.size.width / 2;
  windowPosition.y = 0;
  temp = AXValueCreate(kAXValueCGPointType, &windowPosition);
  AXUIElementSetAttributeValue(win, kAXPositionAttribute, temp);

  windowSize.width = NSScreen.mainScreen.frame.size.width / 2;
  windowSize.height = NSScreen.mainScreen.frame.size.height;
  temp = AXValueCreate(kAXValueCGSizeType, &windowSize);
  AXUIElementSetAttributeValue(win, kAXSizeAttribute, temp);

  CFRelease(temp);
  CFRelease(win);

  return env->intern(env, "t");
}

static emacs_value Fmjolmacs_resize_top(__attribute__((unused)) emacs_env *env,
                                        __attribute__((unused)) ptrdiff_t nargs,
                                        __attribute__((unused))
                                        emacs_value args[],
                                        __attribute__((unused)) void *data) {
  intmax_t pid = env->extract_integer(env, args[0]);

  AXUIElementRef app = AXUIElementCreateApplication(pid);
  AXUIElementRef win;

  AXError ax_error = AXUIElementCopyAttributeValue(app, kAXMainWindowAttribute,
                                                   (CFTypeRef *)&win);

  if (ax_error != kAXErrorSuccess) {
    emacs_error(env, env->intern(env, "mjolmacs-axuielementcopy-error"),
                @"unknown error");
    return env->intern(env, "nil");
  }

  // ignoring other displays for now; this is just a proof of concept

  CGSize windowSize;
  CGPoint windowPosition;
  AXValueRef temp;

  windowSize.width = NSScreen.mainScreen.frame.size.width;
  windowSize.height = NSScreen.mainScreen.frame.size.height / 2;

  // NSLog(@"windowSize.width = %f", windowSize.width);
  // NSLog(@"windowSize.height = %f", windowSize.height);

  windowPosition.x = 0;
  windowPosition.y = 0;
  temp = AXValueCreate(kAXValueCGPointType, &windowPosition);
  AXUIElementSetAttributeValue(win, kAXPositionAttribute, temp);

  temp = AXValueCreate(kAXValueCGSizeType, &windowSize);
  ax_error = AXUIElementSetAttributeValue(win, kAXSizeAttribute, temp);

  CFRelease(temp);
  CFRelease(win);

  return env->intern(env, "t");
}

static emacs_value
Fmjolmacs_resize_bottom(__attribute__((unused)) emacs_env *env,
                        __attribute__((unused)) ptrdiff_t nargs,
                        __attribute__((unused)) emacs_value args[],
                        __attribute__((unused)) void *data) {
  intmax_t pid = env->extract_integer(env, args[0]);

  AXUIElementRef app = AXUIElementCreateApplication(pid);
  AXUIElementRef win;

  AXError ax_error = AXUIElementCopyAttributeValue(app, kAXMainWindowAttribute,
                                                   (CFTypeRef *)&win);

  if (ax_error != kAXErrorSuccess) {
    emacs_error(env, env->intern(env, "mjolmacs-axuielementcopy-error"),
                @"unknown error");
    return env->intern(env, "nil");
  }

  // ignoring other displays for now; this is just a proof of concept

  CGSize windowSize;
  CGPoint windowPosition;
  AXValueRef temp;

  windowPosition.x = 0;
  windowPosition.y = NSScreen.mainScreen.frame.size.height / 2;
  temp = AXValueCreate(kAXValueCGPointType, &windowPosition);
  AXUIElementSetAttributeValue(win, kAXPositionAttribute, temp);

  windowSize.width = NSScreen.mainScreen.frame.size.width;
  windowSize.height = NSScreen.mainScreen.frame.size.height / 2;
  temp = AXValueCreate(kAXValueCGSizeType, &windowSize);
  AXUIElementSetAttributeValue(win, kAXSizeAttribute, temp);

  CFRelease(temp);
  CFRelease(win);

  return env->intern(env, "t");
}

static emacs_value
Fmjolmacs_authorize_notifications(__attribute__((unused)) emacs_env *env,
                                  __attribute__((unused)) ptrdiff_t nargs,
                                  __attribute__((unused)) emacs_value args[],
                                  void *data) {
  MjolmacsCtx *m = data;

  if (!m.isMacApp) {
    emacs_error(env, env->intern(env, "emacs-not-mac-app"),
                @"emacs needs to be run as a .app application; main bundle was "
                @"not found");
    return env->intern(env, "nil");
  }

  if (!m.isCodeSigned) {
    emacs_error(env, env->intern(env, "emacs-not-codesigned"),
                @"emacs needs to be codesigned to all notifications");
    return env->intern(env, "nil");
  }

  UNUserNotificationCenter *center =
      [UNUserNotificationCenter currentNotificationCenter];

  UNAuthorizationOptions options =
      UNAuthorizationOptionAlert | UNAuthorizationOptionSound |
      UNAuthorizationOptionBadge |
      UNAuthorizationOptionProvidesAppNotificationSettings;

  __block NSError *err = nil;

  // force macos calls to be synchronous
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

  [center
      requestAuthorizationWithOptions:options
                    completionHandler:^(__attribute__((unused)) BOOL granted,
                                        NSError *_Nullable error) {
                      if (error) {
                        // granted seems to overlap with error; in testing
                        // this, error was always set to seomthing if
                        // granted was false
                        err = [error retain];
                      }
                      dispatch_semaphore_signal(semaphore);
                    }];

  dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

  if (err) {
    static char notif_warn[] = "mjolmacs: emacs not authorized to send "
                               "notifications; check system prefences to"
                               "allow";
    emacs_value warn_args[] = {
        env->make_string(env, notif_warn, strlen(notif_warn))};
    env->funcall(env, env->intern(env, "message"), 1, warn_args);

    [err release];
    return env->intern(env, "nil");
  }

  return env->intern(env, "t");
}

static emacs_value Fmjolmacs_alert(emacs_env *env, ptrdiff_t nargs,
                                   emacs_value args[], void *data) {
  MjolmacsCtx *m = data;

  if (!m.isMacApp) {
    emacs_error(env, env->intern(env, "emacs-not-mac-app"),
                @"emacs needs to be run as a .app application; main bundle was "
                @"not found");
    return env->intern(env, "nil");
  }

  if (!m.isCodeSigned) {
    emacs_error(env, env->intern(env, "emacs-not-codesigned"),
                @"emacs needs to be codesigned to all notifications");
    return env->intern(env, "nil");
  }

  // make sure notifications are authorized, else nothing will appear to happen
  // and there is no error
  emacs_value sub_args[] = {};
  emacs_value sym = env->funcall(
      env, env->intern(env, "mjolmacs-authorize-notifications"), 0, sub_args);

  if (!env->is_not_nil(env, sym)) {
    // error has already been handled by `mjolmacs-authorize-notifications'
    return env->intern(env, "nil");
  }

  UNUserNotificationCenter *center =
      [UNUserNotificationCenter currentNotificationCenter];

  UNMutableNotificationContent *content;
  UNNotificationRequest *request;

  center.delegate = (id)m;
  content = [[UNMutableNotificationContent alloc] init];

  ptrdiff_t len = 0;
  env->copy_string_contents(env, args[0], NULL, &len);

  char *msg = malloc(len);
  env->copy_string_contents(env, args[0], msg, &len);

  content.body = [NSString stringWithUTF8String:msg];
  free(msg);

  if (nargs > 1 && env->is_not_nil(env, args[1])) {
    len = 0;
    env->copy_string_contents(env, args[1], NULL, &len);

    char *title = malloc(len);
    env->copy_string_contents(env, args[1], title, &len);

    content.title = [NSString stringWithUTF8String:title];
    free(title);
  }

  content.sound = [UNNotificationSound defaultSound];
  // content.attachments =
  content.categoryIdentifier = @"";

  request =
      [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString]
                                           content:content
                                           trigger:nil];

  // force macos calls to be synchronous
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

  [center
      addNotificationRequest:request
       withCompletionHandler:^(NSError *_Nullable error) {
         if (error) {
           NSLog(@"%@",
                 [NSString stringWithFormat:
                               @"(LEEROY) addNotificationRequest: error = %@",
                               error]);
         }
         dispatch_semaphore_signal(semaphore);
       }];

  dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

  return env->intern(env, "t");
}

static emacs_value Fmjolmacs_start(emacs_env *env,
                                   __attribute__((unused)) ptrdiff_t nargs,
                                   emacs_value args[], void *data) {
  MjolmacsCtx *m = data;

  m.isMacApp = [[NSBundle mainBundle] bundleIdentifier] != nil;
  m.isCodeSigned = YES;

  SecStaticCodeRef ref = NULL;

  NSURL *url = [NSURL URLWithString:[[NSBundle mainBundle] executablePath]];

  OSStatus status;

  // obtain the cert info from the executable
  status = SecStaticCodeCreateWithPath((CFURLRef)url, kSecCSDefaultFlags, &ref);

  if (ref == NULL || status != noErr) {
    // definitely not signed
    m.isCodeSigned = NO;
  }

  // create the requirement to check against
  status = SecStaticCodeCheckValidity(ref, kSecCSCheckAllArchitectures, NULL);

  if (status != noErr) {
    m.isCodeSigned = NO;
  }

  if (!m.isMacApp) {
    static char notif_warn[] = "mjolmacs: emacs not running as a bundled app; "
                               "cannot use notifications";
    emacs_value warn_args[] = {
        env->make_string(env, notif_warn, strlen(notif_warn))};
    env->funcall(env, env->intern(env, "message"), 1, warn_args);
  }

  int fd = env->open_channel(env, args[0]);
  [m openChannel:fd];

  return env->intern(env, "t");
}

static emacs_value Fmjolmacs_stop(__attribute__((unused)) emacs_env *env,
                                  __attribute__((unused)) ptrdiff_t nargs,
                                  __attribute__((unused)) emacs_value args[],
                                  void *data) {
  MjolmacsCtx *m = data;

  // last thing to do is shut down the pipe and free our own memory
  [m dealloc];

  dealloc_common();

  return env->intern(env, "t");
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
    return env->intern(env, "nil");
  }

  if (!keys || ![keys count]) {
    // error happened in emacs_parse_key
    return env->intern(env, "nil");
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

  NSString *s = [NSString stringWithUTF8String:func];

  // NSString copies the bytes
  free(func);

  MjolmacsKey *mk = [keys firstObject];
  [m.funcs setObject:s forKey:mk];

  if ([c registerHotKeyWithKeyCode:mk.key
                     modifierFlags:mk.flags
                            target:m
                            action:@selector(hotkeyWithEvent:object:)
                            object:nil]) {
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

int emacs_module_init(struct emacs_runtime *ert) {
  emacs_env *env = ert->get_environment(ert);

  // initialize common variables
  init_common();

  MjolmacsCtx *m = [[MjolmacsCtx alloc] init];

  bind_function(env, "mjolmacs--start", 1, 1, Fmjolmacs_start,
                "Private C function for starting mjolmacs process", m);

  bind_function(env, "mjolmacs--stop", 0, 0, Fmjolmacs_stop,
                "Private C function for stopping the mjolmacs process", m);

  bind_function(env, "mjolmacs--focus-pid", 1, 1, Fmjolmacs_focus_pid,
                "Private C function used solely the previous app that was in "
                "focus before a mjolmacs popup frame was focused.",
                m);

  bind_function(env, "mjolmacs-register", 2, 2, Fmjolmacs_register,
                "Register global key binding to function", m);

  bind_function(
      env, "mjolmacs-authorized-notifications-p", 0, 0,
      Fmjolmacs_authorized_notif_p,
      "Determine if mjolmacs is authorized for notifications.\n\nThere are "
      "three states: 'not-determined, 'granted, and 'denied. 'granted is the "
      "only one that means notifications are allowed. A return value of nil "
      "means that emacs is not running as a bundled mac app and therefore "
      "cannot request authorization at all.",
      m);

  bind_function(env, "mjolmacs-authorize-notifications", 0, 0,
                Fmjolmacs_authorize_notifications,
                "Request authorization to make notifications.", m);

  bind_function(env, "mjolmacs-alert", 1, 2, Fmjolmacs_alert,
                "macOS notification alert.", m);

  bind_function(env, "mjolmacs-authorized-accessibility-p", 0, 0,
                Fmjolmacs_authorized_accessibility_p,
                "Determine if mjolmacs has accessibility api authorized.", m);

  bind_function(env, "mjolmacs-authorize-accessibility", 0, 0,
                Fmjolmacs_authorize_accessibility,
                "Request accessibility api authorization.", m);

  bind_function(env, "mjolmacs--resize-left", 1, 1, Fmjolmacs_resize_left,
                "Test resizing a window to the left half.", m);

  bind_function(env, "mjolmacs--resize-right", 1, 1, Fmjolmacs_resize_right,
                "Test resizing a window to the right half.", m);

  bind_function(env, "mjolmacs--resize-top", 1, 1, Fmjolmacs_resize_top,
                "Test resizing a window to the top half.", m);

  bind_function(env, "mjolmacs--resize-bottom", 1, 1, Fmjolmacs_resize_bottom,
                "Test resizing a window to the bottom half.", m);

  emacs_value Qfeat = env->intern(env, "mjolmacs-module");
  emacs_value Qprovide = env->intern(env, "provide");
  emacs_value args[] = {Qfeat};

  env->funcall(env, Qprovide, 1, args);

  return 0;
}
