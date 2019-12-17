//
//  api.swift
//  VirtualTourist
//
//  Created by سارا on 03/04/1441 AH.
//  Copyright © 1441 Udacity. All rights reserved.
//


import UIKit
import Foundation

struct FlikerResbonse : Codable {
    let photos : Photos
    let stat : String
    
}

struct Photos : Codable {
    let perpage : Int
    let photo : [PhotoParse]
    
}

struct PhotoParse : Codable {
    let id : String
    let url_m : String
    
}




extension FlickrClient {
    
    
    
    func getPhotosFormFlicker(latitude:Double ,longitude:Double, _ completionHandlerForFlickerPhoto: @escaping (_ success: Bool,_ photoData: [Any]?,_   :String?, _ errorString: String?) -> Void) {
        
        
        let bBox = self.bboxString(latitude: latitude, longitude: longitude)
        
        let parameters = [
            FlickrClient.ParameterKeys.Method           : FlickrClient.ParameterValues.SearchMethod
            , FlickrClient.ParameterKeys.APIKey         : FlickrClient.ParameterValues.APIKey
            , FlickrClient.ParameterKeys.Format         : FlickrClient.ParameterValues.ResponseFormat
            , FlickrClient.ParameterKeys.Extras         : FlickrClient.ParameterValues.MediumURL
            , FlickrClient.ParameterKeys.NoJSONCallback : FlickrClient.ParameterValues.DisableJSONCallback
            , FlickrClient.ParameterKeys.SafeSearch     : FlickrClient.ParameterValues.UseSafeSearch
            , FlickrClient.ParameterKeys.BoundingBox    : bBox
            , FlickrClient.ParameterKeys.PhotosPerPage  : FlickrClient.ParameterValues.PhotosPerPage,
              "page":Int.random(in: 1...10)
            ] as [String : Any]
        
        
        
        _ = taskForGETMethod( parameters: parameters as [String : AnyObject] , decode: FlikerResbonse.self) { (result, error) in
            
            
            if let error = error {
                
                completionHandlerForFlickerPhoto(false ,nil ,nil,"\(error.localizedDescription)")
            }else {
                
                let newResult = result as! FlikerResbonse
                
                let resultData = newResult.photos.photo
                
                if newResult.photos.photo.isEmpty {
                    
                    let noPhotoMessage = "This pin has no images!"
                    
                    completionHandlerForFlickerPhoto(true ,nil ,noPhotoMessage,nil)
                    
                } else {
                    completionHandlerForFlickerPhoto(true ,resultData,nil,nil)
                    
                }
                
                
                
                
            }
        }
        
    }
    
    
    
    
    
}


class FlickrClient : NSObject {
    
    
    var session = URLSession.shared
    
    
    
    override init() {
        super.init()
    }
    
    
    
    
    func bboxString(latitude: Double, longitude: Double) -> String {
        
        let minimumLon = max(longitude - FlickrClient.SearchBBoxHalfWidth, FlickrClient.SearchLonRange.0)
        let minimumLat = max(latitude  - FlickrClient.SearchBBoxHalfHeight, FlickrClient.SearchLatRange.0)
        let maximumLon = min(longitude + FlickrClient.SearchBBoxHalfWidth, FlickrClient.SearchLonRange.1)
        let maximumLat = min(latitude  + FlickrClient.SearchBBoxHalfHeight, FlickrClient.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    func taskForGETMethod<D: Decodable>(parameters: [String:AnyObject],decode:D.Type, completionHandlerForGET: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        var parametersWithApiKey = parameters
        
        
        
        var request = NSMutableURLRequest(url: tmdbURLFromParameters(parametersWithApiKey))
        
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            guard (error == nil) else {
                sendError("\(error!.localizedDescription)")
                return
            }
            
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            
            
            self.convertDataWithCompletionHandler(data, decode:decode,completionHandlerForConvertData: completionHandlerForGET)
            
        }
        
        task.resume()
        
        return task
        
        
    }
    
    
    
    
    private func convertDataWithCompletionHandler<D: Decodable>(_ data: Data,decode:D.Type, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        
        do {
            let obj = try JSONDecoder().decode(decode, from: data)
            completionHandlerForConvertData(obj as AnyObject, nil)
            
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
    }
    
    
    private func tmdbURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = FlickrClient.Constants.ApiScheme
        components.host = FlickrClient.Constants.ApiHost
        components.path = FlickrClient.Constants.ApiPath
        
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
            
        }
        
        let url = components.url!
        
        
        return url
    }
    
    
    
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
}

extension FlickrClient {
    
    
    struct Constants {
        
        
        static let ApiKey = "af9404d9cb059882f7c1ca214100d462"
        
        static let ApiScheme = "https"
        static let ApiHost = "api.flickr.com"
        static let ApiPath = "/services/rest"
        
    }
    
    static let SearchBBoxHalfWidth = 0.2
    static let SearchBBoxHalfHeight = 0.2
    static let SearchLatRange = (-90.0, 90.0)
    static let SearchLonRange = (-180.0, 180.0)
    
    
    struct ParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let Extras = "extras"
        static let SafeSearch = "safe_search"
        static let PhotosPerPage = "per_page"
        static let BoundingBox = "bbox"
        
        
    }
    
    struct ParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "af9404d9cb059882f7c1ca214100d462"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1"
        static let MediumURL = "url_m"
        static let UseSafeSearch = "1"
        static let PhotosPerPage = "21"
        
    }
    
    
}


