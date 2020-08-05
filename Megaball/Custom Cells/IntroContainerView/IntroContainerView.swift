//
//  IntroContainerView.swift
//  Megaball
//
//  Created by James Harding on 01/08/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit
import Foundation

@IBDesignable
class IntroContainerView: UIView {
    
    static let CAROUSEL_ITEM_NIB = "IntroContainerView"
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var introImage: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initWithNib()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initWithNib()
    }
    
    convenience init(imageView: String? = "") {
        self.init()
        introImage.image = UIImage(named: imageView!)

        introImage.layer.shadowColor = #colorLiteral(red: 0.2159586251, green: 0.04048030823, blue: 0.3017641902, alpha: 1)
        introImage.layer.shadowOffset = CGSize(width: 0, height: 0)
        introImage.layer.shadowOpacity = 0.5
        introImage.layer.shadowRadius = 4
    }
    
    fileprivate func initWithNib() {
        Bundle.main.loadNibNamed(IntroContainerView.CAROUSEL_ITEM_NIB, owner: self, options: nil)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(contentView)
    }

}
