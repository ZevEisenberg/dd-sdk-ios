/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import Foundation

internal class RUMApplicationScope: RUMScope, RUMContextProvider {
    // MARK: - Child Scopes

    /// Session scope. It gets created with the first event.
    /// Might be re-created later according to session duration constraints.
    private(set) var sessionScope: RUMSessionScope?

    // MARK: - Initialization

    let dependencies: RUMScopeDependencies

    init(dependencies: RUMScopeDependencies) {
        self.dependencies = dependencies
        self.context = RUMContext(
            rumApplicationID: dependencies.rumApplicationID,
            sessionID: .nullUUID,
            activeViewID: nil,
            activeViewPath: nil,
            activeViewName: nil,
            activeUserActionID: nil
        )
    }

    // MARK: - RUMContextProvider

    let context: RUMContext

    // MARK: - RUMScope

    func process(command: RUMCommand, context: DatadogContext, writer: Writer) -> Bool {
        if sessionScope == nil {
            startInitialSession(context: context, writer: writer)
        }

        if let currentSession = sessionScope {
            sessionScope = sessionScope?.scope(byPropagating: command, context: context, writer: writer)

            if sessionScope == nil { // if session expired
                refresh(expiredSession: currentSession, on: command, context: context, writer: writer)
            }
        }

        return true
    }

    // MARK: - Private

    private func refresh(expiredSession: RUMSessionScope, on command: RUMCommand, context: DatadogContext, writer: Writer) {
        let refreshedSession = RUMSessionScope(from: expiredSession, startTime: command.time, context: context)
        sessionScope = refreshedSession
        sessionScopeDidUpdate(refreshedSession)
        _ = refreshedSession.process(command: command, context: context, writer: writer)
    }

    private func startInitialSession(context: DatadogContext, writer: Writer) {
        let initialSession = RUMSessionScope(
            isInitialSession: true,
            parent: self,
            startTime: context.sdkInitDate,
            dependencies: dependencies,
            isReplayBeingRecorded: context.srBaggage?.isReplayBeingRecorded
        )

        if context.applicationStateHistory.currentSnapshot.state != .background {
            // Immediately start the ApplicationLaunchView for the new session
            initialSession.startApplicationLaunchView(context: context, writer: writer)
        }

        sessionScope = initialSession
        sessionScopeDidUpdate(initialSession)
    }

    private func sessionScopeDidUpdate(_ sessionScope: RUMSessionScope) {
        let sessionID = sessionScope.sessionUUID.rawValue.uuidString
        let isDiscarded = !sessionScope.isSampled
        dependencies.onSessionStart?(sessionID, isDiscarded)
    }
}
