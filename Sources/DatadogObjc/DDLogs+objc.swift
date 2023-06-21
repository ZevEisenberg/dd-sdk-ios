/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import Foundation
import DatadogInternal
import DatadogLogs

@objc
public enum DDSDKVerbosityLevel: Int {
    case none
    case debug
    case warn
    case error
    case critical
}

@objc
public enum DDLogLevel: Int {
    case debug
    case info
    case notice
    case warn
    case error
    case critical

    internal init(_ swift: LogLevel) {
        switch swift {
        case .debug:    self = .debug
        case .info:     self = .info
        case .notice:   self = .notice
        case .warn:     self = .warn
        case .error:    self = .error
        case .critical: self = .critical
        }
    }

    internal var swift: LogLevel {
        switch self {
        case .debug:    return .debug
        case .info:     return .info
        case .notice:   return .notice
        case .warn:     return .warn
        case .error:    return .error
        case .critical: return .critical
        }
    }
}

@objc
public class DDLogsConfiguration: NSObject {
    internal var configuration: Logs.Configuration

    /// Sets the sampling rate for logging.
    ///
    /// The sampling rate must be a value between `0` and `100`. A value of `0` means no logs will be processed, `100`
    /// means all logs will be processed.
    ///
    /// By default sampling is disabled, meaning that all logs are being processed).
    @objc public var samplingRate: Float {
        get { configuration.samplingRate }
        set { configuration.samplingRate = newValue }
    }

    /// Overrides the custom server endpoint where Logs are sent.
    @objc public var customIntakeURL: URL? {
        get { configuration.customIntakeURL }
        set { configuration.customIntakeURL = newValue }
    }

    /// Overrides the main bundle instance.
    @objc public var bundle: Bundle {
        get { configuration.bundle }
        set { configuration.bundle = newValue }
    }

    /// Overrides the current process info.
    @objc public var processInfo: ProcessInfo {
        get { configuration.processInfo }
        set { configuration.processInfo = newValue }
    }

    /// Creates a Logs configuration object.
    ///
    /// - Parameters:
    ///   - samplingRate: The sampling rate for logging.
    ///   - customIntakeURL: Overrides the custom server endpoint where Logs are sent.
    ///   - bundle: Overrides the main bundle instance.
    ///   - processInfo: Overrides the current process info.
    @objc
    public init(
        samplingRate: Float = 100,
        customIntakeURL: URL? = nil,
        bundle: Bundle = .main,
        processInfo: ProcessInfo = .processInfo
    ) {
        configuration = .init(
            samplingRate: samplingRate,
            customIntakeURL: customIntakeURL,
            bundle: bundle,
            processInfo: processInfo
        )
    }
}

@objc
public class DDLogs: NSObject {
    @objc
    public static func enable(
        with configuration: DDLogsConfiguration = .init()
    ) {
        Logs.enable(with: configuration.configuration)
    }
}

@objc
public class DDLoggerConfiguration: NSObject {
    internal var configuration: Logger.Configuration

    /// The service name  (default value is set to application bundle identifier)
    @objc public var serviceName: String? {
        get { configuration.serviceName }
        set { configuration.serviceName = newValue }
    }

    /// The logger custom name (default value is set to main bundle identifier)
    @objc public var loggerName: String? {
        get { configuration.loggerName }
        set { configuration.loggerName = newValue }
    }

    /// Enriches logs with network connection info.
    /// This means: reachability status, connection type, mobile carrier name and many more will be added to each log.
    /// For full list of network info attributes see `NetworkConnectionInfo` and `CarrierInfo`.
    ///
    /// `false` by default
    @objc public var sendNetworkInfo: Bool {
        get { configuration.sendNetworkInfo }
        set { configuration.sendNetworkInfo = newValue }
    }

    /// Enables the logs integration with RUM.
    /// If enabled all the logs will be enriched with the current RUM View information and
    /// it will be possible to see all the logs sent during a specific View lifespan in the RUM Explorer.
    ///
    /// `true` by default
    @objc public var bundleWithRUM: Bool {
        get { configuration.bundleWithRUM }
        set { configuration.bundleWithRUM = newValue }
    }

    /// Enables the logs integration with active span API from Tracing.
    /// If enabled all the logs will be bundled with the `DatadogTracer.shared().activeSpan` trace and
    /// it will be possible to see all the logs sent during that specific trace.
    ///
    /// `true` by default
    @objc public var bundleWithTrace: Bool {
        get { configuration.bundleWithTrace }
        set { configuration.bundleWithTrace = newValue }
    }

    /// Enables logs to be sent to Datadog servers.
    /// Can be used to disable sending logs in development.
    /// See also: `printLogsToConsole(_:)`.
    ///
    /// `true` by default
    @objc public var sendLogsToDatadog: Bool {
        get { configuration.sendLogsToDatadog }
        set { configuration.sendLogsToDatadog = newValue }
    }

    /// Enables  logs to be printed to debugger console.
    ///
    /// `false` by default.
    @objc public var printLogsToConsole: Bool {
        get { configuration.consoleLogFormat != nil }
        set { configuration.consoleLogFormat = newValue ? .short : nil }
    }

    /// Set the minim log level reported to Datadog servers.
    /// Any log with a level equal or above the threshold will be sent.
    ///
    /// Note: this setting doesn't impact logs printed to the console if `printLogsToConsole(_:)`
    /// is used - all logs will be printed, no matter of their level.
    ///
    /// `DDLogLevel.debug` by default
    @objc public var datadogReportingThreshold: DDLogLevel {
        get { DDLogLevel(configuration.datadogReportingThreshold) }
        set { configuration.datadogReportingThreshold = newValue.swift }
    }

    /// Creates a Logs configuration object.
    ///
    /// - Parameters:
    ///   - samplingRate: The sampling rate for logging.
    ///   - customIntakeURL: Overrides the custom server endpoint where Logs are sent.
    ///   - bundle: Overrides the main bundle instance.
    ///   - processInfo: Overrides the current process info.
    @objc
    public init(
        serviceName: String? = nil,
        loggerName: String? = nil,
        sendNetworkInfo: Bool = false,
        bundleWithRUM: Bool = true,
        bundleWithTrace: Bool = true,
        sendLogsToDatadog: Bool = true,
        printLogsToConsole: Bool = false,
        datadogReportingThreshold: DDLogLevel = .debug
    ) {
        configuration = .init(
            serviceName: serviceName,
            loggerName: loggerName,
            sendNetworkInfo: sendNetworkInfo,
            bundleWithRUM: bundleWithRUM,
            bundleWithTrace: bundleWithTrace,
            sendLogsToDatadog: sendLogsToDatadog,
            consoleLogFormat: printLogsToConsole ? .short : nil,
            datadogReportingThreshold: datadogReportingThreshold.swift
        )
    }
}

@objc
public class DDLogger: NSObject {
    internal let sdkLogger: LoggerProtocol

    internal init(sdkLogger: LoggerProtocol) {
        self.sdkLogger = sdkLogger
    }

    // MARK: - Public

    @objc
    public func debug(_ message: String) {
        sdkLogger.debug(message)
    }

    @objc
    public func debug(_ message: String, attributes: [String: Any]) {
        sdkLogger.debug(message, attributes: castAttributesToSwift(attributes))
    }

    @objc
    public func debug(_ message: String, error: NSError, attributes: [String: Any]) {
        sdkLogger.debug(message, error: error, attributes: castAttributesToSwift(attributes))
    }

    @objc
    public func info(_ message: String) {
        sdkLogger.info(message)
    }

    @objc
    public func info(_ message: String, attributes: [String: Any]) {
        sdkLogger.info(message, attributes: castAttributesToSwift(attributes))
    }

    @objc
    public func info(_ message: String, error: NSError, attributes: [String: Any]) {
        sdkLogger.info(message, error: error, attributes: castAttributesToSwift(attributes))
    }

    @objc
    public func notice(_ message: String) {
        sdkLogger.notice(message)
    }

    @objc
    public func notice(_ message: String, attributes: [String: Any]) {
        sdkLogger.notice(message, attributes: castAttributesToSwift(attributes))
    }

    @objc
    public func notice(_ message: String, error: NSError, attributes: [String: Any]) {
        sdkLogger.notice(message, error: error, attributes: castAttributesToSwift(attributes))
    }

    @objc
    public func warn(_ message: String) {
        sdkLogger.warn(message)
    }

    @objc
    public func warn(_ message: String, attributes: [String: Any]) {
        sdkLogger.warn(message, attributes: castAttributesToSwift(attributes))
    }

    @objc
    public func warn(_ message: String, error: NSError, attributes: [String: Any]) {
        sdkLogger.warn(message, error: error, attributes: castAttributesToSwift(attributes))
    }

    @objc
    public func error(_ message: String) {
        sdkLogger.error(message)
    }

    @objc
    public func error(_ message: String, attributes: [String: Any]) {
        sdkLogger.error(message, attributes: castAttributesToSwift(attributes))
    }

    @objc
    public func error(_ message: String, error: NSError, attributes: [String: Any]) {
        sdkLogger.error(message, error: error, attributes: castAttributesToSwift(attributes))
    }

    @objc
    public func critical(_ message: String) {
        sdkLogger.critical(message)
    }

    @objc
    public func critical(_ message: String, attributes: [String: Any]) {
        sdkLogger.critical(message, attributes: castAttributesToSwift(attributes))
    }

    @objc
    public func critical(_ message: String, error: NSError, attributes: [String: Any]) {
        sdkLogger.critical(message, error: error, attributes: castAttributesToSwift(attributes))
    }

    @objc
    public func addAttribute(forKey key: String, value: Any) {
        sdkLogger.addAttribute(forKey: key, value: AnyEncodable(value))
    }

    @objc
    public func removeAttribute(forKey key: String) {
        sdkLogger.removeAttribute(forKey: key)
    }

    @objc
    public func addTag(withKey key: String, value: String) {
        sdkLogger.addTag(withKey: key, value: value)
    }

    @objc
    public func removeTag(withKey key: String) {
        sdkLogger.removeTag(withKey: key)
    }

    @objc
    public func add(tag: String) {
        sdkLogger.add(tag: tag)
    }

    @objc
    public func remove(tag: String) {
        sdkLogger.remove(tag: tag)
    }

    @objc
    public static func create(with configuration: DDLoggerConfiguration = .init()) -> DDLogger {
        return DDLogger(sdkLogger: Logger.create(with: configuration.configuration))
    }
}
