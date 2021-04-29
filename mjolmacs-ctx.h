#import "CarbonHotKey/CarbonHotKeyCenter.h"

#import <Cocoa/Cocoa.h>

@interface MjolmacsCtx : NSObject {
}

@property(strong) NSMutableDictionary *funcs;
@property(strong) NSFileHandle *pipe;

- (void)openChannel:(int)fd;
- (void)runLisp:(NSString *)lisp;

@end
