// Нарезка видео (.mov/.mp4) на PNG-кадры через AVFoundation — без ffmpeg/brew.
// Использование: swift frames.swift <video> <out-dir> [fps]
//   fps по умолчанию 1 (1 кадр/сек). Для плотнее — 2; для реже — 0.5.
// Выход: out-dir/frame_0001.png, ... (можно смотреть Read'ом / отдавать Codex как изображения).

import AVFoundation
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write("usage: swift frames.swift <video> <out-dir> [fps]\n".data(using: .utf8)!)
    exit(2)
}
let videoURL = URL(fileURLWithPath: args[1])
let outDir = URL(fileURLWithPath: args[2], isDirectory: true)
let fps = args.count >= 4 ? (Double(args[3]) ?? 1.0) : 1.0
guard fps > 0, fps <= 60, fps.isFinite else {
    FileHandle.standardError.write("error: fps must be in (0, 60]\n".data(using: .utf8)!)
    exit(2)
}

do {
    try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
} catch {
    FileHandle.standardError.write("error: cannot create \(outDir.path): \(error)\n".data(using: .utf8)!)
    exit(1)
}

let asset = AVURLAsset(url: videoURL)
let gen = AVAssetImageGenerator(asset: asset)
gen.appliesPreferredTrackTransform = true          // уважать поворот видео
gen.requestedTimeToleranceBefore = .zero
gen.requestedTimeToleranceAfter = .zero

let sema = DispatchSemaphore(value: 0)
var duration = CMTime.zero
Task {
    duration = (try? await asset.load(.duration)) ?? .zero
    sema.signal()
}
sema.wait()

let total = CMTimeGetSeconds(duration)
guard total > 0 else {
    FileHandle.standardError.write("error: cannot read duration (bad video?)\n".data(using: .utf8)!)
    exit(1)
}

let step = 1.0 / fps
var t = 0.0
var written = 0
var failed = 0
while t < total {
    let time = CMTime(seconds: t, preferredTimescale: 600)
    var ok = false
    if let cg = try? gen.copyCGImage(at: time, actualTime: nil) {
        let name = String(format: "frame_%04d.png", written + 1)
        if let dst = CGImageDestinationCreateWithURL(outDir.appendingPathComponent(name) as CFURL,
                                                     UTType.png.identifier as CFString, 1, nil) {
            CGImageDestinationAddImage(dst, cg, nil)
            ok = CGImageDestinationFinalize(dst)
        }
    }
    if ok { written += 1 } else { failed += 1 }
    t += step
}
print("wrote \(written) frames to \(outDir.path) (\(fps) fps, \(String(format: "%.1f", total))s video)")
if failed > 0 {
    FileHandle.standardError.write("warning: \(failed) frames failed to extract\n".data(using: .utf8)!)
    exit(3)
}
