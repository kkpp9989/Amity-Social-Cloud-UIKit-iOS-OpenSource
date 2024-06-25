//
//  AmityGoogleMapsViewController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 30/5/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import CoreLocation

class AmityGoogleMapsViewController: AmityViewController {
    
    // MARK: - Container View
    @IBOutlet var googleMapsView: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!

    private var searchTextField: UITextField!

    // MARK: - Properties
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var preciseLocationZoomLevel: Float = 15.0
    var placeList: [GMSAutocompleteSuggestion]? = []
    var metadata: [String: Any] = [:]
    let token = GMSAutocompleteSessionToken()
    var isSearch = false

    // The selected marker
    var selectedMarker: GMSMarker?
    
    public var tapDoneButton: (([String:Any]) -> Void)?
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?

    // MARK: - Make controller
    public static func make() -> AmityGoogleMapsViewController {
        let vc = AmityGoogleMapsViewController(nibName: AmityGoogleMapsViewController.identifier, bundle: AmityUIKitManager.bundle)
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGoogleMapsView()
        setupCustomNavigationBar()
        setupTableView()
    }
    
    func setupCustomNavigationBar() {
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
        
        // Set background app for this navigation bar
        theme?.setBackgroundApp(index: 0)
        
        // Done Button
        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        let rightItem = UIBarButtonItem(customView: doneButton)
        
        // Icon image
        let iconImageView = UIImageView(image: AmityIconSet.iconSearch)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.frame = CGRect(x: 0, y: 0, width: 15, height: 15) // Adjust size as needed
        iconImageView.layer.opacity = 0.5
        iconImageView.tintColor = .lightGray
        
        // Text Field
        let screenWidth = UIScreen.main.bounds.width
        let textFieldWidth = screenWidth - 60 - 32 // Adjusted width by use screenWidth - width of button - pedding
        
        let textField = UITextField(frame: CGRect(x: 0, y: 0, width: textFieldWidth, height: 30))
        textField.placeholder = "   Search location"
        textField.backgroundColor = .white
        textField.layer.cornerRadius = 4
        textField.clearButtonMode = .whileEditing
        textField.leftView = iconImageView
        textField.leftView?.contentMode = .center
        textField.leftViewMode = .unlessEditing
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.inputAccessoryView = UIView()
        textField.font = AmityFontSet.body
        textField.delegate = self
        searchTextField = textField
        
        // Set the items in the navigation bar
        navigationItem.rightBarButtonItems = [rightItem]
        navigationItem.titleView = searchTextField
    }
    
    private func setupGoogleMapsView() {
        // Initialize the location manager.
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()

        placesClient = GMSPlacesClient.shared()
                        
        // Check if currentLocation is available, if not, use a default location.
        let latitude = currentLocation?.coordinate.latitude ?? 13.7563
        let longitude = currentLocation?.coordinate.longitude ?? 100.5018
        
        selectedMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        
        let options = GMSMapViewOptions()
        options.frame = googleMapsView.bounds
        options.camera = GMSCameraPosition.camera(withLatitude: latitude,
                                                  longitude: longitude,
                                                  zoom: preciseLocationZoomLevel)
        
        mapView = GMSMapView.init(options: options)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.mapType = .normal
        mapView.delegate = self
        
        // Enable "My Location" button
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        
        selectedMarker?.map = mapView

        // Add the map to the view, hide it until we got a location update.
        googleMapsView.addSubview(mapView)
        mapView.isHidden = true
    }
    
    func setupTableView() {
        tableView.backgroundColor = AmityColorSet.baseInverse
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = true
        tableView.keyboardDismissMode = .onDrag
        tableView.register(AmityGooglePlacesTableViewCell.self, forCellReuseIdentifier: AmityGooglePlacesTableViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableViewHeightConstraint.constant = 0
        
        // Adjust corner radius for bottom view
        tableView.layer.cornerRadius = 16 // Adjust the value as needed
        tableView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner] // Bottom left and bottom right corners
        tableView.layer.masksToBounds = true
    }
    
    // Update the map once the user has made their selection.
    @IBAction func doneButtonTapped() {
        let alert = UIAlertController(title: "Confirm", message: "Shared this location?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: AmityLocalizedStringSet.General.ok.localizedString, style: .default) { [weak self] _ in
            guard let strongSelf = self else { return }
            // Clear the map.
            strongSelf.mapView.clear()
            
            if !strongSelf.isSearch {
                // Check if the selected marker and place are available
                if let selectedMarker = strongSelf.selectedMarker {
                    let latitude = selectedMarker.position.latitude
                    let longitude = selectedMarker.position.longitude
                    
                    // Bind metadata dictionary
                    strongSelf.metadata["location"] = [
                        "lat": latitude,
                        "lng": longitude,
                        "name": nil,
                        "address": nil,
                        "googlemap_placeId": nil
                    ]
                }
            }
            
            // call the tapDoneButton closure if it's set
            strongSelf.tapDoneButton?(strongSelf.metadata)
            strongSelf.generalDismiss()
        })
        
        present(alert, animated: true, completion: nil)
    }
                        
    @objc func backButtonTapped() {
        generalDismiss()
    }
    
    func fetchAutoComplete(text: String) {
        if text.isEmpty { return }
            
        let request = GMSAutocompleteRequest(query: text)
        request.sessionToken = token
        placesClient.fetchAutocompleteSuggestions(from: request, callback: { [weak self] (results, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                print(error)
            } else {
                strongSelf.placeList = results
                strongSelf.tableView.reloadData()
                strongSelf.updateTableViewHeight(isShow: true)
            }
        })
    }
    
    func fetchPlaceDetail(placeID: String, placeData: GMSAutocompleteSuggestion) {
        // Specify the place data types to return.
        let myProperties: [String] = ["geometry/location", "name", "formatted_address"]
        
        // Create the GMSFetchPlaceRequest object.
        let fetchPlaceRequest: GMSFetchPlaceRequest = GMSFetchPlaceRequest(placeID: placeID, placeProperties: myProperties, sessionToken: token)
        placesClient.fetchPlace(with: fetchPlaceRequest) { [weak self] place, error in
            guard let strongSelf = self else { return }
            guard let place, error == nil else { return }
            
            // Bind metadata dictionary
            strongSelf.metadata["location"] = [
                "lat": place.coordinate.latitude,
                "lng": place.coordinate.longitude,
                "name": place.name ?? placeData.placeSuggestion?.attributedPrimaryText.string ?? "",
                "address": place.formattedAddress ?? placeData.placeSuggestion?.attributedSecondaryText?.string ?? "",
                "googlemap_place_id": placeID
            ]
            
            strongSelf.updateTableViewHeight(isShow: false)
            
            let camera = GMSCameraPosition.camera(withLatitude:place.coordinate.latitude,
                                                  longitude: place.coordinate.longitude,
                                                  zoom: strongSelf.preciseLocationZoomLevel)
            strongSelf.mapView.clear()
            strongSelf.selectedMarker = GMSMarker(position: place.coordinate)
            strongSelf.selectedMarker?.map = strongSelf.mapView
            strongSelf.mapView.animate(to: camera)
            strongSelf.isSearch = true
        }
    }
    
    func updateTableViewHeight(isShow: Bool) {
        // Assuming a standard row height (adjust if necessary)
        let rowHeight: CGFloat = 80
        // Calculate the new height based on the number of results
        let newHeight = rowHeight * CGFloat(placeList?.count ?? 0)
        // Get the screen height
        let screenHeight = UIScreen.main.bounds.height
        // Ensure the new height doesn't exceed the screen height
        let maxTableHeight = screenHeight - 100 // Subtract any necessary margins or safe area
        let finalHeight = min(newHeight, maxTableHeight)
        // Update the table view height constraint
        tableViewHeightConstraint.constant = isShow ? finalHeight : 0
        // Animate the height change if needed
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: UITextField Delegate
extension AmityGoogleMapsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        fetchAutoComplete(text: textField.text ?? "")
        return true
    }
}

// MARK: Google Maps Delegate
extension AmityGoogleMapsViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        // Move the marker to the tapped location.
        if selectedMarker == nil {
            selectedMarker = GMSMarker(position: coordinate)
            selectedMarker?.map = mapView
        } else {
            selectedMarker?.position = coordinate
        }
        
        // Animate the camera to the new marker position.
        let cameraUpdate = GMSCameraUpdate.setTarget(coordinate)
        mapView.animate(with: cameraUpdate)
        
        updateTableViewHeight(isShow: false)
        isSearch = false
    }
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        updateTableViewHeight(isShow: false)
    }
}

// MARK: Delegates to handle events for the location manager.
extension AmityGoogleMapsViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        locationManager.stopUpdatingLocation()
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: preciseLocationZoomLevel)
        selectedMarker = GMSMarker(position: location.coordinate)
        selectedMarker?.map = mapView
        
//        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: preciseLocationZoomLevel, bearing: 0, viewingAngle: 0)
        
        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Check accuracy authorization
        if #available(iOS 14.0, *) {
            let accuracy = manager.accuracyAuthorization
            switch accuracy {
            case .fullAccuracy:
                print("Location accuracy is precise.")
            case .reducedAccuracy:
                print("Location accuracy is not precise.")
            @unknown default:
                fatalError()
            }
        } else {
            // Fallback on earlier versions
            manager.requestAlwaysAuthorization()
        }
        
        
        // Handle authorization status
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        @unknown default:
            fatalError()
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}

// MARK: TableView DataSource & Delegate
extension AmityGoogleMapsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return placeList?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: AmityGooglePlacesTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        guard let data = placeList?[indexPath.row] else { return UITableViewCell() }
        cell.configure(withData: data)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedData = placeList?[indexPath.row] else { return }
        searchTextField.attributedText = selectedData.placeSuggestion?.attributedPrimaryText
        fetchPlaceDetail(placeID: selectedData.placeSuggestion?.placeID ?? "", placeData: selectedData)
    }
}
