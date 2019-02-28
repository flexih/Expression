//
//  JAObjectType.h
//  Jarvis
//
//  Created by flexih on 2018/7/26.
//  Copyright © 2018 paopao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, JAObjectKind) {
    JAKindCommon,
    JAKindClass,
    JAKindProtocol,
    JAKindString,
    JAKindNumber,
    JAKindColor,
    JAKindColorRef,
    JAKindImage,
    JAKindCGImageRef,
    JAKindFont,
    JAKindBOOL,
    JAKindInt,
    JAKindCGFloat,
    JAKindDouble,
    JAKindURL,
    JAKindDate,
    JAKindNSTextAlignment,
    JAKindNSLineBreakMode,
    JAKindUIViewContentMode,
    JAKindUIScrollViewContentInsetAdjustmentBehavior,
    JAKindUIScrollViewIndicatorStyleDefault,
    JAKindUIScrollViewKeyboardDismissMode,
    JAKindUITableViewStyle,
    JAKindUITableViewCellSeparatorStyle,
    JAKindUIDatePickerMode,
    JAKindUITableViewCellSelectionStyle
};

typedef NSString * (^JATransformerBlock)(NSString * key);

extern JATransformerBlock JAPrefixTransformer;
extern JATransformerBlock JALayerTransformer;

/*
 * UTC+8
 * yyyy-MM-dd hh:mm
 */
NSCalendar *JAcalendar(void);
NSString *JADateFormatFromDate(NSDate *date);
NSDate *JADateFormatFromString(NSString *string);

@interface JAObjectType : NSObject<NSCopying>

@property (nonatomic) JAObjectKind kind;
@property (nullable, nonatomic, copy) id<NSCopying> value;
@property (nullable, nonatomic, copy) NSString *transform;
@property (nullable, nonatomic, copy) NSString *(^transformer)(NSString *);
@property (nullable, nonatomic, copy) id (^valueTransformer)(id v);
@property (nullable, nonatomic, copy) id (^reverseValueTransformer)(id v);
@property (nonatomic) BOOL readonly;

//share value
+ (instancetype)runtimeKind:(JAObjectKind)kind;
//no share value
+ (instancetype)runtimeKind:(JAObjectKind)kind value:(id<NSCopying> __nullable)value;

- (nullable id)cast:(id __nullable)value;
- (nullable id)reverseCast:(id __nullable)value;
- (nullable NSString *)translate:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
