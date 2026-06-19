// AppDelegate.swift
// Container App Entry Point

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let nav = UINavigationController(rootViewController: SettingsViewController())
        nav.navigationBar.prefersLargeTitles = true
        configureAppearance()
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
        return true
    }
    
    private func configureAppearance() {
        let accentColor = UIColor(red: 0.45, green: 0.30, blue: 1.00, alpha: 1)
        UINavigationBar.appearance().tintColor = accentColor
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        UINavigationBar.appearance().barTintColor = UIColor(red: 0.07, green: 0.07, blue: 0.12, alpha: 1)
        UINavigationBar.appearance().prefersLargeTitles = true
        // Dark mode forced
        if #available(iOS 13.0, *) {
            UINavigationBar.appearance().overrideUserInterfaceStyle = .dark
        }
    }
}
