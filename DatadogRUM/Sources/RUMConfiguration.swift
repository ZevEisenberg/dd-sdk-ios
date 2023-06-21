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

public typealias RUMResourceAttributesProvider = (URLRequest, URLResponse?, Data?, Error?) -> [AttributeKey: AttributeValue]?

public struct RUMConfiguration {
    /// An unique identifier of the RUM application in Datadog.
    public let applicationID: String

    public var sessionSampleRate: Float
    public var telemetrySampleRate: Float

    public var uiKitViewsPredicate: UIKitRUMViewsPredicate?
    public var uiKitActionsPredicate: UIKitRUMUserActionsPredicate?
    public var urlSessionTracking: URLSessionTracking?

    public var frustrationsTracking: Bool
    public var backgroundEventsTracking: Bool

    public var longTaskThreshold: TimeInterval?

    public var vitalsUpdateFrequency: VitalsFrequency?

    public var viewEventMapper: RUMViewEventMapper?
    public var resourceEventMapper: RUMResourceEventMapper?
    public var actionEventMapper: RUMActionEventMapper?
    public var errorEventMapper: RUMErrorEventMapper?
    public var longTaskEventMapper: RUMLongTaskEventMapper?

    public var onSessionStart: RUMSessionListener?

    public var customEndpoint: URL?

    // MARK: - Nested Types

    public struct URLSessionTracking {
        public var firstPartyHosts: FirstPartyHosts?
        public var resourceAttributesProvider: RUMResourceAttributesProvider?

        /// Private init to avoid `invalid redeclaration of synthesized memberwise init(...:)` in extension.
        private init() {}
    }

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

    // MARK: - Additional Interface For Datadog Cross-Platform SDKs

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

    // MARK: - Internal

    /// An extra sampling rate for configuration telemetry events.
    ///
    /// It is applied on top of the value configured in public `telemetrySampleRate`.
    /// It can be overwritten by `InternalConfiguration`.
    internal let defaultConfigurationTelemetrySampleRate: Float = 20.0

    internal var uuidGenerator: RUMUUIDGenerator = DefaultRUMUUIDGenerator()

    internal var traceIDGenerator: TraceIDGenerator = DefaultTraceIDGenerator()

    internal var dateProvider: DateProvider = SystemDateProvider()

    /// Produces view update events' throttler for each started RUM view scope.
    internal var viewUpdatesThrottlerFactory: () -> RUMViewUpdatesThrottlerType = { RUMViewUpdatesThrottler() }

    internal var debugSDK: Bool = ProcessInfo.processInfo.arguments.contains("DD_DEBUG")
    internal var debugViews: Bool = ProcessInfo.processInfo.arguments.contains("DD_DEBUG_RUM")
    internal var ciTestExecutionID: String? = ProcessInfo.processInfo.environment["CI_VISIBILITY_TEST_EXECUTION_ID"]
}

extension RUMConfiguration.URLSessionTracking {
    public struct FirstPartyHosts {
        public var hostsWithTraceHeaderTypes: [String: Set<TracingHeaderType>] = [:]
        public var traceSampleRate: Float

        public init(
            hostsWithTraceHeaderTypes: [String : Set<TracingHeaderType>],
            traceSampleRate: Float = 20.0
        ) {
            self.hostsWithTraceHeaderTypes = hostsWithTraceHeaderTypes
            self.traceSampleRate = traceSampleRate
        }
    }

    public init(
        firstPartyHosts: RUMConfiguration.URLSessionTracking.FirstPartyHosts? = nil,
        resourceAttributesProvider: RUMResourceAttributesProvider? = nil
    ) {
        self.firstPartyHosts = firstPartyHosts
        self.resourceAttributesProvider = resourceAttributesProvider
    }
}

extension RUMConfiguration {
    public init(
        applicationID: String,
        sessionSampleRate: Float = 100,
        telemetrySampleRate: Float = 20,
        uiKitViewsPredicate: UIKitRUMViewsPredicate? = nil,
        uiKitActionsPredicate: UIKitRUMUserActionsPredicate? = nil,
        urlSessionTracking: URLSessionTracking? = nil,
        frustrationsTracking: Bool = true,
        backgroundEventsTracking: Bool = false,
        longTaskThreshold: TimeInterval? = 0.1,
        vitalsUpdateFrequency: VitalsFrequency? = .average,
        viewEventMapper: RUMViewEventMapper? = nil,
        resourceEventMapper: RUMResourceEventMapper? = nil,
        actionEventMapper: RUMActionEventMapper? = nil,
        errorEventMapper: RUMErrorEventMapper? = nil,
        longTaskEventMapper: RUMLongTaskEventMapper? = nil,
        onSessionStart: RUMSessionListener? = nil,
        customEndpoint: URL? = nil
    ) {
        self.applicationID = applicationID
        self.sessionSampleRate = sessionSampleRate
        self.telemetrySampleRate = telemetrySampleRate
        self.uiKitViewsPredicate = uiKitViewsPredicate
        self.uiKitActionsPredicate = uiKitActionsPredicate
        self.urlSessionTracking = urlSessionTracking
        self.frustrationsTracking = frustrationsTracking
        self.backgroundEventsTracking = backgroundEventsTracking
        self.longTaskThreshold = longTaskThreshold
        self.vitalsUpdateFrequency = vitalsUpdateFrequency
        self.viewEventMapper = viewEventMapper
        self.resourceEventMapper = resourceEventMapper
        self.actionEventMapper = actionEventMapper
        self.errorEventMapper = errorEventMapper
        self.longTaskEventMapper = longTaskEventMapper
        self.onSessionStart = onSessionStart
        self.customEndpoint = customEndpoint
    }
}

