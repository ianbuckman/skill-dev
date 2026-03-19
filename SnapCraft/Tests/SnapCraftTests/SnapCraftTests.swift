import Testing

@Test func basicModelCreation() {
    let item = CaptureHistoryItem(
        type: .screenshot,
        filePath: "/tmp/test.png",
        fileSize: 1024
    )
    #expect(item.type == .screenshot)
    #expect(item.filePath == "/tmp/test.png")
    #expect(item.fileSize == 1024)
}
