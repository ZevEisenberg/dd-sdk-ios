/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
import DatadogInternal

public typealias RUMSessionListener = (String, Bool) -> Void

public typealias RUMViewEventMapper = (RUMViewEvent) -> RUMViewEvent
public typealias RUMErrorEventMapper = (RUMErrorEvent) -> RUMErrorEvent?
public typealias RUMResourceEventMapper = (RUMResourceEvent) -> RUMResourceEvent?
public typealias RUMActionEventMapper = (RUMActionEvent) -> RUMActionEvent?
public typealias RUMLongTaskEventMapper = (RUMLongTaskEvent) -> RUMLongTaskEvent?

public typealias URLSessionRUMAttributesProvider = (URLRequest, URLResponse?, Data?, Error?) -> [AttributeKey: AttributeValue]?

public struct RUMConfiguration {
    /// An unique identifier of the RUM application in Datadog.
    public let applicationID: String

    public var sessionSampleRate: Float = 100.0
    public var telemetrySampleRate: Float = 20.0

    public var uiKitViewsPredicate: UIKitRUMViewsPredicate? = nil
    public var uiKitActionsPredicate: UIKitRUMUserActionsPredicate? = nil

    public struct URLSessionTracking {
        public struct FirstPartyHosts {
            public var hostsWithTraceHeaderTypes: [String: Set<TracingHeaderType>] = [:]
            public var traceSampleRate: Float = 20.0

            // MARK: - Internal

            internal var traceIDGenerator: TraceIDGenerator = DefaultTraceIDGenerator()
        }

        public var firstPartyHosts: FirstPartyHosts? = nil
        public var resourceAttributesProvider: ((URLRequest, URLResponse?, Data?, Error?) -> [AttributeKey: AttributeValue]?)? = nil
    }

    public var urlSessionTracking: URLSessionTracking? = nil

    public var frustrationsTracking: Bool = true
    public var backgroundEventsTracking: Bool = false

    public var longTaskThreshold: TimeInterval? = 0.1

    /// Defines the frequency at which RUM collects mobile vitals, such as CPU and memory usage.
    public enum VitalsFrequency: String {
        /// Collect mobile vitals every 100ms.
        case frequent
        /// Collect mobile vitals every 500ms.
        case average
        /// Collect mobile vitals every 1000ms.
        case rare

        internal var timeInterval: TimeInterval {
            switch self {
            case .frequent: return 0.1
            case .average:  return 0.5
            case .rare:     return 1
            }
        }
    }

    public var vitalsUpdateFrequency: VitalsFrequency? = .average

    public var viewEventMapper: RUMViewEventMapper? = nil
    public var resourceEventMapper: RUMResourceEventMapper? = nil
    public var actionEventMapper: RUMActionEventMapper? = nil
    public var errorEventMapper: RUMErrorEventMapper? = nil
    public var longTaskEventMapper: RUMLongTaskEventMapper? = nil

    public var onSessionStart: RUMSessionListener? = nil

    public var customEndpoint: URL? = nil

    // MARK: - Internal

    /// Grants access to an internal interface utilized only by Datadog cross-platform SDKs.
    /// **It is not meant for public use** and it might change without prior notice.
    public var _internal = InternalConfiguration()

    /// An interface granting access to internal methods exclusively utilized by Datadog cross-platform SDKs.
    /// **It is not meant for public use.**
    ///
    /// Methods, members, and functionality of this interface is subject to change without prior notice,
    /// as they are not considered part of the public interface of the Datadog SDK.
    public struct InternalConfiguration {
        /// The sampling rate for configuration telemetry events. When set, it overwrites the value
        /// of `configurationTelemetrySampleRate` in `RUMConfiguration`.
        ///
        /// It is mostly used to enable or disable telemetry events when running test scenarios.
        /// Expects value between `0.0` and `100.0`.
        public var configurationTelemetrySampleRate: Float? = nil
    }

    /// An extra sampling rate for configuration telemetry events.
    ///
    /// It is applied on top of the value configured in public `telemetrySampleRate`.
    /// It can be overwritten by `InternalConfiguration`.
    internal let defaultConfigurationTelemetrySampleRate: Float = 20.0

    internal var uuidGenerator: RUMUUIDGenerator = DefaultRUMUUIDGenerator()

    internal var dateProvider: DateProvider = SystemDateProvider()

    /// Produces view update events' throttler for each started RUM view scope.
    internal var viewUpdatesThrottlerFactory: () -> RUMViewUpdatesThrottlerType = { RUMViewUpdatesThrottler() }

    internal var debugSDK: Bool = ProcessInfo.processInfo.arguments.contains("DD_DEBUG")
    internal var debugViews: Bool = ProcessInfo.processInfo.arguments.contains("DD_DEBUG_RUM")
    internal var ciTestExecutionID: String? = ProcessInfo.processInfo.environment["CI_VISIBILITY_TEST_EXECUTION_ID"]
}
