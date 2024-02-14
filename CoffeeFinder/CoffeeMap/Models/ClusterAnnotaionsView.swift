import MapKit

final class ClusterAnnotaionsView: MKAnnotationView {

    // MARK: Initialization
    private let countLabel = UILabel()

    override var annotation: MKAnnotation? {
        didSet {
             guard let annotation = annotation as? MKClusterAnnotation else {
                assertionFailure("Using LocationDataMapClusterView with wrong annotation type")
                return
            }

            countLabel.text = annotation.memberAnnotations.count < 100 ? "\(annotation.memberAnnotations.count)" : "99+"
        }
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        displayPriority = .defaultHigh
        collisionMode = .circle

        frame = CGRect(x: 0, y: 0, width: 40, height: 50)
        centerOffset = CGPoint(x: 0, y: -frame.size.height / 2)

       
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Setup
    private func setupUI() {
        print()
    }
}
