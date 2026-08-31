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

try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

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
var idx = 1
while t < total {
    let time = CMTime(seconds: t, preferredTimescale: 600)
    if let cg = try? gen.copyCGImage(at: time, actualTime: nil) {
        let name = String(format: "frame_%04d.png", idx)
        let dst = CGImageDestinationCreateWithURL(outDir.appendingPathComponent(name) as CFURL,
                                                  UTType.png.identifier as CFString, 1, nil)
        if let dst = dst {
            CGImageDestinationAddImage(dst, cg, nil)
            CGImageDestinationFinalize(dst)
        }
    }
    idx += 1
    t += step
}
print("wrote \(idx - 1) frames to \(outDir.path) (\(fps) fps, \(String(format: "%.1f", total))s video)")
