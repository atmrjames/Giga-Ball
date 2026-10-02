// Raises (or lowers) a sound file's level by a number of decibels, keeping its format.
//
// Round 360: James asked for Cluster "slightly louder" and the Laser Beam "slightly quiet".
// SpriteKit's `playSoundFileNamed` has no volume, so a level is changed in the file itself.
// Refuses to clip - it stops rather than write a peak at or over -0.2 dBFS.
//
//   DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swiftc -O tools/sound-gain.swift -o /tmp/gain
//   /tmp/gain IN.m4a OUT.m4a 6
//
// **`close()` before the process ends.** An `AVAudioFile` written from a top-level variable is
// never deinitialised, and a file that is not closed is not finalised: the first attempt wrote
// m4a files that nothing could open. Check the result with sound-loudness before it ships.
import AVFoundation
// gain IN OUT DB
let args = CommandLine.arguments
let input = URL(fileURLWithPath: args[1]), output = URL(fileURLWithPath: args[2])
let gain = Float(pow(10.0, Double(args[3])!/20.0))
let file = try! AVAudioFile(forReading: input)
let buf = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))!
try! file.read(into: buf)
var peak: Float = 0
for ch in 0..<Int(buf.format.channelCount) {
    let d = buf.floatChannelData![ch]
    for i in 0..<Int(buf.frameLength) { d[i] *= gain; peak = max(peak, abs(d[i])) }
}
precondition(peak < 0.98, "would clip: peak \(peak)")
let settings: [String: Any] = [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: file.fileFormat.sampleRate,
    AVNumberOfChannelsKey: file.fileFormat.channelCount, AVEncoderBitRateKey: 128_000]
try? FileManager.default.removeItem(at: output)
do {
    let out = try! AVAudioFile(forWriting: output, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
    try! out.write(from: buf)
    out.close()
}
print(String(format: "%@ +%@ dB, new peak %.1f dBFS", input.lastPathComponent as NSString, args[3] as NSString, 20*log10(peak)))
