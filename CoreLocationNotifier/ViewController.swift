//
//  ViewController.swift
//  CoreLocationNotifier
//
//  Created by Wender Patrick on 09/03/2022.
//  Copyright © 2022 outrowender. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var locationStatusLabel: UILabel!
    @IBOutlet weak var notificationLabelStatus: UILabel!
    @IBOutlet weak var appPermissionStatusLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    let locationManager = CLLocationManager()
    var notificationsStatus: Bool = false
    var locationPermissionStatus: CLAuthorizationStatus = .denied
    
    var locations: [CLLocationCoordinate2D] = []
    
    override func viewDidLoad() {
        locationManager.delegate = self
        requestPermissions()
        includeLocations()
        
        super.viewDidLoad()
    }
    
    func includeLocations(){
        // Apple location
        locations.append(CLLocationCoordinate2D(latitude: 37.785834, longitude: -122.406417))
        
        // Mercadinho of minha rua
        locations.append(CLLocationCoordinate2D(latitude: -23.5694878, longitude: -46.7463887))
        
        // Include new locations
    }
    
    func requestPermissions(){
        locationManager.requestAlwaysAuthorization()
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            DispatchQueue.main.async {
                self.updatePermissionsUI(location: nil, notifications: granted)
            }
        }
    }
    
    //MARK: location delegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let distanceMetersRadius = 50.0
        let authorization = CLLocationManager.authorizationStatus()
        
        if authorization == CLAuthorizationStatus.authorizedWhenInUse || authorization == CLAuthorizationStatus.authorizedAlways {
            
            //Include my own location
            if let myLocation = locationManager.location?.coordinate {
                locations.append(myLocation)
            }
            
            for (index,location) in locations.enumerated() {
                let circularRegion = CLCircularRegion.init(center: location, radius: distanceMetersRadius, identifier: "location \(index)")
                
                circularRegion.notifyOnEntry = true
                circularRegion.notifyOnExit = true
                locationManager.startMonitoring(for: circularRegion)
            }
        }
        
        updatePermissionsUI(location: authorization, notifications: nil)
        
        print(locationManager.monitoredRegions)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        fireNotification(id: region.identifier, notificationText: "Arrived in \(region.identifier) region", didEnter: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
//        fireNotification(id: region.identifier, notificationText: "Exited from \(region.identifier) region", didEnter: false)
    }
    
    //MARK: notification
    func fireNotification(id: String, notificationText: String, didEnter: Bool) {
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.getNotificationSettings { (settings) in
            if settings.alertSetting == .enabled {
                let content = UNMutableNotificationContent()
                content.title = didEnter ? "Region detected" : "Left region"
                content.body = notificationText
                content.sound = UNNotificationSound.default
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                
                notificationCenter.add(request, withCompletionHandler: { (error) in
                    if error != nil {
                        // Handle the error
                    }
                })
            }
        }
    }
    
    // MARK: UI stuff
    func updatePermissionsUI(location: CLAuthorizationStatus?, notifications: Bool?){
        
        if let status = location {
            locationPermissionStatus = status
            
            switch status {
            case .restricted:
                locationStatusLabel.text = ".restricted"
                locationStatusLabel.textColor = .red
                break
            case .notDetermined:
                locationStatusLabel.text = ".notDetermined"
                locationStatusLabel.textColor = .red
                break
            case .authorizedWhenInUse:
                locationStatusLabel.text = ".authorizedWhenInUse"
                locationStatusLabel.textColor = .orange
                break
            case .authorizedAlways:
                locationStatusLabel.text = ".authorizedAlways"
                locationStatusLabel.textColor = .green
                break
            default:
                locationStatusLabel.text = ".denied"
                locationStatusLabel.textColor = .red
            }
        }
        
        if let status = notifications {
            notificationsStatus = status
            
            if status == true {
                notificationLabelStatus.text = ".granted"
                notificationLabelStatus.textColor = .green
            }else{
                notificationLabelStatus.text = ".denied"
                notificationLabelStatus.textColor = .red
            }
        }
        
        if notificationsStatus == false {
            appPermissionStatusLabel.text = "App can't notify you"
            appPermissionStatusLabel.textColor = .red
        } else {
            switch locationPermissionStatus {
            case .authorizedWhenInUse:
                appPermissionStatusLabel.text = "App will notify you only if open"
                appPermissionStatusLabel.textColor = .orange
            case .authorizedAlways:
                appPermissionStatusLabel.text = "App will notify you in always"
                appPermissionStatusLabel.textColor = .green
            default:
                appPermissionStatusLabel.text = "App can't get your location"
                appPermissionStatusLabel.textColor = .red
            }
            
        }
    }
    
    
    @IBAction func permissionButtonAction(_ sender: Any) {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }
}


