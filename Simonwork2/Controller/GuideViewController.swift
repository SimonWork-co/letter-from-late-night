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
    @IBOutlet weak var lastView: UIView!
    @IBOutlet weak var startButton: UIButton!
    
    var images = [#imageLiteral(resourceName: "Guide1"), #imageLiteral(resourceName: "Guide2")]
    var imagesViews = [UIImageView]()
    
    //let views : [UIView] = [FirstView(), SecondView(), ThirdView()]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        
        addContentScrollView()
        setPageControl()
        lastView.isHidden = true
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
            if i == 2 {
                pageControl.addTarget(self, action: #selector(startButtonPressed), for: .touchUpInside)
                lastView.isHidden = false
                break
            }
        }
        lastView.isHidden = false
       
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
    
    
    
//    func xibSetup() { // 특정 view를 지정해야 함
//        guard let view = loadViewFromNib(nibName: "FirstView") else {
//            return
//        }
//        view.frame = bounds
//        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        addSubview(view)
//    }

//    func loadViewFromNib(nibName: String) -> UIView? {
//        let bundle = Bundle(for: type(of: self))
//        let nib = UINib(nibName: nibName, bundle: bundle)
//        return nib.instantiate(withOwner: self, options: nil).first as? UIView
//    }
    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        loadView()
//    }
//
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        loadView()
//    }
//
//    private func loadView() {
//        let view = Bundle.main.loadNibNamed("FirstView",owner: self, options: nil)?.first as! UIView
//        view.frame = bounds
//        addSubview(view)
//    }
    @objc func startButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "toSignup", sender: nil)
    }
}
