import XCTest
import CoreTelephony
@testable import Datadog

class CarrierInfoProviderTests: XCTestCase {
    #if os(iOS)
    func testItIsAvailableOnMobile() {
        XCTAssertNotNil(CarrierInfoProvider.getIfAvailable())
    }

    func testWhenCellularServiceIsAvailable_itReturnsCarrierInfo() {
        let serviceID = "000001"
        let telephonyNetworkInfo = CTTelephonyNetworkInfoMock(
            serviceCurrentRadioAccessTechnology: [serviceID: CTRadioAccessTechnologyLTE],
            serviceSubscriberCellularProviders: [serviceID: CTCarrierMock(carrierName: "Carrier", isoCountryCode: "US", allowsVOIP: true)]
        )

        let provider = CarrierInfoProvider(networkInfo: telephonyNetworkInfo)

        XCTAssertEqual(provider.current?.carrierName, "Carrier")
        XCTAssertEqual(provider.current?.carrierISOCountryCode, "US")
        XCTAssertEqual(provider.current?.carrierAllowsVOIP, true)
    }

    func testWhenCellularServiceIsUnavailable_itReturnsCarrierInfo() {
        let telephonyNetworkInfo = CTTelephonyNetworkInfoMock(
            serviceCurrentRadioAccessTechnology: [:],
            serviceSubscriberCellularProviders: [:]
        )

        let provider = CarrierInfoProvider(networkInfo: telephonyNetworkInfo)

        XCTAssertNil(provider.current)
    }

    func testDifferentCarrierInfoRadioAccessTechnologies() {
        func initializeFrom(coreTelephonyConstant: String) -> CarrierInfo.RadioAccessTechnology {
            return CarrierInfo.RadioAccessTechnology(ctRadioAccessTechnologyConstant: coreTelephonyConstant)
        }

        XCTAssertEqual(initializeFrom(coreTelephonyConstant: CTRadioAccessTechnologyGPRS), .GPRS)
        XCTAssertEqual(initializeFrom(coreTelephonyConstant: CTRadioAccessTechnologyEdge), .Edge)
        XCTAssertEqual(initializeFrom(coreTelephonyConstant: CTRadioAccessTechnologyWCDMA), .WCDMA)
        XCTAssertEqual(initializeFrom(coreTelephonyConstant: CTRadioAccessTechnologyHSDPA), .HSDPA)
        XCTAssertEqual(initializeFrom(coreTelephonyConstant: CTRadioAccessTechnologyHSUPA), .HSUPA)
        XCTAssertEqual(initializeFrom(coreTelephonyConstant: CTRadioAccessTechnologyCDMA1x), .CDMA1x)
        XCTAssertEqual(initializeFrom(coreTelephonyConstant: CTRadioAccessTechnologyCDMAEVDORev0), .CDMAEVDORev0)
        XCTAssertEqual(initializeFrom(coreTelephonyConstant: CTRadioAccessTechnologyCDMAEVDORevA), .CDMAEVDORevA)
        XCTAssertEqual(initializeFrom(coreTelephonyConstant: CTRadioAccessTechnologyCDMAEVDORevB), .CDMAEVDORevB)
        XCTAssertEqual(initializeFrom(coreTelephonyConstant: CTRadioAccessTechnologyeHRPD), .eHRPD)
        XCTAssertEqual(initializeFrom(coreTelephonyConstant: CTRadioAccessTechnologyLTE), .LTE)
        XCTAssertEqual(initializeFrom(coreTelephonyConstant: "invalid"), .unknown)
    }
    #else
    func testItIsNotAvailableOnOtherPlatforms() {
        XCTAssertNil(CarrierInfoProvider.getIfAvailable())
    }
    #endif
}
