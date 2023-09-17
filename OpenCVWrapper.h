//
//  OpenCVWrapper.h
//  SimpleCoreMLDemo
//
//  Created by mac on 2023/7/12.
//  Copyright © 2023 Chamin Morikawa. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject

+ (UIImage *)rectifyBiasWithImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
