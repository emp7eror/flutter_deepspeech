//
//  SpeechRecognition.h
//  deepspeech_ios_test
//
//  Created by Alex on 26.10.2020.
//  Copyright © 2020 Mozilla. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN



@protocol SpeechRecognitionIntermediateDelegate <NSObject>

-(void) intermediateResultArrived: (NSString *) result;

@end


@interface SpeechRecognition : NSObject

@property (weak) id<SpeechRecognitionIntermediateDelegate> intermediateResultDelegate;

-(instancetype)init NS_UNAVAILABLE;

-(instancetype) initWithModelPath: (NSString *) modelPath partialThreshod: (NSUInteger) partialThreshold scorerPath: (NSString * _Nullable) scorerPath;

-(void) start;

-(NSString *) finish;


@end

NS_ASSUME_NONNULL_END
