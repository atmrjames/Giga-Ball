//
//  ModeSelectViewController.swift
//  Megaball
//
//  Created by James Harding on 26/07/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class ModeSelectViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource, MenuNavigable {
    
    var selectedLevel: Int?
    var numberOfLevels: Int?
    var levelSender: String?
    var levelPack: Int?
    
    let defaults = UserDefaults.standard
    var hapticsSetting: Bool = true
    var parallaxSetting: Bool = true
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    
    var group: UIMotionEffectGroup?
    var blurView: UIVisualEffectView?
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var contentView: UIView!
    @IBOutlet var modeSelectTableView: UITableView!
    @IBOutlet var backCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        installMenuNavigationSwipes()
        // Back from the left edge, forward from the right - see MenuNavigation
        
        modeSelectTableView.delegate = self
        modeSelectTableView.dataSource = self
        modeSelectTableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "customSettingCell")
        fitTableToItsTwoRows()
        
        backCollectionView.delegate = self
        backCollectionView.dataSource = self
        backCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")

        userSettings()
        setBlur()
        if parallaxSetting {
            addParallax()
        }
        backCollectionView.reloadData()
        modeSelectTableView.reloadData()
        showAnimate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        limitMenuContentSize()
    }

    
    /// Grows the table to exactly the two rows it will ever hold.
    ///
    /// The storyboard sizes it at 140, which was two rows of 70. Glass rows are 78, so the
    /// second one no longer fitted and a two-item chooser acquired a scroll bar. The height
    /// is read off the row height rather than written as a number, so the next time the row
    /// changes size this follows it instead of quietly needing a scroll again.
    ///
    /// The label above moves up by the same amount, so the block keeps the spacing it was
    /// drawn with rather than closing the gap to the text.
    private func fitTableToItsTwoRows() {
        let wanted = SettingsTableViewCell.glassRowHeight*2
        guard let height = modeSelectTableView.constraints.first(where: {
            $0.firstAttribute == .height && $0.secondItem == nil
        }) else { return }
        let grew = wanted - height.constant
        guard grew > 0 else { return }
        height.constant = wanted
        modeSelectTableView.isScrollEnabled = false
        // Nothing left to scroll, and a table that can still be dragged over its own content
        // bounces in a way that reads as a bug on a screen holding two choices

        guard let parent = modeSelectTableView.superview else { return }
        for constraint in parent.constraints
        where constraint.firstItem === modeSelectTableView && constraint.firstAttribute == .top {
            constraint.constant -= grew
            break
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customSettingCell", for: indexPath) as! SettingsTableViewCell
        modeSelectTableView.rowHeight = SettingsTableViewCell.glassRowHeight
        cell.iconImage.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        cell.iconImage.isHidden = false
        cell.settingDescription.text = ""
        cell.settingState.text = ""
        cell.centreLabel.text = ""
        cell.applyGlass()
        cell.tickImage.isHidden = true
        cell.lockedImageView.isHidden = true
        cell.blurView.isHidden = true
        
        cell.descriptionAndStateSharedWidthConstraint.isActive = false
        cell.descriptionTickWidthConstraint.isActive = false
        cell.decriptionFullWidthConstraint.isActive = true

        if indexPath.row == 0 {
            cell.setIcon(UIImage(named:"iconPlayLevel"), recolour: true)
            cell.settingDescription.text = "Play single level only"
        } else {
            cell.setIcon(LevelPackSetup().packIcon(levelPack!), recolour: true)
            // Recoloured after all (round 66). Round 64 called this pack art and left it
            // alone, which was right about pack *thumbnails* and wrong about these: the pack
            // icons are flat single-colour glyphs like the interface ones, so Space Pack's
            // moon was a dark purple mark on a dark row. The screenshot is the only way this
            // distinction is ever going to be got right - the two kinds of image are told
            // apart by looking at them
            // The list of pack icons lives with the pack names in LevelPackSetup - it used to
            // be written out here as well, and in the pack screen, which is two more places to
            // miss when a pack's art is redrawn
            cell.settingDescription.text = "Play \(LevelPackSetup().levelPackNameArray[levelPack!]) from start"
        }
                
        cell.setPressed(false, colour: #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1), duration: 0.2)
        tableView.showsVerticalScrollIndicator = false
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        MenuViewController().clearSavedGame()
        
        if indexPath.row == 0 {
            moveToGame(selectedLevel: selectedLevel!, numberOfLevels: 1, sender: levelSender!, levelPack: levelPack!)
            removeAnimate()
        } else {
            moveToGame(selectedLevel: LevelPackSetup().startLevelNumber[levelPack!], numberOfLevels: LevelPackSetup().numberOfLevels[levelPack!], sender: levelSender!, levelPack: levelPack!)
            removeAnimate()
        }

        if let cell = self.modeSelectTableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
            cell.setPressed(true, colour: #colorLiteral(red: 0.9019607843, green: 1, blue: 0.7019607843, alpha: 1), duration: 0.2)
        }
        tableView.deselectRow(at: indexPath, animated: true)
        // Update table view
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if let cell = self.modeSelectTableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
            cell.setPressed(true, colour: #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1), duration: 0.1)
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if let cell = self.modeSelectTableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
            cell.setPressed(false, colour: #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1), duration: 0.1)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "iconCell", for: indexPath) as! MainMenuCollectionViewCell
        
        cell.frame.size.height = 50
        cell.frame.size.width = cell.frame.size.height
        cell.widthConstraint.constant = MainMenuCollectionViewCell.smallButtonSize
        cell.setButton("ButtonClose.png")
        
        UIView.animate(withDuration: 0.1) {
            cell.view.transform = .identity
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        menuNavigationGoBack()
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if let cell = self.backCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .init(scaleX: 0.95, y: 0.95)
                cell.setPressedArtwork(UIImage(named:"ButtonCloseHighlighted.png"))
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = self.backCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .identity
                cell.setPressedArtwork(UIImage(named:"ButtonClose.png"))
            }
        }
    }
    
    func userSettings() {
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
    }
    
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
    
    func showAnimate() {
        self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        })
    }
    
    /// Does exactly what tapping the back button does.
    ///
    /// The left-edge swipe calls this, so the gesture and the button can never drift apart.
    func menuNavigationGoBack() {
        MenuNavigation.shared.record(self)
        // Remembered, so a swipe from the right edge brings this screen back
        removeAnimate()
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
    
    func moveToGame(selectedLevel: Int, numberOfLevels: Int, sender: String, levelPack: Int) {
        let gameView = self.storyboard?.instantiateViewController(withIdentifier: "gameView") as! GameViewController
        gameView.menuViewControllerDelegate = self as? MenuViewControllerDelegate
        gameView.selectedLevel = selectedLevel
        gameView.numberOfLevels = numberOfLevels
        gameView.levelSender = sender
        gameView.levelPack = levelPack
        self.navigationController?.pushViewController(gameView, animated: true)
    }
    // Segue to GameViewController with selected level

}
