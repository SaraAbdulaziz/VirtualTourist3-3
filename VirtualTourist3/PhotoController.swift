//
//  File.swift
//  VirtualTourist
//
//  Created by سارا on 04/04/1441 AH.
//  Copyright © 1441 Udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class PhotoController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var noImageLable: UILabel!
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    
    @IBOutlet weak var newCollectionButton: UIButton!
    
    
    
    
    var p: Pin!
    
    var photosUArray = [URL]()
    
    var selectedPhotos = [IndexPath]()
    
    
    private var blockOperations: [BlockOperation] = []
    
    var dataController:DataController!
    
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", self.p)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        newCollectionButton.isEnabled = false
        
        setupFetchedResultsController()
        
        if self.fetchedResultsController.fetchedObjects?.count == 0 {
            getPhotosFromFlikr()
        }
        
        createAnnotation()
        setFlowLayout()
        
        collectionView.allowsMultipleSelection = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        
        
    }
    func getPhotosFromFlikr(){
        FlickrClient.sharedInstance().getPhotosFormFlicker(latitude: p.lat, longitude: p.long, { (success, photoData,NoPhotoMessage, errorString)  in
            
            if success {
                
                if NoPhotoMessage == nil {
                    
                    DispatchQueue.main.async {
                        self.noImageLable.isHidden = true
                    }
                    
                    if let photo = photoData as? [PhotoParse] {
                        
                        for i in photo {
                            self.photosUArray.append(URL(string: i.url_m)!)
                            
                        }
                        
                        self.downloadImagesAndsavaItToPhotoData()
                        
                        
                    }
                }else {
                    DispatchQueue.main.async {
                        self.noImageLable.isHidden = false
                        self.noImageLable.text = NoPhotoMessage
                    }
                }
                
                
                
            }
        })
    }
    
    func setFlowLayout(){
        let space:CGFloat = 2.0
        let dim = (view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dim, height: dim)
    }
    
    
    @IBAction func newCollectionTapped(_ sender: UIButton) {
        
        if sender.currentTitle == "New Collection" {
            
            guard let fetchedResults = self.fetchedResultsController.fetchedObjects else {
                return
            }
            
            photosUArray.removeAll()
            
            for i in fetchedResults {
                dataController.viewContext.delete(i)
                try? dataController.viewContext.save()
            }
            
            getPhotosFromFlikr()
            
        } else if sender.currentTitle == "Remove Selected Pictures" {
            
            sender.setTitle("New Collection", for: .normal)
            
            deletePhotos()
            
            
        }
        
    }
    
    
    func createAnnotation(){
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(p.lat, p.long)
        self.mapView.addAnnotation(annotation)
        
        let coredinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(p.lat, p.long)
        let spn = MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
        let region = MKCoordinateRegion(center: coredinate, span: spn)
        self.mapView.setRegion(region, animated: true)
        
    }
    
    func updateUI(cell:PhotoViewCell, status:Bool) {
        
        if status == false {
            
            cell.activityIndicator.isHidden = false
            cell.activityIndicator.startAnimating()
            
        } else {
            
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.isHidden = true
            
            
        }
    }
    
    func downloadImagesAndsavaItToPhotoData(){
        
        if ((fetchedResultsController.fetchedObjects?.isEmpty)!) {
            
            for url in photosUArray {
                
                let dataTask = URLSession.shared.dataTask(with: url) {
                    data, response, error in
                    
                    if error == nil {
                        if let data = data {
                            
                            self.addPhotosToCoreData(data:data)
                            
                            
                            
                        }
                        
                    }else {
                        print(error!)
                    }
                    
                }
                dataTask.resume()
                
            }
            
            
            
            
        }
        
    }
    
    func addPhotosToCoreData(data:Data) {
        let photo = Photo(context: dataController.viewContext)
        
        photo.imgData = data
        photo.creationDate = Date()
        photo.pin = p
        
        
        do
        {
            try dataController.viewContext.save()
        }
        catch
        {
            //ERROR
            print(error)
        }
        
    }
    
    func deletePhotos() {
        
        var photosToDelete: [Photo] = [Photo]()
        
        for i in selectedPhotos {
            photosToDelete.append(fetchedResultsController.object(at: i))
        }
        
        for i in photosToDelete {
            dataController.viewContext.delete(i)
            try? dataController.viewContext.save()
        }
        
        
        selectedPhotos.removeAll()
        
    }
    
    
    deinit {
        
        
        
        for oper: BlockOperation in blockOperations {
            oper.cancel()
        }
        
        blockOperations.removeAll(keepingCapacity: false)
    }
    
    
    
    
}



extension PhotoController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        
        if let sectionInfo = self.fetchedResultsController.sections?[section] {
            return sectionInfo.numberOfObjects
        }
        return 0
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photosCell", for: indexPath) as! PhotoViewCell
        
        cell.selectedView.isHidden = true
        
        self.updateUI(cell: cell, status: false)
        
        
        
        let arrayData = self.fetchedResultsController.fetchedObjects!
        cell.imageFlikr.image =  UIImage(data: arrayData[indexPath.row].imgData!)
        
        
        
        self.updateUI(cell: cell, status: true)
        
        newCollectionButton.isEnabled = true
        
        
        
        return cell
        
    }
    
    
}



extension PhotoController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoViewCell
        
        cell.selectedView.isHidden = false
        newCollectionButton.setTitle("Remove Selected Pictures", for: .normal)
        
        selectedPhotos.append(indexPath)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoViewCell
        
        cell.selectedView.isHidden = true
        
        selectedPhotos.remove(at: indexPath.startIndex)
        
        if selectedPhotos.count == 0 {
            newCollectionButton.setTitle("New Collection", for: .normal)
        }
    }
    
}




extension PhotoController:NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperations.removeAll(keepingCapacity: false)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        
        let op: BlockOperation
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            op = BlockOperation { self.collectionView.insertItems(at: [newIndexPath]) }
            
            
        case .delete:
            guard let indexPath = indexPath else { return }
            op = BlockOperation { self.collectionView.deleteItems(at: [indexPath]) }
        case .move:
            guard let indexPath = indexPath,  let newIndexPath = newIndexPath else { return }
            op = BlockOperation { self.collectionView.moveItem(at: indexPath, to: newIndexPath) }
        case .update:
            guard let indexPath = indexPath else { return }
            op = BlockOperation { self.collectionView.reloadItems(at: [indexPath]) }
            
        }
        
        blockOperations.append(op)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({
            self.blockOperations.forEach { $0.start() }
        }, completion: { finished in
            self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
    
    
}
