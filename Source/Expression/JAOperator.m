//
//  JAOperator.m
//  Jarvis
//
//  Created by flexih on 2018/8/1.
//  Copyright © 2018 paopao. All rights reserved.
//

#import "JAOperator.h"
#import "JADefines.h"

@interface JAOperator ()<NSCopying>
@property (nonatomic, copy) id (^evaluate)(NSArray<id> *args);
@end

@implementation JAOperator

- (instancetype)initWithOperator:(NSString *)operate order:(int)order operands:(int)operands {
    self = [super init];
    if (self) {
        _name = operate;
        _order = order;
        _operands = operands;
    }
    return self;
}

- (instancetype)initWithOperator:(NSString *)operate order:(int)order operands:(int)operands evaluate:(id (^)(NSArray<id> *args))evaluate {
    self = [self initWithOperator:operate order:order operands:operands];
    self.evaluate = evaluate;
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return [[JAOperator alloc] initWithOperator:self.name order:self.order operands:self.operands];
}

- (NSUInteger)hash {
    return self.order;
}

- (BOOL)isEqual:(id)object {
    if (!object) return false;
    let obj = AS(JAOperator, object);
    if (!obj) return false;
    return self.order == obj.order
        && self.operands == obj.operands
        && (self.name == obj.name || [self.name isEqualToString:obj.name]);
}

#if DEBUG
- (NSString *)description {
    return self.name;
}
#endif

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmultichar"
static
NSNumber *mathFun(NSArray<id> *args, int sym) {
    id lhs = ASNumber(args[0]);
    id rhs = ASNumber(args[1]);
    if ([lhs isEqual:[NSNull null]]) lhs = @0;
    if ([rhs isEqual:[NSNull null]]) rhs = @0;
    if (!IS(NSNumber, lhs)) return nil;
    if (!IS(NSNumber, rhs)) return nil;
    double l = [(NSNumber *)lhs doubleValue], r = [(NSNumber *)rhs doubleValue];
    switch (sym) {
        case '<':
            return [NSNumber numberWithBool:l < r];
        case '<=':
            return [NSNumber numberWithBool:l <= r];
        case '>':
            return [NSNumber numberWithBool:l > r];
        case '>=':
            return [NSNumber numberWithBool:l >= r];
        case '==':
            return [NSNumber numberWithBool:fabs(l - r) < FLT_EPSILON];
        case '!=':
            return [NSNumber numberWithBool:fabs(l - r) > FLT_EPSILON];
        case '+':
            return @(l + r);
        case '-':
            return @(l - r);
        case '*':
            return @(l * r);
        case '/':
            if (r == 0) return nil;
            return @(l / r);
        case '%':
            if (r == 0) return nil;
            return @((long)l % (long)r);
        default:
            break;
    }
    return nil;
}
#pragma clang diagnostic pop

static 
let plus = ^id(NSArray<id> *args) {
    id lhs = args[0];
    id rhs = args[1];
    if (IS(NSString, lhs) || IS(NSString, rhs)) {
        return [Stringfy(lhs) stringByAppendingString:Stringfy(rhs)];
    }
    return mathFun(args, '+');
};

static 
let minus = ^id(NSArray<id> *args) {
    return mathFun(args, '-');
};

static 
let multiply = ^id(NSArray<id> *args) {
    return mathFun(args, '*');
};

static 
let divide = ^id(NSArray<id> *args) {
    return mathFun(args, '/');
};

static 
let lessThan = ^id(NSArray<id> *args) {
    return mathFun(args, '<');
};

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmultichar"
static 
let lessThanEqual = ^id(NSArray<id> *args) {
    return mathFun(args, '<=');
};

static 
let greaterThan = ^id(NSArray<id> *args) {
    return mathFun(args, '>');
};

static 
let greaterThanEqual = ^id(NSArray<id> *args) {
    return mathFun(args, '>=');
};

static 
let equal = ^id(NSArray<id> *args) {
    id lhs = args[0];
    id rhs = args[1];
    if (![lhs isMemberOfClass:[rhs class]]) {
        let ln = ASNumber(lhs);
        let rn = ASNumber(rhs);
        if (ln && rn) {
            return [NSNumber numberWithBool:[ln isEqualToNumber:rn]];
            //return [NSNumber numberWithBool:fabs(ln.doubleValue - rn.doubleValue) < FLT_EPSILON];
        }
    }
    return @([lhs isEqual:rhs]);
};

static 
let notEqual = ^id(NSArray<id> *args) {
//    id lhs = args[0];
//    id rhs = args[1];
//    if (![lhs isMemberOfClass:[rhs class]]) {
//        let ln = ASNumber(lhs);
//        let rn = ASNumber(rhs);
//        if (ln && rn) {
//            return [NSNumber numberWithBool:![ln isEqualToNumber:rn]];
//            //return [NSNumber numberWithBool:fabs(ln.doubleValue - rn.doubleValue) > FLT_EPSILON];
//        }
//    }
//    return @(![lhs isEqual:rhs]);
    return [NSNumber numberWithBool:![(NSNumber *)equal(args) boolValue]];
};
#pragma clang diagnostic pop

static 
let condition = ^id(NSArray<id> *args) {
    if (IS(NSNumber, args[0])) return [args[0] boolValue] ? args[1] : args[2];
    if (IS(NSString, args[0]) && [args[0] isEqualToString:@"0"]) return args[2];
    if (args[0] && args[0] != [NSNull null]) return args[1];
    return args[2];
};

static 
let mod = ^id(NSArray<id> *args) {
    return mathFun(args, '%');
};

static
let not = ^id(NSArray<id> *args) {
    return [NSNumber numberWithBool:![ASNumber(args[0]) boolValue]];
};

static
let logicNot = ^id(NSArray<id> *args) {
    return [NSNumber numberWithInteger:~[ASNumber(args[0]) integerValue]];
};

static
let and = ^id(NSArray<id> *args) {
    return [NSNumber numberWithBool:[ASNumber(args[0]) boolValue] && [ASNumber(args[1]) boolValue]];
};

static
let or = ^id(NSArray<id> *args) {
    return [NSNumber numberWithBool:[ASNumber(args[0]) boolValue] || [ASNumber(args[1]) boolValue]];
};

static
let logicAnd = ^id(NSArray<id> *args) {
    return [NSNumber numberWithInteger:[ASNumber(args[0]) integerValue] & [ASNumber(args[1]) integerValue]];
};

static
let logicOr = ^id(NSArray<id> *args) {
    return [NSNumber numberWithInteger:[ASNumber(args[0]) integerValue] | [ASNumber(args[1]) integerValue]];
};

NSDictionary *JAOperators(void) {
    static NSDictionary *allOperators;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allOperators = @{@"!": [[JAOperator alloc] initWithOperator:@"!" order:2 operands:1 evaluate:not],
                         @"~": [[JAOperator alloc] initWithOperator:@"~" order:2 operands:1 evaluate:logicNot],
                         @"+": [[JAOperator alloc] initWithOperator:@"+" order:4 operands:2 evaluate:plus],
                         @"-": [[JAOperator alloc] initWithOperator:@"-" order:4 operands:2 evaluate:minus],
                         @"*": [[JAOperator alloc] initWithOperator:@"*" order:3 operands:2 evaluate:multiply],
                         @"/": [[JAOperator alloc] initWithOperator:@"/" order:3 operands:2 evaluate:divide],
                         @"%": [[JAOperator alloc] initWithOperator:@"%" order:3 operands:2 evaluate:mod],
                         @"<": [[JAOperator alloc] initWithOperator:@"<" order:6 operands:2 evaluate:lessThan],
                         @"<=": [[JAOperator alloc] initWithOperator:@"<=" order:6 operands:2 evaluate:lessThanEqual],
                         @">": [[JAOperator alloc] initWithOperator:@">" order:6 operands:2 evaluate:greaterThan],
                         @">=": [[JAOperator alloc] initWithOperator:@">=" order:6 operands:2 evaluate:greaterThanEqual],
                         @"!=": [[JAOperator alloc] initWithOperator:@"!=" order:7 operands:2 evaluate:notEqual],
                         @"==": [[JAOperator alloc] initWithOperator:@"==" order:7 operands:2 evaluate:equal],
                         @"&&": [[JAOperator alloc] initWithOperator:@"&&" order:11 operands:2 evaluate:and],
                         @"||": [[JAOperator alloc] initWithOperator:@"||" order:12 operands:2 evaluate:or],
                         @"&": [[JAOperator alloc] initWithOperator:@"&" order:8 operands:2 evaluate:logicAnd],
                         @"|": [[JAOperator alloc] initWithOperator:@"|" order:10 operands:2 evaluate:logicOr],
                         @"?:": [[JAOperator alloc] initWithOperator:@"?:" order:13 operands:3 evaluate:condition],
                         //for postfix expression
                         @"(": [[JAOperator alloc] initWithOperator:@"(" order:16 operands:0],
                         @"?": [[JAOperator alloc] initWithOperator:@"?" order:13 operands:3],
                         };
    });
    return allOperators;
}
