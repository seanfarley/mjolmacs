#import <Cocoa/Cocoa.h>
#import <emacs-module.h>
#import "CarbonHotKey/CarbonHotKeyCenter.h"

@interface MjolmacsEnv : NSObject {
  NSMutableDictionary *funcs;
  NSFileHandle *pipe;
}

@end
