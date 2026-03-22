import Foundation

// MARK: - ClipboardContent

enum ClipboardContent: Codable, Hashable, Sendable {
    case text(String)
    case image(Data)
}

// MARK: - ClipboardItem

struct ClipboardItem: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let content: ClipboardContent
    let timestamp: Date
    var isPinned: Bool

    init(id: UUID = UUID(), content: ClipboardContent, isPinned: Bool = false, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isPinned = isPinned
        self.timestamp = timestamp
    }

    /// A short preview string for display purposes.
    /// Text items return the first 100 characters; image items return a size description.
    var preview: String {
        switch content {
        case .text(let string):
            return String(string.prefix(100))
        case .image(let data):
            if let size = imagePixelSize(from: data) {
                return "Image (\(size.width)x\(size.height))"
            }
            return "Image (\(data.count) bytes)"
        }
    }

    /// Extracts text content for search. Returns `nil` for image items.
    var textContent: String? {
        switch content {
        case .text(let string):
            return string
        case .image:
            return nil
        }
    }
}

// MARK: - Image Size Helpers

private func imagePixelSize(from data: Data) -> (width: Int, height: Int)? {
    if let size = pngSize(from: data) { return size }
    if let size = jpegSize(from: data) { return size }
    if let size = gif89aSize(from: data) { return size }
    if let size = bmpSize(from: data) { return size }
    if let size = tiffSize(from: data) { return size }
    return nil
}

/// PNG: width at bytes 16–19, height at 20–23 (big-endian UInt32).
private func pngSize(from data: Data) -> (width: Int, height: Int)? {
    let pngHeader: [UInt8] = [0x89, 0x50, 0x4E, 0x47]
    guard data.count >= 24,
          data.prefix(4).elementsEqual(pngHeader) else { return nil }
    let width = data.bigEndianUInt32(at: 16)
    let height = data.bigEndianUInt32(at: 20)
    return (Int(width), Int(height))
}

/// JPEG: search for SOF0/SOF2 marker (0xFF 0xC0 / 0xFF 0xC2).
private func jpegSize(from data: Data) -> (width: Int, height: Int)? {
    guard data.count >= 2,
          data[data.startIndex] == 0xFF,
          data[data.startIndex + 1] == 0xD8 else { return nil }

    var offset = 2
    while offset + 9 < data.count {
        guard data[data.startIndex + offset] == 0xFF else { break }
        let marker = data[data.startIndex + offset + 1]
        if marker == 0xC0 || marker == 0xC2 {
            let height = data.bigEndianUInt16(at: offset + 5)
            let width = data.bigEndianUInt16(at: offset + 7)
            return (Int(width), Int(height))
        }
        let segmentLength = Int(data.bigEndianUInt16(at: offset + 2))
        offset += 2 + segmentLength
    }
    return nil
}

/// GIF: width/height at bytes 6–9 (little-endian UInt16).
private func gif89aSize(from data: Data) -> (width: Int, height: Int)? {
    guard data.count >= 10 else { return nil }
    let gif87 = Data("GIF87a".utf8)
    let gif89 = Data("GIF89a".utf8)
    let header = data.prefix(6)
    guard header == gif87 || header == gif89 else { return nil }
    let width = data.littleEndianUInt16(at: 6)
    let height = data.littleEndianUInt16(at: 8)
    return (Int(width), Int(height))
}

/// BMP: width at 18–21, height at 22–25 (little-endian Int32, height can be negative).
private func bmpSize(from data: Data) -> (width: Int, height: Int)? {
    guard data.count >= 26,
          data[data.startIndex] == 0x42,     // 'B'
          data[data.startIndex + 1] == 0x4D  // 'M'
    else { return nil }
    let width = data.littleEndianUInt32(at: 18)
    let rawHeight = data.littleEndianInt32(at: 22)
    return (Int(width), abs(Int(rawHeight)))
}

/// TIFF: byte-order aware width/height from first IFD.
private func tiffSize(from data: Data) -> (width: Int, height: Int)? {
    guard data.count >= 8 else { return nil }
    let isLittle: Bool
    if data[data.startIndex] == 0x49, data[data.startIndex + 1] == 0x49 {
        isLittle = true
    } else if data[data.startIndex] == 0x4D, data[data.startIndex + 1] == 0x4D {
        isLittle = false
    } else {
        return nil
    }

    func readU16(_ offset: Int) -> UInt16 {
        isLittle ? data.littleEndianUInt16(at: offset) : data.bigEndianUInt16(at: offset)
    }
    func readU32(_ offset: Int) -> UInt32 {
        isLittle ? data.littleEndianUInt32(at: offset) : data.bigEndianUInt32(at: offset)
    }

    let ifdOffset = Int(readU32(4))
    guard ifdOffset + 2 <= data.count else { return nil }
    let entryCount = Int(readU16(ifdOffset))
    var width: Int?
    var height: Int?

    for i in 0..<entryCount {
        let entryStart = ifdOffset + 2 + i * 12
        guard entryStart + 12 <= data.count else { break }
        let tag = readU16(entryStart)
        let valueType = readU16(entryStart + 2)
        let value: Int
        if valueType == 3 { // SHORT
            value = Int(readU16(entryStart + 8))
        } else {
            value = Int(readU32(entryStart + 8))
        }
        if tag == 256 { width = value }
        if tag == 257 { height = value }
        if width != nil, height != nil { break }
    }
    guard let w = width, let h = height else { return nil }
    return (w, h)
}

// MARK: - Data Extensions

private extension Data {
    func bigEndianUInt32(at offset: Int) -> UInt32 {
        let start = startIndex + offset
        return UInt32(self[start]) << 24
            | UInt32(self[start + 1]) << 16
            | UInt32(self[start + 2]) << 8
            | UInt32(self[start + 3])
    }

    func bigEndianUInt16(at offset: Int) -> UInt16 {
        let start = startIndex + offset
        return UInt16(self[start]) << 8 | UInt16(self[start + 1])
    }

    func littleEndianUInt16(at offset: Int) -> UInt16 {
        let start = startIndex + offset
        return UInt16(self[start]) | UInt16(self[start + 1]) << 8
    }

    func littleEndianUInt32(at offset: Int) -> UInt32 {
        let start = startIndex + offset
        return UInt32(self[start])
            | UInt32(self[start + 1]) << 8
            | UInt32(self[start + 2]) << 16
            | UInt32(self[start + 3]) << 24
    }

    func littleEndianInt32(at offset: Int) -> Int32 {
        Int32(bitPattern: littleEndianUInt32(at: offset))
    }
}
