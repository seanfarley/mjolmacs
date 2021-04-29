#ifndef MJOLMACS_UTILS_H_
#define MJOLMACS_UTILS_H_

#import <Cocoa/Cocoa.h>
#include <emacs-module.h>
#include <objc/NSObjCRuntime.h>

@interface MjolmacsKey : NSObject {
}

@property NSUInteger flags;
@property NSUInteger key;
@property(strong) NSString *binding;

+ (instancetype)keyWithMods:(NSUInteger)key modifier:(NSUInteger)mods;
+ (instancetype)keyWithMods:(NSUInteger)key
                   modifier:(NSUInteger)mods
                    binding:(NSString *)b;

@end

void init_common(emacs_env *env);

void bind_function(emacs_env *env, const char *name, ptrdiff_t min_arity,
                   ptrdiff_t max_arity,
                   emacs_value (*func)(emacs_env *env, ptrdiff_t nargs,
                                       emacs_value *args, void *data),
                   const char *docstring, void *data);

void emacs_error(emacs_env *env, emacs_value err_type, NSString *msg);

NSArray *emacs_parse_keys(emacs_env *env, emacs_value ekb);

#endif // MJOLMACS_UTILS_H_
