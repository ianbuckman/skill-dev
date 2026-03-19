import SwiftUI

struct AnnotationToolbar: View {
    @Binding var selectedTool: AnnotationTool
    @Binding var selectedColor: Color
    @Binding var lineWidth: CGFloat
    @Binding var fontSize: CGFloat
    @Binding var arrowStyle: ArrowStyle
    var onUndo: () -> Void
    var onRedo: () -> Void
    var onSave: () -> Void
    var onCopy: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            ToolSection()
            Divider().frame(height: 28).padding(.horizontal, 8)
            StyleSection()
            Divider().frame(height: 28).padding(.horizontal, 8)
            ActionSection()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func ToolSection() -> some View {
        HStack(spacing: 2) {
            ForEach(AnnotationTool.allCases) { tool in
                ToolButton(tool: tool)
            }
        }
    }

    @ViewBuilder
    private func ToolButton(tool: AnnotationTool) -> some View {
        Button {
            selectedTool = tool
        } label: {
            Image(systemName: tool.systemImage)
                .frame(width: 28, height: 28)
                .background(selectedTool == tool ? Color.accentColor.opacity(0.2) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .help(tool.rawValue)
    }

    @ViewBuilder
    private func StyleSection() -> some View {
        HStack(spacing: 8) {
            ColorPicker("", selection: $selectedColor)
                .labelsHidden()
                .frame(width: 28, height: 28)

            Picker("Width", selection: $lineWidth) {
                Text("1px").tag(CGFloat(1))
                Text("2px").tag(CGFloat(2))
                Text("3px").tag(CGFloat(3))
                Text("5px").tag(CGFloat(5))
                Text("8px").tag(CGFloat(8))
            }
            .labelsHidden()
            .frame(width: 70)

            if selectedTool == .text {
                Picker("Size", selection: $fontSize) {
                    Text("12").tag(CGFloat(12))
                    Text("16").tag(CGFloat(16))
                    Text("20").tag(CGFloat(20))
                    Text("24").tag(CGFloat(24))
                    Text("32").tag(CGFloat(32))
                    Text("48").tag(CGFloat(48))
                }
                .labelsHidden()
                .frame(width: 60)
            }

            if selectedTool == .arrow {
                Picker("Style", selection: $arrowStyle) {
                    Text("Straight").tag(ArrowStyle.straight)
                    Text("Curved").tag(ArrowStyle.curved)
                    Text("Double").tag(ArrowStyle.doubleEnded)
                    Text("Thick").tag(ArrowStyle.thick)
                }
                .labelsHidden()
                .frame(width: 80)
            }
        }
    }

    @ViewBuilder
    private func ActionSection() -> some View {
        HStack(spacing: 4) {
            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("z", modifiers: .command)

            Button(action: onRedo) {
                Image(systemName: "arrow.uturn.forward")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("z", modifiers: [.command, .shift])

            Spacer().frame(width: 8)

            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("c", modifiers: .command)

            Button(action: onSave) {
                Image(systemName: "square.and.arrow.down")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("s", modifiers: .command)
        }
    }
}
