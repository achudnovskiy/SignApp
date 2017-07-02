//
//  MapViewController.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-01-20.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    var signAnnotations:[MKAnnotation] = []
    var signOverlays:[MKOverlay] = []
    let mysteryColor:UIColor = UIColor.orange.withAlphaComponent(0.5)
    let mysteryRadius:CLLocationDistance = 100

    var parentViewCenter:CGPoint!
    var parentViewBounds:CGRect!
    
    @IBOutlet weak var mapView: MKMapView!

    
    // MARK: - Helper methods
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "location"
        {
            let allAnnotations = signAnnotations + [mapView.userLocation as MKAnnotation]
            mapView.showAnnotations(allAnnotations, animated: false)
            adjustMapZoomLevel(false)
            mapView.userLocation.removeObserver(self, forKeyPath: "location")
        }
    }
    
    func adjustMapZoomLevel(_ animated:Bool)
    {
        var region = mapView.region
        region.span.latitudeDelta *= 1.5
        region.span.longitudeDelta *= 1.5
        mapView.setRegion(region, animated: animated)
        
    }
    
    // MARK: Appearance/dissapearance of the map

    func prepareMapViewToShow(locations:[SignObject])
    {
        view.bounds = parentViewBounds
        view.center.x = (-1) * parentViewCenter.x
        
        for sign in locations
        {
            if sign.isCollected
            {
                signAnnotations.append(generateAnnotationFor(sign:sign))
            }
            else
            {
                signOverlays.append(generateAnnotiationForMystery(sign:sign))
            }
        }
        
        mapView.addAnnotations(signAnnotations)
        mapView.addOverlays(signOverlays)

        mapView.showAnnotations(signAnnotations, animated: false)
        
        mapView.showsUserLocation = true
        mapView.userLocation.addObserver(self, forKeyPath: "location", options: [], context: nil)
        adjustMapZoomLevel(false)
    }
    

    
    func animateAppearance(_ completionHandler:@escaping () -> Void)
    {
        DispatchQueue.main.async
            {
                UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions(), animations: {
                    self.view.center.x = self.parentViewCenter.x
                }, completion: {(Bool) in
                    completionHandler()
                })
        }
    }
    
    func animateDissappearance(_ completionHandler:@escaping () -> Void)
    {
        DispatchQueue.main.async
            {
                UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions(), animations: {
                    self.view.center.x = (-1) * self.parentViewCenter.x
                }, completion: {(Bool) in
                    completionHandler()
                })
        }
    }
    
    func clearMapView()
    {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        mapView.showsUserLocation = false
        
        signAnnotations = []
        signOverlays = []
    }
    
    func generateAnnotationFor(sign:SignObject) -> MKPointAnnotation
    {
        let signAnnotation = MKPointAnnotation()
        signAnnotation.title = sign.locationName
        signAnnotation.coordinate = CLLocationCoordinate2D(latitude: sign.latitude, longitude: sign.longitude)
        return signAnnotation
    }
    func generateAnnotiationForMystery(sign:SignObject) -> MKCircle
    {
        let coordinate = CLLocationCoordinate2D(latitude:sign.latitude, longitude:sign.longitude)
        let circle = MKCircle(center: coordinate, radius: mysteryRadius)
        circle.title = "Mystery"
        return circle
    }
    
    //MARK:- MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKCircleRenderer(overlay: overlay)
        if overlay.title! == ("Mystery")
        {
            renderer.fillColor = mysteryColor
        }

        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        
        let annotationIdentifier = "AnnotationIdentifier"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
        if annotationView != nil {
            return annotationView
        }
        else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.canShowCallout = true
            annotationView?.image = #imageLiteral(resourceName: "MapPin").resizeTo(CGSize(width: 18, height: 40))
//            annotationView?.image = UIImage(named: "MapPin")
            return annotationView
        }
    }
}

