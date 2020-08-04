//
//  ViewController.swift
//  FoodLens SDK Example
//
//  Created by Peter Kuhar on 8/4/20.
//  Copyright © 2020 Azumio Inc. All rights reserved.
//

import UIKit
import FoodLensSDK

class ViewController: UIViewController, FoodLensDelegate {
   
    func foodLensPut(_ foodLens: FoodLens, foodCheckIn: FoodLensFoodCheckIn, from viewController: UIViewController?) {
        if let data = try? JSONSerialization.data(withJSONObject: foodCheckIn.dictionaryRepresentation, options: [.prettyPrinted]) {
            let text = String(data: data, encoding: .utf8)!
                       
            //display the result json
            viewController?.dismiss(animated: true, completion: {
                self.alert(title: "Results", message: text )
            })
        }
    }
    
    func foodLensDelete(_ foodLens: FoodLens, foodCheckIn: FoodLensFoodCheckIn, from viewController: UIViewController?) {
        
    }
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var openFoodLensButton: UIButton!
    
    @IBAction func openFoodLens(_ sender: Any) {
        present( foodLensInstance!.instantiateCameraViewController(), animated: true, completion: nil)
        
    }
    
    
    var foodLensInstance:FoodLens? {
        didSet{
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            openFoodLensButton.isEnabled = true
            foodLensInstance?.delegate = self
        }
    }
    
    func alert(title:String, message:String ){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present( alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if ViewController.clientId == ViewController.clientSecret{
            assert(false, "Get your clientId and clientSecret at https://dev.caloriemama.ai/")
        }
        
        
        if let foodlens = FoodLens.lastAuthorizedInstance(){
            foodLensInstance = foodlens
        }else{
            getAPIToken { token in
                FoodLens.authorizedInstance(withAccessToken: token.access_token) { (foodlens, error) in
                    guard let foodlens = foodlens else {
                        if let error = error {
                            self.alert(title: "Error", message: "\(error)")
                            return
                        }
                        return
                    }
                    self.foodLensInstance = foodlens
                }
            }
        }
    }
    
    static let clientId = "GET IT AT https://dev.caloriemama.ai/"
    static let clientSecret = "GET IT AT https://dev.caloriemama.ai/"
    
    private static var urlSession = URLSession(configuration: URLSessionConfiguration.default)
    
    struct TokenPayload: Encodable {
        var grant_type = "foodapi"
        var client_id = clientId
        var client_secret = clientSecret
        var user_id: String
    }
    
    struct TokenResponse: Decodable {
        var access_token: String
    }
    
    struct TokenErrorResponse: Decodable {
        struct Error: Decodable {
            var errorDetail: String
            var code: Int
        }
        var error: Error
    }
    
    /**
     Get the access token based on clientId and Secret.
     Do this server side on your backend.
     */
    func getAPIToken(_ callback:@escaping (TokenResponse) -> Void){
        
        var request = URLRequest(url: URL(string: "https://api.foodlens.com/api2/token")!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let payload = TokenPayload(user_id: "XXX")
        
        let task = ViewController.urlSession.uploadTask(with: request, from: try! JSONEncoder().encode(payload)) { (responseData, response, error) in
            if let data = responseData {
                do {
                    let response = try JSONDecoder().decode(TokenResponse.self, from: data)
                    
                    callback( response )
                    
                } catch (let e) {
                    self.alert(title: "Error", message: "\(e)")
                }
            }
            if let error = error{
                self.alert(title: "Error", message: "\(error)")
            }
        }
        task.resume()
    }
    
    
    
    
    
}

