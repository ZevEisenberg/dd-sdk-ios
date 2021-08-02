/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
import UIKit

/// A class reading the refresh rate (frames per second) of the main screen
internal class VitalRefreshRateReader: ContinuousVitalReader {
    private var valuePublishers = [VitalPublisher]()

    private var displayLink: CADisplayLink?
    private var lastFrameTimestamp: CFTimeInterval?

    init(notificationCenter: NotificationCenter = .default) {
        notificationCenter.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        start()
    }

    deinit {
        stop()
    }

    /// `VitalRefreshRateReader` keeps pushing data to its `observers` at every new frame.
    /// - Parameter observer: receiver of refresh rate per frame.
    func register(_ valuePublisher: VitalPublisher) {
        DispatchQueue.main.async {
            self.valuePublishers.append(valuePublisher)
        }
    }

    /// `VitalRefreshRateReader` stops pushing data to `observer` once unregistered.
    /// - Parameter observer: already added observer; otherwise nothing happens.
    func unregister(_ valuePublisher: VitalPublisher) {
        DispatchQueue.main.async {
            self.valuePublishers.removeAll { existingPublisher in
                return existingPublisher === valuePublisher
            }
        }
    }

    // MARK: - Private

    @objc
    private func displayTick(link: CADisplayLink) {
        if let lastTimestamp = self.lastFrameTimestamp {
            let frameDuration = link.timestamp - lastTimestamp
            let currentFPS = 1.0 / frameDuration

            for publisher in valuePublishers {
                publisher.mutateAsync { currentInfo in
                    currentInfo.addSample(currentFPS)
                }
            }
        }
        lastFrameTimestamp = link.timestamp
    }

    private func start() {
        if displayLink != nil {
            return
        }

        displayLink = CADisplayLink(target: self, selector: #selector(displayTick(link:)))
        displayLink?.add(to: .main, forMode: .default)
    }

    private func stop() {
        displayLink?.invalidate()
        displayLink = nil
        lastFrameTimestamp = nil
    }

    @objc
    private func appWillResignActive() {
        stop()
    }

    @objc
    private func appDidBecomeActive() {
        start()
    }
}
