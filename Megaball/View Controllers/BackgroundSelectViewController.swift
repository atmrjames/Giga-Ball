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
//  One game view, and swiping swaps the background under it. The scene is the constant and the
//  background is the variable, so a row of four scenes said the opposite of what the screen is
//  for - and made the picture of each a quarter of the size it could be.
//

import UIKit

class BackgroundSelectViewController: UIViewController, UICollectionViewDelegate,
                                      UICollectionViewDataSource {

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

    private let mock = GameSceneMockView()
    private var mockAspect: NSLayoutConstraint?

    @IBOutlet var backgroundView: UIView!
    @IBOutlet var contentView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var mockContainer: UIView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var pageControl: UIPageControl!
    @IBOutlet var backButtonCollectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.refreshViewForSyncNotificationKeyReceived),
                                               name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by
        // the main menu screen

        titleLabel.text = "BACKGROUND"

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
        showAnimate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        limitMenuContentSize()
        backButtonCollectionView.collectionViewLayout = closeButtonLayout()
        refreshMockShape()
    }

    // MARK: - The model

    private func buildMock() {
        mock.translatesAutoresizingMaskIntoConstraints = false
        mock.background = selected
        mock.themeIndex = ballSetting
        mock.layer.cornerRadius = 12
        mock.layer.cornerCurve = .continuous
        mock.layer.masksToBounds = true
        mockContainer.addSubview(mock)

        mockContainer.layer.masksToBounds = false
        mockContainer.layer.shadowColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        mockContainer.layer.shadowOffset = CGSize(width: 0, height: 0)
        mockContainer.layer.shadowOpacity = 0.5
        mockContainer.layer.shadowRadius = 6

        NSLayoutConstraint.activate([
            mock.centerXAnchor.constraint(equalTo: mockContainer.centerXAnchor),
            mock.centerYAnchor.constraint(equalTo: mockContainer.centerYAnchor),
            mock.topAnchor.constraint(equalTo: mockContainer.topAnchor),
            mock.bottomAnchor.constraint(equalTo: mockContainer.bottomAnchor),
            mock.widthAnchor.constraint(lessThanOrEqualTo: mockContainer.widthAnchor)
        ])

        for direction in [UISwipeGestureRecognizer.Direction.left, .right] {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
            swipe.direction = direction
            mockContainer.addGestureRecognizer(swipe)
        }

        mockContainer.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(tapped)))
        // Swiping browses, tapping takes it. The background on screen is already the setting,
        // so the tap is not what chooses - it is the way out, said in the obvious place. A
        // player who has found the one they want should not have to look for the close button
    }

    @objc private func tapped() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        close()
    }

    /// Shapes the model to the playfield it is a model of.
    ///
    /// The picture is the device's own play area, so the card is that shape rather than the
    /// card being a shape and the picture sitting letterboxed inside it.
    private func refreshMockShape() {
        mock.screen = view.window?.bounds.size ?? view.bounds.size
        mock.bottomInset = view.window?.safeAreaInsets.bottom ?? view.safeAreaInsets.bottom

        let modelled = mock.modelledSize
        let ratio = modelled.width/max(modelled.height, 1)
        guard abs((mockAspect?.multiplier ?? 0) - ratio) > 0.001 else { return }

        mockAspect?.isActive = false
        let aspect = mock.widthAnchor.constraint(equalTo: mock.heightAnchor, multiplier: ratio)
        aspect.priority = .required
        aspect.isActive = true
        mockAspect = aspect
    }

    // MARK: - Choosing

    @objc private func swiped(_ gesture: UISwipeGestureRecognizer) {
        let step = gesture.direction == .left ? 1 : -1
        let wanted = selected.rawValue + step
        guard GameBackground.allCases.indices.contains(wanted) else {
            nudge(towards: step)
            return
        }
        show(GameBackground.allCases[wanted])
    }

    /// Swaps the background under the scene, and takes it as the choice.
    ///
    /// Committing on arrival rather than on a confirm button: the background you are looking
    /// at is the answer to the question the screen is asking.
    private func show(_ background: GameBackground) {
        selected = background
        defaults.set(background.rawValue, forKey: "backgroundSetting")
        NotificationCenter.default.post(name: .backgroundSettingChanged, object: nil)
        // The scene is live behind the pause menu, so it repaints rather than waiting for
        // the next level

        if hapticsSetting { interfaceHaptic.impactOccurred() }
        updateLabels()

        UIView.transition(with: mock, duration: 0.22,
                          options: [.transitionCrossDissolve, .allowUserInteraction]) {
            self.mock.background = background
        }
        // Crossfaded rather than cut. Between Solid and Classic a hard swap reads as the
        // screen having flickered rather than as something having changed
    }

    /// A small push back at either end of the list, so a swipe with nowhere to go says so
    /// rather than appearing not to have registered.
    private func nudge(towards step: Int) {
        UIView.animate(withDuration: 0.12, animations: {
            self.mock.transform = CGAffineTransform(translationX: CGFloat(-step*12), y: 0)
        }, completion: { _ in
            UIView.animate(withDuration: 0.18) { self.mock.transform = .identity }
        })
    }

    private func updateLabels() {
        nameLabel.text = selected.name
        pageControl.currentPage = selected.rawValue
    }

    private func close() {
        removeAnimate()
        NotificationCenter.default.post(name: .reanimateNotificiation, object: nil)
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
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
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
