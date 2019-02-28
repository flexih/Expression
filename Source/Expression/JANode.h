//
//  JANode.h
//  Jarvis
//
//  Created by flexih on 2019/2/28.
//  Copyright © 2019 paopao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol JANode <NSObject>

- (id)valueForSymbol:(NSString *)symbol;

@end

NS_ASSUME_NONNULL_END
