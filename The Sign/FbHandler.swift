//
//  FbHandler.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-05-27.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit
import FBSDKShareKit

class FbHandler: NSObject, FBSDKSharingDelegate {

    static let shared = FbHandler()

    let fbAppId:String
    override init() {
        fbAppId = Bundle.main.object(forInfoDictionaryKey: "FacebookAppID") as! String
    }
    
    func createFbStory(sign:SignObject) {
        let object = convertSignToFbObject(sign: sign)
        // /me/og.likes
        let action = FBSDKShareOpenGraphAction(type: "/me/og.likes", object: object, key: "object")
        let content = FBSDKShareOpenGraphContent()
        content.action = action
        content.previewPropertyName = "object"
        FBSDKShareAPI.share(with: content, delegate: self)
    }
    
    func convertSignToFbObject(sign:SignObject) -> FBSDKShareOpenGraphObject {
        let properties = [
            "fb:app_id":fbAppId,
            "og:type":"place",
            "og:title":sign.title,
            "place:location:latitude":sign.latitude,
            "place:location:longitude":sign.longitude,
            "og:url":"https://olfe.app.link/aYiRtHw2wD"
        ] as [String : Any]
        return FBSDKShareOpenGraphObject(properties: properties)
    }
    
    //MARK: - FBSDKSharingDelegate protocol
    func sharer(_ sharer: FBSDKSharing!, didFailWithError error: Error!) {
        NSLog("Share fail: \(error)")
    }
    
    func sharer(_ sharer: FBSDKSharing!, didCompleteWithResults results: [AnyHashable: Any]!) {
        NSLog("Share success")
    }

    func sharerDidCancel(_ sharer: FBSDKSharing!) {
        NSLog("Share cancel")
    }
}
