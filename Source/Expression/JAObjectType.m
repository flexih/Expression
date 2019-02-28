//
//  JAObjectType.m
//  Jarvis
//
//  Created by flexih on 2018/7/26.
//  Copyright © 2018 paopao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JAObjectType.h"
#import "JADefines.h"

@interface JAObjectType () {
    struct {
        uint8_t readonly:1;
    } _flag;
}
@end

@implementation JAObjectType
@dynamic readonly;

JATransformerBlock JAPrefixTransformer = ^NSString * _Nonnull(NSString * key) {
    return [@"ja_" stringByAppendingString:key];
};
JATransformerBlock JALayerTransformer = ^NSString * _Nonnull(NSString * key) {
    return [@"layer." stringByAppendingString:key];
};

static
NSDictionary<NSNumber *, JAObjectType *> *defaultKinds(void) {
    static NSDictionary *defaultKinds;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultKinds = @{@(JAKindString): [JAObjectType runtimeKind:JAKindString value:nil],
                         @(JAKindNumber): [JAObjectType runtimeKind:JAKindNumber value:nil],
                         @(JAKindString): [JAObjectType runtimeKind:JAKindString value:nil],
                         @(JAKindColor): [JAObjectType runtimeKind:JAKindColor value:nil],
                         @(JAKindColorRef): [JAObjectType runtimeKind:JAKindColorRef value:nil],
                         @(JAKindImage): [JAObjectType runtimeKind:JAKindCGImageRef value:nil],
                         @(JAKindFont): [JAObjectType runtimeKind:JAKindFont value:nil],
                         @(JAKindBOOL): [JAObjectType runtimeKind:JAKindBOOL value:nil],
                         @(JAKindInt): [JAObjectType runtimeKind:JAKindInt value:nil],
                         @(JAKindCGFloat): [JAObjectType runtimeKind:JAKindCGFloat value:nil],
                         @(JAKindDouble): [JAObjectType runtimeKind:JAKindDouble value:nil],
                         @(JAKindURL): [JAObjectType runtimeKind:JAKindURL value:nil],
                         @(JAKindDate): [JAObjectType runtimeKind:JAKindDate value:nil],
                         @(JAKindNSTextAlignment): [JAObjectType runtimeKind:JAKindNSTextAlignment value:nil],
                         @(JAKindNSLineBreakMode): [JAObjectType runtimeKind:JAKindNSLineBreakMode value:nil],
                         @(JAKindUIViewContentMode): [JAObjectType runtimeKind:JAKindUIViewContentMode value:nil],
                         @(JAKindUIScrollViewContentInsetAdjustmentBehavior): [JAObjectType runtimeKind:JAKindUIScrollViewContentInsetAdjustmentBehavior value:nil],
                         @(JAKindUIScrollViewIndicatorStyleDefault): [JAObjectType runtimeKind:JAKindUIScrollViewIndicatorStyleDefault value:nil],
                         @(JAKindUIScrollViewKeyboardDismissMode): [JAObjectType runtimeKind:JAKindUIScrollViewKeyboardDismissMode value:nil],
                         @(JAKindUITableViewStyle): [JAObjectType runtimeKind:JAKindUITableViewStyle value:nil],
                         @(JAKindUITableViewCellSeparatorStyle): [JAObjectType runtimeKind:JAKindUITableViewCellSeparatorStyle value:nil],
                         @(JAKindUIDatePickerMode): ({let type = [JAObjectType runtimeKind:JAKindUIDatePickerMode value:nil]; type.transform = @"datePickerMode"; type;}),
                         @(JAKindUITableViewCellSelectionStyle): [JAObjectType runtimeKind:JAKindUITableViewCellSelectionStyle value:nil],
                         };
    });
    return defaultKinds;
}

+ (instancetype)runtimeKind:(JAObjectKind)kind {
    return defaultKinds()[@(kind)] ?: [self runtimeKind:kind value:nil];
}

+ (instancetype)runtimeKind:(JAObjectKind)kind value:(id<NSCopying>)value {
    JAObjectType *type = [[self alloc] init];
    type.kind = kind;
    type.value = value;
    return type;
}

- (id)copyWithZone:(NSZone *)zone {
    JAObjectType *one = defaultKinds()[@(self.kind)];
    if (one) return one;
    one = [[self.class allocWithZone:zone] init];
    one.kind = self.kind;
    one.value = self.value;
    one.transform = self.transform;
    one.transformer = self.transformer;
    one.valueTransformer = self.valueTransformer;
    one.reverseValueTransformer =  self.reverseValueTransformer;
    return one;
}

- (nullable id)reverseCast:(id)value {
    if (self.reverseValueTransformer) {
        return self.reverseValueTransformer(value);
    }
    return value;
}

- (id)cast:(id __nullable)value {
    if (self.valueTransformer) {
        return self.valueTransformer(value);
    }
    return [self _cast:value];
}

- (id)_cast:(id __nullable)value {
    Class class = [value class];
    switch (self.kind) {
        case JAKindString:
            return Stringfy(value);
        case JAKindNumber:
            return ASNumber(value);
        case JAKindColor:
            return AS(UIColor, value);
        case JAKindColorRef:
            if ([class isSubclassOfClass:UIColor.class]) {
                return (id)[(UIColor *)value CGColor];
            }
            return nil;
        case JAKindFont:
            if ([class isSubclassOfClass:UIFont.class]) {
                return value;
            }
            break;
        case JAKindBOOL:
            if (IS(NSString, value)) {
                if ([value isEqualToString:@"true"]) {
                    return @YES;
                }
                if ([value isEqualToString:@"false"]) {
                    return @NO;
                }
            } //fallthrough
        case JAKindInt:
        case JAKindCGFloat:
        case JAKindDouble:
            return ASNumber(value);
        case JAKindURL:
            if (IS(NSString, value)) return [NSURL URLWithString:(NSString *)value];
            if (IS(NSURL, value)) return value;
            break;
        case JAKindDate:
            if (IS(NSString, value)) {
                return JADateFormatFromString((NSString *)value);
            }
            break;
        case JAKindUITableViewCellSeparatorStyle:
            if (IS(NSString, value)) {
                if ([value isEqualToString:@"none"]) {
                    return @(UITableViewCellSeparatorStyleNone);
                }
                if ([value isEqualToString:@"line"]) {
                    return @(UITableViewCellSeparatorStyleSingleLine);
                }
            }
            return @(UITableViewCellSeparatorStyleSingleLine);
        case JAKindUITableViewStyle:
            if (IS(NSString, value)) {
                if ([value isEqualToString:@"plain"]) {
                    return @(UITableViewStylePlain);
                }
                if ([value isEqualToString:@"grouped"]) {
                    return @(UITableViewStyleGrouped);
                }
            }
            return @(UITableViewStylePlain);
        case JAKindUIScrollViewKeyboardDismissMode:
            if (IS(NSString, value)) {
                if ([value isEqualToString:@"none"]) {
                    return @(UIScrollViewKeyboardDismissModeNone);
                }
                if ([value isEqualToString:@"onDrag"]) {
                    return @(UIScrollViewKeyboardDismissModeOnDrag);
                }
                if ([value isEqualToString:@"interactive"]) {
                    return @(UIScrollViewKeyboardDismissModeInteractive);
                }
            }
            return @(UIScrollViewKeyboardDismissModeNone);
        case JAKindUIScrollViewIndicatorStyleDefault:
            if (IS(NSString, value)) {
                if ([value isEqualToString:@"default"]) {
                    return @(UIScrollViewIndicatorStyleDefault);
                }
                if ([value isEqualToString:@"black"]) {
                    return @(UIScrollViewIndicatorStyleBlack);
                }
                if ([value isEqualToString:@"white"]) {
                    return @(UIScrollViewIndicatorStyleWhite);
                }
            }
            return @(UIScrollViewIndicatorStyleDefault);
        case JAKindUIScrollViewContentInsetAdjustmentBehavior:
            if (@available(iOS 11, *)) {
                if (IS(NSString, value)) {
                    if ([value isEqualToString:@"automatic"]) {
                        return @(UIScrollViewContentInsetAdjustmentAutomatic);
                    }
                    if ([value isEqualToString:@"scrollableAxes"]) {
                        return @(UIScrollViewContentInsetAdjustmentScrollableAxes);
                    }
                    if ([value isEqualToString:@"never"]) {
                        return @(UIScrollViewContentInsetAdjustmentNever);
                    }
                    if ([value isEqualToString:@"always"]) {
                        return @(UIScrollViewContentInsetAdjustmentAlways);
                    }
                }
            }
            return @0;
        case JAKindUIViewContentMode:
            if (IS(NSString, value)) {
                if ([value isEqualToString:@"scaleToFill"]) {
                    return @(UIViewContentModeScaleToFill);
                }
                if ([value isEqualToString:@"scaleAspectFit"]) {
                    return @(UIViewContentModeScaleAspectFit);
                }
                if ([value isEqualToString:@"scaleAspectFill"]) {
                    return @(UIViewContentModeScaleAspectFill);
                }
                if ([value isEqualToString:@"redraw"]) {
                    return @(UIViewContentModeRedraw);
                }
                if ([value isEqualToString:@"center"]) {
                    return @(UIViewContentModeCenter);
                }
                if ([value isEqualToString:@"top"]) {
                    return @(UIViewContentModeTop);
                }
                if ([value isEqualToString:@"bottom"]) {
                    return @(UIViewContentModeBottom);
                }
                if ([value isEqualToString:@"left"]) {
                    return @(UIViewContentModeLeft);
                }
                if ([value isEqualToString:@"right"]) {
                    return @(UIViewContentModeRight);
                }
                if ([value isEqualToString:@"topLeft"]) {
                    return @(UIViewContentModeTopLeft);
                }
                if ([value isEqualToString:@"topRight"]) {
                    return @(UIViewContentModeTopRight);
                }
                if ([value isEqualToString:@"bottomLeft"]) {
                    return @(UIViewContentModeBottomLeft);
                }
                if ([value isEqualToString:@"bottomRight"]) {
                    return @(UIViewContentModeBottomRight);
                }
            }
            return @(UIViewContentModeScaleToFill);
        case JAKindNSLineBreakMode:
            if (IS(NSString, value)) {
                if ([(NSString *)value isEqualToString:@"wordWrap"]) {
                    return @(NSLineBreakByWordWrapping);
                }
                if ([(NSString *)value isEqualToString:@"charWrap"]) {
                    return @(NSLineBreakByCharWrapping);
                }
                if ([(NSString *)value isEqualToString:@"clip"]) {
                    return @(NSLineBreakByClipping);
                }
                if ([(NSString *)value isEqualToString:@"truncateHead"]) {
                    return @(NSLineBreakByTruncatingHead);
                }
                if ([(NSString *)value isEqualToString:@"truncateTail"]) {
                    return @(NSLineBreakByTruncatingTail);
                }
                if ([(NSString *)value isEqualToString:@"truncateMiddle"]) {
                    return @(NSLineBreakByTruncatingMiddle);
                }
            }
            return @(NSLineBreakByWordWrapping);
        case JAKindNSTextAlignment:
            if (IS(NSString, value)) {
                if ([(NSString *)value isEqualToString:@"left"]) {
                    return @(NSTextAlignmentLeft);
                }
                if ([(NSString *)value isEqualToString:@"right"]) {
                    return @(NSTextAlignmentRight);
                }
                if ([(NSString *)value isEqualToString:@"center"]) {
                    return @(NSTextAlignmentCenter);
                }
                if ([(NSString *)value isEqualToString:@"justified"]) {
                    return @(NSTextAlignmentJustified);
                }
            }
            return @(NSTextAlignmentLeft);
        case JAKindClass:
            if (IS(NSString, self.value) && [class isSubclassOfClass:NSClassFromString((NSString *)self.value)]) {
                return value;
            }
            break;
        case JAKindProtocol:
            if (IS(NSString, self.value)) {
                if ([value conformsToProtocol:NSProtocolFromString((NSString *)self.value)]) {
                    return value;
                }
                return nil;
            }
            if (IS(NSArray, self.value)) {
                for (id obj in (NSArray *)self.value) {
                    let name = AS(NSString, obj);
                    if (name) {
                        if (![value conformsToProtocol:NSProtocolFromString(name)]) {
                            return nil;
                        }
                    }
                }
                return value;
            }
            return nil;
        case JAKindUIDatePickerMode:
            if (IS(NSString, value)) {
                NSString *val = (NSString *)value;
                if ([val isEqualToString:@"time"]) {
                    return @(UIDatePickerModeTime);
                }
                if ([val isEqualToString:@"date"]) {
                    return @(UIDatePickerModeDate);
                }
                if ([val isEqualToString:@"dateAndTime"]) {
                    return @(UIDatePickerModeDateAndTime);
                }
                if ([val isEqualToString:@"countDownTimer"]) {
                    return @(UIDatePickerModeCountDownTimer);
                }
            }
            return @(UIDatePickerModeTime);
        case JAKindUITableViewCellSelectionStyle:
            if (IS(NSString, value)) {
                NSString *val = (NSString *)value;
                if ([val isEqualToString:@"none"]) {
                    return @(UITableViewCellSelectionStyleNone);
                }
                if ([val isEqualToString:@"blue"]) {
                    return @(UITableViewCellSelectionStyleBlue);
                }
                if ([val isEqualToString:@"gray"]) {
                    return @(UITableViewCellSelectionStyleGray);
                }
            }
            return @(UITableViewCellSelectionStyleDefault);
        default:
            break;
    }
    return value;
}

- (nullable NSString *)translate:(NSString *)key {
    return self.transform ?: (self.transformer ? self.transformer(key) : nil);
}

- (void)setReadonly:(BOOL)readonly {
    _flag.readonly = !!readonly;
}

- (BOOL)readonly {
    return _flag.readonly;
}

@end

NSCalendar *JAcalendar(void) {
    static NSCalendar *calendar;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        calendar.timeZone = [NSTimeZone timeZoneWithName:@"zh_CN"];
        calendar.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
    });
    return calendar;
}

NSString *JADateFormatFromDate(NSDate *date) {
    if (date == nil) return nil;
    NSDateComponents *components = [JAcalendar() components:NSCalendarUnitMinute|NSCalendarUnitHour|NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:date];
    return [NSString stringWithFormat:@"%ld-%02ld-%02ld %02ld:%02ld", (long)components.year, (long)components.month, (long)components.day, (long)components.hour, (long)components.minute];
}

NSDate *JADateFormatFromString(NSString *string) {
    if (string == nil) return nil;
    char year[5], month[3], day[3], hour[3], minute[3];
    NSInteger nowYear = 0, nowMonth = 0, nowDay = 0;
    int count = 0;
    if (string.length <= 10) {
        if (string.length == 10) {
            count = sscanf(string.UTF8String, "%4[0-9]-%2[0-9]-%2[0-9]", year, month, day);
            if (count != 3) return nil;
        } else if (string.length == 5) {
            count = sscanf(string.UTF8String, "%2[0-9]:%2[0-9]", hour, minute);
            if (count != 2) return nil;
            [JAcalendar() getEra:nil year:&nowYear month:&nowMonth day:&nowDay fromDate:[NSDate date]];
        }
    } else {
        count = sscanf(string.UTF8String, "%4[0-9]-%2[0-9]-%2[0-9] %2[0-9]:%2[0-9]", year, month, day, hour, minute);
        if (count != 5) return nil;
    }
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = count == 2 ? nowYear : atol(year);
    components.month = count == 2 ? nowMonth : atol(month);
    components.day = count == 2 ? nowDay : atol(day);
    if (count != 3) {
        components.hour = atol(hour);
        components.minute = atol(minute);
    }
    let date = [JAcalendar() dateFromComponents:components];
    return date;
}
