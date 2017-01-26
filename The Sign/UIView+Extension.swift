//
//  UIView+Extension.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-01-21.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit

extension UIView {

    func applyPlainShadow() {
        let layer = self.layer
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.6
        layer.shadowRadius = 2
    }

}
