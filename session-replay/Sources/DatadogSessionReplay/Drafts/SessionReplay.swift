/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
import Datadog

/// A draft interface for SR Feature initialization.
/// TODO: RUMM-2268 Design convenient public API
public struct SessionReplay {
    @discardableResult
    public static func initialize(
        with configuration: SessionReplayConfiguration,
        in datadogInstance: DatadogCoreProtocol = defaultDatadogCore
    ) -> SessionReplayController {
        do {
            let feature = SessionReplayFeature(configuration: configuration)
            try datadogInstance.register(feature: feature)

            guard let scope = datadogInstance.scope(for: feature.name) else {
                throw FatalError(description: "Failed to obtain `FeatureScope` for \(feature.name)")
            }

            feature.register(sessionReplayScope: scope)

            return feature
        } catch let error {
            consolePrint("\(error)")
            return NOPSessionReplayController()
        }
    }
}

/// A draft interface of SR controller.
/// TODO: RUMM-2268 Design convenient public API
public protocol SessionReplayController {
    /// Start recording.
    func start()

    /// Stop recording.
    func stop()

    /// Changes the content recording policy.
    func change(privacy: SessionReplayPrivacy)
}

internal struct NOPSessionReplayController: SessionReplayController {
    func start() {}
    func stop() {}
    func change(privacy: SessionReplayPrivacy) {}
}
