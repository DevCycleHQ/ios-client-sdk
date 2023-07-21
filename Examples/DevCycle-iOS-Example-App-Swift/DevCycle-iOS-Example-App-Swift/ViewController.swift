//
//  ViewController.swift
//  DevCycle-Example-App
//
//

import UIKit
import DevCycle

class ViewController: UIViewController {

    @IBOutlet weak var titleHeader: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    
    var loggedIn: Bool = false
    var client: DevCycleClient?
    var titleHeaderVar: DVCVariable<String>?
    var loginCtaVar: DVCVariable<String>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.client = DevCycleManager.shared.client
        self.loginCtaVar = client?.variable(key: "login-cta-copy", defaultValue: "Log").onUpdate(handler: { value in
            self.setLoginButtonTitle(self.loggedIn)
        })
        self.titleHeaderVar = client?.variable(key: "title-header-copy", defaultValue: "DevCycle iOS Example App").onUpdate(handler: { value in
            self.setTitleHeader()
        })
        self.setTitleHeader()
        self.setLoginButtonTitle(false)
    }
    
    func setTitleHeader() {
        guard let titleHeaderVar = self.titleHeaderVar else {
            return
        }
        self.titleHeader.text = titleHeaderVar.value
    }

    func setLoginButtonTitle(_ bool: Bool) {
        guard let loginCta = self.loginCtaVar else {
            return
        }
        self.loggedIn = bool
        self.loginButton.setTitle("\(loginCta.value) \(self.loggedIn ? "out" : "in")", for: .normal)
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        guard let client = self.client else { return }
        if (self.loggedIn) {
            try? client.resetUser { [weak self] error, variables in
                guard let self = self else { return }
                self.setLoginButtonTitle(false)
                print("Reset User!")
                print("Variables: \(String(describing: variables))")
            }
        } else {
            let user = try? DevCycleUser.builder()
                              .userId("my-user1")
                              .email("my-email@email.com")
                              .country("CA")
                              .name("Ash Ketchum")
                              .language("EN")
                              .customData([
                                "customkey": "customValue"
                              ])
                              .privateCustomData([
                                "customkey2": "customValue2"
                              ])
                              .build()
            try? client.identifyUser(user: user!) { [weak self] error, variables in
                guard let self = self else { return }
                self.setLoginButtonTitle(true)
                print("Logged in as User: \(String(describing: user?.userId))!")
                print("Variables: \(String(describing: variables))")
                
                let variable = client.variable(key: "num_key", defaultValue: 0)
                let variable2 = client.variable(key: "num_key_defaulted", defaultValue: 0)
                if (variable.value == 1) {
                    print("Num_key is 1!")
                } else {
                    print("Num_key is 0!")
                }
                if (variable2.value == 1) {
                    print("Evaluated num_key_defaulted")
                } else {
                    print("Defaulted num_key_defaulted")
                }
            }
        }
    }
    
    @IBAction func track(_ sender: Any) {
        guard let client = self.client else { return }
        let event = try! DevCycleEvent.builder()
                                 .type("my_event")
                                 .target("my_target")
                                 .value(3)
                                 .metaData([ "key": "value" ])
                                 .clientDate(Date())
                                 .build()
        client.track(event)
        print("Tracked event to DevCycle")
    }
    
    @IBAction func logAllFeatures(_ sender: Any) {
        guard let client = self.client else { return }
        print("All Features: \(client.allFeatures())")
        print("All Variables: \(client.allVariables())")
    }
}

