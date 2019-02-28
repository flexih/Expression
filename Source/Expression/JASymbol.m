//
//  JASymbol.m
//  Jarvis
//
//  Created by flexih on 2018/8/1.
//  Copyright © 2018 paopao. All rights reserved.
//

#import "JASymbol.h"
#import "JADefines.h"
#import "JAOperator.h"
#import <UIKit/UIKit.h>

static
NSDictionary *formatParams(NSArray<id> *args) {
    NSCAssert(args.count > 0, @"%ld != paramters count of at()", (long)args.count);
    if (args.count == 0) return nil;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:args.count / 2];
    for (size_t i = 0; i < args.count; i += 2) {
        id<NSCopying> key = ASP(NSCopying, args[i]);
        if (!key) continue;
        if (i + 1 >= args.count) break;
        id value = args[i + 1];
        params[key] = value;
    }
    return params.count > 0 ? params : nil;
}

static
JAEvaluator JADefaultFunctions(NSString *symbol) {
    static NSDictionary<NSString *, JAEvaluator> *functions;
    if (!functions) {
        functions = @{
                      @"min": ^id(NSArray<id> *args) {
                          NSCAssert(args.count == 2, @"%ld != paramters count of min()", (long)args.count);
                          if (args.count != 2) return nil;
                          id lhs = args[0];
                          id rhs = args[1];
                          if ([lhs isEqual:[NSNull null]]) lhs = @0;
                          if ([rhs isEqual:[NSNull null]]) rhs = @0;
                          if (!IS(NSNumber, lhs)) return nil;
                          if (!IS(NSNumber, rhs)) return nil;
                          return @(MIN([lhs doubleValue], [rhs doubleValue]));
                      },
                      @"max": ^id(NSArray<id> *args) {
                          NSCAssert(args.count == 2, @"%ld != paramters count of max()", (long)args.count);
                          if (args.count != 2) return nil;
                          id lhs = args[0];
                          id rhs = args[1];
                          if ([lhs isEqual:[NSNull null]]) lhs = @0;
                          if ([rhs isEqual:[NSNull null]]) rhs = @0;
                          if (!IS(NSNumber, lhs)) return nil;
                          if (!IS(NSNumber, rhs)) return nil;
                          return @(MAX([lhs doubleValue], [rhs doubleValue]));
                      },
                      @"split": ^id(NSArray<id> *args) {
                          NSCAssert(args.count == 3, @"%ld != paramters count of split()", (long)args.count);
                          if (args.count != 3) return nil;
                          let lhs = AS(NSString, args[0]);
                          let rhs = AS(NSString, args[1]);
                          let index = AS(NSNumber, args[2]);
                          if (!lhs || !rhs || index == nil) return nil;
                          let components = [lhs componentsSeparatedByString:rhs];
                          let i = index.unsignedIntegerValue;
                          if (i >= components.count) return nil;
                          return components[i];
                      },
                      @"len":^id(NSArray<id> *args) {
                          NSCAssert(args.count == 1, @"%ld != paramters count of count()", (long)args.count);
                          if (args.count != 1) return nil;
                          id lhs = args[0];
                          if (IS(NSArray, lhs)) {
                              return @([(NSArray *)lhs count]);
                          }
                          if (IS(NSString, lhs)) {
                              return @([(NSString *)lhs length]);
                          }
                          if (IS(NSDictionary, lhs)) {
                              return @([(NSDictionary *)lhs count]);
                          }
                          return nil;
                      },
                      @"ele":^id(NSArray<id> *args) {
                          NSCAssert(args.count == 2, @"%ld != paramters count of ele()", (long)args.count);
                          if (args.count != 2) return nil;
                          NSArray *lhs = AS(NSArray, args[0]);
                          NSNumber *rhs = ASNumber(args[1]);
                          if (lhs == nil  || rhs == nil) return nil;
                          NSUInteger index = rhs.integerValue;
                          if (index >= lhs.count) return nil;
                          return lhs[index];
                      },
                      @"get":^id(NSArray<id> *args) {
                          NSCAssert(args.count == 2, @"%ld != paramters count of get()", (long)args.count);
                          if (args.count != 2) return nil;
                          id lhs = args[0];
                          id rhs = args[1];
                          return [lhs objectForKey:rhs];
                      },
                      @"dict":^id(NSArray<id> *args) {
                          NSCAssert(args.count > 0, @"%ld != paramters count of dict()", (long)args.count);
                          return formatParams(args);
                      },
                      @"array":^id(NSArray<id> *args) {
                          NSCAssert(args.count > 0, @"%ld != paramters count of array()", (long)args.count);
                          if (args.count == 0) return nil;
                          NSMutableArray *array = [NSMutableArray arrayWithCapacity:args.count];
                          for (size_t i = 0; i < args.count; ++i) {
                              id e = args[i];
                              if (e && e != [NSNull null]) {
                                  [array addObject:e];
                              }
                          }
                          return array.count?array.copy:nil;
                      },
                      @"round":^id(NSArray<id> *args) {
                          NSCAssert(args.count == 1, @"%ld != paramters count of at()", (long)args.count);
                          if (args.count != 1) return nil;
                          let lhs = ASNumber(args.firstObject);
                          return [NSNumber numberWithInteger:round([lhs doubleValue])];
                      },
                      @"ceil":^id(NSArray<id> *args) {
                          NSCAssert(args.count == 1, @"%ld != paramters count of at()", (long)args.count);
                          if (args.count != 1) return nil;
                          let lhs = ASNumber(args.firstObject);
                          return [NSNumber numberWithDouble:ceil([lhs doubleValue])];
                      },
                      @"floor":^id(NSArray<id> *args) {
                          NSCAssert(args.count == 1, @"%ld != paramters count of at()", (long)args.count);
                          if (args.count != 1) return nil;
                          let lhs = ASNumber(args.firstObject);
                          if (lhs == nil) return nil;
                          return [NSNumber numberWithDouble:floor([lhs doubleValue])];
                      },
                      @"decimal":^id(NSArray<id> *args) {
                          NSCAssert(args.count == 2, @"%ld != paramters count of at()", (long)args.count);
                          if (args.count != 2) return nil;
                          let lhs = ASNumber(args[0]);
                          let decimal = ASNumber(args[1]);
                          if (lhs == nil || decimal == nil) return nil;
                          let format = [NSString stringWithFormat:@"%%.%ldlf", decimal.longValue];
                          let result = [NSString stringWithFormat:format, lhs.doubleValue];
                          return result;
                      },
                      @"joined":^id(NSArray<id> *args) {
                          NSCAssert(args.count == 2, @"%ld != paramters count of at()", (long)args.count);
                          if (args.count != 2) return nil;
                          let seperator = ASString(args[1]);
                          let lhs = AS(NSArray, args[0]);
                          if (lhs == nil || seperator == nil) return nil;
                          NSMutableArray<NSString *> *components = [NSMutableArray arrayWithCapacity:lhs.count];
                          for (size_t i = 0; i < lhs.count; ++i) {
                              let string = ASString(lhs[i]);
                              if (string.length) {
                                  [components addObject:string];
                              }
                          }
                          if (components.count == 0) return @"";
                          return [components componentsJoinedByString:seperator];
                      },
                      @"onePixel":^id(NSArray<id> *args) {
                          return @(1/UIScreen.mainScreen.scale);
                      },
                      @"isiOS":^id(NSArray<id> *args) {
                          return @YES;
                      },
                      @"isAndroid":^id(NSArray<id> *args) {
                          return @NO;
                      },
                      @"truncate":^id(NSArray<id> *args) {
                          NSCAssert(args.count == 3, @"%ld != paramters count of at()", (long)args.count);
                          if (args.count != 3) return nil;
                          let string = AS(NSString, args[0]);
                          let count = ASNumber(args[1]).integerValue;
                          let trunc = AS(NSString, args[2]) ?: @"";
                          if (string.length > count) {
                              return [[string substringToIndex:count] stringByAppendingString:trunc];
                          }
                          return string;
                      },
                    };
    }
    return functions[symbol];
}

@interface JASymbol ()
//@property (nonatomic, strong) id evaluatedValue;
#if DEBUG
@property (nonatomic, copy) NSString *expression;
#endif
@end

@implementation JASymbol

static
NSNumber *parseRealNumber(NSString *expression) {
    int dot = -1;
    long fraction = 0;
    long integer = 0;
    for (int i = 0; i < expression.length; ++i) {
        unichar ch = [expression characterAtIndex:i];
        if (ch >= '0' && ch <= '9') {
            if (dot >= 0) {
                fraction = fraction * 10 + ch - '0';
            } else {
                integer = integer * 10 + ch - '0';
            }
        } else if (ch == '.') {
            if (dot >= 0) return nil;
            dot = i;
        } else {
            return nil;
        }
    }
    if (dot >= 0) {
        return @(integer + fraction / pow(10, expression.length - dot - 1));
    } else {
        return @(integer);
    }
}

static
NSNumber *parseHex(NSString *expression) {
    if (expression.length < 2) return nil;
    if ([expression characterAtIndex:0] == '0' &&
        ([expression characterAtIndex:1] == 'x' || [expression characterAtIndex:1] == 'X')) {
        return JAParseHexTail(expression, 2);
    }
    return nil;
}

NSNumber *JAParseHexTail(NSString *expression, size_t from) {
    long num = 0;
    for (size_t i = from; i < expression.length; ++i) {
        unichar ch = [expression characterAtIndex:i];
        if (ch >= '0' && ch <= '9') {
            num = num * 16 + (ch - '0');
        } else if (ch >= 'a' && ch <= 'f') {
            num = num * 16 + (ch - 'a') + 10;
        } else if (ch >= 'A' && ch <= 'F') {
            num = num * 16 + (ch - 'A') + 10;
        } else {
            return nil;
        }
    }
    return @(num);
}

static
NSString *parseLiteral(NSString *expression) { // literal, {}, #id, .
    if (expression.length > 2 &&
        [expression characterAtIndex:0] == '{' &&
        [expression characterAtIndex:expression.length - 1] == '}') {
        return [expression substringWithRange:NSMakeRange(1, expression.length - 2)];
    }
    return expression;
}

NSNumber *JAPasrseNumber(NSString *expression) {
    NSNumber *num = parseRealNumber(expression) ?: parseHex(expression);
    if (num != nil) return num;
    //true, false
    if ([expression isEqualToString:@"true"]) return @YES;
    if ([expression isEqualToString:@"false"]) return @NO;
    return nil;
}

NSString *JAParseString(NSString *expression) { // 'string'
    if (expression.length < 2) return nil;
    if ([expression characterAtIndex:0] == '\'' &&
        [expression characterAtIndex:expression.length - 1] == '\'') {
        return [expression substringWithRange:NSMakeRange(1, expression.length - 2)];
    }
    return nil;
}

+ (instancetype)symbolWithExpression:(NSString *)expression {
    return [[self alloc] initWithExpression:expression];
}

- (instancetype)initWithExpression:(NSString *)expression {
    self = [super init];
    if (self) {
#if DEBUG
        _expression = expression;
#endif
        id value = JAPasrseNumber(expression) ?: JAParseString(expression);
        if (value) {
            _type = JASymbolTypeConstant;
        } else {
            value = parseLiteral(expression);
            if (value) {
                _type = JASymbolTypeLiteral;
            }
        }
        _value = value;
    }
    return self;
}

- (id)evaluate {
    ///TODO:how to save computed result, when to clean up
//    if (self.evaluatedValue) return self.evaluatedValue;
    
    if (self.type == JASymbolTypeConstant) {
        return self.value;
    }
    
    if (self.type == JASymbolTypeLiteral) {
        if (self.evaluator) {
            let evaluator = self.evaluator(self);
            if (evaluator) {
                return evaluator(nil);
            }
        }
        return nil;
    }
    
    NSMutableArray *args = [NSMutableArray arrayWithCapacity:self.args.count];
    
    for (JASymbol *symbol in self.args) {
        id evaluated = [symbol evaluate];
        [args addObject:evaluated ?: [NSNull null]];
    }
    
    if (self.type == JASymbolTypeOperator) {
        JAAssert(args.count == self.operator.operands, @"argc not match");
        if (args.count == self.operator.operands) {
            var evaluator = self.operator.evaluate;
            if (!evaluator) {
                evaluator = self.evaluator(self);
            }
            return evaluator(args);
        }
    } else if (self.type == JASymbolTypeFunction) {
        if (self.evaluator) {
            let evaluator = JADefaultFunctions((NSString *)self.value) ?: self.evaluator(self);
            if (evaluator) {
                return evaluator(args);
            }
        }
    }
    
    return nil;
}

- (BOOL)isEqual:(id)object {
    if (!object) return false;
    let obj = AS(JASymbol, object);
    if (!obj) return false;
    return self.type == obj.type && [self.value isEqual:obj.value];
}

- (NSUInteger)hash {
    return self.value.hash;
}

#if DEBUG
- (NSString *)description {
    NSMutableString *desc = [NSMutableString string];
    if (self.type == JASymbolTypeFunction || self.type == JASymbolTypeOperator) {
        if (self.type == JASymbolTypeFunction) {
            [desc appendString:self.value.description];
        }
        if (self.args.count > 1) {
            [desc appendString:@"("];
        }
        [self.args enumerateObjectsUsingBlock:^(JASymbol * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [desc appendFormat:@"%@", obj.description];
            if (idx + 1 < self.args.count) {
                if (self.type == JASymbolTypeOperator) {
                    [desc appendString:self.operator.name];
                } else {
                    [desc appendString:@", "];
                }
            }
        }];
        if (self.args.count > 1) {
            [desc appendString:@")"];
        }
    } else {
        [desc appendString:self.value.description];
    }
    return desc.copy;
}
#endif

@end


