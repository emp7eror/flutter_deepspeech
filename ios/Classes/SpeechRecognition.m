//
//  SpeechRecognition.m
//  deepspeech_ios_test
//
//  Created by Alex on 26.10.2020.
//  Copyright © 2020 Mozilla. All rights reserved.
//

#import "SpeechRecognition.h"
#import "deepspeech.h"
#import "RealtimeAudioListener.h"


#define printDSErrorIfNeed(result, str, ret) \
if (result != 0){\
    NSLog(@"%s, err: %s", str, DS_ErrorCodeToErrorMessage(result));\
    ret\
}

@interface SpeechRecognition ()<RealtimeAudioListenerDelegate>
{
    ModelState *model;
    StreamingState *stream;
    RealtimeAudioListener *listener;
    NSUInteger partialThreshold;
    long long buffer_count;
}
@end



static NSString * DStoNS(char * ds_result){
    NSString* ns_result = [NSString stringWithCString:ds_result encoding:NSUTF8StringEncoding];
    DS_FreeString(ds_result);
    return ns_result;
}

@implementation SpeechRecognition

-(instancetype) initWithModelPath: (NSString *) modelPath partialThreshod: (NSUInteger) partialThreshold scorerPath: (NSString * _Nullable) scorerPath {
    self = [super init];
    if (self) {
        int result = DS_CreateModel([modelPath cStringUsingEncoding:NSUTF8StringEncoding
                        ], &model);
        printDSErrorIfNeed(result, "Failed to create model", return nil;)
        if (scorerPath) {
            result = DS_EnableExternalScorer(model, [scorerPath cStringUsingEncoding:NSUTF8StringEncoding]);
            printDSErrorIfNeed(result, "Failed to append scorer", return nil;)
        }
        listener = [[RealtimeAudioListener alloc] initWithSampleRate:16000 andFrame:64];
        listener.delegate = self;
        self->partialThreshold = partialThreshold;
    }
    return self;
}

-(void) push:(void *)buffer nFrames:(int)nFrames
{
    DS_FeedAudioContent(stream, (const short *)buffer, nFrames);
    buffer_count += nFrames;
    if (self.intermediateResultDelegate == nil){
        return;
    }
    if (buffer_count % partialThreshold == 0){
        NSString* result = DStoNS(DS_IntermediateDecode(stream));
        [self.intermediateResultDelegate intermediateResultArrived:result];
    }
}

- (void)start
{
    if(stream != NULL){
        return;
    }
    int result = DS_CreateStream(model, &stream);
    printDSErrorIfNeed(result, "Cant create stream", return;)
    [listener start];
}


- (NSString *)finish
{
    if (stream == NULL){
        return nil;
    }
    [listener stop];
    NSString*result = DStoNS(DS_FinishStream(stream));
    stream = NULL;
    return result;
}

- (void)dealloc
{
    if (stream != NULL){
        DS_FreeStream(stream);
    }
    DS_FreeModel(model);
}



@end
