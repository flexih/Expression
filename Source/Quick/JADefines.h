//
//  JADefines.h
//  Jarvis
//
//  Created by flexih on 12/02/2018.
//  Copyright © 2018 paopao. All rights reserved.
//

#ifndef JADefines_H
#define JADefines_H

#import <Foundation/Foundation.h>

#ifndef AS
static inline
id pp_obj_cast(Class clz, id obj) {
    if ([obj isKindOfClass:clz]) {
        return obj;
    }
    return nil;
};
#define AS(clz, obj) ((clz *)pp_obj_cast([clz class], obj))
#endif

#ifndef ASP
#define ASP(p, obj) ([(obj) conformsToProtocol:@protocol(p)]?(obj):nil)
#endif

#ifndef IS
#define IS(clz, obj) (AS(clz, obj) != nil)
#endif

#ifndef let
#define let __auto_type const
#endif

#ifndef var
#define var __auto_type
#endif

#ifndef _ASNumber
#define _ASNumber
static inline
NSNumber *ASNumber(id value) {
    if (IS(NSNumber, value)) {
        return value;
    }
    if (IS(NSString, value)) {
        return [NSNumber numberWithDouble:[(NSString *)value doubleValue]];
    }
    return nil;
}
#endif

#ifndef _ASString
#define _ASString
static inline
NSString *ASString(id value) {
    if (IS(NSString, value)) {
        return value;
    }
    if (IS(NSNumber, value)) {
        return [(NSNumber *)value stringValue];
    }
    return nil;
}
#endif

#ifndef _Stringfy
#define _Stringfy
static inline
NSString *Stringfy(id value) {
    if (IS(NSString, value)) {
        return value;
    }
    if (IS(NSNumber, value)) {
        return [(NSNumber *)value stringValue];
    }
    if (IS(NSObject, value)) {
        [(NSObject *)value description];
    }
    return nil;
}
#endif

#if DEBUG
#define JAAssert(condition, format, ...) NSAssert(condition, format, ##__VA_ARGS__)
#define JALog(condition, format, ...) do {\
  if (!(condition)) { \
    NSLog(format, ##__VA_ARGS__); \
  } \
} while(0)
#else
#define JAAssert(...)
#define JALog(...)
#endif

#endif /* JADefines_H */
