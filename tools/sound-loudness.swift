// Prints each sound file's peak, average and active-part level, in dBFS.
//
// Round 360, for judging "too quiet" against the rest of the game rather than by ear on a
// simulator that plays no sound at all. "active" is the share of samples above 1%, and the
// active level is the average over just those - a short click in a long file is quiet on
// average and loud where it is.
//
//   DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swiftc -O tools/sound-loudness.swift -o /tmp/loud
//   /tmp/loud Megaball/Sounds/*.m4a
import AVFoundation
for path in CommandLine.arguments.dropFirst() {
    let file = try! AVAudioFile(forReading: URL(fileURLWithPath: path))
    let buf = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))!
    try! file.read(into: buf)
    var peak: Float = 0; var sum: Double = 0; var n = 0
    var activeSum: Double = 0; var activeN = 0
    for ch in 0..<Int(buf.format.channelCount) {
        let d = buf.floatChannelData![ch]
        for i in 0..<Int(buf.frameLength) { let v = abs(d[i]); peak = max(peak, v); sum += Double(v*v); n += 1
            if v > 0.01 { activeSum += Double(v*v); activeN += 1 } }
    }
    let rms = sqrt(sum/Double(max(n,1))); let arms = sqrt(activeSum/Double(max(activeN,1)))
    let name = (path as NSString).lastPathComponent
    print(String(format: "%-26@ peak %.3f (%.1f dBFS)  rms %.4f (%.1f dB)  active-rms %.1f dB  active %.0f%%", name as NSString, peak, 20*log10(peak), rms, 20*log10(rms), 20*log10(arms), 100*Double(activeN)/Double(n)))
}
