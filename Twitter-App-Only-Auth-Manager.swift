//
//  TwitterAPI.swift
//  TLT
//
//  Created by Bliss Wetchaye on 2018-08-06.
//  Copyright © 2018 Confusians. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire

class TwitterAPIManager: NSObject {
    
    static var shared = TwitterAPIManager()
    let kConsumerKey = "Global.twitter_kConsumerKey"
    let kConsumerSecretKey = "Global.twitter_kConsumerSecretKey"
    let kTwitterAuthAPI = "Global.twitter_kTwitterAuthAPI"
    let twitterGrantType = "client_credentials"
    let protectionSpace = URLProtectionSpace(host: "https://tlt.api.twitter.com/oauth2/token", port: 0, protocol: "https", realm: "Restricted", authenticationMethod: NSURLAuthenticationMethodHTTPBasic)
    var credential: URLCredential?
    let twitterAPIURL = "https://api.twitter.com/1.1"
    
    func requestTwitterBearerToken(completion : (( Bool  , Error?) -> Void)? = nil ){
        var header = Dictionary<String,String>()
        // 3. Get getBase64EncodedBearerToken

        let bearerTokenCredentials = "\(kConsumerKey.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""):\(kConsumerSecretKey.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "")"
        guard let bearerTokenCredentialsBase64 = bearerTokenCredentials.base64Encoded() else { return }
        header["Authorization"] = "Basic \(bearerTokenCredentialsBase64)"
        header["Content-Type"] = "application/x-www-form-urlencoded"
        var params = Dictionary<String,Any>()
        params["grant_type"] = twitterGrantType
        // 4. Make "kTwitterAuthAPI" call with "Basic Authorization"

        let request = Alamofire.request(kTwitterAuthAPI, method: .post, parameters: params, encoding: URLEncoding.default , headers: header).responseJSON
        {[unowned self](response:DataResponse<Any>) in
            switch(response.result) {
            case .success(_):
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        // 5. Get "access_token" and use it in "Bearer Authorization" calls
                        let credential = URLCredential.init(user: "TLTTwitterBearerToken", password: json["access_token"].string!, persistence: .permanent)
                        // 6. Save Bearer in Keychain
                        URLCredentialStorage.shared.set(credential, for: self.protectionSpace)
                        completion?(true, nil)
                    }catch(let error){
                        completion?(false , error)
                    }
                }
                break
            case .failure(let error):
                completion?(false , error)
                break
            }
        }
    }
    
    func checkTwitterToken(completion : (( Bool  , Error?) -> Void)? = nil) {
        if credential == nil {
            let credentials = URLCredentialStorage.shared.credentials(for: self.protectionSpace)
            guard let oneCredential = credentials?.first  else {
                requestTwitterBearerToken() { [unowned self] (success, error) in
                    if success {
                        completion?(true, nil)
                    } else {
                        completion?(false, error)
                    }
                }
                return
            }
            credential = oneCredential.value
            completion?(true, nil)
        } else {
            completion?(true, nil)
        }
    }
    
    func requestTimeline(lastID: String? = nil, completion: (([AnyObject]?, Error?) -> Void)?) {
        checkTwitterToken() { [unowned self] (success, error) in
            if success {
                var header = Dictionary<String,String>()
                header["Authorization"] = "Bearer \(self.credential?.password ?? "")"
                header["Content-Type"] = "application/x-www-form-urlencoded"
                var urlString = "\(self.twitterAPIURL)/statuses/user_timeline.json"
                if (lastID != nil) {
                    urlString = "\(self.twitterAPIURL)/statuses/user_timeline.json"
                }
                
                //Do API call
                completion?(nil, nil)
            } else {
                completion?(nil, error)
            }
        }
    }
    
}

extension String {
    func base64Encoded() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }
}
