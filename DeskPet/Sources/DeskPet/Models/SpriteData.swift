import SwiftUI

// MARK: - Pixel Color Palette

/// Simplified color enum for 16x16 pixel grid definitions.
/// Maps to SwiftUI Color for rendering.
enum PixelColor: UInt8, Sendable {
    case clear      // transparent
    case outline    // dark brown/black outline
    case body       // orange body
    case bodyLight  // lighter orange highlight
    case belly      // cream/white belly & face
    case nose       // pink nose
    case eye        // dark eye
    case tail       // orange tail (same as body, semantic alias handled by usage)
    case blush      // pink blush on cheeks
    case heart      // red heart (for reacting)
    case zzz        // blue zzz (for sleeping)

    var color: Color {
        switch self {
        case .clear:     return .clear
        case .outline:   return Color(red: 0.2, green: 0.13, blue: 0.07)
        case .body:      return Color(red: 0.93, green: 0.6, blue: 0.2)
        case .bodyLight: return Color(red: 0.98, green: 0.73, blue: 0.35)
        case .belly:     return Color(red: 1.0, green: 0.95, blue: 0.85)
        case .nose:      return Color(red: 0.95, green: 0.5, blue: 0.5)
        case .eye:       return Color(red: 0.15, green: 0.1, blue: 0.05)
        case .tail:      return Color(red: 0.93, green: 0.6, blue: 0.2)
        case .blush:     return Color(red: 1.0, green: 0.65, blue: 0.65)
        case .heart:     return Color(red: 0.95, green: 0.25, blue: 0.3)
        case .zzz:       return Color(red: 0.4, green: 0.6, blue: 0.95)
        }
    }
}

// Short aliases for compact grid definitions
private let __ = PixelColor.clear
private let OL = PixelColor.outline
private let BD = PixelColor.body
private let BL = PixelColor.bodyLight
private let BE = PixelColor.belly
private let NS = PixelColor.nose
private let EY = PixelColor.eye
private let TL = PixelColor.tail
private let BU = PixelColor.blush
private let HT = PixelColor.heart
private let ZZ = PixelColor.zzz

// MARK: - Sprite Frame Type

/// A single 16x16 pixel sprite frame.
struct SpriteFrame: Sendable {
    let pixels: [[PixelColor]]

    static let size = 16

    init(_ pixels: [[PixelColor]]) {
        self.pixels = pixels
    }
}

// MARK: - SpriteData

/// Central container for all animation sprite frames.
/// Pure code-defined pixel art -- no external image dependencies.
enum SpriteData: Sendable {

    /// Returns the frames for a given animation state.
    static func frames(for state: AnimationState) -> [SpriteFrame] {
        switch state {
        case .idle:     return idleFrames
        case .walking:  return walkingFrames
        case .sitting:  return sittingFrames
        case .sleeping: return sleepingFrames
        case .running:  return runningFrames
        case .reacting: return reactingFrames
        }
    }

    // MARK: - Idle (2 frames: standing + tail wag)

    static let idleFrames: [SpriteFrame] = [
        // Frame 0: standing still, tail up-right
        SpriteFrame([
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, OL, OL, __, __, __, __, OL, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, OL, __, __, OL, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, OL, OL, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, EY, BD, BD, BD, BD, EY, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, NS, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, __, OL, BD, BU, BE, BE, BU, BD, OL, __, __, __, __, __],
            [__, __, __, __, OL, BD, BE, BE, BD, OL, __, __, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, BD, BE, BE, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, OL, __, __, __],
            [__, __, __, OL, BD, OL, __, OL, BD, OL, __, OL, TL, OL, __, __],
            [__, __, __, OL, BD, OL, __, OL, BD, OL, __, __, OL, TL, OL, __],
            [__, __, __, OL, OL, OL, __, OL, OL, OL, __, __, __, OL, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
        ]),
        // Frame 1: tail wagging down
        SpriteFrame([
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, OL, OL, __, __, __, __, OL, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, OL, __, __, OL, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, OL, OL, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, EY, BD, BD, BD, BD, EY, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, NS, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, __, OL, BD, BU, BE, BE, BU, BD, OL, __, __, __, __, __],
            [__, __, __, __, OL, BD, BE, BE, BD, OL, __, __, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, BD, BE, BE, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, __, OL, BD, OL, __, OL, BD, OL, __, OL, OL, __, __, __],
            [__, __, __, OL, BD, OL, __, OL, BD, OL, __, OL, TL, OL, __, __],
            [__, __, __, OL, OL, OL, __, OL, OL, OL, __, __, OL, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
        ]),
    ]

    // MARK: - Walking (4 frames: four-legged walk cycle)

    static let walkingFrames: [SpriteFrame] = [
        // Frame 0: left legs forward
        SpriteFrame([
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, OL, OL, __, __, __, __, OL, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, OL, __, __, OL, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, OL, OL, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, EY, BD, BD, BD, BD, EY, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, NS, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, __, __, OL, BD, BE, BE, BD, OL, __, __, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, BD, BE, BE, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, OL, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, TL, OL, __, __],
            [__, __, OL, BD, OL, __, __, __, OL, BD, OL, __, OL, __, __, __],
            [__, OL, BD, OL, __, __, __, __, __, OL, BD, OL, __, __, __, __],
            [__, OL, OL, __, __, __, __, __, __, OL, OL, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
        ]),
        // Frame 1: passing position
        SpriteFrame([
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, OL, OL, __, __, __, __, OL, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, OL, __, __, OL, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, OL, OL, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, EY, BD, BD, BD, BD, EY, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, NS, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, __, __, OL, BD, BE, BE, BD, OL, __, __, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, BD, BE, BE, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, OL, __, __, __],
            [__, __, __, OL, BD, OL, __, OL, BD, OL, __, OL, TL, OL, __, __],
            [__, __, __, OL, BD, OL, __, OL, BD, OL, __, __, OL, __, __, __],
            [__, __, __, OL, OL, OL, __, OL, OL, OL, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
        ]),
        // Frame 2: right legs forward
        SpriteFrame([
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, OL, OL, __, __, __, __, OL, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, OL, __, __, OL, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, OL, OL, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, EY, BD, BD, BD, BD, EY, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, NS, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, __, __, OL, BD, BE, BE, BD, OL, __, __, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, BD, BE, BE, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, OL, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, TL, OL, __, __],
            [__, __, __, OL, BD, OL, __, __, OL, BD, OL, __, OL, __, __, __],
            [__, __, __, OL, BD, OL, __, OL, BD, OL, __, __, __, __, __, __],
            [__, __, __, OL, OL, __, __, OL, OL, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
        ]),
        // Frame 3: passing position (mirror)
        SpriteFrame([
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, OL, OL, __, __, __, __, OL, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, OL, __, __, OL, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, OL, OL, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, EY, BD, BD, BD, BD, EY, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, NS, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, __, __, OL, BD, BE, BE, BD, OL, __, __, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, BD, BE, BE, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, OL, __, __, __],
            [__, __, __, OL, BD, OL, __, OL, BD, OL, OL, TL, OL, __, __, __],
            [__, __, __, OL, BD, OL, __, OL, BD, OL, __, __, __, __, __, __],
            [__, __, __, OL, OL, OL, __, OL, OL, OL, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
        ]),
    ]

    // MARK: - Sitting (2 frames: sitting + licking paw)

    static let sittingFrames: [SpriteFrame] = [
        // Frame 0: sitting upright
        SpriteFrame([
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, OL, OL, __, __, __, __, OL, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, OL, __, __, OL, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, OL, OL, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, EY, BD, BD, BD, BD, EY, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, NS, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, __, OL, BD, BU, BE, BE, BU, BD, OL, __, __, __, __, __],
            [__, __, __, __, OL, BD, BE, BE, BD, OL, __, __, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, __, OL, BD, BD, BD, BD, BD, BD, OL, __, __, __, __, __],
            [__, __, __, OL, BD, BD, BD, BD, BD, BD, OL, OL, __, __, __, __],
            [__, __, __, OL, OL, BD, BD, BD, BD, OL, OL, TL, OL, __, __, __],
            [__, __, __, __, OL, OL, OL, OL, OL, OL, __, OL, TL, OL, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, OL, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
        ]),
        // Frame 1: licking paw (paw raised)
        SpriteFrame([
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, OL, OL, __, __, __, __, OL, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, OL, __, __, OL, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, OL, OL, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, EY, BD, BD, BD, BD, EY, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, NS, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, __, __, OL, BD, BE, BE, BD, OL, __, __, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, OL, BD, OL, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, OL, BD, OL, __, OL, BD, BD, BD, BD, OL, __, __, __, __, __],
            [__, __, OL, __, __, OL, BD, BD, BD, BD, OL, OL, __, __, __, __],
            [__, __, __, __, __, OL, OL, BD, BD, OL, OL, TL, OL, __, __, __],
            [__, __, __, __, __, __, OL, OL, OL, OL, __, OL, TL, OL, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, OL, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
        ]),
    ]

    // MARK: - Sleeping (2 frames: lying down + breathing rise with ZZZ)

    static let sleepingFrames: [SpriteFrame] = [
        // Frame 0: lying down, eyes closed
        SpriteFrame([
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, OL, OL, __, __, __, __, OL, OL, __, __, __, __, __, __],
            [__, OL, BD, BD, OL, __, __, OL, BD, BD, OL, __, __, __, __, __],
            [__, OL, BD, BD, BD, OL, OL, BD, BD, BD, OL, __, __, __, __, __],
            [__, OL, BD, OL, BD, BD, BD, BD, OL, BD, OL, __, __, __, __, __],
            [__, OL, BD, BD, BD, NS, BD, BD, BD, BD, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __, __],
            [OL, OL, OL, BD, BD, BE, BE, BD, BD, BD, OL, OL, OL, __, __, __],
            [OL, TL, OL, OL, BD, BD, BD, BD, BD, OL, OL, BD, OL, __, __, __],
            [__, OL, __, __, OL, OL, OL, OL, OL, __, __, OL, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
        ]),
        // Frame 1: breathing rise + ZZZ
        SpriteFrame([
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, ZZ, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, ZZ, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, ZZ, ZZ, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, OL, OL, __, __, __, __, OL, OL, __, __, __, __, __, __],
            [__, OL, BD, BD, OL, __, __, OL, BD, BD, OL, __, __, __, __, __],
            [__, OL, BD, BD, BD, OL, OL, BD, BD, BD, OL, __, __, __, __, __],
            [__, OL, BD, OL, BD, BD, BD, BD, OL, BD, OL, __, __, __, __, __],
            [__, OL, BD, BD, BD, NS, BD, BD, BD, BD, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __, __],
            [OL, OL, BD, BD, BD, BE, BE, BD, BD, BD, OL, OL, OL, __, __, __],
            [OL, TL, OL, OL, BD, BD, BD, BD, BD, OL, OL, BD, OL, __, __, __],
            [__, OL, __, __, OL, OL, OL, OL, OL, __, __, OL, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
        ]),
    ]

    // MARK: - Running (4 frames: fast run cycle)

    static let runningFrames: [SpriteFrame] = [
        // Frame 0: fully extended
        SpriteFrame([
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, OL, OL, __, __, __, __, OL, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, OL, __, __, OL, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, OL, OL, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, EY, BD, BD, BD, BD, EY, BD, OL, __, __, __, __],
            [__, __, __, OL, BD, BD, NS, BD, BD, BD, OL, __, __, __, __, __],
            [__, __, __, __, OL, BD, BE, BE, BD, OL, __, __, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, OL, __, __, __],
            [__, OL, BD, BD, BD, BD, BD, BD, BD, BD, BD, OL, TL, OL, __, __],
            [OL, BD, OL, __, __, __, __, __, __, __, OL, BD, OL, __, __, __],
            [OL, OL, __, __, __, __, __, __, __, __, __, OL, BD, OL, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, OL, OL, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
        ]),
        // Frame 1: legs gathering
        SpriteFrame([
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, OL, OL, __, __, __, __, OL, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, OL, __, __, OL, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, OL, OL, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, EY, BD, BD, BD, BD, EY, BD, OL, __, __, __, __],
            [__, __, __, OL, BD, BD, NS, BD, BD, BD, OL, __, __, __, __, __],
            [__, __, __, __, OL, BD, BE, BE, BD, OL, __, __, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, OL, __, __, __],
            [__, __, __, OL, OL, BD, OL, OL, BD, OL, OL, TL, OL, __, __, __],
            [__, __, __, __, OL, BD, OL, OL, BD, OL, __, OL, __, __, __, __],
            [__, __, __, __, OL, OL, __, __, OL, OL, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
        ]),
        // Frame 2: fully extended (opposite)
        SpriteFrame([
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, OL, OL, __, __, __, __, OL, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, OL, __, __, OL, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, OL, OL, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, EY, BD, BD, BD, BD, EY, BD, OL, __, __, __, __],
            [__, __, __, OL, BD, BD, NS, BD, BD, BD, OL, __, __, __, __, __],
            [__, __, __, __, OL, BD, BE, BE, BD, OL, __, __, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, OL, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, OL, BD, TL, OL, __, __],
            [__, __, __, OL, BD, __, __, __, __, OL, BD, OL, OL, __, __, __],
            [__, __, OL, BD, OL, __, __, __, __, __, OL, OL, __, __, __, __],
            [__, __, OL, OL, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
        ]),
        // Frame 3: legs gathering (mirror)
        SpriteFrame([
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, OL, OL, __, __, __, __, OL, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, OL, __, __, OL, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, OL, OL, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, EY, BD, BD, BD, BD, EY, BD, OL, __, __, __, __],
            [__, __, __, OL, BD, BD, NS, BD, BD, BD, OL, __, __, __, __, __],
            [__, __, __, __, OL, BD, BE, BE, BD, OL, __, __, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, OL, __, __, __],
            [__, __, OL, OL, BD, OL, OL, OL, BD, OL, __, OL, TL, OL, __, __],
            [__, __, __, OL, BD, OL, __, OL, BD, OL, __, __, OL, __, __, __],
            [__, __, __, OL, OL, __, __, OL, OL, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
        ]),
    ]

    // MARK: - Reacting (2 frames: jump up + heart)

    static let reactingFrames: [SpriteFrame] = [
        // Frame 0: jumping up (raised position)
        SpriteFrame([
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, OL, OL, __, __, __, __, OL, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, OL, __, __, OL, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, OL, OL, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, EY, BD, BD, BD, BD, EY, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, NS, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, __, OL, BD, BU, BE, BE, BU, BD, OL, __, __, __, __, __],
            [__, __, __, __, OL, BD, BE, BE, BD, OL, __, __, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, BD, BE, BE, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, __, OL, OL, OL, __, OL, OL, OL, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
        ]),
        // Frame 1: with heart floating above
        SpriteFrame([
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, HT, __, HT, __],
            [__, __, __, __, __, __, __, __, __, __, __, HT, HT, HT, HT, HT],
            [__, __, __, OL, OL, __, __, __, __, OL, OL, HT, HT, HT, HT, HT],
            [__, __, OL, BD, BD, OL, __, __, OL, BD, BD, OL, HT, HT, HT, __],
            [__, __, OL, BD, BD, BD, OL, OL, BD, BD, BD, OL, __, HT, __, __],
            [__, __, OL, BD, EY, BD, BD, BD, BD, EY, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, NS, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, __, OL, BD, BU, BE, BE, BU, BD, OL, __, __, __, __, __],
            [__, __, __, __, OL, BD, BE, BE, BD, OL, __, __, __, __, __, __],
            [__, __, __, OL, BD, BD, BE, BE, BD, BD, OL, __, __, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, OL, BD, BD, BD, BD, BD, BD, BD, BD, OL, __, __, __, __],
            [__, __, __, OL, BD, OL, __, OL, BD, OL, __, __, __, __, __, __],
            [__, __, __, OL, OL, OL, __, OL, OL, OL, __, __, __, __, __, __],
            [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __],
        ]),
    ]
}
