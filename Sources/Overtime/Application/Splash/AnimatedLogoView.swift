//
//  AnimatedLogoView.swift
//  
//
//  Created by Daniel Baldonado on 9/24/24.
//

import UIKit

class ORingView: UIView {
    var centerImageSize: CGSize? {
        didSet {
            setNeedsDisplay()
        }
    }

    override func tintColorDidChange() {
        setNeedsDisplay()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initView()
    }

    func initView() {
        backgroundColor = .clear
    }


    override func draw(_ rect: CGRect) {
        guard let centerImageSize = centerImageSize else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.clear(rect)
        let size = rect.size
        context.setStrokeColor(tintColor.cgColor)
        let lineWidth: CGFloat = centerImageSize.width * 0.085
        let cornerSize = size.width * 0.35 + (rect.width - centerImageSize.width) * 0.1
        let lineCenterOffset = lineWidth/2
        let curveControlPointOffset = lineWidth * 1.1 + (rect.width - centerImageSize.width) * 0.01
        let path = UIBezierPath()
        path.move(to: CGPoint(x: lineCenterOffset, y: lineCenterOffset))
        //Top left
        path.move(to: CGPoint(x: lineCenterOffset + cornerSize, y: lineCenterOffset))
        //Line to top right
        path.addLine(to: CGPoint(x: rect.width - lineCenterOffset - cornerSize, y: lineCenterOffset))
        //Top right curve
        path.addQuadCurve(to: CGPoint(x: rect.width - lineCenterOffset, y: lineCenterOffset + cornerSize), controlPoint: CGPoint(x: rect.width - curveControlPointOffset , y: curveControlPointOffset))
        //Line to bottom right
        path.addLine(to: CGPoint(x: rect.width - lineCenterOffset, y: rect.height - lineCenterOffset - cornerSize))
        //Bottom right curve
        path.addQuadCurve(to: CGPoint(x: rect.width - lineCenterOffset - cornerSize, y: rect.height - lineCenterOffset), controlPoint: CGPoint(x: rect.width - curveControlPointOffset , y: rect.height - curveControlPointOffset))
        //Line to bottom left
        path.addLine(to: CGPoint(x: lineCenterOffset + cornerSize, y: rect.height - lineCenterOffset))
        //Bottom left curve
        path.addQuadCurve(to: CGPoint(x: lineCenterOffset, y: rect.height - lineCenterOffset - cornerSize), controlPoint: CGPoint(x: curveControlPointOffset , y: rect.height - curveControlPointOffset))
        //Line to top left
        path.addLine(to: CGPoint(x: lineCenterOffset, y: lineCenterOffset + cornerSize))
        //Top left curve
        path.addQuadCurve(to: CGPoint(x: lineCenterOffset + cornerSize, y: lineCenterOffset), controlPoint: CGPoint(x: curveControlPointOffset , y: curveControlPointOffset))
        path.close()

        path.lineWidth = lineWidth

        path.stroke()
    }
}

public class AnimatedLogoView: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initView()
    }

    override public var tintColor: UIColor! {
        didSet {
            radialViews.forEach({ $0.tintColor = tintColor })
        }
    }

    public var imageColor = UIColor.white {
        didSet {
            let image = imageView.image?.withRenderingMode(.alwaysTemplate)
            imageView.image = image
            imageView.tintColor = imageColor
        }
    }

    public var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }

    var centerImageSizeConstraints: [NSLayoutConstraint]?
    public var centerImageSize = CGSize(width: 120, height: 144) {
        didSet {
            resetImageSizeConstraints()
        }
    }

    func resetImageSizeConstraints() {
        radialViews.forEach({
            $0.centerImageSize = centerImageSize
        })
        centerImageSizeConstraints?.forEach({ $0.isActive = false })
        guard imageView.superview != nil else { return }
        let heightConstraint = imageView.heightAnchor.constraint(equalToConstant: centerImageSize.height)
        let widthConstraint = imageView.widthAnchor.constraint(equalToConstant: centerImageSize.width)
        centerImageSizeConstraints = [heightConstraint, widthConstraint]
        centerImageSizeConstraints?.forEach({ $0.isActive = true })
    }

    private lazy var imageView: UIImageView = {
        let view = UIImageView(image: image)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var radialViews: [ORingView] = {
        var views: [ORingView] = []

        (0..<6).forEach { (_) in
            let view = ORingView()
            view.tintColor = tintColor
            view.centerImageSize = centerImageSize
            view.alpha = 0
            views.append(view)
        }

        return views
    }()

    var animationCount = 0
    func animate() {
        let animationIteration = animationCount % 2 == 0
        //Absolute times in seconds
        let pulseDuration = animationIteration ? 0.8 : 0.5
        let offset = pulseDuration / 10.0
        let pauseDuration = animationIteration ? 0 : 0.5
        let count = Double(radialViews.count)
        let duration = pulseDuration
        for i in 0..<Int(count) {
            UIView.animateKeyframes(withDuration: duration, delay: Double(i) * offset, options: [.beginFromCurrentState, .calculationModeCubic]) { [weak self] in
                guard let self = self else { return }

                //Relative times in fraction of animation
                var relativeTime = 0.0
                var stepDuration = 0.0

                //Pulse up
                stepDuration = (pulseDuration / 2) / duration
                UIView.addKeyframe(withRelativeStartTime: relativeTime, relativeDuration: stepDuration) {
                    self.radialViews[i].alpha = (animationIteration ? 0.3 : 0.1) + 0.5 * pow(CGFloat((count - Double(i)) / count), 2)
                }
                relativeTime += stepDuration

                //Pulse down
                stepDuration = (pulseDuration / 2) / duration
                UIView.addKeyframe(withRelativeStartTime: relativeTime, relativeDuration: stepDuration) {
                    self.radialViews[i].alpha = 0
                }
                relativeTime += stepDuration

            } completion: { [weak self] (_) in
                guard let self = self else { return }
                if i == Int(count) - 1 {
                    if !self.onAnimationCompleted() {
                        self.animationCount += 1
                        DispatchQueue.main.asyncAfter(deadline: .now() + pauseDuration) { [weak self] in
                            self?.animate()
                        }
                    }
                }
            }
        }
    }

    public func startAnimating() {
        animate()
    }

    public var onAnimationCompleted: () -> Bool = { return false }

    public func initView() {
        addSubview(imageView)

        imageView.centerInSuperview()

        resetImageSizeConstraints()

        var i = 0
        let spacing: Int = Int(centerImageSize.width * 0.085 * 3.5)
        radialViews.forEach { (view) in
            i += 1
            addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.centerInSuperview()
            view.constrainDimensions(width: CGFloat(Int(centerImageSize.width) + i * spacing), height: CGFloat(Int(centerImageSize.height) + i * spacing))
        }
        radialViews.last?.pinEdgesToSuperviewEdges()
    }
}
