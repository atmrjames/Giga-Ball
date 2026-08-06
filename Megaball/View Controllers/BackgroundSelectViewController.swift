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
//  So the screen swipes between scale models of the game scene, one per background, drawn at
//  this device's proportions (`GameSceneMockView`). The one on screen is the one selected: the
//  choice is made by looking, which is the only way this choice was ever going to be made.
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

    @IBOutlet var backgroundView: UIView!
    @IBOutlet var contentView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var mockCollectionView: UICollectionView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var summaryLabel: UILabel!
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

        mockCollectionView.delegate = self
        mockCollectionView.dataSource = self
        mockCollectionView.register(BackgroundMockCell.self,
                                    forCellWithReuseIdentifier: BackgroundMockCell.identifier)
        mockCollectionView.showsHorizontalScrollIndicator = false
        mockCollectionView.backgroundColor = .clear
        mockCollectionView.decelerationRate = .fast
        mockCollectionView.contentInsetAdjustmentBehavior = .never
        // Snapping is done by hand rather than with `isPagingEnabled`, which can only page a
        // full view's width. The cards are narrower than that so the next one shows at the
        // edge - a screen where something is clearly waiting to the right is one people swipe,
        // and this one is no use to anybody who does not

        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil),
                                          forCellWithReuseIdentifier: "iconCell")
        // Collection view setup

        pageControl.numberOfPages = GameBackground.allCases.count
        pageControl.isUserInteractionEnabled = false
        // The dots say where you are in the row; the row itself is how you move

        summaryLabel.numberOfLines = 2
        summaryLabel.adjustsFontSizeToFitWidth = true
        summaryLabel.minimumScaleFactor = 0.8
        // Held at two lines' height by a constraint, so a one-line summary does not shorten
        // the row of cards and move every card up as you swipe onto it

        userSettings()
        selected = GameBackground.stored(defaults.integer(forKey: "backgroundSetting"))

        if parallaxSetting {
            addParallax()
        }
        updateLabels()
        showAnimate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        limitMenuContentSize()

        applyCardLayout()
        backButtonCollectionView.collectionViewLayout = closeButtonLayout()
    }

    // MARK: - The row of cards

    /// The most of the collection view's width one card may take.
    ///
    /// Enough short of the full width that the neighbouring cards show at both edges.
    private static let cardFraction: CGFloat = 0.76
    private static let cardSpacing: CGFloat = 14

    /// A card is exactly as wide as the picture in it.
    ///
    /// The model keeps the device's shape whatever it is given, so a card wider than that
    /// would be a rounded rectangle with the picture letterboxed inside it - and the empty
    /// margins would be what shows at the edges of the screen instead of the next background.
    private var cardWidth: CGFloat {
        let screen = modelledScreen
        guard screen.height > 0 else { return 0 }
        let byHeight = mockCollectionView.bounds.height*(screen.width/screen.height)
        let byWidth = mockCollectionView.bounds.width*BackgroundSelectViewController.cardFraction
        return min(byHeight, byWidth).rounded()
    }

    /// How far the row moves between one card being centred and the next.
    private var pageWidth: CGFloat {
        max(cardWidth + BackgroundSelectViewController.cardSpacing, 1)
    }

    /// Lays the cards out centred, with the first and last able to reach the middle.
    ///
    /// Re-applied only when the size it would produce has actually changed - laying out a
    /// collection view sets a new layout, which lays it out again.
    private func applyCardLayout() {
        let size = CGSize(width: cardWidth, height: mockCollectionView.bounds.height)
        guard size.width > 0, size.height > 0, size != appliedCardSize else { return }
        appliedCardSize = size

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = size
        layout.minimumLineSpacing = BackgroundSelectViewController.cardSpacing
        layout.minimumInteritemSpacing = 0

        let margin = (mockCollectionView.bounds.width - size.width)/2
        layout.sectionInset = UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin)
        // With this inset a card is centred exactly when the offset is a whole number of
        // pages, which is what lets the snapping below be arithmetic rather than a search

        mockCollectionView.collectionViewLayout = layout
        mockCollectionView.reloadData()
        mockCollectionView.layoutIfNeeded()
        mockCollectionView.contentOffset = CGPoint(x: CGFloat(selected.rawValue)*pageWidth, y: 0)
        // Opens on the background in use, and comes back to it after a rotation - assigning a
        // layout puts the row back to the start
    }

    private var appliedCardSize: CGSize = .zero

    // MARK: - The models

    /// The screen the models are of.
    ///
    /// The device's own, so the shapes shown are the shapes the player will get. Falls back to
    /// the view's own size before there is a window to ask.
    private var modelledScreen: CGSize {
        view.window?.bounds.size ?? view.bounds.size
    }

    private var modelledBottomInset: CGFloat {
        view.window?.safeAreaInsets.bottom ?? view.safeAreaInsets.bottom
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        collectionView === backButtonCollectionView ? 1 : GameBackground.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard collectionView === mockCollectionView else {
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

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BackgroundMockCell.identifier,
                                                      for: indexPath) as! BackgroundMockCell
        cell.show(GameBackground.allCases[indexPath.item],
                  screen: modelledScreen,
                  bottomInset: modelledBottomInset,
                  theme: ballSetting)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView === backButtonCollectionView else { return }
        close()
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard collectionView === backButtonCollectionView else { return }
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
        guard collectionView === backButtonCollectionView else { return }
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

    // MARK: - Choosing

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === mockCollectionView else { return }
        // The dots follow the finger rather than waiting for the page to settle, so the swipe
        // has something to answer it while it is happening
        pageControl.currentPage = page(in: scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === mockCollectionView else { return }
        commit(page(in: scrollView))
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView === mockCollectionView else { return }
        commit(page(in: scrollView))
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView === mockCollectionView, decelerate == false else { return }
        commit(page(in: scrollView))
        // A slow drag that lands without any momentum never decelerates, so it would
        // otherwise change the picture without changing the setting
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView === mockCollectionView else { return }
        pageAtDragStart = page(in: scrollView)
    }

    /// Stops the row on a card rather than wherever the flick ran out.
    ///
    /// One card per gesture, however hard the swipe: four options do not need to be flicked
    /// past, and a picker that overshoots the one you were aiming at is a picker you fight.
    ///
    /// Counted from where the drag started rather than from where the row is now. A quick
    /// swipe has already carried the row most of a card by the time it ends, so "the page it
    /// is on, plus one" was two pages from where the finger went down.
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView === mockCollectionView else { return }

        var wanted: Int
        if velocity.x > 0.2 {
            wanted = pageAtDragStart + 1
        } else if velocity.x < -0.2 {
            wanted = pageAtDragStart - 1
        } else {
            // A slow drag goes wherever it was let go of, which may be the card it started on
            wanted = page(at: targetContentOffset.pointee.x)
        }
        wanted = min(max(wanted, 0), GameBackground.allCases.count - 1)
        targetContentOffset.pointee = CGPoint(x: CGFloat(wanted)*pageWidth, y: 0)
    }

    private var pageAtDragStart = 0

    private func page(in scrollView: UIScrollView) -> Int {
        page(at: scrollView.contentOffset.x)
    }

    private func page(at offset: CGFloat) -> Int {
        let page = Int((offset/pageWidth).rounded())
        return min(max(page, 0), GameBackground.allCases.count - 1)
    }

    /// Takes the background now on screen as the chosen one.
    ///
    /// Committing on arrival rather than on a confirm button: the page you are looking at is
    /// the answer to the question the screen is asking, and there is nothing a confirmation
    /// step would add except a way to leave with the wrong one selected.
    private func commit(_ page: Int) {
        let background = GameBackground.allCases[page]
        pageControl.currentPage = page
        guard background != selected else { return }

        selected = background
        defaults.set(background.rawValue, forKey: "backgroundSetting")
        NotificationCenter.default.post(name: .backgroundSettingChanged, object: nil)
        // The scene is live behind the pause menu, so it repaints rather than waiting for
        // the next level

        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        updateLabels()
    }

    private func updateLabels() {
        nameLabel.text = selected.name
        summaryLabel.text = selected.summary
        pageControl.currentPage = selected.rawValue
    }

    private func close() {
        removeAnimate()
        NotificationCenter.default.post(name: .reanimateNotificiation, object: nil)
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
        mockCollectionView.reloadData()
        backButtonCollectionView.reloadData()
    }
    // Runs when the NSUbiquitousKeyValueStore changes
}

/// One page of the picker: a model of the scene, with a shadow so it reads as a card lying on
/// the blurred menu behind rather than as a hole cut in it.
final class BackgroundMockCell: UICollectionViewCell {

    static let identifier = "backgroundMockCell"

    private let mock = GameSceneMockView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(mock)
        mock.translatesAutoresizingMaskIntoConstraints = false
        mock.layer.cornerRadius = 12
        mock.layer.cornerCurve = .continuous
        mock.layer.masksToBounds = true

        contentView.layer.masksToBounds = false
        contentView.layer.shadowColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        contentView.layer.shadowOffset = CGSize(width: 0, height: 0)
        contentView.layer.shadowOpacity = 0.5
        contentView.layer.shadowRadius = 6

        NSLayoutConstraint.activate([
            mock.topAnchor.constraint(equalTo: contentView.topAnchor),
            mock.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            mock.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mock.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(_ background: GameBackground, screen: CGSize, bottomInset: CGFloat, theme: Int) {
        mock.background = background
        mock.screen = screen
        mock.bottomInset = bottomInset
        mock.themeIndex = theme
    }
}
