package flutter.flutter_deepspeech

import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File


object Keys {
  const val methodChannel = "flutter_deepspeech"
  const val eventChannel = "flutter_deepspeech_partial"

  const val initSpeechMethod = "init"
  const val modelPathArgKey = "model_path"
  const val scorerPathArgKey = "scorer_path"
  const val partialThresholdArgKey = "partial_threshold"

  const val startListeningMethod = "start"
  const val finishListeningMethod = "finish"
}


/** FlutterDeepspeechPlugin */
class FlutterDeepspeechPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private var speechRecognition: SpeechRecognition?=null
  private lateinit var channel : MethodChannel
  private lateinit var eventChannel: EventChannel
  private var eventSink: EventChannel.EventSink?=null
  private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, Keys.methodChannel)
    channel.setMethodCallHandler(this)
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, Keys.eventChannel)
    eventChannel.setStreamHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
        Keys.initSpeechMethod -> {
            initSpeechRecognition(call, result)
        }
        Keys.startListeningMethod -> {
            startListening(call, result)
        }
        Keys.finishListeningMethod -> {
            finishListening(call, result)
        }
        else -> {
          result.notImplemented()
        }
    }
  }

    private fun isPowerOf2(_n: Int): Boolean {
        var n = _n
        while (n > 1 && n % 2 == 0) {
            n /= 2
        }
        return n == 1
    }

  private fun initSpeechRecognition(@NonNull call: MethodCall, @NonNull result: Result){
      val modelPath: String? = call.argument(Keys.modelPathArgKey)
      if(modelPath == null){
        result.error("MODEL_PATH_NULL", "Model path is empty", null)
        return
      }
      if (!File(modelPath).exists()){
        result.error("MODEL_FILE_IS_NOT_EXISTS", "Model file is not exists", null)
        return
      }
      val partialThreshold: Int? = call.argument(Keys.partialThresholdArgKey)
      if (partialThreshold == null){
        result.error("THRESHOLD_NOT_SPECIFIED", "Threshold not specified", null)
        return
      }
      if (partialThreshold < 256 && isPowerOf2(partialThreshold)){
        result.error("THRESHOLD_INVALID", "Threshold should be > 256 and power of 2", null)
        return
      }
      val scorerPath: String? = call.argument(Keys.scorerPathArgKey)
      if (scorerPath != null){
        if (!File(modelPath).exists()){
          result.error("SCORER_FILE_IS_NOT_EXISTS", "Scorer file is not exists", null)
          return
        }
      }
      speechRecognition = SpeechRecognition(modelPath, partialThreshold, scorerPath)
      result.success("OK")
  }

  private fun startListening(@NonNull call: MethodCall, @NonNull result: Result){
      if (speechRecognition == null){
        result.error("SPEECH_NOT_INITIALIZED", "initialize speech service", null)
        return
      }
      speechRecognition!!.start()
      result.success("OK")
  }

  private fun finishListening(@NonNull call: MethodCall, @NonNull result: Result){
    if (speechRecognition == null){
      result.error("SPEECH_NOT_INITIALIZED", "initialize speech service", null)
      return
    }
    speechRecognition!!.finish { res ->
        uiThreadHandler.post {
            result.success(res)
        }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    if (speechRecognition == null){
      events!!.error("SPEECH_NOT_INITIALIZED", "initialize speech service", null)
      return
    }
    this.eventSink = events
    this.speechRecognition!!.intermediateResult = {
        uiThreadHandler.post {
            this.eventSink?.success(mapOf("result" to it))
        }
    }
  }

  override fun onCancel(arguments: Any?) {
    this.eventSink = null
    this.speechRecognition?.intermediateResult = null
  }
}
