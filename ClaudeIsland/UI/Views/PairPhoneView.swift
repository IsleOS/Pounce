//
//  PairPhoneView.swift
//  ClaudeIsland
//
//  QR code pairing button in settings menu + floating QR window.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - Menu Row (inside NotchMenuView)

struct PairPhoneRow: View {
    @ObservedObject var syncManager = SyncManager.shared
    @State private var isHovered = false

    var body: some View {
        Button {
            QRPairingWindow.shared.show()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(isHovered ? 1 : 0.6))
                    .frame(width: 16)

                Text("Pair iPhone")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(isHovered ? 1 : 0.7))

                Spacer()

                if syncManager.isEnabled {
                    HStack(spacing: 3) {
                        Circle().fill(Color.green).frame(width: 5, height: 5)
                        Text("Online")
                            .font(.system(size: 9))
                            .foregroundColor(.green.opacity(0.7))
                    }
                } else {
                    Image(systemName: "qrcode")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Floating QR Window

@MainActor
final class QRPairingWindow {
    static let shared = QRPairingWindow()

    private var window: NSWindow?

    func show() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let contentView = QRPairingContentView {
            self.close()
        }

        let hostingView = NSHostingView(rootView: contentView)
        let windowWidth: CGFloat = 280
        let windowHeight: CGFloat = 380
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        w.backgroundColor = .clear
        w.isOpaque = false
        w.hasShadow = true
        w.isMovableByWindowBackground = true
        w.contentView = hostingView

        // Center on screen
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            let x = screenFrame.midX - windowWidth / 2
            let y = screenFrame.midY - windowHeight / 2
            w.setFrameOrigin(NSPoint(x: x, y: y))
        }

        w.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        w.makeKeyAndOrderFront(nil)
        w.isReleasedWhenClosed = false

        // Close on click outside
        NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak w] event in
            if let window = w, !NSPointInRect(event.locationInWindow, window.contentView?.bounds ?? .zero) {
                if event.window != window {
                    self.close()
                }
            }
            return event
        }

        self.window = w
    }

    func close() {
        window?.close()
        window = nil
    }
}

// MARK: - QR Content View

private struct QRPairingContentView: View {
    let onClose: () -> Void
    @State private var qrImage: NSImage?
    @State private var deviceName = Host.current().localizedName ?? "Mac"
    @State private var isHoveringClose = false

    private var serverUrl: String {
        SyncManager.shared.serverUrl ?? "https://island.wdao.chat"
    }

    var body: some View {
        VStack(spacing: 16) {
            // Close button
            HStack {
                Spacer()
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(isHoveringClose ? 0.6 : 0.25))
                }
                .buttonStyle(.plain)
                .onHover { isHoveringClose = $0 }
            }
            .padding(.bottom, -8)

            // QR Code with integrated label
            if let qrImage {
                VStack(spacing: 10) {
                    Image(nsImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.white)
                        )
                }
            }

            // Title
            Text("Scan with CodeLight")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            // Info pills
            HStack(spacing: 8) {
                infoPill(icon: "link", text: URL(string: serverUrl)?.host ?? serverUrl)
                infoPill(icon: "desktopcomputer", text: deviceName)
            }
        }
        .padding(20)
        .frame(width: 280, height: 380)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.5), radius: 30, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
        )
        .onAppear {
            generateQRCode()
        }
    }

    private func infoPill(icon: String, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(text)
                .font(.system(size: 9))
                .lineLimit(1)
        }
        .foregroundColor(.white.opacity(0.4))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(.white.opacity(0.06)))
    }

    private func generateQRCode() {
        let payload: [String: String] = [
            "s": serverUrl,
            "k": "",
            "n": deviceName,
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(jsonString.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return }

        let scale = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: scale)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return }

        qrImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}
