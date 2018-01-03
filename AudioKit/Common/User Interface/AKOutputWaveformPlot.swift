//
//  AKOutputWaveformPlot
//  AudioKitUI
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2017 AudioKit. All rights reserved.
//

extension Notification.Name {
    static let IAAConnected = Notification.Name(rawValue: "IAAConnected")
    static let IAADisconnected = Notification.Name(rawValue: "IAADisconnected")
}

/// Wrapper class for plotting audio from the final mix in a waveform plot
@IBDesignable
open class AKOutputWaveformPlot: EZAudioPlot {

    public var isConnected = false

    internal func setupNode() {
        if !isConnected {
            AudioKit.engine.outputNode.installTap(onBus: 0,
                                                  bufferSize: bufferSize,
                                                  format: nil) { [weak self] (buffer, _) in
                                                    guard let strongSelf = self else {
                                                        AKLog("Unable to create strong ref to self")
                                                        return
                                                    }
                                                    buffer.frameLength = strongSelf.bufferSize
                                                    let offset = Int(buffer.frameCapacity - buffer.frameLength)
                                                    if let tail = buffer.floatChannelData?[0] {
                                                        strongSelf.updateBuffer(&tail[offset],
                                                                                withBufferSize: strongSelf.bufferSize)
                                                    }
            }
            isConnected = true
        }
    }

    // Useful to reconnect after connecting to Audiobus or IAA
    @objc func reconnect() {
        AudioKit.engine.outputNode.removeTap(onBus: 0)
        setupNode()
    }

    @objc open func pause() {
        if isConnected {
            AudioKit.engine.outputNode.removeTap(onBus: 0)
            isConnected = false
        }
    }

    @objc open func resume() {
        setupNode()
    }

    func setupReconnection() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reconnect),
                                               name: .IAAConnected,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reconnect),
                                               name: .IAADisconnected,
                                               object: nil)
    }

    internal var bufferSize: UInt32 = 1_024

    deinit {
        AudioKit.engine.outputNode.removeTap(onBus: 0)
    }

    /// Initialize the plot in a frame
    ///
    /// - parameter frame: CGRect in which to draw the plot
    ///
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupNode()
        setupReconnection()
    }

    /// Initialize the plot in a frame with a different buffer size
    ///
    /// - Parameters:
    ///   - frame: CGRect in which to draw the plot
    ///   - bufferSize: size of the buffer - raise this number if the device struggles with generating the waveform
    ///
    @objc public init(frame: CGRect, bufferSize: Int) {
        super.init(frame: frame)
        self.bufferSize = UInt32(bufferSize)
        setupNode()
        setupReconnection()
    }

    /// Required coder-based initialization (for use with Interface Builder)
    ///
    /// - parameter coder: NSCoder
    ///
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupNode()
        setupReconnection()
    }

    /// Create a View with the plot (usually for playgrounds)
    ///
    /// - Parameters:
    ///   - width: Width of the view
    ///   - height: Height of the view
    ///
    open static func createView(width: CGFloat = 440, height: CGFloat = 200.0) -> AKView {

        let frame = CGRect(x: 0.0, y: 0.0, width: width, height: height)
        let plot = AKOutputWaveformPlot(frame: frame)

        plot.plotType = .buffer
        plot.backgroundColor = AKColor.clear
        plot.shouldCenterYAxis = true

        let containerView = AKView(frame: frame)
        containerView.addSubview(plot)
        return containerView
    }
}
