/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import XCTest
import TestUtilities

@testable import DatadogLogs
@testable import Datadog

class DatadogLogsBuilderTests: XCTestCase {
    private var core: DatadogCoreProxy! // swiftlint:disable:this implicitly_unwrapped_optional

    override func setUp() {
        super.setUp()
        core = DatadogCoreProxy(context: .mockRandom())

        let feature: LogsFeature = .mockWith(
            applicationBundleIdentifier: "com.datadog.unit-tests"
        )
        try! core.register(feature: feature)
    }

    override func tearDown() {
        core.flushAndTearDown()
        core = nil
        super.tearDown()
    }

    func testDefaultLogger() throws {
        let logger = Logger.create(in: core)

        let remoteLogger = try XCTUnwrap(logger as? RemoteLogger)
        XCTAssertNil(remoteLogger.configuration.service)
        XCTAssertEqual(remoteLogger.configuration.loggerName, "com.datadog.unit-tests")
        XCTAssertFalse(remoteLogger.configuration.sendNetworkInfo)
        XCTAssertEqual(remoteLogger.configuration.threshold, .debug)
        XCTAssertNil(remoteLogger.configuration.eventMapper)
        XCTAssertTrue(remoteLogger.rumContextIntegration)
        XCTAssertTrue(remoteLogger.activeSpanIntegration)
    }

    func testDefaultLoggerWithRUMEnabled() throws {
        let logger1 = Logger.create(in: core)
        XCTAssertTrue(try XCTUnwrap(logger1 as? RemoteLogger).rumContextIntegration)

        let logger2 = Logger.create(
            with: Logger.Configuration(
                bundleWithRUM: false
            ),
            in: core
        )
        XCTAssertFalse(try XCTUnwrap(logger2 as? RemoteLogger).rumContextIntegration)
    }

    func testDefaultLoggerWithTracingEnabled() throws {
        let logger1 = Logger.create(in: core)
        XCTAssertTrue(try XCTUnwrap(logger1 as? RemoteLogger).activeSpanIntegration)

        let logger2 = Logger.create(
            with: Logger.Configuration(
                bundleWithTrace: false
            ),
            in: core
        )
        XCTAssertFalse(try XCTUnwrap(logger2 as? RemoteLogger).activeSpanIntegration)
    }

    func testCustomizedLogger() throws {
        let logger = Logger.create(
            with: Logger.Configuration(
                serviceName: "custom-service-name",
                loggerName: "custom-logger-name",
                sendNetworkInfo: true,
                bundleWithRUM: false,
                bundleWithTrace: false,
                datadogReportingThreshold: .error
            ),
            in: core
        )

        let remoteLogger = try XCTUnwrap(logger as? RemoteLogger)
        XCTAssertEqual(remoteLogger.configuration.service, "custom-service-name")
        XCTAssertEqual(remoteLogger.configuration.loggerName, "custom-logger-name")
        XCTAssertTrue(remoteLogger.configuration.sendNetworkInfo)
        XCTAssertEqual(remoteLogger.configuration.threshold, .error)
        XCTAssertNil(remoteLogger.configuration.eventMapper)
        XCTAssertFalse(remoteLogger.rumContextIntegration)
        XCTAssertFalse(remoteLogger.activeSpanIntegration)
    }

    func testCombiningInternalLoggers() throws {
        var logger: LoggerProtocol

        logger = Logger.create(in: core)
        XCTAssertTrue(logger is RemoteLogger)

        logger = Logger.create(with: Logger.Configuration(sendLogsToDatadog: true), in: core)
        XCTAssertTrue(logger is RemoteLogger)

        logger = Logger.create(with: Logger.Configuration(sendLogsToDatadog: false), in: core)
        XCTAssertTrue(logger is NOPLogger)

        logger = Logger.create(with: Logger.Configuration(consoleLogFormat: .short), in: core)
        var combinedLogger = try XCTUnwrap(logger as? CombinedLogger)
        XCTAssertTrue(combinedLogger.combinedLoggers[0] is RemoteLogger)
        XCTAssertTrue(combinedLogger.combinedLoggers[1] is ConsoleLogger)

        logger = Logger.create(with: Logger.Configuration(consoleLogFormat: nil), in: core)
        XCTAssertTrue(logger is RemoteLogger)

        logger = Logger.create(
            with: Logger.Configuration(
                sendLogsToDatadog: true,
                consoleLogFormat: .short
            ),
            in: core
        )
        combinedLogger = try XCTUnwrap(logger as? CombinedLogger)
        XCTAssertTrue(combinedLogger.combinedLoggers[0] is RemoteLogger)
        XCTAssertTrue(combinedLogger.combinedLoggers[1] is ConsoleLogger)

        logger = Logger.create(
            with: Logger.Configuration(
                sendLogsToDatadog: false,
                consoleLogFormat: .short
            ),
            in: core
        )
        XCTAssertTrue(logger is ConsoleLogger)

        logger = Logger.create(
            with: Logger.Configuration(
                sendLogsToDatadog: true,
                consoleLogFormat: nil
            ),
            in: core
        )
        XCTAssertTrue(logger is RemoteLogger)

        logger = Logger.create(
            with: Logger.Configuration(
                sendLogsToDatadog: false,
                consoleLogFormat: nil
            ),
            in: core
        )
        XCTAssertTrue(logger is NOPLogger)
    }
}
