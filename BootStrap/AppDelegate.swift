//
//  AppDelegate.swift
//
//  Created by Istiak on 9/7/18.
//  Copyright © 2018 Monstar Lab Bangladesh Ltd. All rights reserved.
//

import UIKit
import Fabric
import RxFlow
import RxSwift
import RxCocoa
import XCGLogger
import Crashlytics
import Firebase
import GoogleMobileAds
import AppsFlyerLib
import IQKeyboardManagerSwift

let log: XCGLogger = {
    #if DEBUG
    let log = XCGLogger(identifier: "advancedLoggerDebug", includeDefaultDestinations: false)
    let systemDestination = AppleSystemLogDestination(identifier: XCGLogger.Constants.systemLogDestinationIdentifier)
    
    systemDestination.outputLevel = .debug
    systemDestination.showLogIdentifier = false
    systemDestination.showFunctionName = true
    systemDestination.showThreadName = true
    systemDestination.showLevel = true
    systemDestination.showFileName = true
    systemDestination.showLineNumber = true
    
    log.add(destination: systemDestination)
    log.logAppDetails()
    #else
    let log = XCGLogger(identifier: "advancedLoggerRelease", includeDefaultDestinations: false)
    let systemDestination = AppleSystemLogDestination(identifier: XCGLogger.Constants.systemLogDestinationIdentifier)
    
    systemDestination.outputLevel = .severe
    systemDestination.showLogIdentifier = true
    systemDestination.showFunctionName = true
    systemDestination.showThreadName = true
    systemDestination.showLevel = true
    systemDestination.showFileName = true
    systemDestination.showLineNumber = true
    
    log.add(destination: systemDestination)
    log.logAppDetails()
    #endif
    
    return log
}()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let disposeBag = DisposeBag()
    let coordinator = Coordinator()
    let dynamicLinkCoordinator = Coordinator()
    let preferenceService = PreferencesService()
    let keyManager = KeyManager()
    var appFlow: AppFlow!
    weak var currentFlow: Flow!
    
    lazy var appServices = {
        return AppServices(preferencesService: self.preferenceService)
    }()

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        setupCrashlytics()
        setupFirebase()
        setupGoogleAnalytics()
        setupAdMob()
        setupAppsFlyer()
        IQKeyboardManager.shared.enable = true
        #if DEV && STG
        DeployGateSDK.sharedInstance().launchApplication(withAuthor: "BootStrap", key: "d1b3b630a30c1393ed8954b3c65d5d2f83d07641")
        #endif
        
        guard let window = self.window else { return false }
        coordinator.rx.didNavigate.subscribe(onNext: {[weak self] (flow, step) in
            self?.currentFlow = flow
            print ("did navigate to flow=\(flow) and step=\(step)")
        }).disposed(by: self.disposeBag)
        
        self.appFlow = AppFlow(withWindow: window, andServices: self.appServices)
        coordinator.coordinate(flow: self.appFlow, withStepper: AppStepper(withServices: self.appServices))

//        _ = Observable<Int>.interval(1, scheduler: MainScheduler.instance)
//            .subscribe(onNext: { _ in
//                print("Resource count \(RxSwift.Resources.total)")
//            })

        return true
    }
    
    var canCoordinateToDLFlow: Bool {
        return preferenceService.didSplash()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        AppsFlyerTracker.shared().trackAppLaunch()
    }

    func applicationWillTerminate(_ application: UIApplication) {

    }

    func setupCrashlytics() {
       Fabric.with([Crashlytics.self])
    }

    func setupFirebase() {
        FirebaseApp.configure()
    }

    func setupGoogleAnalytics() {
        guard let gai = GAI.sharedInstance() else {
            assert(false, "Google Analytics not configured correctly")
            return
        }
        gai.tracker(withTrackingId: keyManager.provideGoogleAnalyticsID())
        // Optional: automatically report uncaught exceptions.
        gai.trackUncaughtExceptions = true

        // Optional: set Logger to VERBOSE for debug information.
        // Remove before app release.
        gai.logger.logLevel = .verbose
    }

    func setupAdMob() {
        let addMobAppID = keyManager.provideAdMobAppID()
        GADMobileAds.configure(withApplicationID:addMobAppID)
    }

    func setupAppsFlyer() {
        let appsFlyerDevKey = keyManager.provideAppsFlyerDevKey()
        let appleAppID = keyManager.provideAppAppleID()
        AppsFlyerTracker.shared().appsFlyerDevKey = appsFlyerDevKey
        AppsFlyerTracker.shared().appleAppID = appleAppID
        AppsFlyerTracker.shared().delegate = self
        #if DEBUG
        AppsFlyerTracker.shared().isDebug = true
        #endif
    }

}

extension AppDelegate: AppsFlyerTrackerDelegate {

}
