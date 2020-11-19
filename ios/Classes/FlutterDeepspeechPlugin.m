#import "FlutterDeepspeechPlugin.h"
#import "SpeechRecognition.h"


NSString* _methodChannel = @"flutter_deepspeech";
NSString* _eventChannel = @"flutter_deepspeech_partial";

const NSString* _initSpeechMethod = @"init";

const NSString* _modelPathArgKey = @"model_path";
const NSString* _scorerPathArgKey = @"scorer_path";
const NSString* _partialThresholdArgKey = @"partial_threshold";

const NSString* _startListeningMethod = @"start";
const NSString* _finishListeningMethod = @"finish";



@interface FlutterDeepspeechPlugin ()<SpeechRecognitionIntermediateDelegate, FlutterStreamHandler>
{
    SpeechRecognition* recognition;
    FlutterEventSink eventSink;
}
@end


@implementation FlutterDeepspeechPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:_methodChannel
            binaryMessenger:[registrar messenger]];

    FlutterEventChannel *stream  = [FlutterEventChannel eventChannelWithName:_eventChannel binaryMessenger:[registrar messenger]];

  FlutterDeepspeechPlugin* instance = [[FlutterDeepspeechPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
  [stream setStreamHandler:instance];

}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult) result {
  if ([_initSpeechMethod isEqualToString:call.method]) {
      [self initSpeechRecognition:call result:result];
  } else if ([_startListeningMethod isEqualToString:call.method]){
      [self startListening:call result:result];
  } else if ([_finishListeningMethod isEqualToString:call.method]){
      [self finishListening:call result:result];
  }  else {
    result(FlutterMethodNotImplemented);
  }
}

-(void) initSpeechRecognition:(FlutterMethodCall*)call result:(FlutterResult)result
{
    NSString *modelPath = call.arguments[_modelPathArgKey];
    if (modelPath == nil){
        result([FlutterError errorWithCode: @"MODEL_PATH_NULL" message:@"Model path is empty" details:nil]);
        return;
    }

    if (![[NSFileManager defaultManager] fileExistsAtPath:modelPath]){
        result([FlutterError errorWithCode:@"MODEL_FILE_IS_NOT_EXISTS" message:@"Model file is not exists" details:nil]);
        return;
    }

    NSNumber * threshold = call.arguments[_partialThresholdArgKey];

    if (threshold == nil){
        result([FlutterError errorWithCode:@"THRESHOLD_NOT_SPECIFIED" message:@"Threshold not specified" details:nil]);
        return;
    }

    if (threshold.intValue < 256 && powerof2(threshold.intValue)){
        result([FlutterError errorWithCode:@"THRESHOLD_INVALID" message:@"Threshold should be > 256" details:nil]);
        return;
    }

    NSString *scorerPath = call.arguments[_scorerPathArgKey];

    if (scorerPath != nil && ![[NSFileManager defaultManager] fileExistsAtPath:scorerPath]){
        result([FlutterError errorWithCode:@"SCORER_FILE_IS_NOT_EXISTS" message:@"Scorer file is not exists" details:nil]);
        return;
    }

    recognition = [[SpeechRecognition alloc] initWithModelPath:modelPath partialThreshod:threshold.unsignedIntValue scorerPath:scorerPath];

    result(@"OK");
}

-(void) startListening:(FlutterMethodCall*)call result:(FlutterResult)result
{
    if (recognition == nil){
        result([FlutterError errorWithCode:@"SPEECH_NOT_INITIALIZED" message:@"initialize speech service" details:nil]);
        return;
    }

    [recognition start];
    result(@"OK");
}

-(void) finishListening:(FlutterMethodCall*)call result:(FlutterResult)result
{
    if (recognition == nil){
        result([FlutterError errorWithCode:@"SPEECH_NOT_INITIALIZED" message:@"initialize speech service" details:nil]);
        return;
    }

    result([recognition finish]);
}


- (void)intermediateResultArrived:(nonnull NSString *)result {
    self->eventSink(@{@"result": result});
}

- (FlutterError * _Nullable) onCancelWithArguments:(id _Nullable)arguments {
    recognition.intermediateResultDelegate = nil;
    self->eventSink = nil;
    return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
    if (recognition == nil){
        return [FlutterError errorWithCode:@"SPEECH_NOT_INITIALIZED" message:@"initialize speech service" details:nil];
    }
    self->eventSink = events;
    recognition.intermediateResultDelegate = self;
    return nil;
}

@end
