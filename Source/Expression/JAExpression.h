//
//  JAExpression.h
//  Jarvis
//
//  Created by flexih on 2018/7/25.
//  Copyright © 2018 paopao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JASymbol.h"
#import "JAObjectType.h"

@protocol JANode;

@interface JAExpression : NSObject

@property (readonly) NSArray<NSString *> *symbolNames;
@property (nonatomic, strong) JAObjectType *runtimeType;
@property (readonly) BOOL isConstant;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)expression:(NSString *)expression
                 constants:(JASymbolEvaluator)constants
           symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
                      node:(id<JANode>)node
                     error:(NSError **)error;

+ (instancetype)evaluteExpression:(id (^)(void))evaluator
                        constants:(JASymbolEvaluator)constants
                  symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
                             node:(id<JANode>)node
                            error:(NSError **)error;

+ (instancetype)fontExpression:(NSString *)expression
                     constants:(JASymbolEvaluator)constants
               symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
                          node:(id<JANode>)node
                         error:(NSError **)error;

+ (instancetype)colorExpression:(NSString *)expression
                      constants:(JASymbolEvaluator)constants
                symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
                           node:(id<JANode>)node
                          error:(NSError **)error;

+ (instancetype)stringExpression:(NSString *)expression
                       constants:(JASymbolEvaluator)constants
                 symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
                            node:(id<JANode>)node
                           error:(NSError **)error;

+ (instancetype)percentExpression:(NSString *)expression
                       ofProperty:(NSString *)property
                        constants:(JASymbolEvaluator)constants
                  symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
                             node:(id<JANode>)node
                            error:(NSError **)error;

+ (instancetype)sizeExpression:(NSString *)expression
                    ofProperty:(NSString *)property
                     constants:(JASymbolEvaluator)constants
               symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
                          node:(id<JANode>)node
                         error:(NSError **)error;

+ (instancetype)expression:(NSString *)expression
               runtimeType:(JAObjectType *)runtimeType
                 constants:(JASymbolEvaluator)constants
           symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
                      node:(id<JANode>)node
                     error:(NSError **)error;

+ (instancetype)expression:(NSString *)expression
                 constants:(JASymbolEvaluator)constants
           symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
            stateEvaluator:(id (^)(JASymbol *symbol))stateEvaluator
                      node:(id<JANode>)node
                     error:(NSError **)error;

- (id)evaluate;

@end
