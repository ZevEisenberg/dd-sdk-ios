/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import UIKit

internal class ShapesViewController: UIViewController {
    @IBOutlet weak var yellowView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        yellowView?.layer.borderWidth = 5
        yellowView?.layer.borderColor = UIColor.yellow.cgColor
    }
}

internal class PopupsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(showAlert))
        view.addGestureRecognizer(tap)
    }

    @objc func showAlert() {
        let alertController = UIAlertController(
            title: "Alert Example",
            message: "This is an elaborate example of UIAlertController",
            preferredStyle: .alert
        )

        alertController.addTextField { (textField) in
            textField.placeholder = "Enter your name"
        }

        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { [weak alertController] _ in
            if let textField = alertController?.textFields?[0], let text = textField.text {
                print("Name entered: \(text)")
            }
        }
        alertController.addAction(confirmAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            print("Action cancelled")
        }
        alertController.addAction(cancelAction)

        let customAction = UIAlertAction(title: "Custom", style: .destructive) { (_) in
            print("Custom action selected")
        }
        alertController.addAction(customAction)
        present(alertController, animated: false)
    }
}
