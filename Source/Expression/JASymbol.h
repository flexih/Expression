//
//  JASymbol.h
//  Jarvis
//
//  Created by flexih on 2018/8/1.
//  Copyright © 2018 paopao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JAOperator.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, JASymbolType) {
    JASymbolTypeOperator = 1,
    JASymbolTypeConstant, // number, 'string'
    JASymbolTypeLiteral, // variable
    JASymbolTypeFunction // fun(a,b)
};

@class JASymbol;

typedef id (^JAEvaluator)(NSArray<id> *args);
typedef JAEvaluator (^JASymbolEvaluator)(JASymbol *symbol);

@interface JASymbol : NSObject

@property (nonatomic) JASymbolType type;
@property (nonatomic, strong) JAOperator *operator;
@property (nonatomic, copy) id<NSCopying, NSObject> value; //NSNumber, NSString
@property (nonatomic, strong) NSArray<JASymbol *> *args;
@property (nonatomic, copy) JASymbolEvaluator evaluator;

+ (instancetype)symbolWithExpression:(NSString *)expression;

- (instancetype)initWithExpression:(NSString *)expression;

- (nullable id)evaluate;

@end

NSNumber *JAParseHexTail(NSString *expression, size_t from);
NSString *JAParseString(NSString *expression);
NSNumber *JAPasrseNumber(NSString *expression);

NS_ASSUME_NONNULL_END
