//
//  RealtimeAudioListener.m
//  audio_test
//
//  Created by Alex on 05.10.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

#import "RealtimeAudioListener.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#include "error.hpp"


@interface RealtimeAudioListener ()
{
    AudioStreamBasicDescription ioFormat;
    @public AudioUnit unit;
    int sampleRate;
    int framePerSlice;
}

@property (atomic, assign) BOOL audioUnitRunning;

@end

AudioStreamBasicDescription CreateIOFormat(int sampleRate, int bytesPerFrame) {
    AudioStreamBasicDescription ioFormat;
    ioFormat.mSampleRate = sampleRate;
    ioFormat.mFormatID = kAudioFormatLinearPCM;
    ioFormat.mChannelsPerFrame = 1;
    ioFormat.mFormatFlags = kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
    ioFormat.mReserved = 0;
    ioFormat.mFramesPerPacket = 1;
    ioFormat.mBitsPerChannel = 8 * bytesPerFrame;
    ioFormat.mBytesPerFrame = bytesPerFrame;
    ioFormat.mBytesPerPacket = bytesPerFrame;
    return ioFormat;
}

static OSStatus performRender (void                         *inRefCon,
                               AudioUnitRenderActionFlags   *ioActionFlags,
                               const AudioTimeStamp         *inTimeStamp,
                               UInt32                         inBusNumber,
                               UInt32                         inNumberFrames,
                               AudioBufferList              *ioData)
{
    auto handler = (__bridge RealtimeAudioListener*)inRefCon;
    OSStatus err = AudioUnitRender(handler->unit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
    auto buffer = ioData->mBuffers[0].mData;
    [handler.delegate push: buffer nFrames:inNumberFrames];
    return err;
}

@implementation RealtimeAudioListener


-(instancetype)initWithSampleRate: (int) sampleRate andFrame: (int) frame
{
    self = [super init];
    if (self) {
        self->sampleRate = sampleRate;
        self->framePerSlice = frame;
        self->ioFormat = CreateIOFormat(sampleRate, sizeof(int16_t));
        [self setupAudioUnit];
        [self setupAudioSession];
    }
    return self;
}


-(void) stop
{
    OSStatus err = AudioOutputUnitStop(unit);
    if (err)
        NSLog(@"couldn't stop AURemoteIO: %d", (int)err);
    else
        self.audioUnitRunning = false;
}

-(void) start
{
    OSStatus err = AudioOutputUnitStart(unit);
    if (err)
        NSLog(@"couldn't start AURemoteIO: %d", (int)err);
    else
        self.audioUnitRunning = true;
}

 -(void) handleInterruption:(NSNotification *) notification
{
    int theInterruptionType =  [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
    if (theInterruptionType == AVAudioSessionInterruptionTypeBegan) {
        [self stop];
    }

    if (theInterruptionType == AVAudioSessionInterruptionTypeEnded) {
        // make sure to activate the session
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if (nil != error) NSLog(@"AVAudioSession set active failed with error: %@", error);
        [self start];
    }
}

-(void) handleMediaServerReset
{
    [self setupAudioUnit];
    [self setupAudioSession];
    if (self.audioUnitRunning)
        [self start];
}


-(void) setupAudioSession
{
    try {
        AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
        NSError *error = nil;
        [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
        ThrowIfError((OSStatus)error.code, "couldn't set session's audio category");
        NSTimeInterval bufferDuration = .005;
        [sessionInstance setPreferredIOBufferDuration:bufferDuration error:&error];
        ThrowIfError((OSStatus)error.code, "couldn't set session's I/O buffer duration");
        [sessionInstance setPreferredSampleRate:sampleRate error:&error];
        ThrowIfError((OSStatus)error.code, "couldn't set session's preferred sample rate");
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMediaServerReset) name:AVAudioSessionMediaServicesWereResetNotification object:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        ThrowIfError((OSStatus)error.code, "couldn't set session active");
    }

    catch (const Error &e) {
        NSLog(@"Error returned from setupAudioSession: %d: %s", e.code, e.description.c_str());
    }
    catch (...) {
        NSLog(@"Unknown error returned from setupAudioSession");
    }
}

-(void) setupAudioUnit
{
    try {
        AudioComponentDescription desc;
        desc.componentType = kAudioUnitType_Output;
#if TARGET_OS_IOS
        desc.componentSubType = kAudioUnitSubType_RemoteIO;
#endif
        desc.componentManufacturer = kAudioUnitManufacturer_Apple;
        desc.componentFlags = 0;
        desc.componentFlagsMask = 0;

        AudioComponent comp = AudioComponentFindNext(NULL, &desc);
        ThrowIfError(AudioComponentInstanceNew(comp, &unit), "Can't create audio unit");

        UInt32 one = 1;

        ThrowIfError(AudioUnitSetProperty(unit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one)),
                     "Can't set audio input");
        ThrowIfError(AudioUnitSetProperty(unit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one)), "");

        ThrowIfError(AudioUnitSetProperty(unit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one)), "could not enable input on AURemoteIO");
        ThrowIfError(AudioUnitSetProperty(unit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one)), "could not enable output on AURemoteIO");

        ThrowIfError(AudioUnitSetProperty(unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &ioFormat, sizeof(ioFormat)), "couldn't set the input client format on AURemoteIO");
        ThrowIfError(AudioUnitSetProperty(unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &ioFormat, sizeof(ioFormat)), "couldn't set the output client format on AURemoteIO");

        // Set the MaximumFramesPerSlice property. This property is used to describe to an audio unit the maximum number
        // of samples it will be asked to produce on any single given call to AudioUnitRender

        ThrowIfError(AudioUnitSetProperty(unit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &framePerSlice, sizeof(UInt32)), "couldn't set max frames per slice on AURemoteIO");

        // Get the property value back from AURemoteIO. We are going to use this value to allocate buffers accordingly
        UInt32 propSize = sizeof(UInt32);
        ThrowIfError(AudioUnitGetProperty(unit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &framePerSlice, &propSize), "couldn't get max frames per slice on AURemoteIO");

        AURenderCallbackStruct renderCallback;
        renderCallback.inputProc = performRender;
        renderCallback.inputProcRefCon = (__bridge  void *)self;
        ThrowIfError(AudioUnitSetProperty(unit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallback, sizeof(renderCallback)), "couldn't set render callback on AURemoteeIO");

        // Initialize the AURemoteIO instance
        ThrowIfError(AudioUnitInitialize(unit), "couldn't initialize AURemoteIO instance");

    } catch (const Error &e) {
        NSLog(@"Error returned from setupIOUnit: %d: %s", e.code, e.description.c_str());
    }
    catch (...) {
        NSLog(@"Unknown error returned from setupIOUnit");
    }
}


@end
