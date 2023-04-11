//
//  GuideViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/04/02.
//

import UIKit

//[iOS/UI] Swift 스크롤뷰로 이미지 페이지처럼 넘기기(Image Paging with UIScrollView)
//https://fomaios.tistory.com/entry/Swift-%EC%8A%A4%ED%81%AC%EB%A1%A4%EB%B7%B0%EB%A1%9C-%EC%9D%B4%EB%AF%B8%EC%A7%80-%ED%8E%98%EC%9D%B4%EC%A7%80%EC%B2%98%EB%9F%BC-%EB%84%98%EA%B8%B0%EA%B8%B0Image-Paging-with-UIScrollView

//[iOS] 커스텀 UIView - xib이용하기 (2가지 방법)
//https://dongminyoon.tistory.com/50

extension UIView {
    static func loadFromNib<T>() -> T? {
        let identifier = String(describing: T.self)
        let view = Bundle.main.loadNibNamed(identifier, owner: self, options: nil)?.first
        return view as? T
    }
}

class GuideViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    //var images = [#imageLiteral(resourceName: "google logo"), #imageLiteral(resourceName: "ellipse"), #imageLiteral(resourceName: "google logo")]
    @IBOutlet weak var startButton: UIButton!
    
    var images = [#imageLiteral(resourceName: "Guide1"), #imageLiteral(resourceName: "Guide2")]
    var imagesViews = [UIImageView]()
    
    //let views : [UIView] = [FirstView(), SecondView(), ThirdView()]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        
        addContentScrollView()
        setPageControl()
    }
    
    let FirstView : FirstView? = UIView.loadFromNib()
    let SecondView : SecondView? = UIView.loadFromNib()
    let ThirdView : ThirdView? = UIView.loadFromNib()
    
    private func addContentScrollView() {
        
        let viewNames = [FirstView, SecondView, ThirdView]
        for i in 0..<viewNames.count {
            //var uiView = views[i]
            let uiViewName = viewNames[i]
            let xPos = scrollView.frame.width * CGFloat(i)
            
            uiViewName?.frame = CGRect(x: xPos, y: 0, width: scrollView.bounds.width, height: scrollView.bounds.height)
            scrollView.addSubview(uiViewName!)
            scrollView.contentSize.width = uiViewName!.frame.width * CGFloat(i + 1)
        }
    }
        
    private func setPageControl() {
        pageControl.numberOfPages = 3
    }
    
    private func setPageControlSelectedPage(currentPage:Int) {
        pageControl.currentPage = currentPage
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let value = scrollView.contentOffset.x/scrollView.frame.size.width
        setPageControlSelectedPage(currentPage: Int(round(value)))
    }

    @IBAction func startButtonPressed(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let initialNavigationController = storyboard.instantiateViewController(identifier: "NavigationController")
        initialNavigationController.modalPresentationStyle = .fullScreen
        self.show(initialNavigationController, sender: UIButton())
    }
    
}
