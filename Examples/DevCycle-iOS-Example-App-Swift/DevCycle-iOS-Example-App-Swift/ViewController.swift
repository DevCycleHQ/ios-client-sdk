//
//  ViewController.swift
//  DevCycle-Example-App
//
//

import DevCycle
import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var titleHeader: UILabel!
    @IBOutlet weak var loginButton: UIButton!

    var loggedIn: Bool = false
    var titleHeaderVar: DVCVariable<String>?
    var loginCtaVar: DVCVariable<String>?

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            guard let client = await DevCycleManager.shared.clientAsync else { return }
            self.loginCtaVar = client.variable(key: "login-cta-copy", defaultValue: "Log")
                .onUpdate(handler: { value in
                    self.setLoginButtonTitle(self.loggedIn)
                })
            self.titleHeaderVar = client.variable(
                key: "title-header-copy", defaultValue: "DevCycle iOS Example App"
            ).onUpdate(handler: { value in
                self.setTitleHeader()
            })
            self.setTitleHeader()
            self.setLoginButtonTitle(false)
        }
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
        Task {
            guard let client = await DevCycleManager.shared.clientAsync else { return }
            if self.loggedIn {
                do {
                    _ = try await client.resetUser()
                    self.setLoginButtonTitle(false)
                    print("Reset User!")
                } catch {
                    print("Error resetting user: \(error)")
                }
            } else {
                do {
                    let user = try DevCycleUser.builder()
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
                    _ = try await client.identifyUser(user: user)
                    self.setLoginButtonTitle(true)
                    print("Logged in as User: \(String(describing: user.userId))!")

                    let numKeyValue = client.variableValue(key: "num_key", defaultValue: Double(0))
                    print("Num_key is \(numKeyValue)!")

                    let numKeyDefaultedValue = client.variableValue(
                        key: "num_key_defaulted", defaultValue: Double(0))
                    print("Num_key_defaulted is \(numKeyDefaultedValue)!")
                } catch {
                    print("Error identifying user: \(error)")
                }
            }
        }
    }

    @IBAction func track(_ sender: Any) {
        Task {
            guard let client = await DevCycleManager.shared.clientAsync else { return }
            let event = try! DevCycleEvent.builder()
                .type("my_event")
                .target("my_target")
                .value(3)
                .metaData(["key": "value"])
                .clientDate(Date())
                .build()
            client.track(event)
            print("Tracked event to DevCycle")
        }
    }

    @IBAction func logAllFeatures(_ sender: Any) {
        Task {
            guard let client = await DevCycleManager.shared.clientAsync else { return }
            print("All Features: \(client.allFeatures())")
            print("All Variables: \(client.allVariables())")
        }
    }
}
