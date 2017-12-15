import UIKit

class SiteDetailsViewController: NUXAbstractViewController, SigninKeyboardResponder {

    // MARK: - SigninKeyboardResponder Properties

    @IBOutlet weak var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet weak var verticalCenterConstraint: NSLayoutConstraint?

    // MARK: - Properties

    @IBOutlet weak var stepLabel: UILabel!
    @IBOutlet weak var stepDescriptionLabel1: UILabel!
    @IBOutlet weak var stepDescriptionLabel2: UILabel!
    @IBOutlet weak var siteTitleField: LoginTextField!
    @IBOutlet weak var taglineField: LoginTextField!
    @IBOutlet weak var tagDescriptionLabel: UILabel!
    @IBOutlet weak var nextButton: LoginButton!

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        setLabelText()
        setupNextButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureViewForEditingIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }

    /// Configure the view for an editing state. Should only be called from viewWillAppear
    /// as this method skips animating any change in height.
    ///
    private func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editiing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            siteTitleField.becomeFirstResponder()
        }
    }

    private func configureView() {
        _ = addHelpButtonToNavController()

        navigationItem.title = NSLocalizedString("Create New Site", comment: "Create New Site title.")
        WPStyleGuide.configureColors(for: view, andTableView: nil)
        tagDescriptionLabel.textColor = WPStyleGuide.greyDarken20()
        nextButton.isEnabled = false
        siteTitleField.textInsets = WPStyleGuide.edgeInsetForLoginTextFields()
        taglineField.textInsets = WPStyleGuide.edgeInsetForLoginTextFields()
    }

    private func setLabelText() {
        stepLabel.text = NSLocalizedString("STEP 3 OF 4", comment: "Step for view.")
        stepDescriptionLabel1.text = NSLocalizedString("Tell us more about the site you're creating.", comment: "Shown during the site details step of the site creation flow.")
        stepDescriptionLabel2.text = NSLocalizedString("What's the title and tagline?", comment: "Prompts the user for Site details information.")

        siteTitleField.placeholder = NSLocalizedString("Add title", comment: "Site title placeholder.")
        siteTitleField.accessibilityIdentifier = "Site title"

        taglineField.placeholder = NSLocalizedString("Optional tagline", comment: "Site tagline placeholder.")
        taglineField.accessibilityIdentifier = "Site tagline"

        tagDescriptionLabel.text = NSLocalizedString("The tagline is a short line of text shown right below the title in most themes, and acts as site metadata on search engines.", comment: "Tagline description.")
    }

    private func setupNextButton() {
        let nextButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        nextButton?.setTitle(nextButtonTitle, for: UIControlState())
        nextButton?.setTitle(nextButtonTitle, for: .highlighted)
        nextButton?.accessibilityIdentifier = "Next Button"
    }

    // MARK: - Button Handling

    @IBAction func nextButtonPressed(_ sender: Any) {
        validateForm()
    }

    private func validateForm() {
        if siteTitleField.nonNilTrimmedText().isEmpty {
            displayErrorAlert(NSLocalizedString("Site Title must have a value.", comment: "Error shown when Site Title does not have a value."), sourceTag: .wpComCreateSiteDetails)
        }
        else {
            let message = "Title: '\(siteTitleField.text!)'\nTagline: '\(taglineField.text ?? "")'\nThis is a work in progress. If you need to create a site, disable the siteCreation feature flag."
            let alertController = UIAlertController(title: nil,
                                                    message: message,
                                                    preferredStyle: .alert)
            alertController.addDefaultActionWithTitle("OK")
            self.present(alertController, animated: true, completion: nil)
        }
    }

    private func toggleNextButton(_ textField: UITextField) {
        if textField == siteTitleField {
            nextButton.isEnabled = !textField.nonNilTrimmedText().isEmpty
        }
    }

    // MARK: - Keyboard Notifications

    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }

    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }

    // MARK: - LoginWithLogoAndHelpViewController

    /// Override this to use the appropriate sourceTag.
    ///
    override func handleHelpButtonTapped(_ sender: AnyObject) {
        displaySupportViewController(sourceTag: .wpComCreateSiteDetails)
    }

    // MARK: - Misc

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: - UITextFieldDelegate

extension SiteDetailsViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == siteTitleField {
            taglineField.becomeFirstResponder()
        } else if textField == taglineField {
            view.endEditing(true)
            validateForm()
        }

        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == siteTitleField {
            let updatedString = NSString(string: textField.text!).replacingCharacters(in: range, with: string)
            nextButton.isEnabled = !updatedString.trim().isEmpty
        }
        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if textField == siteTitleField {
            nextButton.isEnabled = false
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        toggleNextButton(textField)
    }

    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        toggleNextButton(textField)
    }

}
