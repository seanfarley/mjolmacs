#include "mjolmacs-utils.h"
#include "mjolmacs-constants.h"

#import <Carbon/Carbon.h>

@implementation MjolmacsKey

- (id)init {
  self = [super init];
  if (self) {
    _flags = 0;
    _key = 0;
    _binding = nil;
  }

  return self;
}

+ (instancetype)keyWithMods:(NSUInteger)key modifier:(NSUInteger)mods {
  MjolmacsKey *k = [[MjolmacsKey alloc] init];

  k.key = key;
  k.flags = mods;

  return k;
}

+ (instancetype)keyWithMods:(NSUInteger)key
                   modifier:(NSUInteger)mods
                    binding:(NSString *)b {
  MjolmacsKey *k = [MjolmacsKey keyWithMods:key modifier:mods];

  k.binding = b;

  return k;
}

- (NSUInteger)flags {
  // having a custom setter means we need to define our own getter
  return _flags;
}

- (void)setFlags:(NSUInteger)flags {
  // remove all the bits that aren't shift, ctrl, super, and alt

  NSUInteger extra =
      flags & ~(NSEventModifierFlagControl | NSEventModifierFlagOption |
                NSEventModifierFlagCommand | NSEventModifierFlagShift);

  if (extra) {
    NSLog(@"mjolmacs: removing extra modifier bits %lx", extra);
  }

  _flags = flags - extra;
}

- (BOOL)isEqual:(id)other {
  MjolmacsKey *o = other;
  // binding is just a convenience string for the user's original string, so we
  // don't need to compare its value
  return (_key == o.key) && (_flags == o.flags);
}

- (NSString *)description {

  NSMutableArray *mods = [[NSMutableArray alloc] init];

  if (_flags & NSEventModifierFlagControl) {
    [mods addObject:@"Control"];
  }
  if (_flags & NSEventModifierFlagOption) {
    [mods addObject:@"Meta"];
  }
  if (_flags & NSEventModifierFlagCommand) {
    [mods addObject:@"Super"];
  }
  if (_flags & NSEventModifierFlagShift) {
    [mods addObject:@"Shift"];
  }

  NSString *mods_str = @"None";
  if (mods && [mods count]) {
    mods_str = [mods componentsJoinedByString:@"-"];
  }

  return [NSString
      stringWithFormat:@"(modifiers %@, key: %@, orig: %@)", mods_str,
                       rev_key_map[[NSNumber numberWithUnsignedInteger:_key]],
                       _binding];
}

@end

void init_common(emacs_env *env) {
  Qnil = env->intern(env, "nil");
  Qt = env->intern(env, "t");

  control = [NSNumber numberWithUnsignedLong:NSEventModifierFlagControl];
  meta = [NSNumber numberWithUnsignedLong:NSEventModifierFlagOption];
  command = [NSNumber numberWithUnsignedLong:NSEventModifierFlagCommand];
  shift = [NSNumber numberWithUnsignedLong:NSEventModifierFlagShift];

  modifier_map = @{
    @"C" : control,
    // @"H" : @"Hyper",
    @"M" : meta,
    @"s" : command,
    @"S" : shift,
  };

  // a map of a key to a combo of [modifier, key]; this is needed to properly
  // handle shifted keys, e.g. $, %, ^
  key_map = @{
    @"SPC" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_Space] ],
    @"ESC" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_Escape] ],
    @"TAB" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_Tab] ],
    @"DEL" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_Delete] ],
    @"A" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_A] ],
    @"B" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_B] ],
    @"C" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_C] ],
    @"D" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_D] ],
    @"E" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_E] ],
    @"F" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_F] ],
    @"G" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_G] ],
    @"H" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_H] ],
    @"I" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_I] ],
    @"J" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_J] ],
    @"K" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_K] ],
    @"L" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_L] ],
    @"M" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_M] ],
    @"N" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_N] ],
    @"O" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_O] ],
    @"P" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_P] ],
    @"Q" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_Q] ],
    @"R" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_R] ],
    @"S" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_S] ],
    @"T" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_T] ],
    @"U" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_U] ],
    @"V" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_V] ],
    @"W" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_W] ],
    @"X" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_X] ],
    @"Y" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_Y] ],
    @"Z" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_Z] ],
    @"`" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_Grave] ],
    @"1" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_1] ],
    @"2" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_2] ],
    @"3" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_3] ],
    @"4" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_4] ],
    @"5" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_5] ],
    @"6" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_6] ],
    @"7" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_7] ],
    @"8" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_8] ],
    @"9" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_9] ],
    @"0" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_0] ],
    @"-" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_Minus] ],
    @"=" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_Equal] ],
    @"[" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_LeftBracket] ],
    @"]" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_RightBracket] ],
    @"\\" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_Backslash] ],
    @";" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_Semicolon] ],
    @"'" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_Quote] ],
    @"," : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_Comma] ],
    @"." : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_Period] ],
    @"/" : @[ @0, [NSNumber numberWithUnsignedLong:kVK_ANSI_Slash] ],
    // shifted keys
    @"~" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_Grave] ],
    @"!" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_1] ],
    @"@" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_2] ],
    @"#" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_3] ],
    @"$" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_4] ],
    @"%" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_5] ],
    @"^" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_6] ],
    @"&" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_7] ],
    @"*" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_8] ],
    @"(" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_9] ],
    @")" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_0] ],
    @"_" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_Minus] ],
    @"+" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_Equal] ],
    @"{" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_LeftBracket] ],
    @"}" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_RightBracket] ],
    @"|" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_Backslash] ],
    @":" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_Semicolon] ],
    @"\"" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_Quote] ],
    @"<" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_Comma] ],
    @">" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_Period] ],
    @"?" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_Slash] ],
  };

  rev_key_map = @{
    [NSNumber numberWithUnsignedLong:kVK_Space] : @"SPC",
    [NSNumber numberWithUnsignedLong:kVK_Escape] : @"ESC",
    [NSNumber numberWithUnsignedLong:kVK_Tab] : @"TAB",
    [NSNumber numberWithUnsignedLong:kVK_Delete] : @"DEL",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_A] : @"A",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_B] : @"B",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_C] : @"C",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_D] : @"D",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_E] : @"E",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_F] : @"F",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_G] : @"G",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_H] : @"H",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_I] : @"I",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_J] : @"J",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_K] : @"K",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_L] : @"L",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_M] : @"M",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_N] : @"N",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_O] : @"O",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_P] : @"P",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_Q] : @"Q",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_R] : @"R",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_S] : @"S",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_T] : @"T",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_U] : @"U",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_V] : @"V",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_W] : @"W",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_X] : @"X",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_Y] : @"Y",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_Z] : @"Z",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_Grave] : @"`",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_1] : @"1",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_2] : @"2",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_3] : @"3",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_4] : @"4",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_5] : @"5",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_6] : @"6",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_7] : @"7",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_8] : @"8",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_9] : @"9",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_0] : @"0",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_Minus] : @"-",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_Equal] : @"=",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_LeftBracket] : @"[",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_RightBracket] : @"]",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_Backslash] : @"\\",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_Semicolon] : @";",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_Quote] : @"'",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_Comma] : @",",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_Period] : @".",
    [NSNumber numberWithUnsignedLong:kVK_ANSI_Slash] : @"/",
    // TODO shifted keys
    // @"~" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_Grave ]],
    // @"!" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_1 ]],
    // @"@" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_2 ]],
    // @"#" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_3 ]],
    // @"$" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_4 ]],
    // @"%" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_5 ]],
    // @"^" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_6 ]],
    // @"&" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_7 ]],
    // @"*" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_8 ]],
    // @"(" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_9 ]],
    // @")" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_0 ]],
    // @"_" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_Minus ]],
    // @"+" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_Equal ]],
    // @"{" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_LeftBracket
    // ]],
    // @"}" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_RightBracket
    // ]],
    // @"|" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_Backslash ]],
    // @":" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_Semicolon ]],
    // @"\"" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_Quote ]],
    // @"<" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_Comma ]],
    // @">" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_Period ]],
    // @"?" : @[ shift, [NSNumber numberWithUnsignedLong:kVK_ANSI_Slash ]],
  };
}

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

void emacs_error(emacs_env *env, emacs_value err_type, NSString *msg) {
  env->non_local_exit_throw(
      env, err_type, env->make_string(env, [msg UTF8String], [msg length]));
}

NSArray *emacs_parse_keys(emacs_env *env, emacs_value ekb) {
  NSMutableArray *mac_keys = [[NSMutableArray alloc] init];

  ptrdiff_t len = 0;
  env->copy_string_contents(env, ekb, NULL, &len);

  char *kb_cstr = malloc(len);
  env->copy_string_contents(env, ekb, kb_cstr, &len);

  NSString *kb = [NSString stringWithUTF8String:kb_cstr];

  NSArray *keys = [kb componentsSeparatedByString:@" "];

  // should be ok to free this now
  free(kb_cstr);

  for (id element in keys) {
    MjolmacsKey *mk = [[MjolmacsKey alloc] init];

    // store original keybinding
    mk.binding = element;

    NSMutableArray *seq = [NSMutableArray
        arrayWithArray:[element componentsSeparatedByString:@"-"]];

    // the key is always last
    NSString *key = [[seq lastObject] uppercaseString];
    [seq removeLastObject];

    for (id modifier in seq) {
      NSNumber *mod_key = modifier_map[modifier];
      NSLog(@"modifier: %@", mod_key);

      if (!mod_key) {
        emacs_error(
            env, env->intern(env, "modifier-key-not-found"),
            [NSString
                stringWithFormat:@"the given modifier key [%@] was not found",
                                 modifier]);
        return nil;
      }

      mk.flags |= [mod_key longValue];
    }

    NSArray *mac_key_arr = key_map[key];
    if (!mac_key_arr || ![mac_key_arr count]) {
      emacs_error(
          env, env->intern(env, "key-not-found"),
          [NSString stringWithFormat:@"the given key [%@] was not found", key]);
      return nil;
    }

    mk.flags |= [[mac_key_arr firstObject] longValue];
    mk.key = [[mac_key_arr lastObject] longValue];

    [mac_keys addObject:mk];
  }

  // copy makes immutable, well, copies (it's also optimized for this use-case)
  return [mac_keys copy];
}
