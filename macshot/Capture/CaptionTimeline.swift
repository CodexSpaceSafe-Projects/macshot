import Foundation
import CoreGraphics

/// Splits recognized speech into caption lines of a few words.
nonisolated enum CaptionTimeline {
    struct Word: Equatable, Sendable {
        var text: String
        var start: Double
        var end: Double
    }

    static func segments(from words: [Word], maxWords: Int, maxGap: Double = 0.9) -> [VideoCaptionSegment] {
        var result: [VideoCaptionSegment] = []
        var current: [Word] = []
        func flush() {
            guard let first = current.first, let last = current.last else { return }
            let text = current.map(\.text).joined(separator: " ")
            result.append(VideoCaptionSegment(startTime: first.start, endTime: max(last.end, first.start + 0.4), text: text))
            current.removeAll()
        }
        for word in words where !word.text.trimmingCharacters(in: .whitespaces).isEmpty {
            if let last = current.last, word.start - last.end > maxGap || current.count >= maxWords { flush() }
            current.append(word)
            if word.text.last.map({ ".!?".contains($0) }) == true { flush() }
        }
        flush()
        for i in result.indices.dropLast() where result[i].endTime > result[i + 1].startTime {
            result[i].endTime = result[i + 1].startTime
        }
        return result
    }

    /// `captions` must be sorted by start time.
    static func active(at t: Double, in captions: [VideoCaptionSegment]) -> (VideoCaptionSegment, CGFloat)? {
        guard let caption = captions.last(where: { $0.startTime <= t && t < $0.endTime }) else { return nil }
        let appear = min(1, (t - caption.startTime) / 0.12)
        let vanish = min(1, (caption.endTime - t) / 0.12)
        return (caption, CGFloat(max(0, min(appear, vanish))))
    }

    /// SubRip text for the captions, on the edited (output) clock.
    static func srt(_ captions: [VideoCaptionSegment], mapTime: (Double) -> Double) -> String {
        func stamp(_ seconds: Double) -> String {
            let ms = Int((max(0, seconds) * 1000).rounded())
            return String(format: "%02d:%02d:%02d,%03d", ms / 3_600_000, (ms / 60_000) % 60, (ms / 1000) % 60, ms % 1000)
        }
        var lines: [String] = []
        for (index, caption) in captions.sorted(by: { $0.startTime < $1.startTime }).enumerated() {
            let start = mapTime(caption.startTime), end = mapTime(caption.endTime)
            guard end > start else { continue }
            lines.append("\(index + 1)\n\(stamp(start)) --> \(stamp(end))\n\(caption.text)\n")
        }
        return lines.joined(separator: "\n")
    }
}
