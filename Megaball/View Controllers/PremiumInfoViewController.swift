//
//  PremiumInfoViewController.swift
//  Megaball
//
//  Created by James Harding on 26/07/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit
import StoreKit

class PremiumInfoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource {
    
    var premiumSetting: Bool?
    let defaults = UserDefaults.standard
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    var IAPLocalPrice: String?
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    
    var group: UIMotionEffectGroup?
    var blurView: UIVisualEffectView?
    
    var sender: String?
    
    var products: [SKProduct] = []
    var localCurrency: String?
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var contentView: UIView!
    
    @IBOutlet var infoTableView: UITableView!
    @IBOutlet var premiumTableView: UITableView!
    @IBOutlet var backCollectionView: UICollectionView!
    
    @IBOutlet var premiumIconImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.iAPcompleteNotificationKeyReceived), name: .iAPcompleteNotification, object: nil)
        // Sets up an observer to watch for notifications to check for in-app purchase success
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshViewForSyncNotificationKeyReceived), name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by the main menu screen
        
        infoTableView.delegate = self
        infoTableView.dataSource = self
        infoTableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "customSettingCell")
        
        premiumTableView.delegate = self
        premiumTableView.dataSource = self
        premiumTableView.register(UINib(nibName: "IAPTableViewCell", bundle: nil), forCellReuseIdentifier: "iAPCell")
        
        backCollectionView.delegate = self
        backCollectionView.dataSource = self
        backCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        
        premiumIconImage.image = UIImage(named:"iconPremiumYellow")
        
        if view.frame.height <= 600 {
            infoTableView.isScrollEnabled = true
        }
        
        userSettings()
        loadProducts()
        
        if sender != "Info" {
            setBlur()
        }
        
        if parallaxSetting! {
            addParallax()
        }
        infoTableView.reloadData()
        premiumTableView.reloadData()
        backCollectionView.reloadData()
        showAnimate()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.premiumTableView {
            return 1
        } else {
            return 5
        }
    }
    // Set number of cells in table view
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.premiumTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "iAPCell", for: indexPath) as! IAPTableViewCell
            premiumTableView.rowHeight = 84.0
            cell.priceLabel.text = IAPLocalPrice
            cell.tagLine.text = "Upgrade now"
            cell.iconImage.image = UIImage(named:"iconPremium.png")!
            
            UIView.animate(withDuration: 0.2) {
                cell.cellView.transform = .identity
                cell.cellView.backgroundColor = #colorLiteral(red: 0.9019607843, green: 1, blue: 0.7019607843, alpha: 1)
            }
            tableView.showsVerticalScrollIndicator = false
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "customSettingCell", for: indexPath) as! SettingsTableViewCell
                        
            infoTableView.rowHeight = 70.0
            cell.iconImage.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
            cell.iconImage.isHidden = false
            
            cell.settingDescription.text = ""
            cell.settingState.text = ""
            cell.centreLabel.text = ""
            cell.tickImage.isHidden = true
            cell.lockedImageView.isHidden = true
            cell.blurView.isHidden = true
            cell.cellView2.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
            cell.settingDescription.textColor = #colorLiteral(red: 0.2159586251, green: 0.04048030823, blue: 0.3017641902, alpha: 1)
            
            cell.descriptionAndStateSharedWidthConstraint.isActive = false
            cell.descriptionTickWidthConstraint.isActive = false
            cell.decriptionFullWidthConstraint.isActive = true

            cell.iconImage.image = UIImage(named:"ButtonPremium")
            cell.settingDescription.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
            
            switch indexPath.row {
            case 0:
                cell.settingDescription.text = "Unlock all 110 levels and 11 level packs"
            case 1:
                cell.settingDescription.text = "Unlock all 28 power-ups"
            case 2:
                cell.settingDescription.text = "Unlock all 12 themes and app icons"
            case 3:
                cell.settingDescription.text = "Remove ads"
            case 4:
                cell.settingDescription.text = "Show your support for the app"

            default:
                break
            }
            
            UIView.animate(withDuration: 0.2) {
                cell.cellView2.transform = .identity
                cell.cellView2.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
            }
            tableView.showsVerticalScrollIndicator = false
            return cell
        }
    }
    
    func loadProducts() {
        products = []
        GigaBallProducts.store.requestProducts{ [weak self] success, products in
          guard let self = self else { return }
          if success {
            self.products = products!
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == premiumTableView {
            // IAPHandler().unlockPremiumContent() // Beta builds only
            if products.count > 0 {
                showPurchaseScreen()
                let product = products[0]
                GigaBallProducts.store.buyProduct(product)
            }
            UIView.animate(withDuration: 0.2) {
                let cell = self.premiumTableView.cellForRow(at: indexPath) as! IAPTableViewCell
                cell.cellView.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView.backgroundColor = #colorLiteral(red: 0.9019607843, green: 1, blue: 0.7019607843, alpha: 1)
            }
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.reloadData()
            // Update table view
        }
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if tableView == premiumTableView {
            if hapticsSetting! {
                interfaceHaptic.impactOccurred()
            }
            UIView.animate(withDuration: 0.1) {
                let cell = self.premiumTableView.cellForRow(at: indexPath) as! IAPTableViewCell
                cell.cellView.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if tableView == premiumTableView {
            if hapticsSetting! {
                interfaceHaptic.impactOccurred()
            }
            UIView.animate(withDuration: 0.1) {
                let cell = self.premiumTableView.cellForRow(at: indexPath) as! IAPTableViewCell
                cell.cellView.transform = .identity
                cell.cellView.backgroundColor = #colorLiteral(red: 0.9019607843, green: 1, blue: 0.7019607843, alpha: 1)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "iconCell", for: indexPath) as! MainMenuCollectionViewCell
        
        cell.frame.size.height = 50
        cell.frame.size.width = cell.frame.size.height
        cell.widthConstraint.constant = 40
        cell.iconImage.image = UIImage(named:"ButtonClose.png")
        
        UIView.animate(withDuration: 0.1) {
            cell.view.transform = .identity
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        removeAnimate()
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.backCollectionView.cellForItem(at: indexPath) as! MainMenuCollectionViewCell
            cell.view.transform = .init(scaleX: 0.95, y: 0.95)
            cell.iconImage.image = UIImage(named:"ButtonCloseHighlighted.png")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.backCollectionView.cellForItem(at: indexPath) as! MainMenuCollectionViewCell
            cell.view.transform = .identity
            cell.iconImage.image = UIImage(named:"ButtonClose.png")
        }
    }
    
    func showPurchaseScreen() {
        let iAPVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "iAPVC") as! InAppPurchaseViewController
        self.addChild(iAPVC)
        iAPVC.view.frame = self.view.frame
        self.view.addSubview(iAPVC.view)
        iAPVC.didMove(toParent: self)
    }
    // Show iAPVC as popup
    
    func setBlur() {
        backgroundView.backgroundColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.5)
        let blurEffect = UIBlurEffect(style: .dark)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView!.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blurView!, at: 0)

        NSLayoutConstraint.activate([
        blurView!.heightAnchor.constraint(equalTo: backgroundView.heightAnchor),
        blurView!.widthAnchor.constraint(equalTo: backgroundView.widthAnchor),
        blurView!.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
        blurView!.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
        blurView!.topAnchor.constraint(equalTo: backgroundView.topAnchor),
        blurView!.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        ])
        // Keep the frame of the blurView consistent with that of the associated view.
    }
    
    func userSettings() {
        premiumSetting = defaults.bool(forKey: "premiumSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        IAPLocalPrice = defaults.string(forKey: "IAPLocalPrice")
    }
    
    func showAnimate() {
        self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        })
    }
    
    func removeAnimate() {
        NotificationCenter.default.post(name: .returnItemDetailsNotification, object: nil)
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.view.alpha = 0.0})
        { (finished: Bool) in
            if (finished) {
                self.view.removeFromSuperview()
            }
        }
    }
    
    func addParallax() {
        var amount = 25
        if view.frame.width > 450 {
            amount = 50
            // iPad
        }
        
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount

        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount
        
        if group != nil {
            contentView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        contentView.addMotionEffect(group!)
    }
    
    @objc func iAPcompleteNotificationKeyReceived(_ notification: Notification) {
        removeAnimate()
    }
    
    @objc func refreshViewForSyncNotificationKeyReceived(notification:Notification) {
        userSettings()
        if premiumSetting! {
            removeAnimate()
        }
    }
    // Runs when the NSUbiquitousKeyValueStore changes
}
