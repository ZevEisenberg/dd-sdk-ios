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

public struct RUMConfiguration2 {
    /// An unique identifier of the RUM application in Datadog app.
    public let applicationID: String


    public var sessionSampleRate: Float = 100.0
    public var telemetrySampleRate: Float = 20.0

    public var viewEventMapper: RUMViewEventMapper? = nil
    public var resourceEventMapper: RUMResourceEventMapper? = nil
    public var actionEventMapper: RUMActionEventMapper? = nil
    public var errorEventMapper: RUMErrorEventMapper? = nil
    public var longTaskEventMapper: RUMLongTaskEventMapper? = nil

    public var uiKitViewsPredicate: UIKitRUMViewsPredicate? = nil
    public var uiKitActionsPredicate: UIKitRUMUserActionsPredicate? = nil

    public struct URLSessionTracking {
        public struct FirstPartyHosts {
            public var hostsWithTraceHeaderTypes: [String: Set<TracingHeaderType>]
            public var traceSampleRate: Float = 20.0
        }

        public var firstPartyHosts: FirstPartyHosts? = nil
        public var resourceAttributesProvider: ((URLRequest, URLResponse?, Data?, Error?) -> [AttributeKey: AttributeValue]?)? = nil
    }

    public var urlSessionTracking: URLSessionTracking? = nil

    public var longTaskThreshold: TimeInterval? = nil

    /// https://github.com/DataDog/dd-sdk-android/blob/feature/sdkv2/features/dd-sdk-android-rum/src/main/kotlin/com/datadog/android/rum/configuration/VitalsUpdateFrequency.kt
    /// Defines the frequency at which RUM collects mobile vitals, such as CPU and memory usage.
    public enum VitalsFrequency: String {
        /// Collect mobile vitals every 100ms.
        case frequent
        /// Collect mobile vitals every 500ms.
        case average
        /// Collect mobile vitals every 1000ms.
        case rare
        /// Don't provide mobile vitals.
        case never
    }

    public var vitalsUpdateFrequency: VitalsFrequency = .average

    public var frustrationsTracking: Bool = true
    public var backgroundEventsTracking: Bool = false
    public var sessionListener: RUMSessionListener? = nil

    public var customEndpoint: URL? = nil

    /// Grants access to an internal interface utilized only by Datadog cross-platform SDKs.
    /// **It is not meant for public use** and it might change without prior notice.
    public var _internal = RUMInternalConfiguration()

    /// An extra sampling rate for configuration telemetry events.
    ///
    /// It is applied on top of the value configured in public `telemetrySampleRate`.
    /// It can be overwritten by cross-platform SDKs - see `RUMConfigurationInternal`.
    internal let configurationTelemetrySampleRate: Float = 20.0
}

/// An interface granting access to internal methods exclusively utilized by Datadog cross-platform SDKs.
/// **It is not meant for public use.**
///
/// Methods, members, and functionality of this interface is subject to change without prior notice,
/// as they are not considered part of the public interface of the Datadog SDK.
public struct RUMInternalConfiguration {
    /// The sampling rate for configuration telemetry events. When set, it overwrites the value
    /// of `configurationTelemetrySampleRate` in `RUMConfiguration`.
    ///
    /// It is mostly used to enable or disable telemetry events when running test scenarios.
    /// Expects value between `0.0` and `100.0`.
    public var configurationTelemetrySampleRate: Float? = nil
}


public struct RUMConfiguration {
    public struct Instrumentation {
        public let uiKitRUMViewsPredicate: UIKitRUMViewsPredicate?
        public let uiKitRUMUserActionsPredicate: UIKitRUMUserActionsPredicate?
        public let longTaskThreshold: TimeInterval?

        public init(
            uiKitRUMViewsPredicate: UIKitRUMViewsPredicate? = nil,
            uiKitRUMUserActionsPredicate: UIKitRUMUserActionsPredicate? = nil,
            longTaskThreshold: TimeInterval? = nil
        ) {
            self.uiKitRUMViewsPredicate = uiKitRUMViewsPredicate
            self.uiKitRUMUserActionsPredicate = uiKitRUMUserActionsPredicate
            self.longTaskThreshold = longTaskThreshold
        }
    }

    /* ✅ internal */ public var customIntakeURL: URL?
    /* ✅ internal */ public let applicationID: String
    /* ✅ internal */ public var sessionSampler: Sampler
    /* ✅ internal */ public var telemetrySampler: Sampler
    /* ❌ internal */ public var configurationTelemetrySampler: Sampler
    /* ✅ internal */ public var viewEventMapper: RUMViewEventMapper?
    /* ✅ internal */ public var resourceEventMapper: RUMResourceEventMapper?
    /* ✅ internal */ public var actionEventMapper: RUMActionEventMapper?
    /* ✅ internal */ public var errorEventMapper: RUMErrorEventMapper?
    /* ✅ internal */ public var longTaskEventMapper: RUMLongTaskEventMapper?
    /// RUM auto instrumentation configuration, `nil` if not enabled.
    /* ✅ internal */ public var instrumentation: Instrumentation
    /* ✅ internal */ public var backgroundEventTrackingEnabled: Bool
    /* ✅ internal */ public var frustrationTrackingEnabled: Bool
    /* ✅ internal */ public var onSessionStart: RUMSessionListener?
    /* ✅ internal */ public var firstPartyHosts: FirstPartyHosts?
    /* ✅ internal */ public var tracingSampler: Sampler
    /* ❌ internal */ public var traceIDGenerator: TraceIDGenerator
    /// An optional RUM Resource attributes provider.
    /* ✅ internal */ public var rumAttributesProvider: URLSessionRUMAttributesProvider?
    /* ✅ internal */ public var vitalsFrequency: TimeInterval?
    /* ❌ internal */ public var dateProvider: DateProvider
    /* ❌ internal */ public var testExecutionId: String?
    /* ❌ internal */ public var processInfo: ProcessInfo

    let uuidGenerator: RUMUUIDGenerator

    public init(
        applicationID: String,
        sessionSampler: Sampler = Sampler(samplingRate: 100),
        telemetrySampler: Sampler = Sampler(samplingRate: 20),
        configurationTelemetrySampler: Sampler = Sampler(samplingRate: 20),
        viewEventMapper: RUMViewEventMapper? = nil,
        resourceEventMapper: RUMResourceEventMapper? = nil,
        actionEventMapper: RUMActionEventMapper? = nil,
        errorEventMapper: RUMErrorEventMapper? = nil,
        longTaskEventMapper: RUMLongTaskEventMapper? = nil,
        instrumentation: Instrumentation = .init(),
        backgroundEventTrackingEnabled: Bool = false,
        frustrationTrackingEnabled: Bool = true,
        onSessionStart: RUMSessionListener? = nil,
        firstPartyHosts: FirstPartyHosts? = nil,
        tracingSampler: Sampler = Sampler(samplingRate: 20),
        traceIDGenerator: TraceIDGenerator = DefaultTraceIDGenerator(),
        rumAttributesProvider: URLSessionRUMAttributesProvider? = nil,
        vitalsFrequency: TimeInterval? = nil,
        dateProvider: DateProvider = SystemDateProvider(),
        customIntakeURL: URL? = nil,
        testExecutionId: String? = nil,
        processInfo: ProcessInfo = .processInfo
    ) {
        self.customIntakeURL = customIntakeURL
        self.applicationID = applicationID
        self.sessionSampler = sessionSampler
        self.telemetrySampler = telemetrySampler
        self.configurationTelemetrySampler = configurationTelemetrySampler
        self.uuidGenerator = DefaultRUMUUIDGenerator()
        self.viewEventMapper = viewEventMapper
        self.resourceEventMapper = resourceEventMapper
        self.actionEventMapper = actionEventMapper
        self.errorEventMapper = errorEventMapper
        self.longTaskEventMapper = longTaskEventMapper
        self.instrumentation = instrumentation
        self.backgroundEventTrackingEnabled = backgroundEventTrackingEnabled
        self.frustrationTrackingEnabled = frustrationTrackingEnabled
        self.onSessionStart = onSessionStart
        self.firstPartyHosts = firstPartyHosts
        self.tracingSampler = tracingSampler
        self.traceIDGenerator = traceIDGenerator
        self.rumAttributesProvider = rumAttributesProvider
        self.vitalsFrequency = vitalsFrequency
        self.dateProvider = dateProvider
        self.testExecutionId = testExecutionId
        self.processInfo = processInfo
    }

    init(
        applicationID: String,
        uuidGenerator: RUMUUIDGenerator = DefaultRUMUUIDGenerator(),
        sessionSampler: Sampler = Sampler(samplingRate: 100),
        telemetrySampler: Sampler = Sampler(samplingRate: 20),
        configurationTelemetrySampler: Sampler = Sampler(samplingRate: 20),
        viewEventMapper: RUMViewEventMapper? = nil,
        resourceEventMapper: RUMResourceEventMapper? = nil,
        actionEventMapper: RUMActionEventMapper? = nil,
        errorEventMapper: RUMErrorEventMapper? = nil,
        longTaskEventMapper: RUMLongTaskEventMapper? = nil,
        instrumentation: Instrumentation = .init(),
        backgroundEventTrackingEnabled: Bool = false,
        frustrationTrackingEnabled: Bool = true,
        onSessionStart: RUMSessionListener? = nil,
        firstPartyHosts: FirstPartyHosts? = nil,
        tracingSampler: Sampler = Sampler(samplingRate: 20),
        traceIDGenerator: TraceIDGenerator = DefaultTraceIDGenerator(),
        rumAttributesProvider: URLSessionRUMAttributesProvider? = nil,
        vitalsFrequency: TimeInterval? = nil,
        dateProvider: DateProvider = SystemDateProvider(),
        customIntakeURL: URL? = nil,
        testExecutionId: String? = nil,
        processInfo: ProcessInfo = .processInfo
    ) {
        self.customIntakeURL = customIntakeURL
        self.applicationID = applicationID
        self.sessionSampler = sessionSampler
        self.telemetrySampler = telemetrySampler
        self.configurationTelemetrySampler = configurationTelemetrySampler
        self.uuidGenerator = uuidGenerator
        self.viewEventMapper = viewEventMapper
        self.resourceEventMapper = resourceEventMapper
        self.actionEventMapper = actionEventMapper
        self.errorEventMapper = errorEventMapper
        self.longTaskEventMapper = longTaskEventMapper
        self.instrumentation = instrumentation
        self.backgroundEventTrackingEnabled = backgroundEventTrackingEnabled
        self.frustrationTrackingEnabled = frustrationTrackingEnabled
        self.onSessionStart = onSessionStart
        self.firstPartyHosts = firstPartyHosts
        self.tracingSampler = tracingSampler
        self.traceIDGenerator = traceIDGenerator
        self.rumAttributesProvider = rumAttributesProvider
        self.vitalsFrequency = vitalsFrequency
        self.dateProvider = dateProvider
        self.testExecutionId = testExecutionId
        self.processInfo = processInfo
    }
}
