

import UIKit

class AlertPresenter {
    static func show(model: AlertModel, vc: UIViewController) {
        let alert = UIAlertController (
            title: model.title, message: model.message, preferredStyle: .alert)
        
        let action = UIAlertAction(title: model.buttonText, style: .default) { _ in model.completion()
        }
        
        alert.addAction(action)
        vc.present(alert, animated: true, completion: nil)
    }
}
