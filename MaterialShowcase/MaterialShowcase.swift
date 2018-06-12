//
//  MaterialShowcase.swift
//  MaterialShowcase
//
//  Created by Quang Nguyen on 5/4/17.
//  Copyright © 2017 Aromajoin. All rights reserved.
//
import UIKit

@objc public protocol MaterialShowcaseDelegate: class {
  @objc optional func showCaseWillDismiss(showcase: MaterialShowcase, didTapTarget:Bool)
  @objc optional func showCaseDidDismiss(showcase: MaterialShowcase, didTapTarget:Bool)
}

public class MaterialShowcase: UIView {
  
  @objc public enum BackgroundTypeStyle: Int {
    case circle //default
    case full//full screen
  }
  
  @objc public enum RippleType: Int {
    case circle //default
    case square // same size of view
  }
  
  @objc public enum CloseType: Int {
    case expand //default
    case collapse // collapse to target
  }
  
  // MARK: Material design guideline constant
  let BACKGROUND_ALPHA: CGFloat = 0.96
  let TARGET_HOLDER_RADIUS: CGFloat = 44
  let TEXT_CENTER_OFFSET: CGFloat = 44 + 20
  let INSTRUCTIONS_CENTER_OFFSET: CGFloat = 20
  let LABEL_MARGIN: CGFloat = 40
  let TARGET_PADDING: CGFloat = 20
  
  // Other default properties
  let LABEL_DEFAULT_HEIGHT: CGFloat = 50
  let BACKGROUND_DEFAULT_COLOR = UIColor.fromHex(hexString: "#2196F3")
  let TARGET_HOLDER_COLOR = UIColor.white
  
  // MARK: Animation properties
  var ANI_COMEIN_DURATION: TimeInterval = 0.5 // second
  var ANI_GOOUT_DURATION: TimeInterval = 0.5  // second
  var ANI_TARGET_HOLDER_SCALE: CGFloat = 2.2
  let ANI_RIPPLE_COLOR = UIColor.white
  let ANI_RIPPLE_ALPHA: CGFloat = 0.5
  let ANI_RIPPLE_SCALE: CGFloat = 1.6
  
  var offsetThreshold: CGFloat = 88
  
  // MARK: Private view properties
  var containerView: UIView!
  var targetView: UIView!
  var backgroundView: UIView!
  var targetHolderView: UIView!
  var hiddenTargetHolderView: UIView!
  var targetRippleView: UIView!
  var targetCopyView: UIView!
  var instructionView: MaterialShowcaseInstructionView!
  
  // MARK: Public Properties
  
  // Background
  @objc public var backgroundPromptColor: UIColor!
  @objc public var backgroundPromptColorAlpha: CGFloat = 0.0
  @objc public var backgroundViewType: BackgroundTypeStyle = .circle
  // Tap zone settings
  // - false: recognize tap from all displayed showcase.
  // - true: recognize tap for targetView area only.
  @objc public var isTapRecognizerForTagretView: Bool = false
  // Target
  @objc public var shouldSetTintColor: Bool = true
  @objc public var targetTintColor: UIColor!
  @objc public var targetHolderRadius: CGFloat = 0.0
  @objc public var targetHolderColor: UIColor!
  @objc public var targetBoundsInset: CGPoint = CGPoint.zero
  // Text
  @objc public var primaryText: String!
  @objc public var secondaryText: String!
  @objc public var primaryTextColor: UIColor!
  @objc public var secondaryTextColor: UIColor!
  @objc public var primaryTextSize: CGFloat = 0.0
  @objc public var secondaryTextSize: CGFloat = 0.0
  @objc public var primaryTextFont: UIFont?
  @objc public var secondaryTextFont: UIFont?
  @objc public var primaryTextAlignment: NSTextAlignment = .left
  @objc public var secondaryTextAlignment: NSTextAlignment = .left
  // Animation
  @objc public var aniComeInDuration: TimeInterval = 0.0
  @objc public var aniGoOutDuration: TimeInterval = 0.0
  @objc public var aniRippleScale: CGFloat = 0.0
  @objc public var aniRippleColor: UIColor!
  @objc public var aniRippleAlpha: CGFloat = 0.0
  @objc public var aniRippleType: RippleType = .circle
  @objc public var aniCloseType: CloseType = .expand
  @objc public var aniCloseAnimationCurve: CAMediaTimingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0, 1, 1) //CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
  @objc public var aniOpenAnimationCurve: CAMediaTimingFunction = CAMediaTimingFunction(controlPoints: 0, 0, 0.2, 1) //CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)


  
  // Delegate
  @objc public weak var delegate: MaterialShowcaseDelegate?
  
  public init() {
    // Create frame
    let frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    super.init(frame: frame)
    
    configure()
  }
  
  // No supported initilization method
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - Public APIs
extension MaterialShowcase {
  
  /// Sets a general UIView as target
  @objc public func setTargetView(view: UIView) {
    targetView = view
    if let label = targetView as? UILabel {
      targetTintColor = label.textColor
      backgroundPromptColor = label.textColor
    } else if let button = targetView as? UIButton {
      let tintColor = button.titleColor(for: .normal)
      targetTintColor = tintColor
      backgroundPromptColor = tintColor
    } else {
      targetTintColor = targetView.tintColor
      backgroundPromptColor = targetView.tintColor
    }
  }
  
  /// Sets a UIBarButtonItem as target
  @objc public func setTargetView(barButtonItem: UIBarButtonItem) {
    if let view = (barButtonItem.value(forKey: "view") as? UIView)?.subviews.first {
      targetView = view
    }
  }
  
  /// Sets a UITabBar Item as target
  @objc public func setTargetView(tabBar: UITabBar, itemIndex: Int) {
    let tabBarItems = orderedTabBarItemViews(of: tabBar)
    if itemIndex < tabBarItems.count {
      targetView = tabBarItems[itemIndex]
      targetTintColor = tabBar.tintColor
      backgroundPromptColor = tabBar.tintColor
    } else {
      print ("The tab bar item index is out of range")
    }
  }
  
  /// Sets a UITableViewCell as target
  @objc public func setTargetView(tableView: UITableView, section: Int, row: Int) {
    let indexPath = IndexPath(row: row, section: section)
    targetView = tableView.cellForRow(at: indexPath)//?.contentView
    // for table viewcell, we do not need target holder (circle view)
    // therefore, set its radius = 0
    targetHolderRadius = 0
  }
  
  /// Shows it over current screen after completing setup process
  @objc public func show(animated: Bool = true, completion handler: (()-> Void)?) {
    initViews()
    alpha = 0.0
    containerView.addSubview(self)
    self.layoutIfNeeded()
    
    let scale = TARGET_HOLDER_RADIUS / (backgroundView.frame.width / 2)
    let center = backgroundView.center
    
    backgroundView.transform = CGAffineTransform(scaleX: scale, y: scale) // Initial set to support animation
    self.backgroundView.center = self.targetHolderView.center
    if animated {

      // LABEL FRAMES (non lo faccio con le transform perché per qualche motivo le duplica)
      let offsetY: CGFloat = 8
      let primaryFrame = self.instructionView.primaryLabel.frame
      let secondaryFrame = self.instructionView.secondaryLabel.frame
      
      self.instructionView.primaryLabel.frame = primaryFrame.offsetBy(dx: 0, dy: offsetY)
      self.instructionView.secondaryLabel.frame = secondaryFrame.offsetBy(dx: 0, dy: offsetY)
      self.instructionView.primaryLabel.alpha = 0
      self.instructionView.secondaryLabel.alpha = 0

      CATransaction.begin()
      CATransaction.setAnimationTimingFunction(aniOpenAnimationCurve)
      
      UIView.animateKeyframes(withDuration: aniComeInDuration, delay: 0, options: [], animations: {
        UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
          self.targetHolderView.transform = CGAffineTransform(scaleX: 1, y: 1)
          self.backgroundView.transform = CGAffineTransform(scaleX: 1, y: 1)
          self.backgroundView.center = center
          self.alpha = 1.0
        })

        UIView.addKeyframe(withRelativeStartTime: 0.45, relativeDuration: 0.5, animations: {
          self.instructionView.primaryLabel.frame = primaryFrame
          self.instructionView.primaryLabel.alpha = 1
        })

        UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5, animations: {
          self.instructionView.secondaryLabel.frame = secondaryFrame
          self.instructionView.secondaryLabel.alpha = 1
        })
      }) { _ in
        self.startAnimations()
      }
      
      CATransaction.commit()
    } else {
      self.alpha = 1.0
    }
    // Handler user's action after showing.
    if let handler = handler {
      handler()
    }
  }
}

// MARK: - Utility API
extension MaterialShowcase {
  /// Returns the current showcases displayed on screen.
  /// It will return null if no showcase exists.
  public static func presentedShowcases() -> [MaterialShowcase]? {
    guard let window = UIApplication.shared.delegate?.window else {
      return nil
    }
    return window?.subviews.filter({ (view) -> Bool in
      return view is MaterialShowcase
    }) as? [MaterialShowcase]
  }
}

// MARK: - Setup views internally
extension MaterialShowcase {
  
  /// Initializes default view properties
  func configure() {
    backgroundColor = UIColor.clear
    guard let window = UIApplication.shared.delegate?.window else {
      return
    }
    containerView = window
    setDefaultProperties()
  }
  
  func setDefaultProperties() {
    // Background
    backgroundPromptColor = BACKGROUND_DEFAULT_COLOR
    backgroundPromptColorAlpha = BACKGROUND_ALPHA
    // Target view
    targetTintColor = BACKGROUND_DEFAULT_COLOR
    targetHolderColor = TARGET_HOLDER_COLOR
    targetHolderRadius = TARGET_HOLDER_RADIUS
    // Text
    primaryText = MaterialShowcaseInstructionView.PRIMARY_DEFAULT_TEXT
    secondaryText = MaterialShowcaseInstructionView.SECONDARY_DEFAULT_TEXT
    primaryTextColor = MaterialShowcaseInstructionView.PRIMARY_TEXT_COLOR
    secondaryTextColor = MaterialShowcaseInstructionView.SECONDARY_TEXT_COLOR
    primaryTextSize = MaterialShowcaseInstructionView.PRIMARY_TEXT_SIZE
    secondaryTextSize = MaterialShowcaseInstructionView.SECONDARY_TEXT_SIZE
    // Animation
    aniComeInDuration = ANI_COMEIN_DURATION
    aniGoOutDuration = ANI_GOOUT_DURATION
    aniRippleAlpha = ANI_RIPPLE_ALPHA
    aniRippleColor = ANI_RIPPLE_COLOR
    aniRippleScale = ANI_RIPPLE_SCALE
  }
  
  func startAnimations() {
    
    // X & Y Deltas animation scale
    let startScaleXDelta: CGFloat = 0.1
    let startScaleYDelta: CGFloat = 0.1
    let endScaleXDelta: CGFloat = self.aniRippleScale - 1.0
    let endScaleYDelta: CGFloat = self.aniRippleScale - 1.0
    
    // Calculate ratio
    let ratio: CGFloat
    switch aniRippleType {
    case .circle:
      ratio = 1
    case .square:
      ratio = targetRippleView.frame.width / targetRippleView.frame.height
    }
    
    // Calculate transforms
    var startScaleX: CGFloat
    var startScaleY: CGFloat
    var endScaleX: CGFloat
    var endScaleY: CGFloat

    if ratio > 1 {
      startScaleX = 1.0 + ((1.0 / ratio) * startScaleXDelta)
      startScaleY = 1.0 + startScaleYDelta
      endScaleX = 1.0 + ((1.0 / ratio) * endScaleXDelta)
      endScaleY = 1.0 + endScaleYDelta
    } else {
      startScaleX = 1.0 + startScaleXDelta
      startScaleY = 1.0 + (ratio * startScaleXDelta)
      endScaleX = 1.0 + endScaleXDelta
      endScaleY = 1.0 + (ratio * endScaleXDelta)
    }
    
    let options: UIViewKeyframeAnimationOptions = [.curveEaseInOut, .repeat]
    UIView.animateKeyframes(withDuration: 1, delay: 0, options: options, animations: {
      UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5, animations: {
        self.targetRippleView.alpha = self.ANI_RIPPLE_ALPHA
        self.targetHolderView.transform = CGAffineTransform(scaleX: startScaleX, y: startScaleY)
        self.targetRippleView.transform = CGAffineTransform(scaleX: startScaleX, y: startScaleY)
      })
      
      UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5, animations: {
        self.targetHolderView.transform = CGAffineTransform.identity
        self.targetRippleView.alpha = 0
        self.targetRippleView.transform = CGAffineTransform(scaleX: endScaleX, y: endScaleY)
      })
      
    }, completion: nil)
  }
  
  func initViews() {
    let center = calculateCenter(at: targetView, to: containerView)
    
    addTargetRipple(at: center)
    addTargetHolder(at: center)
    
    // if color is not UIColor.clear, then add the target snapshot
    if targetHolderColor != .clear {
      addTarget(at: center)
    }
    
    //In iPad version InstructionView was add to backgroundView
    if UIDevice.current.userInterfaceIdiom == .pad {
      addBackground()
    }
    
    addInstructionView(at: center)
    instructionView.layoutIfNeeded()
    
    //FIX LAYOUT INSTRUCTION AFTER LAYOUT
    var frame = instructionView.frame
    let offset: CGFloat = 20
    if getTargetPosition(target: targetView, container: containerView) == .above {
      frame.origin.y = (center.y + targetView.bounds.height * 0.5) + offset
      instructionView.frame = frame
    } else {
      frame.origin.y = (center.y - targetView.bounds.height * 0.5 - frame.size.height) - offset
      instructionView.frame = frame
    }
    
    //END FIX
    
    //In iPhone version InstructionView was add to self view
    if UIDevice.current.userInterfaceIdiom != .pad {
      addBackground()
    }
    
    // Disable subview interaction to let users click to general view only
    subviews.forEach({$0.isUserInteractionEnabled = false})
    
    if isTapRecognizerForTagretView {
      //Add gesture recognizer for targetCopyView
      hiddenTargetHolderView.addGestureRecognizer(tapGestureRecoganizer())
      hiddenTargetHolderView.isUserInteractionEnabled = true
    } else {
      // Add gesture recognizer for both container and its subview
      addGestureRecognizer(tapGestureRecoganizer())
	  hiddenTargetHolderView.addGestureRecognizer(tapGestureRecoganizer())
	  hiddenTargetHolderView.isUserInteractionEnabled = true
    }
  }
  
  /// Add background which is a big circle
  private func addBackground() {
    
    switch self.backgroundViewType {
    case .circle:
      let radius: CGFloat!
      
      var center = targetRippleView.center//getOuterCircleCenterPoint(for: targetCopyView)
      
      if UIDevice.current.userInterfaceIdiom == .pad {
        radius = 300.0
      } else {
        switch aniRippleType {
        case .circle:
          //TODO: Per il momento solo con square, a circle lascio il default
          radius = getOuterCircleRadius(center: center, textBounds: instructionView.frame, targetBounds: targetRippleView.frame)
        case .square:
          let offsetPercentage = 0.1
          if getTargetPosition(target: targetView, container: containerView) == .above {
            let targetCenter = calculateCenter(at: targetView, to: containerView)
            
            let rightCorner = CGPoint(x: targetCenter.x + targetView.bounds.width * 0.5,
                                      y: targetCenter.y - targetView.bounds.height * 0.5)

            let bottomScreen = CGPoint(x: UIScreen.main.bounds.width * 0.5, y: UIScreen.main.bounds.height)
            radius = distance(rightCorner, bottomScreen)

            center = CGPoint(x: bottomScreen.x, y: bottomScreen.y - abs(targetCenter.y - bottomScreen.y) * offsetPercentage)
          } else {
            let targetCenter = calculateCenter(at: targetView, to: containerView)
            let rightCornerBottom = CGPoint(x: targetCenter.x + targetView.bounds.width * 0.5,
                                            y: targetCenter.y + targetView.bounds.height * 0.5)
            let topScreen = CGPoint(x: UIScreen.main.bounds.width * 0.5, y: 0)
            radius = distance(rightCornerBottom, topScreen)
            
            center = CGPoint(x: topScreen.x, y: topScreen.y + abs(targetCenter.y - topScreen.y) * offsetPercentage)
          }
        }
      }
      
      backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: radius * 2,height: radius * 2))
      backgroundView.center = center
      
      backgroundView.asCircle()
    case .full:
      backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width,height: UIScreen.main.bounds.height))
    }
    backgroundView.backgroundColor = backgroundPromptColor.withAlphaComponent(backgroundPromptColorAlpha)
    insertSubview(backgroundView, belowSubview: targetRippleView)
    
    switch aniRippleType {
    case .circle:
      addBackgroundMask(with: targetHolderRadius, in: backgroundView)
    case .square:
      addBackgroundMask(with: 0, in: backgroundView)
    }

  }
  
  private func addBackgroundMask(with radius: CGFloat, in view: UIView) {
    
    let center = backgroundViewType == .circle ? view.bounds.center : targetRippleView.center
    let mutablePath = CGMutablePath()
    mutablePath.addRect(view.bounds)
    mutablePath.addArc(center: center, radius: radius, startAngle: 0.0, endAngle: 2 * 3.14, clockwise: false)
    
    let mask = CAShapeLayer()
    mask.path = mutablePath
    mask.fillRule = kCAFillRuleEvenOdd
    
    view.layer.mask = mask
  }
  
  /// A background view which add ripple animation when showing target view
  private func addTargetRipple(at center: CGPoint) {
    // Init according ripple type
    switch aniRippleType {
    case .circle:
      targetRippleView = UIView(frame: CGRect(x: 0, y: 0, width: targetHolderRadius * 2,height: targetHolderRadius * 2).insetBy(dx: targetBoundsInset.x, dy: targetBoundsInset.y))
    case .square:
      targetRippleView = UIView(frame: CGRect(x: 0, y: 0, width: targetView.frame.width, height: targetView.frame.height).insetBy(dx: targetBoundsInset.x, dy: targetBoundsInset.y))
    }
    
    targetRippleView.center = center
    targetRippleView.backgroundColor = aniRippleColor
    targetRippleView.alpha = 0.0 //set it invisible
    
    switch aniRippleType {
    case .circle:
      targetRippleView.asCircle()
    case .square:
      // Do nothing... (for now!)
      break
    }

    
    addSubview(targetRippleView)
  }
	
  
  /// A shape background view of target view
  private func addTargetHolder(at center: CGPoint) {
    hiddenTargetHolderView = UIView()
    hiddenTargetHolderView.backgroundColor = .clear
    
    switch aniRippleType {
    case .circle:
      targetHolderView = UIView(frame: CGRect(x: 0, y: 0, width: targetHolderRadius * 2,height: targetHolderRadius * 2).insetBy(dx: targetBoundsInset.x, dy: targetBoundsInset.y))
    case .square:
      targetHolderView = UIView(frame: CGRect(x: 0, y: 0, width: targetView.frame.width,height: targetView.frame.height).insetBy(dx: targetBoundsInset.x, dy: targetBoundsInset.y))
    }
    
    targetHolderView.center = center
    targetHolderView.backgroundColor = targetHolderColor

    switch aniRippleType {
    case .circle:
      targetHolderView.asCircle()
    case .square:
      // Do nothing... (for now!)
      break
    }

    hiddenTargetHolderView.frame = targetHolderView.frame
    targetHolderView.transform = CGAffineTransform(scaleX: 1/ANI_TARGET_HOLDER_SCALE, y: 1/ANI_TARGET_HOLDER_SCALE) // Initial set to support animation
    addSubview(hiddenTargetHolderView)
    addSubview(targetHolderView)
  }
  
  /// Create a copy view of target view
  /// It helps us not to affect the original target view
  private func addTarget(at center: CGPoint) {
    let frame = targetView.bounds.insetBy(dx: targetBoundsInset.x, dy: targetBoundsInset.y)
    targetCopyView = targetView.resizableSnapshotView(from: frame,
                                                      afterScreenUpdates: true,
                                                      withCapInsets: .zero)

    
    if shouldSetTintColor {
      targetCopyView.setTintColor(targetTintColor, recursive: true)
      
      if targetCopyView is UIButton {
        let button = targetView as! UIButton
        let buttonCopy = targetCopyView as! UIButton
        buttonCopy.setImage(button.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
        buttonCopy.setTitleColor(targetTintColor, for: .normal)
        buttonCopy.isEnabled = true
      } else if targetCopyView is UIImageView {
        let imageView = targetView as! UIImageView
        let imageViewCopy = targetCopyView as! UIImageView
        imageViewCopy.image = imageView.image?.withRenderingMode(.alwaysTemplate)
      } else if let imageViewCopy = targetCopyView.subviews.first as? UIImageView,
        let labelCopy = targetCopyView.subviews.last as? UILabel {
        let imageView = targetView.subviews.first as! UIImageView
        imageViewCopy.image = imageView.image?.withRenderingMode(.alwaysTemplate)
        labelCopy.textColor = targetTintColor
      } else if let label = targetCopyView as? UILabel {
        label.textColor = targetTintColor
      }
    }
    
    let width = targetCopyView.frame.width
    let height = targetCopyView.frame.height
    targetCopyView.frame = CGRect(x: 0, y: 0, width: width, height: height)
    targetCopyView.center = center
    targetCopyView.translatesAutoresizingMaskIntoConstraints = true
    
    addSubview(targetCopyView)
  }
  
  /// Configures and adds primary label view
  private func addInstructionView(at center: CGPoint) {
    instructionView = MaterialShowcaseInstructionView()
    
    instructionView.primaryTextAlignment = primaryTextAlignment
    instructionView.primaryTextFont = primaryTextFont
    instructionView.primaryTextSize = primaryTextSize
    instructionView.primaryTextColor = primaryTextColor
    instructionView.primaryText = primaryText
    
    instructionView.secondaryTextAlignment = secondaryTextAlignment
    instructionView.secondaryTextFont = secondaryTextFont
    instructionView.secondaryTextSize = secondaryTextSize
    instructionView.secondaryTextColor = secondaryTextColor
    instructionView.secondaryText = secondaryText
    
    // Calculate x position
    var xPosition = LABEL_MARGIN
    
    // Calculate y position
    var yPosition: CGFloat!
    
    // Calculate instructionView width
    var width : CGFloat
    
    if UIDevice.current.userInterfaceIdiom == .pad {
      width = backgroundView.frame.width - xPosition
      
      if backgroundView.frame.origin.x < 0 {
        xPosition = abs(backgroundView.frame.origin.x) + xPosition
      } else if (backgroundView.frame.origin.x + backgroundView.frame.size.width >
        UIScreen.main.bounds.width) {
        width = backgroundView.frame.size.width - (xPosition*2)
      }
      if xPosition + width > backgroundView.frame.size.width {
        width = width - CGFloat(xPosition/2)
      }
      
      if getTargetPosition(target: targetView, container: containerView) == .above {
        yPosition = (backgroundView.frame.size.height/2) + TEXT_CENTER_OFFSET
      } else {
        yPosition = TEXT_CENTER_OFFSET + LABEL_DEFAULT_HEIGHT * 2
      }
    } else {
      if getTargetPosition(target: targetView, container: containerView) == .above {
        
        yPosition = center.y + TARGET_PADDING +  (targetView.bounds.height / 2 > self.targetHolderRadius ? targetView.bounds.height / 2 : self.targetHolderRadius)
        
      } else {
        yPosition = center.y - TEXT_CENTER_OFFSET - LABEL_DEFAULT_HEIGHT * 2
      }
      
      width = containerView.frame.width - (xPosition + xPosition)
    }
    
    instructionView.frame = CGRect(x: xPosition,
                                   y: yPosition,
                                   width: width ,
                                   height: 0)
    if UIDevice.current.userInterfaceIdiom == .pad {
      backgroundView.addSubview(instructionView)
    } else {
      addSubview(instructionView)
    }
  }
  
  /// Handles user's tap
  private func tapGestureRecoganizer() -> UIGestureRecognizer {
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(MaterialShowcase.tapGestureSelector))
    tapGesture.numberOfTapsRequired = 1
    tapGesture.numberOfTouchesRequired = 1
    return tapGesture
  }
  
  @objc private func tapGestureSelector(tapGesture:UITapGestureRecognizer) {
	completeShowcase(didTapTarget: tapGesture.view === hiddenTargetHolderView)
  }
  
  /// Default action when dimissing showcase
  /// Notifies delegate, removes views, and handles out-going animation
	@objc public func completeShowcase(animated: Bool = true, didTapTarget: Bool = false) {
    if delegate != nil && delegate?.showCaseDidDismiss != nil {
      delegate?.showCaseWillDismiss?(showcase: self, didTapTarget: didTapTarget)
    }
    if animated {
      targetRippleView.removeFromSuperview()
      
      switch self.aniCloseType {
      case.expand:
        UIView.animateKeyframes(withDuration: aniGoOutDuration, delay: 0, options: [], animations: {
          UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 3/5, animations: {
            self.backgroundView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            self.targetHolderView.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
            self.backgroundView.alpha = 0
          })
          UIView.addKeyframe(withRelativeStartTime: 3/5, relativeDuration: 2/5, animations: {
            self.alpha = 0
          })
        }, completion: { (success) in
          // Recycle subviews
          self.recycleSubviews()
          // Remove it from current screen
          self.removeFromSuperview()
        })
      case .collapse:

        let minAxis = min(targetView.frame.width, targetView.frame.height)
        let scaleX = minAxis / self.backgroundView.frame.width
        let scaleY = minAxis / self.backgroundView.frame.height

        
        let offsetY: CGFloat = 8
        let primaryFrame = self.instructionView.primaryLabel.frame
        let secondaryFrame = self.instructionView.secondaryLabel.frame

        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(aniCloseAnimationCurve)

        UIView.animateKeyframes(withDuration: aniGoOutDuration, delay: 0, options: [], animations: {
          UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
            self.backgroundView.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
          })

          UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.6, animations: {
            self.instructionView.primaryLabel.frame = primaryFrame.offsetBy(dx: 0, dy: offsetY)
            self.instructionView.primaryLabel.alpha = 0
          })

          UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.6, animations: {
            self.instructionView.secondaryLabel.frame = secondaryFrame.offsetBy(dx: 0, dy: offsetY)
            self.instructionView.secondaryLabel.alpha = 0
          })
          
        }, completion: { (success) in
          // Recycle subviews
          self.recycleSubviews()
          // Remove it from current screen
          self.removeFromSuperview()
        })
        
        CATransaction.commit()
      }
    } else {
      // Recycle subviews
      self.recycleSubviews()
      // Remove it from current screen
      self.removeFromSuperview()
    }
    if delegate != nil && delegate?.showCaseDidDismiss != nil {
      delegate?.showCaseDidDismiss?(showcase: self, didTapTarget: didTapTarget)
    }
  }
  
  private func recycleSubviews() {
    subviews.forEach({$0.removeFromSuperview()})
  }
}

// MARK: - Private helper methods
extension MaterialShowcase {
  
  /// Defines the position of target view
  /// which helps to place texts at suitable positions
  enum TargetPosition {
    case above // at upper screen part
    case below // at lower screen part
  }
  
  /// Detects the position of target view relative to its container
  func getTargetPosition(target: UIView, container: UIView) -> TargetPosition {
    let center = calculateCenter(at: targetView, to: container)
    if center.y < container.frame.height / 2{
      return .above
    } else {
      return .below
    }
  }
  
  // Calculates the center point based on targetview
  func calculateCenter(at targetView: UIView, to containerView: UIView) -> CGPoint {
    let targetRect = targetView.convert(targetView.bounds , to: containerView)
    return targetRect.center
  }
  
  // Gets all UIView from TabBarItem.
  func orderedTabBarItemViews(of tabBar: UITabBar) -> [UIView] {
    let interactionViews = tabBar.subviews.filter({$0.isUserInteractionEnabled})
    return interactionViews.sorted(by: {$0.frame.minX < $1.frame.minX})
  }
}
