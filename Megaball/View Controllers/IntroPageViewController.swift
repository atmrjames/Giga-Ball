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
        let imageView = ["IntroView1", "IntroView2", "IntroView3", "IntroView4", "IntroView5"]
        
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
