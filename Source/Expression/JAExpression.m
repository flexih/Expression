//
//  JAExpression.m
//  Jarvis
//
//  Created by flexih on 2018/7/25.
//  Copyright © 2018 paopao. All rights reserved.
//

#import "JAExpression.h"
#import "JADefines.h"
#import "JAObjectType.h"
#import "JAOperator.h"
#import "JANode.h"
#import "JAObjectType.h"
#import <UIKit/UIKit.h>

@interface JAExpression ()
///TODO:affected literals
@property (nonatomic, strong) JASymbol *root;
@property (nonatomic, copy) NSArray<NSString *> *symbolNames;
@property (nonatomic, copy) id (^evaluator)(void);
@property (nonatomic) BOOL isConstant;

@end

@implementation JAExpression

static
NSCharacterSet *skipCharacterSet() {
    static NSCharacterSet *skipCharacterSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        skipCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    });
    return skipCharacterSet;
}

+ (NSArray *)postfixExpression:(NSString *)expression symbolEvaluator:(JASymbolEvaluator)symbolEvaluator {
    static NSCharacterSet *operatorCharacterSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        operatorCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"()+-*/%?:<>=!&|~"];
    });
    
    BOOL toClose = 0; //seperate differents
    BOOL inQuote = 0;
    size_t i = 0, beg = 0, end = 0;
    
    NSMutableArray<JAOperator *> *operatorStack = [NSMutableArray array];
    let resultList = [NSMutableArray array];
    
    for (; i < expression.length; ++i) {
        unichar ch = [expression characterAtIndex:i];
        if (ch == '\'') inQuote = !inQuote;
        if (!inQuote && [operatorCharacterSet characterIsMember:ch]) {
            if (!toClose) {
                toClose = 1;
                end = i;
            }
            if (toClose) {
                if (end > beg) {
                    let symbol = [JASymbol symbolWithExpression:[expression substringWithRange:NSMakeRange(beg, end - beg)]];
                    [resultList addObject:symbol];
                    end = beg = i + 1;
                }
            }
            if (ch == '(') {
                unichar prev;
                if (i > 1) {
                    prev = [expression characterAtIndex:i - 1];
                    if (![operatorCharacterSet characterIsMember:prev]) { //fun(x,y)
                        JASymbol *symbol = resultList.lastObject;
                        symbol.type = JASymbolTypeFunction;
                        BOOL quoted = false;
                        size_t b = i;
                        size_t j;
                        size_t bracketed = 1;
                        NSMutableArray<JASymbol *> *args;
                        for (j = i + 1; j < expression.length; ++j) {
                            unichar next = [expression characterAtIndex:j];
                            if (next == ',' && !quoted && bracketed == 1) {
                                NSString *argument = [expression substringWithRange:NSMakeRange(b + 1, j - b - 1)];
                                if (argument.length > 0) {
                                    if (!args) {
                                        args = [NSMutableArray array];
                                    }
                                    [args addObject:[self parseExpression:argument symbolEvaluator:symbolEvaluator]];
                                }
                                b = j;
                            } else if (next == '\'') {
                                quoted = !quoted;
                            } else if (next == '(') {
                                bracketed++;
                            } else if (next == ')') {
                                if (--bracketed == 0) {
                                    NSString *argument = [expression substringWithRange:NSMakeRange(b + 1, j - b - 1)];
                                    if (argument.length > 0) {
                                        if (!args) {
                                            args = [NSMutableArray array];
                                        }
                                        [args addObject:[self parseExpression:argument symbolEvaluator:symbolEvaluator]];
                                    }
                                    break;
                                }
                            }
                        }
                        if (args.count > 0) {
                            symbol.args = args;
                        }
                        i = j;
                        continue;
                    }
                }
                [operatorStack addObject:JAOperators()[@"("]];
                continue;
            } else if (ch == ')') {
                do {
                    let top = operatorStack.lastObject;
                    JALog(top != nil, @"miss (");
                    if (top == nil) return nil;
                    if ([top.name isEqualToString:@"("]) {
                        [operatorStack removeLastObject];
                        break;
                    }
                    [resultList addObject:top];
                    [operatorStack removeLastObject];
                } while(1);
                continue;
            }
            
            unichar next;
            size_t len = 1;
            if (i + 1 < expression.length) {
                next = [expression characterAtIndex:i + 1];
                if (next == '=') {
                    if (ch == '<' || ch == '>' || ch == '!' || ch == '=') {
                        len = 2;
                    }
                } else if ((ch == '|' || ch == '&') && ch == next) {
                    len = 2;
                }
            }
            JAOperator *o;
            if (ch == '?') {
                o = JAOperators()[@"?"];
            } else if (ch == ':') {
                do {
                    let top = operatorStack.lastObject;
                    JALog(top != nil, @"miss ?");
                    if (top == nil) return nil;
                    if ([top.name isEqualToString:@"?"]) {
                        [operatorStack replaceObjectAtIndex:operatorStack.count - 1 withObject:JAOperators()[@"?:"]];
                        break;
                    }
                    [resultList addObject:top];
                    [operatorStack removeLastObject];
                } while(1);
                continue;
            } else {
                NSString *operator = [expression substringWithRange:NSMakeRange(i, len)];
                o = JAOperators()[operator];
                if (ch == '%') {
                    JALog(i > 0, @"%% cannot be first");
                    //100% - width
                    //100%
                    //100%3+4
                    //100%var
                    //100%(xxx)
                    //(20-100%)/2
                    BOOL postfixPercent = false;
                    size_t j = i + 1;
                    for (; j < expression.length; ++j) {
                        unichar next = [expression characterAtIndex:j];
                        if ([skipCharacterSet() characterIsMember:next]) continue;
                        postfixPercent = [operatorCharacterSet characterIsMember:next];
                        break;
                    }
                    if (j == expression.length) postfixPercent = true;
                    if (postfixPercent) {
                        o = o.copy;
                        o.operands = 1;
                        o.order = 0;
                    }
                }
            }
            JALog(o != nil, @"Not Support operator:%c", (char)ch);
            if (o) {
                do {
                    let top = operatorStack.lastObject;
                    if (!top) {
                        [operatorStack addObject:o];
                        break;
                    }
                    if (o.order < top.order) {
                        [operatorStack addObject:o];
                        break;
                    } else {
                        [resultList addObject:operatorStack.lastObject];
                        [operatorStack removeLastObject];
                    }
                } while (1);
            }
            i += len - 1;
        } else if (!inQuote && [skipCharacterSet() characterIsMember:ch]) {
            if (toClose) {
                beg = i;
                continue;
            } else {
                toClose = 1;
                end = i;
            }
            if (toClose) {
                if (end > beg) {
                    let symbol = [JASymbol symbolWithExpression:[expression substringWithRange:NSMakeRange(beg, end - beg)]];
                    [resultList addObject:symbol];
                    end = beg = i + 1;
                }
            }
        } else {
            if (toClose) {
                beg = i;
            }
            toClose = 0;
        }
    }
    
    if (!toClose) {
        end = i;
        if (end > beg) {
            let symbol = [JASymbol symbolWithExpression:[expression substringWithRange:NSMakeRange(beg, end - beg)]];
            [resultList addObject:symbol];
        }
    }
    
    do {
        let o = operatorStack.lastObject;
        if (!o) break;
        [resultList addObject:o];
        [operatorStack removeLastObject];
    } while (operatorStack.lastObject);
    
    return resultList;
}

+ (JASymbol *)parseExpression:(NSString *)expression symbolEvaluator:(JASymbolEvaluator)symbolEvaluator {
    let resultList = [self postfixExpression:expression symbolEvaluator:symbolEvaluator];
    let parsedResult = [NSMutableArray array];
    
    for (size_t i = 0; i < resultList.count; ++i) {
        id element = resultList[i];
        if (IS(JAOperator, element)) {
            JAOperator *operator = (JAOperator *)element;
            JASymbol *symbol = [[JASymbol alloc] init];
            symbol.operator = operator;
            symbol.type = JASymbolTypeOperator;
            symbol.evaluator = symbolEvaluator;
            NSMutableArray<JASymbol *> *args = [NSMutableArray array];
            JALog(operator.operands <= parsedResult.count, @"miss match argc %@", expression);
            if (operator.operands > parsedResult.count) return nil;
            size_t j;
            for (j = parsedResult.count - operator.operands; j < parsedResult.count; ++j) {
                [args addObject:parsedResult[j]];
            }
            symbol.args = args;
            [parsedResult removeObjectsInRange:NSMakeRange(j - operator.operands, operator.operands)];
            [parsedResult addObject:symbol];
        } else {
            AS(JASymbol, element).evaluator = symbolEvaluator;
            [parsedResult addObject:element];
        }
    }
    //parsedResult might have more than one element when some not-support cases  occur
    return parsedResult.firstObject;
}

+ (instancetype)evaluteExpression:(id (^)(void))evaluator
                        constants:(JASymbolEvaluator)constants
                  symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
                             node:(id<JANode>)node
                            error:(NSError **)error {
    JAExpression *one = [[self alloc] initWithEvaluator:evaluator];
    return one;
}

static
void JAExpressionSymbolNames(JASymbol *symbol, NSMutableSet<NSString *> *symbolNames, JASymbolEvaluator constants, BOOL *isConstant) {
    switch ((NSInteger)symbol.type) {
        case JASymbolTypeLiteral:
            JALog(IS(NSString, symbol.value), @"must be string");
            if (constants && !constants(symbol)) {
                *isConstant = false;
            }
            [symbolNames addObject:(NSString *)symbol.value];
            break;
        case JASymbolTypeFunction:
        case JASymbolTypeOperator:
            for (JASymbol *sub in symbol.args) JAExpressionSymbolNames(sub, symbolNames, constants, isConstant);
            break;
        default:
            break;
    }
}

- (instancetype)initWithRoot:(JASymbol *)root isConstant:(BOOL)isConstant symbolNames:(NSArray<NSString *> *)symbolNames {
    self = [super init];
    if (self) {
        _root = root;
        _isConstant = isConstant;
        _symbolNames = symbolNames;
    }
    return self;
}

- (instancetype)initWithEvaluator:(id (^)(void))evaluator {
    self = [super init];
    if (self) {
        _evaluator = evaluator;
    }
    return self;
}

+ (instancetype)expression:(NSString *)expression
                 constants:(JASymbolEvaluator)constants
           symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
                      node:(id<JANode>)node
                     error:(NSError **)error {
    JAExpression *expr;
    expr = [self ifExpression:expression constants:constants symbolEvaluator:symbolEvaluator node:node error:error];
    if (expr != nil) return expr;
    expr = [self switchExpression:expression constants:constants symbolEvaluator:symbolEvaluator node:node error:error];
    if (expr != nil) return expr;
    let symbol = [self parseExpression:expression symbolEvaluator:^JAEvaluator(JASymbol * _Nonnull symbol) {
        id value = constants?constants(symbol):NULL;
        if (value) {
            return constants(symbol);
        }
        if (symbolEvaluator) {
            let evaluator = symbolEvaluator(symbol);
            if (evaluator) {
                return evaluator;
            }
        }
        return nil;
    }];
    if (!symbol) return nil;
    
    BOOL isConstant = true;
    NSMutableSet<NSString *> *symbolNames = [NSMutableSet set];
    JAExpressionSymbolNames(symbol, symbolNames, constants, &isConstant);
    
    expr = [[JAExpression alloc] initWithRoot:symbol isConstant:isConstant symbolNames:symbolNames.count > 0 ? symbolNames.allObjects : nil];
    return expr;
}

static
UIFont *JAFont(NSString *fontName, CGFloat fontSize, NSString *fontTrait) {
    if (fontSize == 0) fontSize = UIFont.systemFontSize;
    UIFontDescriptorSymbolicTraits trait = 0;
    if ([fontTrait isEqualToString:@"bold"]) {
        trait = UIFontDescriptorTraitBold;
    } else if ([fontTrait isEqualToString:@"italic"]) {
        trait = UIFontDescriptorTraitItalic;
    }
    if (fontName == nil) fontName = @"system";
    if ([fontName isEqualToString:@"system"] || [fontName isEqualToString:@"System"]) {
        if (trait == UIFontDescriptorTraitBold) {
            return [UIFont boldSystemFontOfSize:fontSize];
        }
        if (trait == UIFontDescriptorTraitItalic) {
            return [UIFont italicSystemFontOfSize:fontSize];
        }
        return [UIFont systemFontOfSize:fontSize];
    }
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor fontDescriptorWithFontAttributes:@{UIFontDescriptorFamilyAttribute: fontName,
                                                                                            UIFontDescriptorSizeAttribute: @(fontSize),
                                                                                            UIFontDescriptorTraitsAttribute: @{UIFontSymbolicTrait: @(trait)}
                                                                                            }];
    JALog(fontDescriptor != nil, @"font descriptior invalid %@", fontName);
    return [UIFont fontWithDescriptor:fontDescriptor size:0];
}

//(Helvetica|System) 30 (italic | bold | regular)
+ (instancetype)fontExpression:(NSString *)expression
                     constants:(JASymbolEvaluator)constants
               symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
                          node:(id<JANode>)node
                         error:(NSError **)error {
    JAExpression *aExpression = [self stringExpression:expression constants:constants symbolEvaluator:symbolEvaluator node:node error:error];
    JAExpression *compoundExpression = [self evaluteExpression:^id {
        let text = AS(NSString, [aExpression evaluate]);
        NSString *fontName;
        NSString *fontTrait;
        CGFloat fontSize = 0;
        NSArray<NSString *> *components = [text componentsSeparatedByString:@" "];
        if (components.count == 3) {
            fontName = components[0];
            fontSize = [components[1] doubleValue];
            fontTrait = components[2];
            JALog(fontSize > 0, @"font size invalid %@", text);
        }
        if (components.count == 2) { //30 trait, System 30
            if ((fontSize = [components[0] doubleValue]) > 0) {
                fontName = @"system";
                fontTrait = components[1];
            } else if ((fontSize = [components[1] doubleValue]) > 0) {
                fontName = components[0];
            } else {
                JALog(0, @"font format invalid %@", text);
            }
        }
        if (components.count == 1) { //30
            fontName = @"system";
            fontSize = [components[0] doubleValue];
            JALog(fontSize > 0, @"font size invalid %@", text);
        }
        let font = JAFont(fontName, fontSize, fontTrait);
        JALog(font != nil, @"font invalid %@", text);
        return font;
    } constants:constants symbolEvaluator:symbolEvaluator node:node error:error];
    compoundExpression.isConstant = aExpression.isConstant;
    compoundExpression.symbolNames = aExpression.symbolNames;
    return compoundExpression;
}

static
UIColor *JAColorForName(NSString *name) {
    static NSDictionary *colors;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colors = @{@"black": [UIColor blackColor],
                   @"darkGray": [UIColor darkGrayColor],
                   @"lightGray": [UIColor lightGrayColor],
                   @"white": [UIColor whiteColor],
                   @"gray": [UIColor grayColor],
                   @"red": [UIColor redColor],
                   @"green": [UIColor greenColor],
                   @"blue": [UIColor blueColor],
                   @"cyan": [UIColor cyanColor],
                   @"yellow": [UIColor yellowColor],
                   @"magenta": [UIColor magentaColor],
                   @"orange": [UIColor orangeColor],
                   @"purple": [UIColor purpleColor],
                   @"brown": [UIColor brownColor],
                   @"clear": [UIColor clearColor]};
    });
    return colors[name];
}

+ (instancetype)colorExpression:(NSString *)expression
                      constants:(JASymbolEvaluator)constants
                symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
                           node:(id<JANode>)node
                          error:(NSError **)error {
    let rgb = ^id(NSArray<id> *args) {
        JALog(args.count == 3, @"rgb(3) argc not match:%ld", (long)args.count);
        if (args.count == 3) {
            return [UIColor colorWithRed:ASNumber(args[0]).doubleValue/255
                                   green:ASNumber(args[1]).doubleValue/255
                                    blue:ASNumber(args[2]).doubleValue/255 alpha:1];
        }
        return nil;
    };
    
    let rgba = ^id(NSArray<id> *args) {
        JALog(args.count == 4, @"rgb(4) argc not match:%ld", (long)args.count);
        if (args.count == 4) {
            return [UIColor colorWithRed:ASNumber(args[0]).doubleValue/255
                                   green:ASNumber(args[1]).doubleValue/255
                                    blue:ASNumber(args[2]).doubleValue/255
                                   alpha:ASNumber(args[3]).doubleValue];
        }
        return nil;
    };
    
    return [self expression:expression constants:^JAEvaluator(JASymbol *symbol) {
        if (symbol.type == JASymbolTypeFunction) {
            if ([symbol.value isEqual:@"rgb"]) {
                return rgb;
            }
            if ([symbol.value isEqual:@"rgba"]) {
                return rgba;
            }
        }
        
        if (symbol.type == JASymbolTypeLiteral) {
            let value = AS(NSString, symbol.value);
            if ([value characterAtIndex:0] == '#') {
                if (value.length == 4) {
                    int c = JAParseHexTail(value, 1).intValue;
                    int r = c >> 8 & 0xf;
                    int g = c >> 4 & 0xf;
                    int b = c & 0xf;
                    return ^id(NSArray<id> *args) {
                        return rgb(@[@(r * 16 + r), @(g * 16 + g), @(b * 16 + b)]);
                    };
                }
                if (value.length == 7) {
                    int c = JAParseHexTail(value, 1).intValue;
                    return ^id(NSArray<id> *args) {
                        return rgb(@[@(c >> 16 & 0xff), @(c >> 8 & 0xff), @(c & 0xff)]);
                    };
                }
            } else {
                let color = JAColorForName(value);
                if (color) {
                    return ^id(NSArray<id> *args) {
                        return color;
                    };
                }
            }
        }
        
        if (constants) {
            return constants(symbol);
        }
        
        return nil;
    } symbolEvaluator:symbolEvaluator node:node error:error];
}

+ (instancetype)stringExpression:(NSString *)expression
                       constants:(JASymbolEvaluator)constants
                 symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
                            node:(id<JANode>)node
                           error:(NSError **)error {
    size_t i = 0, beg = 0, end = 0;
    bool bracket = false;
    NSMutableArray *parts = [NSMutableArray array];
    
    for (; i < expression.length; ++i) {
        unichar ch = [expression characterAtIndex:i];
        switch (ch) {
            case '{':
                if (bracket) {
                    if (error) *error = [NSError errorWithDomain:@"invalide {" code:0 userInfo:nil];
                    return nil;
                }
                end = i;
                if (end > beg) {
                    let part = [expression substringWithRange:NSMakeRange(beg, end - beg)];
                    [parts addObject:part];
                }
                end = beg = i + 1;
                bracket = true;
                break;
            case '}':
                if (!bracket) {
                    if (error) *error = [NSError errorWithDomain:@"invalide }" code:0 userInfo:nil];
                    return nil;
                }
                end = i;
                if (end > beg) {
                    let part = [expression substringWithRange:NSMakeRange(beg, end - beg)];
                    JAExpression *sube = [self expression:part constants:constants symbolEvaluator:symbolEvaluator node:node error:error];
                    if (error && *error) {
                        return nil;
                    }
                    [parts addObject:sube];
                }
                end = beg = i + 1;
                bracket = false;
                break;
            default:
                break;
        }
    }
    
    if (i > end) {
        end = i;
        if (end > beg) {
            if (bracket) {
                if (error) *error = [NSError errorWithDomain:@"invalide {, expect }" code:0 userInfo:nil];
                return nil;
            }
            let part = [expression substringWithRange:NSMakeRange(beg, end - beg)];
            [parts addObject:part];
        }
    }
    
    JAExpression *aExpression = [self evaluteExpression:^id {
        NSMutableString *result = [NSMutableString string];
        for (int i = 0; i < parts.count; ++i) {
            if (IS(NSString, parts[i])) {
                [result appendString:(NSString *)parts[i]];
            } else {
                let sub = (JAExpression *)parts[i];
                let str = Stringfy([sub evaluate]);
                if (str) {
                    [result appendString:str];
                }
            }
        }
        return result.copy;
    } constants:constants symbolEvaluator:symbolEvaluator node:node error:error];
    
    BOOL isConstant = true;
    NSMutableSet<NSString *> *symbolNames = [NSMutableSet set];
    for (id obj in parts) {
        let sub = AS(JAExpression, obj);
        if (sub) {
            [symbolNames addObjectsFromArray:sub.symbolNames];
            isConstant &= sub.isConstant;
        }
    }
    aExpression.isConstant = isConstant;
    aExpression.symbolNames = symbolNames.allObjects;
    return aExpression;
}

+ (instancetype)percentExpression:(NSString *)expression
                       ofProperty:(NSString *)property
                        constants:(JASymbolEvaluator)constants
                  symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
                             node:(id<JANode>)node
                            error:(NSError **)error {
    let __weak wnode = node;
    return [self expression:expression constants:^JAEvaluator(JASymbol * _Nonnull symbol) {
        if (symbol.type == JASymbolTypeOperator) {
            if ([symbol.operator.name isEqual:@"%"] && symbol.operator.operands == 1) {
                return ^id(NSArray<id> *args) {
                    return @([args[0] doubleValue] * 0.01 * [[wnode valueForSymbol:property] doubleValue]);
                };
            }
        }
        if (constants) {
            return constants(symbol);
        }
        return nil;
    }  symbolEvaluator:symbolEvaluator node:node error:error];
}

+ (instancetype)sizeExpression:(NSString *)expression
                    ofProperty:(NSString *)property
                     constants:(JASymbolEvaluator)constants
               symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
                          node:(id<JANode>)node
                         error:(NSError **)error {
    let __weak wnode = node;
    return [JAExpression percentExpression:expression
                                ofProperty:[@"parent.containerSize." stringByAppendingString:property]
                                 constants:^JAEvaluator(JASymbol *symbol) {
                                     if (symbol.type == JASymbolTypeLiteral && [symbol.value isEqual:@"auto"]) {
                                         return ^id(NSArray<id> *args) {
                                             return [wnode valueForSymbol:[@"autoSize." stringByAppendingString:property]];
                                         };
                                     }
                                     if (constants) {
                                         return constants(symbol);
                                     }
                                     return nil;
                                 }
                           symbolEvaluator:symbolEvaluator node:node error:error];
}

+ (instancetype)imageExpression:(NSString *)expression
                      constants:(JASymbolEvaluator)constants
                symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
                           node:(id<JANode>)node
                          error:(NSError **)error {
    JAExpression *expr = [self expression:expression constants:^JAEvaluator(JASymbol *symbol) {
        if (symbol.type == JASymbolTypeLiteral) {
            let image = [UIImage imageNamed:AS(NSString, symbol.value)];
            if (image) {
                return ^id(NSArray<id> *args) {
                    return image;
                };
            }
        }
        return constants?constants(symbol):nil;
    } symbolEvaluator:symbolEvaluator node:node error:error];
    JAExpression *one = [self evaluteExpression:^id {
        id v = [expr evaluate];
        let imageName = AS(NSString, v);
        if (!imageName) return v;
        let image = [UIImage imageNamed:imageName];
        return image;
    } constants:constants symbolEvaluator:symbolEvaluator node:node error:error];
    one.isConstant = expr.isConstant;
    one.symbolNames = expr.symbolNames;
    return one;
}

+ (instancetype)expression:(NSString *)expression
               runtimeType:(JAObjectType *)runtimeType
                 constants:(JASymbolEvaluator)constants
           symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
                      node:(id<JANode>)node
                     error:(NSError **)error {
    switch (runtimeType.kind) {
        case JAKindString:
        case JAKindURL:
        case JAKindNSTextAlignment:
        case JAKindNSLineBreakMode:
        case JAKindUIViewContentMode:
        case JAKindUIScrollViewContentInsetAdjustmentBehavior:
        case JAKindUIScrollViewIndicatorStyleDefault:
        case JAKindUIScrollViewKeyboardDismissMode:
        case JAKindUITableViewStyle:
        case JAKindUITableViewCellSeparatorStyle:
        case JAKindUITableViewCellSelectionStyle:
        case JAKindUIDatePickerMode:
            return [self stringExpression:expression constants:constants symbolEvaluator:symbolEvaluator node:node error:error];
        case JAKindColor:
        case JAKindColorRef:
            return [self colorExpression:expression constants:constants symbolEvaluator:symbolEvaluator node:node error:error];
        case JAKindFont:
            return [self fontExpression:expression constants:constants symbolEvaluator:symbolEvaluator node:node error:error];
        case JAKindImage:
        case JAKindCGImageRef:
            return [self imageExpression:expression constants:constants symbolEvaluator:symbolEvaluator node:node error:error];
        default:
            break;
    }
    return [self expression:expression constants:constants symbolEvaluator:symbolEvaluator node:node error:error];
}

- (id)evaluate {
    if (self.evaluator) return self.evaluator();
    let symbol = self.root;
    return [symbol evaluate];
}

static
NSString *extractBracket(NSString *string, NSUInteger from, NSUInteger *aEnd) {
    bool expectBracket = true;
    int brackets = 0;
    NSUInteger beg = 0, end = 0;
    NSUInteger i = from;
    for (; i < string.length; i++) {
        unichar ch = [string characterAtIndex:i];
        if (ch == '(') {
            if (brackets == 0) {
                beg = i + 1;
                expectBracket = false;
            }
            brackets += 1;
        } else if (ch == ')') {
            if (brackets == 0) return nil;
            brackets -= 1;
            if (brackets == 0) {
                end = i;
                break;
            }
        } else if (expectBracket) {
            if (![skipCharacterSet() characterIsMember:ch]) break;
        }
    }
    if (expectBracket || brackets != 0) return nil;
    if (end <= beg) return nil;
    if (aEnd) *aEnd = i;
    return [string substringWithRange:NSMakeRange(beg, end - beg)];
}

/*
 case 5:
 expression
 case 'string':
 expression
 default:
 expression
 */
+ (instancetype)switchExpression:(NSString *)expression
                       constants:(JASymbolEvaluator)constants
                 symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
                            node:(id<JANode>)node
                           error:(NSError **)error {
    if (![expression hasPrefix:@"switch"]) return nil;
    NSUInteger i = 6;
    let condition = extractBracket(expression, i, &i);
    if (!condition) return nil;
    JAExpression *conditionExpression = [JAExpression expression:condition
                                                       constants:constants
                                                 symbolEvaluator:symbolEvaluator
                                                            node:node
                                                           error:error];
    JAExpression *defaultExpression;
    NSMutableDictionary<id, JAExpression *> *caseExpressions = [NSMutableDictionary dictionary];
    BOOL toClose = 0, quote = 0, defaultCase = 0, isCase = 0;
    NSUInteger beg = 0, end = 0;
    for (i = i + 1, beg = i; i < expression.length; i++) {
        unichar ch = [expression characterAtIndex:i];
        if ([skipCharacterSet() characterIsMember:ch] || (ch == ':' && !quote)) {
            if (!toClose) {
                toClose = 1;
                end = i;
            }
            NSString *sub;
            if (toClose) {
                if (end <= beg) continue;
                sub = [expression substringWithRange:NSMakeRange(beg, end - beg)];
                end = beg = i + 1;
            }
            if (!isCase) {
                isCase = 1;
                if ([sub isEqualToString:@"default"]) {
                    JALog(!defaultCase, @"more than one default case in %@", expression);
                    defaultCase = 1;
                } else {
                    defaultCase = 0;
                }
            }
            if (ch == ':') {
                //scan to case(default)
                for (beg = ++i; i < expression.length; i++) {
                    unichar last = [expression characterAtIndex:i];
                    if (last == 'e' && i > 4) {
                        if ([expression characterAtIndex:i - 1] == 's' &&
                            [expression characterAtIndex:i - 2] == 'a' &&
                            [expression characterAtIndex:i - 3] == 'c' &&
                            [skipCharacterSet() characterIsMember:[expression characterAtIndex:i - 4]]) {
                            end = i - 3;
                            i = end - 1;
                            break;
                        }
                    } else if (last == 't' && i > 7) {
                        if ([expression characterAtIndex:i - 1] == 'l' &&
                            [expression characterAtIndex:i - 2] == 'u' &&
                            [expression characterAtIndex:i - 3] == 'a' &&
                            [expression characterAtIndex:i - 4] == 'f' &&
                            [expression characterAtIndex:i - 5] == 'e' &&
                            [expression characterAtIndex:i - 6] == 'd' &&
                            [skipCharacterSet() characterIsMember:[expression characterAtIndex:i - 7]]) {
                            end = i - 6;
                            i = end - 1;
                            break;
                        }
                    }
                }
                if (i == expression.length) end = i;
                let caseSub = [expression substringWithRange:NSMakeRange(beg, end - beg)];
                JAExpression *caseExpression = [self expression:caseSub
                                                      constants:constants
                                                symbolEvaluator:symbolEvaluator
                                                           node:node
                                                          error:error];
                if (defaultCase) {
                    defaultExpression = caseExpression;
                } else {
                    id<NSCopying> aCase = JAParseString(sub) ?: JAPasrseNumber(sub);
                    JAAssert(aCase && sub, @"case value is empty in %@", expression);
                    caseExpressions[aCase] = caseExpression;
                }
                beg = end + i;
                isCase = 0;
            }
        } else {
            if (ch == '\'') quote = !quote;
            if (toClose) beg = i;
            toClose = 0;
        }
    }
    JAExpression *switchExpression = [self evaluteExpression:^id {
        id condition = [conditionExpression evaluate];
        id caseExpression = caseExpressions[condition];
        if (caseExpression) return [caseExpression evaluate];
        return [defaultExpression evaluate];
    } constants:constants symbolEvaluator:symbolEvaluator node:node error:error];
    BOOL isConstant = true;
    NSMutableSet<NSString *> *symbolNames = [NSMutableSet set];
    for (id obj in caseExpressions.allValues) {
        let sub = AS(JAExpression, obj);
        if (sub) {
            [symbolNames addObjectsFromArray:sub.symbolNames];
            isConstant &= sub.isConstant;
        }
    }
    switchExpression.isConstant = isConstant;
    switchExpression.symbolNames = symbolNames.allObjects;
    return switchExpression;
}

/*
 if (expression)
 expression
 elif (expression)
 expression
 else
 expression
 */
+ (instancetype)ifExpression:(NSString *)expression
                   constants:(JASymbolEvaluator)constants
             symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
                        node:(id<JANode>)node
                       error:(NSError **)error {
    if (![expression hasPrefix:@"if"]) return nil;
    NSMutableArray<JAExpression *> *expressions = [NSMutableArray array];
    NSUInteger i = 0, beg = 0, end = 0;
    for (; i < expression.length; ++i) {
        unichar ch = [expression characterAtIndex:i];
        if (![skipCharacterSet() characterIsMember:ch]) continue;
        end = i;
        let key = [expression substringWithRange:NSMakeRange(beg, end - beg)];
        if ([key isEqualToString:@"if"] || [key isEqualToString:@"elif"]) {
            let condition = extractBracket(expression, i, &i);
            if (!condition) return nil;
            JAExpression *expr = [self expression:condition
                                        constants:constants
                                  symbolEvaluator:symbolEvaluator
                                             node:node
                                            error:error];
            if (!expr) return nil;
            [expressions addObject:expr];
            beg = end = i + 1;
        } else {
            JAAssert([key isEqualToString:@"else"], @"invalid %@", key);
            if (![key isEqualToString:@"else"]) return nil;
            beg = end + 1;
        }
        bool quote = false;
        for (; i < expression.length; ++i) {
            unichar ch = [expression characterAtIndex:i];
            if (ch == '\'') {
                quote = !quote;
                continue;
            }
            if (i > 2 && [expression characterAtIndex:i] == 'f' && [expression characterAtIndex:i - 1] == 'i') {
                if ([skipCharacterSet() characterIsMember:[expression characterAtIndex:i - 3]]) {
                    end = i - 1;
                    i = end - 1;
                    break;
                }
                if (i > 4 &&
                    [expression characterAtIndex:i - 2] == 'l' &&
                    [expression characterAtIndex:i - 3] == 'e' &&
                    [skipCharacterSet() characterIsMember:[expression characterAtIndex:i - 4]]) {
                    end = i - 3;
                    i = end - 1;
                    break;
                }
            }
            if (i > 4 &&
                [expression characterAtIndex:i] == 'e' &&
                [expression characterAtIndex:i - 1] == 's' &&
                [expression characterAtIndex:i - 2] == 'l' &&
                [expression characterAtIndex:i - 3] == 'e' &&
                [skipCharacterSet() characterIsMember:[expression characterAtIndex:i - 4]]) {
                end = i - 3;
                i = end - 1;
                break;
            }
        }
        if (i == expression.length) end = i;
        let caseExpression = [expression substringWithRange:NSMakeRange(beg, end - beg)];
        JAExpression *caseExpr = [self expression:caseExpression
                                        constants:constants
                                  symbolEvaluator:symbolEvaluator
                                             node:node
                                            error:error];
        [expressions addObject:caseExpr];
        beg = end;
    }
    JAExpression *ifExpression = [self evaluteExpression:^id {
        size_t count = expressions.count;
        for (size_t j = 0; j < count; j += 2) {
            if (j + 1 >= count) return [expressions[j] evaluate];
            let conditionExpr = expressions[j];
            id value = ASNumber([conditionExpr evaluate]);
            if ([value boolValue]) return [expressions[j + 1] evaluate];
        }
        return nil;
    } constants:constants symbolEvaluator:symbolEvaluator node:node error:error];
    BOOL isConstant = true;
    NSMutableSet<NSString *> *symbolNames = [NSMutableSet set];
    for (id obj in expressions) {
        let sub = AS(JAExpression, obj);
        if (sub) {
            [symbolNames addObjectsFromArray:sub.symbolNames];
            isConstant &= sub.isConstant;
        }
    }
    ifExpression.isConstant = isConstant;
    ifExpression.symbolNames = symbolNames.allObjects;
    return ifExpression;
}

+ (instancetype)expression:(NSString *)expression
                 constants:(JASymbolEvaluator)constants
           symbolEvaluator:(JASymbolEvaluator)symbolEvaluator
            stateEvaluator:(id (^)(JASymbol *symbol))stateEvaluator
                      node:(id<JANode>)node
                     error:(NSError **)error {
    let aConstants = ^JAEvaluator(JASymbol * _Nonnull symbol) {
        if (symbol.type == JASymbolTypeLiteral) {
            id v = stateEvaluator ? stateEvaluator(symbol) : nil;
            if (v) {
                return ^(NSArray<id> *args) {
                    return v;
                };
            }
        }
        if (constants) {
            return constants(symbol);
        }
        return nil;
    };
    return [self expression:expression constants:aConstants symbolEvaluator:symbolEvaluator node:node error:error];
}

#if DEBUG
- (NSString *)description {
    NSMutableString *desc = [NSMutableString string];
    [desc appendFormat:@"\nisConstant:%ld\n", (long)self.isConstant];
    if (self.root) {
        [desc appendString:self.root.description];
    }
    return desc.copy;
}
#endif

@end


