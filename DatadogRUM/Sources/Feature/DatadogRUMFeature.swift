/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
import DatadogInternal

internal typealias RUMFeature = DatadogRUMFeature

// TODO: RUMM-2922 Rename to `RUMFeature`
internal final class DatadogRUMFeature: DatadogRemoteFeature {
    static let name = "rum"

    let requestBuilder: FeatureRequestBuilder

    let messageReceiver: FeatureMessageReceiver

    let monitor: Monitor

    let instrumentation: RUMInstrumentation

    let telemetry: TelemetryCore

    internal struct LaunchArguments {
        static let DebugRUM = "DD_DEBUG_RUM"
    }

    convenience init(
        in core: DatadogCoreProtocol,
        configuration: RUMConfiguration
    ) throws {
        let dependencies = RUMScopeDependencies(
            core: core,
            rumApplicationID: configuration.applicationID,
            sessionSampler: Sampler(samplingRate: configuration.debugSDK ? 100 : configuration.sessionSampleRate),
            backgroundEventTrackingEnabled: configuration.backgroundEventsTracking,
            frustrationTrackingEnabled: configuration.frustrationsTracking,
            firstPartyHosts: configuration.urlSessionTracking?.firstPartyHosts
                .map { FirstPartyHosts($0.hostsWithTraceHeaderTypes) },
            eventBuilder: RUMEventBuilder(
                eventsMapper: RUMEventsMapper(
                    viewEventMapper: configuration.viewEventMapper,
                    errorEventMapper: configuration.errorEventMapper,
                    resourceEventMapper: configuration.resourceEventMapper,
                    actionEventMapper: configuration.actionEventMapper,
                    longTaskEventMapper: configuration.longTaskEventMapper
                )
            ),
            rumUUIDGenerator: configuration.uuidGenerator,
            ciTest: configuration.ciTestExecutionID.map { RUMCITest(testExecutionId: $0) },
            viewUpdatesThrottlerFactory: configuration.viewUpdatesThrottlerFactory,
            vitalsReaders: configuration.vitalsUpdateFrequency.map { VitalsReaders(frequency: $0.timeInterval) },
            onSessionStart: configuration.onSessionStart
        )

        try self.init(
            in: core,
            configuration: configuration,
            with: Monitor(core: core, dependencies: dependencies, dateProvider: configuration.dateProvider)
        )
    }

    private init(
        in core: DatadogCoreProtocol,
        configuration: RUMConfiguration,
        with monitor: Monitor
    ) throws {
        self.monitor = monitor
        self.instrumentation = RUMInstrumentation(
            uiKitRUMViewsPredicate: configuration.uiKitViewsPredicate,
            uiKitRUMActionsPredicate: configuration.uiKitActionsPredicate,
            longTaskThreshold: configuration.longTaskThreshold,
            dateProvider: configuration.dateProvider
        )
        self.requestBuilder = RequestBuilder(customIntakeURL: configuration.customEndpoint)
        self.messageReceiver = CombinedFeatureMessageReceiver(
            TelemetryReceiver(
                dateProvider: configuration.dateProvider,
                sampler: Sampler(samplingRate: configuration.telemetrySampleRate),
                configurationExtraSampler: Sampler(
                    samplingRate: configuration._internal.configurationTelemetrySampleRate ?? configuration.defaultConfigurationTelemetrySampleRate
                )
            ),
            ErrorMessageReceiver(monitor: monitor),
            WebViewEventReceiver(
                dateProvider: configuration.dateProvider,
                commandSubscriber: monitor
            ),
            CrashReportReceiver(
                applicationID: configuration.applicationID,
                dateProvider: configuration.dateProvider,
                sessionSampler: Sampler(samplingRate: configuration.debugSDK ? 100 : configuration.sessionSampleRate),
                backgroundEventTrackingEnabled: configuration.backgroundEventsTracking,
                uuidGenerator: configuration.uuidGenerator,
                ciTest: configuration.ciTestExecutionID.map { RUMCITest(testExecutionId: $0) }
            )
        )
        self.telemetry = TelemetryCore(core: core)

        // Forward instrumentation calls to monitor:
        instrumentation.publish(to: monitor)

        // Send configuration telemetry:
        telemetry.configuration(
            mobileVitalsUpdatePeriod: configuration.vitalsUpdateFrequency?.timeInterval.toInt64Milliseconds,
            sessionSampleRate: Int64(withNoOverflow: configuration.sessionSampleRate),
            telemetrySampleRate: Int64(withNoOverflow: configuration.telemetrySampleRate),
            traceSampleRate: configuration.urlSessionTracking?.firstPartyHosts.map { Int64(withNoOverflow: $0.traceSampleRate) },
            trackBackgroundEvents: configuration.backgroundEventsTracking,
            trackFrustrations: configuration.frustrationsTracking,
            trackInteractions: configuration.uiKitActionsPredicate != nil,
            trackLongTask: configuration.longTaskThreshold != nil,
            trackNativeLongTasks: configuration.longTaskThreshold != nil,
            trackNativeViews: configuration.uiKitViewsPredicate != nil,
            trackNetworkRequests: configuration.urlSessionTracking != nil,
            useFirstPartyHosts: configuration.urlSessionTracking?.firstPartyHosts.map { !$0.hostsWithTraceHeaderTypes.isEmpty }
        )
    }
}

extension DatadogRUMFeature: Flushable {
    /// Awaits completion of all asynchronous operations.
    ///
    /// **blocks the caller thread**
    func flush() {
        monitor.flush()
    }
}
