//
//  GigaBallProducts.swift
//  Megaball
//
//  Created by James Harding on 05/09/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import Foundation

public struct GigaBallProducts {
    public static let SwiftShopping = "com.atmrjames.Megaball.GigaBallPremium"
    private static let productIdentifiers = NSSet(objects: GigaBallProducts.SwiftShopping)
    public static let store = IAPHandler(productIds: GigaBallProducts.productIdentifiers as! Set<ProductIdentifier>)
}

func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
    return productIdentifier.components(separatedBy: ".").last
}

