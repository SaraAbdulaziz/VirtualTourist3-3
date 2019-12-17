import UIKit
import MapKit
import CoreData

class LocationViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    var dController:DataController!
    
    var anno = [MKAnnotation]()
    
    var pSelected: Pin!
    
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    fileprivate func setUpFetchedResultsController() {
        
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dController.viewContext, sectionNameKeyPath: nil, cacheName: "PinData")
        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch()
        }catch{
            fatalError("The fetch could not be performed : \(error.localizedDescription)")
        }
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let longGesture = UILongPressGestureRecognizer(target: self, action:
            #selector(longTap(_:)))
        mapView.addGestureRecognizer(longGesture)
        setUpFetchedResultsController()
        showPinsOnMapWhenAppStart()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setUpFetchedResultsController()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "toPhoto" ) {
            if let vc = segue.destination as? PhotoController {
                
                vc.dataController = dController
                vc.p = pSelected
                
            }
        }
        
        
    }
    
    
    func showPinsOnMapWhenAppStart(){
        
        
        if let lastPin = fetchedResultsController.fetchedObjects?.first {
            zoomToLastPin(lastPin: lastPin)
            
        }
        
        
        for loc in fetchedResultsController.fetchedObjects! {
            
            let lat = loc.lat
            let long = loc.long
            
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            let annot = MKPointAnnotation()
            annot.coordinate = coordinate
            
            self.anno.append(annot)
            
        }
        DispatchQueue.main.async {
            self.mapView.addAnnotations(self.anno)
            
        }
        
    }
    
    
    func zoomToLastPin(lastPin:Pin){
        
        
        let coredinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(lastPin.coordinate.latitude, lastPin.coordinate.longitude)
        
        let spn = MKCoordinateSpan(latitudeDelta: 3.0, longitudeDelta: 3.0)
        let region = MKCoordinateRegion(center: coredinate, span: spn)
        self.mapView.setRegion(region, animated: true)
        
    }
    
    
    @objc func longTap(_ sender: UIGestureRecognizer){
        if sender.state == .ended {
            
            let touchLocation = sender.location(in: mapView)
            let coordinate = mapView.convert(touchLocation,
                                             toCoordinateFrom: mapView)
            
            addPinToCoreData(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
        }
        
    }
    
    
    func addPinToCoreData(latitude: Double ,longitude: Double) {
        let p = Pin(context: dController.viewContext)
        
        p.lat = latitude
        p.long = longitude
        p.creationDate = Date()
        
        do
        {
            try dController.viewContext.save()
        }
        catch
        {
            
            
            print(error)
        }
    }
    
    
    
}


extension LocationViewController : NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        
        guard let pin = anObject as? Pin else {
            preconditionFailure("All changes observed in the map view controller should be for Point instances")
        }
        
        
        switch type {
        case .insert:
            DispatchQueue.main.async {
                self.mapView.addAnnotation(pin)
            }
            
        case .delete:
            mapView.removeAnnotation(pin)
            
        case .update:
            mapView.removeAnnotation(pin)
            mapView.addAnnotation(pin)
            
        case .move: break
            
        }
    }
}


extension Pin: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        
        let latDegrees = CLLocationDegrees(lat)
        let longDegrees = CLLocationDegrees(long)
        return CLLocationCoordinate2D(latitude: latDegrees, longitude: longDegrees)
        
    }
}


extension LocationViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        
        let annotation = view.annotation
        let annotationLat = annotation?.coordinate.latitude
        let annotationLong = annotation?.coordinate.longitude
        if let result = fetchedResultsController.fetchedObjects {
            for pin in result {
                if pin.lat == annotationLat && pin.long == annotationLong {
                    pSelected = pin
                    performSegue(withIdentifier: "toPhoto", sender: self)
                    
                    break
                }
            }
            
            
            
            
        }
        
        
        
    }
    
}
