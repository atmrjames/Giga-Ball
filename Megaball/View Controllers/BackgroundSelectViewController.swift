//
//  BackgroundSelectViewController.swift
//  Megaball
//
//  Choosing a background by looking at it.
//
//  This replaces a settings row that showed the current background's name and cycled to the
//  next one when tapped. That worked, in the sense that every background was reachable, but
//  three of the four are shades of the same purple and a name does not distinguish them - the
//  only way to see what you were choosing was to start a level.
//
//  One game view, and swiping slides the backgrounds behind it. The scene is the constant and
//  the background is the variable, so a row of four scenes said the opposite of what the screen
//  is for - and made the picture of each a quarter of the size it could be.
//
//  The backgrounds are a paging scroll view *under* the scene rather than a crossfade on top of
//  it. A crossfade happens after the gesture and tells the player what they chose; a strip that
//  moves with the finger lets them see what they are choosing while they are still choosing it,
//  and gives them back the half-swipe that changes their mind.
//

import UIKit

class BackgroundSelectViewController: UIViewController, UICollectionViewDelegate,
                                      UICollectionViewDataSource, UIScrollViewDelegate,
                                      MenuNavigable {

    let defaults = UserDefaults.standard
    var hapticsSetting: Bool = true
    var parallaxSetting: Bool = true
    var ballSetting: Int = 0
    // User settings

    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    var group: UIMotionEffectGroup?
    // UI property setup

    /// Which background is showing, and therefore which is chosen.
    private var selected: GameBackground = .classic

    private let card = UIView()
    private let backgrounds = UIScrollView()
    private let mock = GameSceneMockView()
    private var layers: [GameBackgroundView] = []
    private var mockAspect: NSLayoutConstraint?
    private var laidOut = CGSize.zero

    @IBOutlet var backgroundView: UIView!
    @IBOutlet var contentView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var mockContainer: UIView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var pageControl: UIPageControl!
    @IBOutlet var backButtonCollectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        installMenuNavigationSwipes()
        // Back from the left edge, forward from the right - see MenuNavigation

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.refreshViewForSyncNotificationKeyReceived),
                                               name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by
        // the main menu screen

        titleLabel.text = "BACKGROUND"
        loosenNameSpacing(by: 12)

        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil),
                                          forCellWithReuseIdentifier: "iconCell")
        // Collection view setup

        pageControl.numberOfPages = GameBackground.allCases.count
        pageControl.isUserInteractionEnabled = false
        // The dots say which of the four is showing, and that there are four. The picture
        // itself is how you move between them

        userSettings()
        selected = GameBackground.stored(defaults.integer(forKey: "backgroundSetting"))

        buildMock()
        if parallaxSetting {
            addParallax()
        }
        updateLabels()
        backButtonCollectionView.reloadData()
        hideReturnToGameButton()
        // No big play here (play-test round 21). This screen is a full-bleed preview of the
        // playfield, and a button floating over a picture of the game reads as part of it
        showAnimate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        limitMenuContentSize()
        backButtonCollectionView.collectionViewLayout = closeButtonLayout()
        refreshMockShape()
    }

    /// Opens the gap between the preview card and the background's name.
    ///
    /// The constraint is the storyboard's, so it is found rather than replaced - adding a
    /// second one would only fight it. Which way the constant moves depends on which end of
    /// the constraint the label is, which is why both are handled.
    private func loosenNameSpacing(by extra: CGFloat) {
        guard let parent = nameLabel.superview else { return }
        for constraint in parent.constraints {
            if constraint.firstItem === nameLabel && constraint.firstAttribute == .top {
                constraint.constant += extra
                return
            }
            if constraint.secondItem === nameLabel && constraint.secondAttribute == .top {
                constraint.constant -= extra
                return
            }
        }
    }

    // MARK: - The model

    private func buildMock() {
        card.translatesAutoresizingMaskIntoConstraints = false
        card.layer.cornerRadius = 12
        card.layer.cornerCurve = .continuous
        card.layer.masksToBounds = true
        card.backgroundColor = .black
        mockContainer.addSubview(card)

        mockContainer.layer.masksToBounds = false
        mockContainer.layer.shadowColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        mockContainer.layer.shadowOffset = CGSize(width: 0, height: 0)
        mockContainer.layer.shadowOpacity = 0.5
        mockContainer.layer.shadowRadius = 6

        backgrounds.isPagingEnabled = true
        backgrounds.showsHorizontalScrollIndicator = false
        backgrounds.contentInsetAdjustmentBehavior = .never
        backgrounds.delegate = self
        backgrounds.backgroundColor = .clear
        backgrounds.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(backgrounds)

        // The last background, then all of them, then the first. Swiping past either end
        // lands on a copy of what is at the other, and the strip is silently moved to the real
        // one while it is standing still - so the row has no ends to run into and the wrap is
        // never seen happening
        let strip = [GameBackground.allCases.last!] + GameBackground.allCases
            + [GameBackground.allCases.first!]

        for option in strip {
            let layer = GameBackgroundView()
            layer.background = option
            backgrounds.addSubview(layer)
            layers.append(layer)
        }

        mock.translatesAutoresizingMaskIntoConstraints = false
        mock.themeIndex = ballSetting
        mock.isUserInteractionEnabled = false
        // The scene sits on top and never moves. Touches belong to the strip behind it
        card.addSubview(mock)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: mockContainer.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: mockContainer.centerYAnchor),
            card.topAnchor.constraint(equalTo: mockContainer.topAnchor),
            card.bottomAnchor.constraint(equalTo: mockContainer.bottomAnchor),
            card.widthAnchor.constraint(lessThanOrEqualTo: mockContainer.widthAnchor),

            backgrounds.topAnchor.constraint(equalTo: card.topAnchor),
            backgrounds.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            backgrounds.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            backgrounds.trailingAnchor.constraint(equalTo: card.trailingAnchor),

            mock.topAnchor.constraint(equalTo: card.topAnchor),
            mock.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            mock.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            mock.trailingAnchor.constraint(equalTo: card.trailingAnchor)
        ])

        card.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(tapped)))
        // Swiping browses, tapping takes it. The background on screen is already the setting,
        // so the tap is not what chooses - it is the way out, said in the place a player is
        // already looking rather than at the close button
    }

    @objc private func tapped() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        close()
    }

    /// Shapes the model to the playfield it is a model of, and lays the strip out behind it.
    ///
    /// The picture is the device's own play area, so the card is that shape rather than the
    /// card being a shape and the picture sitting letterboxed inside it.
    private func refreshMockShape() {
        let screen = view.window?.bounds.size ?? view.bounds.size
        let inset = view.window?.safeAreaInsets.bottom ?? view.safeAreaInsets.bottom

        mock.screen = screen
        mock.bottomInset = inset
        for layer in layers {
            layer.screen = screen
            layer.bottomInset = inset
        }

        let modelled = mock.modelledSize
        let ratio = modelled.width/max(modelled.height, 1)
        if abs((mockAspect?.multiplier ?? 0) - ratio) > 0.001 {
            mockAspect?.isActive = false
            let aspect = card.widthAnchor.constraint(equalTo: card.heightAnchor,
                                                     multiplier: ratio)
            aspect.priority = .required
            aspect.isActive = true
            mockAspect = aspect
        }

        let size = backgrounds.bounds.size
        guard size.width > 0, size.height > 0 else { return }
        guard size != laidOut else { return }
        laidOut = size
        // Only when it has actually changed: laying the strip out sets a content offset, and
        // doing that on every layout pass would drag the player's swipe back

        for (index, layer) in layers.enumerated() {
            layer.frame = CGRect(x: size.width*CGFloat(index), y: 0,
                                 width: size.width, height: size.height)
        }
        backgrounds.contentSize = CGSize(width: size.width*CGFloat(layers.count),
                                         height: size.height)
        backgrounds.contentOffset = CGPoint(x: size.width*CGFloat(page(of: selected)), y: 0)
    }

    // MARK: - Choosing

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === backgrounds, scrollView.bounds.width > 0 else { return }
        pageControl.currentPage = background(atPage: page(in: scrollView)).rawValue
        // The dots follow the finger rather than waiting for the page to settle, so the swipe
        // has something answering it while it is happening
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        settle(scrollView)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        settle(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard decelerate == false else { return }
        settle(scrollView)
        // A slow drag that lands without momentum never decelerates, so it would otherwise
        // change the picture without changing the setting
    }

    /// Where a background sits in the strip, which is one along from its own index because of
    /// the copy at the front.
    private func page(of background: GameBackground) -> Int {
        background.rawValue + 1
    }

    /// Which page of the strip is showing, copies included.
    private func page(in scrollView: UIScrollView) -> Int {
        let page = Int((scrollView.contentOffset.x/max(scrollView.bounds.width, 1)).rounded())
        return min(max(page, 0), layers.count - 1)
    }

    /// Which background a page of the strip is, reading the copies as what they are copies of.
    private func background(atPage page: Int) -> GameBackground {
        let count = GameBackground.allCases.count
        let index = ((page - 1) % count + count) % count
        return GameBackground.allCases[index]
    }

    /// Takes whichever background the strip came to rest on.
    ///
    /// Committing on arrival rather than on a confirm button: the background you are looking
    /// at is the answer to the question the screen is asking.
    private func settle(_ scrollView: UIScrollView) {
        guard scrollView === backgrounds else { return }
        let landed = page(in: scrollView)
        let background = background(atPage: landed)

        // Standing on a copy: put the strip on the real one, without animating, so what the
        // player sees does not change and the row has somewhere to go next time
        if landed == 0 || landed == layers.count - 1 {
            scrollView.setContentOffset(CGPoint(x: scrollView.bounds.width*CGFloat(page(of: background)),
                                                y: 0), animated: false)
        }

        guard background != selected else { return }

        selected = background
        defaults.set(background.rawValue, forKey: "backgroundSetting")
        NotificationCenter.default.post(name: .backgroundSettingChanged, object: nil)
        // The scene is live behind the pause menu, so it repaints rather than waiting for
        // the next level

        if hapticsSetting { interfaceHaptic.impactOccurred() }
        updateLabels()
    }

    private func updateLabels() {
        nameLabel.text = selected.name.uppercased()
        pageControl.currentPage = selected.rawValue
    }

    private func close() {
        menuNavigationGoBack()
    }

    // MARK: - The close button

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "iconCell",
                                                      for: indexPath) as! MainMenuCollectionViewCell
        cell.frame.size.height = 50
        cell.frame.size.width = cell.frame.size.height
        cell.widthConstraint.constant = 40
        cell.iconImage.image = UIImage(named: "ButtonClose.png")

        UIView.animate(withDuration: 0.1) {
            cell.view.transform = .identity
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        close()
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if let cell = backButtonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .init(scaleX: 0.95, y: 0.95)
                cell.iconImage.image = UIImage(named: "ButtonCloseHighlighted.png")
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = backButtonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .identity
                cell.iconImage.image = UIImage(named: "ButtonClose.png")
            }
        }
    }

    private func closeButtonLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 50, height: 50)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }

    // MARK: - Housekeeping

    func userSettings() {
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        ballSetting = defaults.integer(forKey: "ballSetting")
        // Load user settings
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
        self.view.alpha = 0.0
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
        NotificationCenter.default.post(name: .reanimateNotificiation, object: nil)
    }

    func removeAnimate() {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.view.alpha = 0.0})
        { (finished: Bool) in
            if (finished) {
                self.view.removeFromSuperview()
            }
        }
    }

    @objc func refreshViewForSyncNotificationKeyReceived(notification: Notification) {
        userSettings()
        mock.themeIndex = ballSetting
        backButtonCollectionView.reloadData()
    }
    // Runs when the NSUbiquitousKeyValueStore changes
}
