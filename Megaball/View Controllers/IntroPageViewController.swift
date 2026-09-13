//
//  IntroPageViewController.swift
//  Megaball
//
//  Created by James Harding on 30/07/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class IntroPageViewController: UIPageViewController, UIPageViewControllerDataSource {
//    , UIPageViewControllerDelegate
    
    var items: [UIViewController] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        populateItems()
        
        if let firstViewController = items.first {
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
    }

    func populateItems() {
        let imageView = ["IntroView1", "IntroView8", "IntroView2", "IntroView3", "IntroView6",
                         "IntroView7", "IntroView4", "IntroView5"]
        // Welcome, then what is new in 1.3, then the four modes in the order the main menu
        // lists them - Classic, Endless, Endless Mayhem, Daily Challenge - then Power-Ups and
        // Tips & Tricks as before (James's 1.3 pages, round 322). The names are the order they
        // were drawn in, not the order they are read in: 6 is Endless Mayhem, 7 the Daily
        // Challenge, and 8 the Version 1.3 page, which arrived as "IntroView6 Copy"
        
        for t in imageView {
            let c = createCarouselItemController(with: t)
            items.append(c)
        }
    }
    
    func createCarouselItemController(with imageView: String) -> UIViewController {
        let c = UIViewController()
        c.view = IntroContainerView(imageView: imageView)
        return c
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return items.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstViewController = viewControllers?.first,
            let firstViewControllerIndex = items.firstIndex(of: firstViewController) else {
                return 0
        }
        return firstViewControllerIndex
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let viewControllerIndex = items.firstIndex(of: viewController) else {
            return nil
        }
        
        var previousIndex = 0
        if viewControllerIndex > 0 {
            previousIndex = viewControllerIndex - 1
        } else {
            return nil
        }
        
        return items[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let viewControllerIndex = items.firstIndex(of: viewController) else {
            return nil
        }
        
        var nextIndex = 0
        if viewControllerIndex < items.count-1 {
            nextIndex = viewControllerIndex + 1
        } else {
            return nil
        }
        
        return items[nextIndex]
    }

}
