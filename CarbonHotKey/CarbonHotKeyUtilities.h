/*
 CarbonHotKey -- CarbonHotKeyUtilities.h

 Copyright (c) 2010-2015 Dave DeLong <https://www.davedelong.com>
 Copyright (c) 2021 Sean Farley <https://farley.io>

 Permission to use, copy, modify, and/or distribute this software for any
 purpose with or without fee is hereby granted, provided that the above
 copyright notice and this permission notice appear in all copies.

 The software is provided "as is", without warranty of any kind, including all
 implied warranties of merchantability and fitness. In no event shall the
 author(s) or copyright holder(s) be liable for any claim, damages, or other
 liability, whether in an action of contract, tort, or otherwise, arising from,
 out of, or in connection with the software or the use or other dealings in the
 software.
 */

#import <Foundation/Foundation.h>

extern NSString *CarbonStringFromKeyCode(unsigned short keyCode,
                                         NSUInteger modifiers);
extern UInt32 CarbonModifierFlagsFromCocoaModifiers(NSUInteger flags);
