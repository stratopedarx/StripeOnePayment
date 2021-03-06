//
//  ViewController.swift
//  StripOneTimePayment
//
//  Created by Sergey Lobanov on 02.11.2021.
//

import UIKit
import Stripe
import Alamofire

class ViewController: UIViewController {
    
    // MARK: UIView
    var productStackView = UIStackView()
    var paymentStackView = UIStackView()
    var productImageView = UIImageView()
    var productLabel = UILabel()
    var payButton = UIButton()
    var loadingSpinner = UIActivityIndicatorView()
    var outputTextView = UITextView()
    var paymentTextField = STPPaymentCardTextField()  // for credit card
    
    var backendURL = "https://stripe-one-time-payment-lob.herokuapp.com/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Setup some UI like buttons and labels
        // Also setup STPPaymantCardTextField from Stripe-iOS
        self.setupUI()
        
    }
    
    func setupUI() {
        setupProductImage()
        setupProductLabel()
        setupLoadingSpinner()
        setupPaymentTextField()
        setupPayButton()
        setupOutputTextView()
        
        self.productStackView.frame = CGRect(x: 0, y: 70, width: 330, height: 150)
        self.productStackView.center.x = self.view.center.x
        self.productStackView.alignment = .center
        self.productStackView.axis = .vertical
        self.productStackView.distribution = .equalSpacing
        
        self.productStackView.addArrangedSubview(self.productImageView)
        self.productStackView.setCustomSpacing(10, after: self.productImageView)
        self.productStackView.addArrangedSubview(self.productLabel)
        
        self.view.addSubview(self.productStackView)
        
        self.paymentStackView.frame = CGRect(x: 0, y: 260, width: 300, height: 100)
        self.paymentStackView.center.x = self.view.center.x
        self.paymentStackView.alignment = .fill
        self.paymentStackView.axis = .vertical
        self.paymentStackView.distribution = .equalSpacing
        
        self.paymentStackView.addArrangedSubview(self.paymentTextField)
        self.paymentStackView.addArrangedSubview(self.payButton)
        
        self.view.addSubview(self.paymentStackView)
    }
    
    func setupProductImage() {
        self.productImageView = UIImageView(frame: CGRect(x: 50, y: 50, width: 275, height: 200))
        self.productImageView.image = UIImage(named: "stripe_press")
        self.productImageView.contentMode = .scaleAspectFit
    }
    
    func setupProductLabel() {
        self.productLabel.frame = CGRect(x: 0, y: 270, width: self.view.frame.width, height: 50)
        self.productLabel.text = "Buy a Stripe press book - $10.99"
        self.productLabel.textAlignment = .center
    }
    
    func setupLoadingSpinner() {
        self.loadingSpinner.color = UIColor.darkGray
        self.loadingSpinner.frame = CGRect(x: 0, y: 380, width: 25, height: 25)
        self.loadingSpinner.center.x = self.view.center.x
        
        self.view.addSubview(self.loadingSpinner)
    }
    
    func setupPaymentTextField() {
        self.paymentTextField.frame = CGRect(x: 0, y: 0, width: 330, height: 60)
    }
    
    func setupPayButton() {
        self.payButton.frame = CGRect(x: 60, y: 480, width: 150, height: 40)
        self.payButton.setTitle("Submit Payment", for: .normal)
        self.payButton.setTitleColor(UIColor.white, for: .normal)
        self.payButton.layer.cornerRadius = 5.0
        self.payButton.backgroundColor = UIColor.init(red: 50/255, green: 50/2500, blue: 93/255, alpha: 1.0)
        self.payButton.layer.borderWidth = 1.0
        self.payButton.addTarget(self, action: #selector(pay), for: .touchUpInside)
    }
    
    func setupOutputTextView() {
        self.outputTextView.frame = CGRect(x: 0, y: 420, width: self.view.frame.width - 50, height: 100)
        self.outputTextView.center.x = self.view.center.x
        self.outputTextView.textAlignment = .left
        self.outputTextView.font = UIFont.systemFont(ofSize: 18)
        self.outputTextView.text = ""
        self.outputTextView.layer.borderColor = UIColor.purple.cgColor
        self.outputTextView.layer.borderWidth = 1.0
        self.outputTextView.isEditable = false
        
        self.view.addSubview(self.outputTextView)
    }
    
    func startLoading() {
        DispatchQueue.main.async {
            self.loadingSpinner.startAnimating()
            self.loadingSpinner.isHidden = false
        }
    }
    
    func stopLoading() {
        DispatchQueue.main.async {
            self.loadingSpinner.stopAnimating()
            self.loadingSpinner.isHidden = true
        }
    }
    
    func displayStatus(_ message: String) {
        DispatchQueue.main.async {
            self.outputTextView.text! += message + "\n"
            
            self.outputTextView.scrollRangeToVisible(NSMakeRange(self.outputTextView.text.count - 1, 1))
        }
    }
    
    // MARK: - Button Actions
    @objc func pay() {
        // 1) [server-side] Create a PaymentIntent
        // 2) [cliend-side] Confirm the PaymentIntent
        
        // make a POST request to the /create_payment_intent endpoint
        self.startLoading()
        self.displayStatus("Creating PaymentIntent")
        
        createPaymentIntent { paymentIntentResponse, error in
            if let error = error {
                self.stopLoading()
                self.displayStatus(error.localizedDescription)
                print(error)
                return
            } else {
                guard let responseDictionary = paymentIntentResponse as? [String: AnyObject] else {
                    print("Incorrect response")
                    return
                }
                
                print(responseDictionary)
                let clientSecret = responseDictionary["secret"] as! String
                self.displayStatus("Created PaymentIntent")
                
                // Confirm the PaymentIntent using STPPaymentHandler
                // Implement delegates for STPAuthentificationContext
                
                let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                let paymentMethodParams = STPPaymentMethodParams(
                    card: self.paymentTextField.cardParams,
                    billingDetails: nil,
                    metadata: nil)
                paymentIntentParams.paymentMethodParams = paymentMethodParams
                
                STPPaymentHandler.shared().confirmPayment(
                    paymentIntentParams,
                    with: self) { status, paymentIntent, error in
                        self.stopLoading()
                        
                        var resultString = ""
                        
                        switch status {
                        case .canceled:
                            resultString = "Payment canceled"
                        case .failed:
                            resultString = "Payment faild, please try a different card"
                        case .succeeded:
                            resultString = "Payment successful"
                        }
                        print(resultString)
                        self.displayStatus(resultString)
                    }
                
                
                self.stopLoading()
            }
        }
        
    }
    
    func createPaymentIntent(completion: @escaping STPJSONResponseCompletionBlock) {
        guard var url = URL(string: backendURL) else { return }
        url.appendPathComponent("create_payment_intent")
        
        AF.request(url, method: .post, parameters: [:])
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .failure(let error):
                    completion(nil, error)
                case .success(let json):
                    completion(json as? [String: Any], nil)
                }
            }
    }
}

// MARK: - STPAuthenticationContext Delegate

extension ViewController: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return self
    }
    
    
}
