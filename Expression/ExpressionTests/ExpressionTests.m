//
//  ExpressionTests.m
//  JarvisTests
//
//  Created by flexih on 2018/7/25.
//  Copyright © 2018 paopao. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JAExpression.h"
#import "JANode.h"

@interface ExpressionTests : XCTestCase

@end

@implementation ExpressionTests

- (void)testAndOr {
    id value0 = [[JAExpression expression:@"1||2" constants:nil symbolEvaluator:nil node:nil error:nil] evaluate];
    XCTAssertTrue([value0 boolValue]);
}

- (void)testlogicNot {
    id value0 = [[JAExpression expression:@"2&~2" constants:nil symbolEvaluator:nil node:nil error:nil] evaluate];
    XCTAssertTrue([value0 integerValue] == 0);
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
  
    id value1 = [[JAExpression expression:@"2+5" constants:nil symbolEvaluator:nil node:nil error:nil] evaluate];
    XCTAssertTrue([value1 isEqual:@7]);
  
  id value2 = [[JAExpression expression:@"a+b" constants:^JAEvaluator(JASymbol *symbol) {
        return ^id(NSArray<id> *args) {
            return @{@"a": @2, @"b": @5}[symbol.value];
        };
    } symbolEvaluator:nil node:nil error:nil] evaluate];
    XCTAssertTrue([value2 isEqual:@7]);
    
    id value3 = [[JAExpression stringExpression:@" hello, world {name} " constants:^JAEvaluator(JASymbol *symbol) {
        return ^id(NSArray<id> *args) {
            return @{@"name": @"f"}[symbol.value];
        };
    } symbolEvaluator:nil node:nil error:nil] evaluate];
    XCTAssertTrue([value3 isEqual:@" hello, world f "]);
}

- (void)testBracket {
    id value0 = [JAExpression expression:@"3+(4+5)" constants:nil symbolEvaluator:nil node:nil error:nil];
    XCTAssertTrue([[value0 evaluate] isEqual:@12]);
}

- (void)testColor {
    id value6 = [[JAExpression colorExpression:@"#fff" constants:nil symbolEvaluator:nil node:nil error:nil] evaluate];
    XCTAssertTrue([value6 isKindOfClass:[UIColor class]]);
    CGFloat white, alpha;
    [(UIColor *)value6 getWhite:&white alpha:&alpha];
    XCTAssertTrue(fabs(1 - white) < 0.001 && fabs(1 - alpha) < 0.001);
    
    id value7 = [[JAExpression colorExpression:@"#ffffff" constants:nil symbolEvaluator:nil node:nil error:nil] evaluate];
    XCTAssertTrue([value7 isKindOfClass:[UIColor class]]);
    [(UIColor *)value7 getWhite:&white alpha:&alpha];
    XCTAssertTrue(fabs(1 - white) < 0.001 && fabs(1 - alpha) < 0.001);
    
    id value4 = [[JAExpression colorExpression:@"white" constants:nil symbolEvaluator:nil node:nil error:nil] evaluate];
    XCTAssertTrue([value4 isEqual:[UIColor whiteColor]]);
    [(UIColor *)value4 getWhite:&white alpha:&alpha];
    XCTAssertTrue(fabs(1 - white) < 0.001 && fabs(1 - alpha) < 0.001);
}

- (void)testFont {
    UIFont *value1 = [[JAExpression fontExpression:@"Helvetica 30 italic" constants:nil symbolEvaluator:nil node:nil error:nil] evaluate];
    XCTAssertTrue([value1 isKindOfClass:UIFont.class]);
    XCTAssertTrue([value1.familyName isEqualToString:@"Helvetica"] && value1.pointSize == 30);
    
    UIFont *value2 = [[JAExpression fontExpression:@"Helvetica 30" constants:nil symbolEvaluator:nil node:nil error:nil] evaluate];
    XCTAssertTrue([value2 isKindOfClass:UIFont.class]);
    XCTAssertTrue([value2.familyName isEqualToString:@"Helvetica"] && value1.pointSize == 30);
    
    UIFont *value3 = [[JAExpression fontExpression:@"30 bold" constants:nil symbolEvaluator:nil node:nil error:nil] evaluate];
    XCTAssertTrue([value3 isKindOfClass:UIFont.class]);
    XCTAssertTrue([value3.familyName isEqualToString:[UIFont boldSystemFontOfSize:30].familyName] && value3.pointSize == 30);
    
    UIFont *value4 = [[JAExpression fontExpression:@"30" constants:nil symbolEvaluator:nil node:nil error:nil] evaluate];
    XCTAssertTrue([value4 isKindOfClass:UIFont.class]);
    XCTAssertTrue([value4.familyName isEqualToString:[UIFont systemFontOfSize:30].familyName] && value4.pointSize == 30);
    
    UIFont *value5 = [[JAExpression fontExpression:@"System 30" constants:nil symbolEvaluator:nil node:nil error:nil] evaluate];
    XCTAssertTrue([value5 isKindOfClass:UIFont.class]);
    XCTAssertTrue([value5.familyName isEqualToString:[UIFont systemFontOfSize:30].familyName] && value5.pointSize == 30);
}

- (void)test {
    id value = [[JAExpression expression:@"3%" constants:nil symbolEvaluator:^JAEvaluator(JASymbol * _Nonnull symbol) {
        if (symbol.type == JASymbolTypeOperator) {
            if ([symbol.operator.name isEqual:@"%"]) {
                return ^id(NSArray<id> *args) {
                    return @([args[0] doubleValue] * 0.01);
                };
            }
        }
        return nil;
    } node:nil error:nil] evaluate];
    XCTAssertTrue([value isEqual:@(0.03)]);
}

- (void)testCondition {
    NSError *error;
    id v = [JAExpression expression:@"1>2?2+3:4+5" constants:nil symbolEvaluator:nil node:nil error:&error];
    [v evaluate];
}

- (void)testText {
    NSError *error;
    id v = [JAExpression stringExpression:@"{read>=10000?read/10000.0+'万':(read==0?'评论':read)}" constants:nil symbolEvaluator:^JAEvaluator(JASymbol * _Nonnull symbol) {
        if (symbol.type == JASymbolTypeLiteral) {
            if ([symbol.value isEqual:@"read"]) {
                return ^id(NSArray<id> *args) {
                    return @(11000);
                };
            }
        }
        return nil;
    } node:nil error:&error];
    [v evaluate];
}

- (void)testString {
    id value = [JAExpression expression:@"10+'万'" constants:nil symbolEvaluator:nil node:nil error:nil];
    [value evaluate];
}

- (void)testSwitchCase {
    NSError *error;
    id e = [JAExpression expression:@"switch (len(pictures)) case 1: '1' default: '0' case 2: '2'" constants:^JAEvaluator(JASymbol * _Nonnull symbol) {
        if (symbol.type == JASymbolTypeLiteral) {
            if ([symbol.value isEqual:@"pictures"]) {
                return ^id(NSArray<id> *args) {
                    return @[@1,@2];
                };
            }
        }
        return nil;
    } symbolEvaluator:nil stateEvaluator:nil node:nil error:&error];
    id v = [e evaluate];
    XCTAssertTrue([@"2" isEqual:v]);
}

- (void)testIfCase {
    NSError *error;
    id e = [JAExpression expression:@"if (sourceType == 1) textOnly?'feedText':'feedImage' elif (sourceType == 8 && extendType != 6 && extendType != 7) 'feedVideo' elif (count(pictures) == 9) 'feedImage9' elif (count(pictures) == 8) 'feedImage8' elif (count(pictures) == 7) 'feedImage7' elif (count(pictures) == 6) 'feedImage6' elif (count(pictures) == 5) 'feedImage5' elif (count(pictures) == 4) 'feedImage4' elif (count(pictures) == 3) 'feedImage3' elif (count(pictures) == 2) 'feedImage2' elif (count(pictures) == 1) 'feedImage1'" constants:^JAEvaluator(JASymbol * _Nonnull symbol) {
        if (symbol.type == JASymbolTypeLiteral) {
            if ([symbol.value isEqual:@"pictures"]) {
                return ^id(NSArray<id> *args) {
                    return @[@1,@2];
                };
            }
            if ([symbol.value isEqual:@"sourceType"]) {
                return ^id(NSArray<id> *args) {
                    return @1;
                };
            }
        }
        return nil;
    } symbolEvaluator:nil stateEvaluator:nil node:nil error:&error];
    id v = [e evaluate];
    XCTAssertTrue([@"feedImage" isEqual:v]);
}

- (void)testRepeat {
    NSError *error;
    id e = [JAExpression stringExpression:@"{joined(array(repeat==508?'每天':'',repeat==508?'':((repeat&128)==128?'周日':''),repeat==508?'':((repeat&2)==2?'周一':''),repeat==508?'':((repeat&4)==4?'周二':''),repeat==508?'':((repeat&8)==8?'周三':''),repeat==508?'':((repeat&16)==16?'周四':''),repeat==508?'':((repeat&32)==32?'周五':''),repeat==508?'':((repeat&64)==64?'周六':'')), ' ')}" constants:nil
                          symbolEvaluator:^JAEvaluator(JASymbol * _Nonnull symbol) {
                              if ([symbol.value isEqual:@"repeat"]) {
                                  return ^(NSArray<id> *args) {
                                      return @((2 << 1) | (2 << 2));
                                  };
                              }
                              return nil;
                          } node:nil error:&error];
    id v = [e evaluate];
    NSLog(@"%@", v);
}

@end
