/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import DatadogInternal

/// An entry point to Datadog RUM feature.
public struct RUM {
    /// Enables Datadog RUM feature.
    /// - Parameters:
    ///   - configuration: configuration of the feature
    ///   - core: the instance of Datadog SDK to enable RUM in (global instance by default)
    public static func enable(
        with configuration: RUMConfiguration, in core: DatadogCoreProtocol = CoreRegistry.default
    ) {
        do {
            try enableOrThrow(with: configuration, in: core)
        } catch let error {
           consolePrint("\(error)")
       }
    }

    internal static func enableOrThrow(
        with configuration: RUMConfiguration, in core: DatadogCoreProtocol
    ) throws {
        guard !(core is NOPDatadogCore) else {
            throw ProgrammerError(
                description: "Datadog SDK must be initialized before calling `RUM.enable(with:)`."
            )
        }

        // Register RUM feature:
        let rum = try RUMFeature(in: core, configuration: configuration)
        try core.register(feature: rum)

        // If resource tracking is configured, register URLSession Instrumentation feature:
        if let urlSessionConfig = configuration.urlSessionTracking {
            let urlSessionHandler = URLSessionRUMResourcesHandler(
                dateProvider: configuration.dateProvider,
                rumAttributesProvider: urlSessionConfig.resourceAttributesProvider,
                distributedTracing: {
                    guard let firstPartyHostsConfig = urlSessionConfig.firstPartyHosts else {
                        return nil
                    }
                    return DistributedTracing(
                        sampler: Sampler(samplingRate: configuration.debugSDK ? 100 : firstPartyHostsConfig.traceSampleRate),
                        firstPartyHosts: FirstPartyHosts(firstPartyHostsConfig.hostsWithTraceHeaderTypes),
                        traceIDGenerator: firstPartyHostsConfig.traceIDGenerator
                    )
                }()
            )

            urlSessionHandler.publish(to: rum.monitor)
            try core.register(urlSessionHandler: urlSessionHandler)
        }

        if configuration.debugViews {
            consolePrint("⚠️ Overriding RUM debugging with DD_DEBUG_RUM launch argument")
            rum.monitor.debug = true
        }

        rum.monitor.notifySDKInit()
    }
}
