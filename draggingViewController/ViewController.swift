//
//  ViewController.swift
//  draggingViewController
//
//  Created by Vincent Douant on 31/10/2018.
//  Copyright © 2018 Vincent Douant. All rights reserved.
//

import UIKit


let DraggingViewShadowTag: Int = 18267
let DraggingViewAnimationDuration: TimeInterval = 0.25

extension UIView {
    var draggingConstraint: NSLayoutConstraint? {
        return superview?.constraints.first(where: { $0.firstAnchor == self.topAnchor })
    }
}

extension UIViewController : UIGestureRecognizerDelegate {
    var stickyOffset: CGFloat {
        return self.view.frame.height / 2
    }
    func presentDraggingViewController(_ viewController: UIViewController) {
        let container = UIView()
        container.frame = self.view.frame

        let shadow = UIView()
        shadow.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        shadow.frame = self.view.frame
        shadow.alpha = 0
        shadow.tag = DraggingViewShadowTag
        container.addSubview(shadow)
        shadow.translatesAutoresizingMaskIntoConstraints = false
        shadow.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        shadow.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        shadow.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        shadow.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true

        let draggingView = viewController.view!
//        draggingView.frame = CGRect(origin: CGPoint(x: 0, y: container.frame.height), size: container.frame.size)
        container.addSubview(draggingView)
        draggingView.translatesAutoresizingMaskIntoConstraints = false
        draggingView.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        draggingView.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        draggingView.topAnchor.constraint(equalTo: container.topAnchor, constant: container.frame.height).isActive = true
        draggingView.heightAnchor.constraint(equalTo: container.heightAnchor, constant: 0).isActive = true


        let gesture = UIPanGestureRecognizer(target: self, action: #selector(UIViewController.draggingViewMove(gesture:)))
        gesture.delegate = self
        gesture.minimumNumberOfTouches = 1
        gesture.maximumNumberOfTouches = 1
        let touchView = UIView()
        touchView.backgroundColor = .blue
        draggingView.addSubview(touchView)
        touchView.addGestureRecognizer(gesture)
        touchView.translatesAutoresizingMaskIntoConstraints = false
        touchView.centerXAnchor.constraint(equalTo: draggingView.centerXAnchor).isActive = true
        touchView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        touchView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        touchView.topAnchor.constraint(equalTo: draggingView.topAnchor).isActive = true

        viewController.willMove(toParent: self)
        self.addChild(viewController)
        self.view.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        container.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        container.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        container.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        viewController.didMove(toParent: self)


        container.layoutIfNeeded()
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            shadow.alpha = 1
//           draggingView.frame.origin.y = self.stickyOffset
            draggingView.draggingConstraint?.constant = self.stickyOffset
            container.layoutIfNeeded()
        }, completion: { (_) -> Void in
            touchView.bringSubviewToFront(draggingView)
        })
    }

    func dismissDraggingViewController(_ viewController: UIViewController) {
        viewController.willMove(toParent: nil)

        let draggingView = viewController.view!

        UIView.animate(withDuration: DraggingViewAnimationDuration, animations: { () -> Void in
//            draggingView.frame.origin.y = self.view.frame.height
            draggingView.draggingConstraint?.constant = self.view.frame.height
            draggingView.superview?.viewWithTag(DraggingViewShadowTag)?.alpha = 0
            draggingView.superview?.layoutIfNeeded()
        }, completion: { (_) -> Void in
            draggingView.superview?.removeFromSuperview()
            viewController.removeFromParent()
            viewController.didMove(toParent: nil)
        })
    }

    @objc func draggingViewMove(gesture: UIPanGestureRecognizer) {
        guard let draggingView = gesture.view?.superview else { return }
        let delta = gesture.translation(in: draggingView)
        let velocity = gesture.velocity(in: draggingView)
        let magnitude = sqrtf(Float((velocity.x * velocity.x) + (velocity.y * velocity.y)))
        print("velocity \(velocity) magnitude \(magnitude) delta \(delta)")
        switch gesture.state {
        case .changed:
            let y = draggingView.frame.origin.y + delta.y
            if y <= stickyOffset {
//                draggingView.frame.origin.y = max(y, 0)

                draggingView.draggingConstraint?.constant = max(y, self.view.safeAreaInsets.top)
            }
            break
        case .ended:
            var duration = TimeInterval(draggingView.frame.origin.y / abs(velocity.y))
            duration = DraggingViewAnimationDuration
            if velocity.y < 0 || velocity.y == 0 && draggingView.frame.origin.y < stickyOffset / 2 {
                print("top")
                UIView.animate(withDuration: duration, animations: {
                    //                    draggingView.frame.origin.y = 0
                    draggingView.draggingConstraint?.constant = self.view.safeAreaInsets.top
                    draggingView.superview?.layoutIfNeeded()
                    (draggingView.draggingConstraint?.secondItem as? UIView)?.layoutIfNeeded()
                })
            } else if draggingView.frame.origin.y == stickyOffset {
                print("bottom")
                self.dismissDraggingViewController(draggingView.next as! UIViewController)
            } else {
                print("stickyOffset")
                UIView.animate(withDuration: duration, animations: {
//                    draggingView.frame.origin.y = self.stickyOffset
                    draggingView.draggingConstraint?.constant = self.stickyOffset
                    draggingView.superview?.layoutIfNeeded()
                })
            }
            break
        default:
            return
        }
        gesture.setTranslation(CGPoint.zero, in: draggingView.superview)
    }

    private func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

protocol DraggingViewControllerProtocol {
    func DVC_viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
}

extension DraggingViewControllerProtocol where Self: UIViewController {
    func DVC_viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if self.view.draggingConstraint?.constant != 0 {
            self.view.draggingConstraint?.constant = size.height / 2
        }
    }
}

class CollectionViewCell: UICollectionViewCell {

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .orange
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class DraggingViewController : UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, DraggingViewControllerProtocol {

    var collectionView: UICollectionView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView?.register(CollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        view.addSubview(collectionView!)
        collectionView?.translatesAutoresizingMaskIntoConstraints = false
        collectionView?.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView?.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView?.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        collectionView?.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        collectionView?.dataSource = self
        collectionView?.delegate = self

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("viewDidDisappear")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("viewWillDisappear")
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        DVC_viewWillTransition(to: size, with: coordinator)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 100
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 50, height: 50)
    }
}

class ViewController: UIViewController {

    let button = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        button.setTitle("Show", for: .normal)
        button.backgroundColor = .yellow
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 100).isActive = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        button.addTarget(self, action: #selector(showDraggingView), for: .touchUpInside)
    }

    @objc func showDraggingView() {
        presentDraggingViewController(DraggingViewController())
    }
}

