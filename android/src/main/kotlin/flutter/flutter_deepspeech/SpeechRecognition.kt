package flutter.flutter_deepspeech

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import org.mozilla.deepspeech.libdeepspeech.DeepSpeechModel
import java.util.concurrent.atomic.AtomicBoolean


typealias TranscriptionResultCallback = ((String) -> Unit)

class SpeechRecognition(modelPath: String, private var partialThreshold: Int, scorerPath: String?) {

    private val model: DeepSpeechModel = DeepSpeechModel(modelPath)
    private var transcriptionThread: Thread? = null
    private var isRecording: AtomicBoolean = AtomicBoolean(false)

    init {
        if (scorerPath != null) {
            model.enableExternalScorer(scorerPath);
        }
    }

    private var lastResult: TranscriptionResultCallback? = null
    var intermediateResult: TranscriptionResultCallback? = null


    fun start() {
        if (isRecording.compareAndSet(false, true)) {
            transcriptionThread = Thread(Runnable { transcribe() }, "Transcription Thread")
            transcriptionThread?.start()
        }
    }

    fun finish(completion: TranscriptionResultCallback) {
        this.lastResult = completion
        isRecording.set(false)
    }

    private fun transcribe() {
        // We read from the recorder in chunks of 2048 shorts. With a model that expects its input
        // at 16000Hz, this corresponds to 2048/16000 = 0.128s or 128ms.
        val audioBufferSize = partialThreshold
        val audioData = ShortArray(audioBufferSize)


        val streamContext = model.createStream()

        val recorder = AudioRecord(
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                model.sampleRate(),
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                audioBufferSize
        )

        recorder.startRecording()

        while (isRecording.get()) {
            recorder.read(audioData, 0, audioBufferSize)
            model.feedAudioContent(streamContext, audioData, audioData.size)
            val decoded = model.intermediateDecode(streamContext)
            intermediateResult?.invoke(decoded)
        }

        val decoded = model.finishStream(streamContext)
        this.lastResult?.invoke(decoded)
        this.lastResult = null

        recorder.stop()
        recorder.release()
    }


}