//
//  RealtimeAudioListener.h
//  audio_test
//
//  Created by Alex on 05.10.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@protocol RealtimeAudioListenerDelegate <NSObject>

-(void) push: (void *) buffer nFrames:(int) nFrames;

@end


@interface RealtimeAudioListener : NSObject

-(instancetype)init NS_UNAVAILABLE;

-(instancetype)initWithSampleRate: (int) sampleRate andFrame: (int) frame;

@property (nonatomic, weak) id<RealtimeAudioListenerDelegate> delegate;

-(void) start;
-(void) stop;

@end

NS_ASSUME_NONNULL_END
