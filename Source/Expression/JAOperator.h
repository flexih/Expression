//
//  JAOperator.h
//  Jarvis
//
//  Created by flexih on 2018/8/1.
//  Copyright © 2018 paopao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JAOperator : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic) int order;
@property (nonatomic) int operands;
@property (readonly) id (^evaluate)(NSArray<id> *args);

- (instancetype)initWithOperator:(NSString *)operate order:(int)order operands:(int)operands;

@end

NSDictionary *JAOperators(void);

NS_ASSUME_NONNULL_END
