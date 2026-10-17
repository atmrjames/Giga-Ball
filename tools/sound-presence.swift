// Makes a sound louder on a phone's speaker: lifts everything above a crossover, then drives
// the whole into a soft limiter so the peaks round off rather than clip. Keeps the file's own
// format, so a .caf stays a .caf.
//
// Round 388: James, "exploding brick sound effect should be louder". `explosion.caf` was
// already the loudest effect in the game by its active level (-13.1 dB) and peaked at -1.6
// dBFS, so `sound-gain` could add a dB and a half and no more. Two thirds of its energy was
// below 150 Hz, which a phone's speaker barely plays - the boom was loud in the file and quiet
// in the hand. So this raises what the speaker *can* play and lets the limiter take the
// headroom the bass was spending.
//
//   DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swiftc -O tools/sound-presence.swift -o /tmp/presence
//   /tmp/presence IN OUT CROSSOVER_HZ LIFT_DB DRIVE_DB
//
// Check the result with sound-loudness, and listen to it on a device: the simulator here plays
// nothing at all.
import AVFoundation

let args = CommandLine.arguments
let input = URL(fileURLWithPath: args[1]), output = URL(fileURLWithPath: args[2])
let crossover = Float(args[3])!
let lift = Float(pow(10.0, Double(args[4])!/20.0))
let drive = Float(pow(10.0, Double(args[5])!/20.0))

let file = try! AVAudioFile(forReading: input)
let buf = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))!
try! file.read(into: buf)
let rate = Float(file.processingFormat.sampleRate)
let a = exp(-2*Float.pi*crossover/rate)
let ceiling: Float = 0.95

var peak: Float = 0
for channel in 0..<Int(buf.format.channelCount) {
    let d = buf.floatChannelData![channel]
    var first: Float = 0, second: Float = 0
    for i in 0..<Int(buf.frameLength) {
        // Two one-pole low passes in a row: the low band, and what is left is the high one
        first = (1 - a)*d[i] + a*first
        second = (1 - a)*first + a*second
        let low = second, high = d[i] - second
        let lifted = (low + high*lift)*drive
        d[i] = ceiling*tanh(lifted/ceiling)
        // tanh is the soft limiter: near-linear for quiet samples, rounding towards the
        // ceiling for loud ones, so nothing can reach full scale
        peak = max(peak, abs(d[i]))
    }
}

try? FileManager.default.removeItem(at: output)
do {
    let out = try! AVAudioFile(forWriting: output, settings: file.fileFormat.settings,
                               commonFormat: .pcmFormatFloat32, interleaved: false)
    try! out.write(from: buf)
    out.close()
    // Closed before the process ends, or the file is never finalised (see sound-gain)
}
print(String(format: "%@: above %.0f Hz +%@ dB, driven +%@ dB, new peak %.1f dBFS",
             input.lastPathComponent as NSString, crossover, args[4] as NSString,
             args[5] as NSString, 20*log10(peak)))
