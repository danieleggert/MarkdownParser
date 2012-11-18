#ifndef _OS_X_OBJC_COMPATIBILITY_H_
#define _OS_X_OBJC_COMPATIBILITY_H_

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED

#import "NSFont+UIKitAdditions.h"

// Types
#define UIImage			NSImage
#define UIFont			NSFont
#define UIColor			NSColor

#define CGSize			NSSize
#define CGPoint			NSPoint
#define CGRect			NSRect

// Functions
#define CGSizeMake		NSMakeSize
#define CGPointMake		NSMakePoint
#define CGRectMake		NSMakeRect
#define CGRectDivide	NSDivideRect

// Constants
#define CGRectMinXEdge	NSMinXEdge
#define CGRectMinYEdge	NSMinYEdge
#define CGRectMaxXEdge	NSMaxXEdge
#define CGRectMaxYEdge	NSMaxYEdge

#endif

#endif /* _OS_X_OBJC_COMPATIBILITY_H_ */
