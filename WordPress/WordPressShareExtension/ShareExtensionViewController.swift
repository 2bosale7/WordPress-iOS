import Foundation
import UIKit
import MobileCoreServices
import WordPressKit
import Aztec
import Gridicons
import WordPressShared


class ShareExtensionViewController: UIViewController {

    // MARK: - Private Constants

    fileprivate let defaultMaxDimension = 3000
    fileprivate let postStatuses = [
        // TODO: This should eventually be moved into WordPressComKit
        "draft": NSLocalizedString("Draft", comment: "Draft post status"),
        "publish": NSLocalizedString("Publish", comment: "Publish post status")
    ]

    fileprivate enum MediaSettings {
        static let filename = "image.jpg"
        static let mimeType = "image/jpeg"
    }

    // MARK: - Private Properties

    /// WordPress.com Username
    ///
    fileprivate lazy var wpcomUsername: String? = {
        ShareExtensionService.retrieveShareExtensionUsername()
    }()

    /// WordPress.com OAuth Token
    ///
    fileprivate lazy var oauth2Token: String? = {
        ShareExtensionService.retrieveShareExtensionToken()
    }()

    /// Selected Site's ID
    ///
    fileprivate lazy var selectedSiteID: Int? = {
        ShareExtensionService.retrieveShareExtensionDefaultSite()?.siteID
    }()

    /// Selected Site's Name
    ///
    fileprivate lazy var selectedSiteName: String? = {
        ShareExtensionService.retrieveShareExtensionDefaultSite()?.siteName
    }()

    /// Maximum Image Size
    ///
    fileprivate lazy var maximumImageSize: CGSize = {
        let dimension = ShareExtensionService.retrieveShareExtensionMaximumMediaDimension() ?? self.defaultMaxDimension
        return CGSize(width: dimension, height: dimension)
    }()

    /// Tracks Instance
    ///
    fileprivate lazy var tracks: Tracks = {
        Tracks(appGroupName: WPAppGroupName)
    }()

    /// Format Bar
    ///
    fileprivate(set) lazy var formatBar: Aztec.FormatBar = {
        return self.createToolbar()
    }()

    /// Aztec's Awesomeness
    ///
    fileprivate(set) lazy var richTextView: Aztec.TextView = {

        let paragraphStyle = ParagraphStyle.default

        // Paragraph style customizations will go here.
        paragraphStyle.lineSpacing = 4

        let textView = Aztec.TextView(defaultFont: Fonts.regular, defaultParagraphStyle: paragraphStyle, defaultMissingImage: Assets.defaultMissingImage)

        textView.inputProcessor = PipelineProcessor([CalypsoProcessorIn()])

        textView.outputProcessor = PipelineProcessor([CalypsoProcessorOut()])

        let accessibilityLabel = NSLocalizedString("Rich Content", comment: "Post Rich content")
        self.configureDefaultProperties(for: textView, accessibilityLabel: accessibilityLabel)

        let linkAttributes: [NSAttributedStringKey: Any] = [.underlineStyle: NSUnderlineStyle.styleSingle.rawValue,
                                                            .foregroundColor: Colors.aztecLinkColor]

        textView.delegate = self
        textView.formattingDelegate = self
        textView.textAttachmentDelegate = self
        textView.backgroundColor = Colors.aztecBackground
        textView.linkTextAttributes = NSAttributedStringKey.convertToRaw(attributes: linkAttributes)
        textView.textAlignment = .natural

        if #available(iOS 11, *) {
            textView.smartDashesType = .no
            textView.smartQuotesType = .no
        }

        return textView
    }()

    /// Aztec's Text Placeholder
    ///
    fileprivate(set) lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Share your story here...", comment: "Aztec's Text Placeholder")
        label.textColor = Colors.placeholder
        label.font = Fonts.regular
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .natural
        return label
    }()

    /// Title's UITextView
    ///
    fileprivate(set) lazy var titleTextField: UITextView = {
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .natural

        let attributes: [NSAttributedStringKey: Any] = [.foregroundColor: UIColor.darkText,
                                                        .font: Fonts.title,
                                                        .paragraphStyle: titleParagraphStyle]

        let textView = UITextView()

        textView.accessibilityLabel = NSLocalizedString("Title", comment: "Post title")
        textView.delegate = self
        textView.font = Fonts.title
        textView.returnKeyType = .next
        textView.textColor = UIColor.darkText
        textView.typingAttributes = NSAttributedStringKey.convertToRaw(attributes: attributes)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textAlignment = .natural
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.spellCheckingType = .default

        return textView
    }()

    /// Placeholder Label
    ///
    fileprivate(set) lazy var titlePlaceholderLabel: UILabel = {
        let placeholderText = NSLocalizedString("Title", comment: "Placeholder for the post title.")
        let titlePlaceholderLabel = UILabel()

        let attributes: [NSAttributedStringKey: Any] = [.foregroundColor: Colors.title, .font: Fonts.title]

        titlePlaceholderLabel.attributedText = NSAttributedString(string: placeholderText, attributes: attributes)
        titlePlaceholderLabel.sizeToFit()
        titlePlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        titlePlaceholderLabel.textAlignment = .natural

        return titlePlaceholderLabel
    }()

    /// Title's Height Constraint
    ///
    fileprivate var titleHeightConstraint: NSLayoutConstraint!


    /// Title's Top Constraint
    ///
    fileprivate var titleTopConstraint: NSLayoutConstraint!


    /// Placeholder's Top Constraint
    ///
    fileprivate var textPlaceholderTopConstraint: NSLayoutConstraint!

    /// Separator View
    ///
    fileprivate(set) lazy var separatorView: UIView = {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 1))

        v.backgroundColor = Colors.separator
        v.translatesAutoresizingMaskIntoConstraints = false

        return v
    }()

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        // Tracker
        tracks.wpcomUsername = wpcomUsername
        title = NSLocalizedString("WordPress", comment: "Application title")

        loadContent(extensionContext: extensionContext)

        // TODO: Fix the warnings triggered by this one!
        WPFontManager.loadNotoFontFamily()

        // Setup
        configureView()
        configureSubviews()

        // Setup Autolayout
        view.setNeedsUpdateConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tracks.trackExtensionLaunched(oauth2Token != nil)
        dismissIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        var safeInsets = self.view.layoutMargins
        safeInsets.top = richTextView.textContainerInset.top
        richTextView.textContainerInset = safeInsets
    }

    // MARK: - Title and Title placeholder position methods

    func refreshTitlePosition() {
        let referenceView: UITextView = richTextView
        titleTopConstraint.constant = -(referenceView.contentOffset.y+referenceView.contentInset.top)

        var contentInset = referenceView.contentInset
        contentInset.top = (titleHeightConstraint.constant + separatorView.frame.height)
        referenceView.contentInset = contentInset

        textPlaceholderTopConstraint.constant = referenceView.textContainerInset.top + referenceView.contentInset.top
    }

    func updateTitleHeight() {
        let referenceView: UITextView = richTextView
        let layoutMargins = view.layoutMargins
        let insets = titleTextField.textContainerInset

        var titleWidth = titleTextField.bounds.width
        if titleWidth <= 0 {
            // Use the title text field's width if available, otherwise calculate it.
            // View's frame minus left and right margins as well as margin between title and beta button
            titleWidth = view.frame.width - (insets.left + insets.right + layoutMargins.left + layoutMargins.right)
        }

        let sizeThatShouldFitTheContent = titleTextField.sizeThatFits(CGSize(width: titleWidth, height: CGFloat.greatestFiniteMagnitude))
        titleHeightConstraint.constant = max(sizeThatShouldFitTheContent.height, titleTextField.font!.lineHeight + insets.top + insets.bottom)

        textPlaceholderTopConstraint.constant = referenceView.textContainerInset.top + referenceView.contentInset.top

        var contentInset = referenceView.contentInset
        contentInset.top = (titleHeightConstraint.constant + separatorView.frame.height)
        referenceView.contentInset = contentInset
        referenceView.setContentOffset(CGPoint(x: 0, y: -contentInset.top), animated: false)
    }

    // MARK: - Configuration Methods

    func configureView() {
        edgesForExtendedLayout = UIRectEdge()
        view.backgroundColor = .white
    }

    func configureSubviews() {
        view.addSubview(richTextView)
        view.addSubview(titleTextField)
        view.addSubview(titlePlaceholderLabel)
        view.addSubview(separatorView)
        view.addSubview(placeholderLabel)
    }

    override func updateViewConstraints() {

        super.updateViewConstraints()

        titleHeightConstraint = titleTextField.heightAnchor.constraint(equalToConstant: titleTextField.font!.lineHeight)
        titleTopConstraint = titleTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: -richTextView.contentOffset.y)
        textPlaceholderTopConstraint = placeholderLabel.topAnchor.constraint(equalTo: richTextView.topAnchor, constant: richTextView.textContainerInset.top + richTextView.contentInset.top)
        updateTitleHeight()
        let layoutGuide = view.layoutMarginsGuide

        NSLayoutConstraint.activate([
            titleTextField.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            titleTopConstraint,
            titleHeightConstraint
            ])

        let insets = titleTextField.textContainerInset

        NSLayoutConstraint.activate([
            titlePlaceholderLabel.leftAnchor.constraint(equalTo: titleTextField.leftAnchor, constant: insets.left + titleTextField.textContainer.lineFragmentPadding),
            titlePlaceholderLabel.rightAnchor.constraint(equalTo: titleTextField.rightAnchor, constant: -insets.right - titleTextField.textContainer.lineFragmentPadding),
            titlePlaceholderLabel.topAnchor.constraint(equalTo: titleTextField.topAnchor, constant: insets.top),
            titlePlaceholderLabel.heightAnchor.constraint(equalToConstant: titleTextField.font!.lineHeight)
            ])

        NSLayoutConstraint.activate([
            separatorView.leftAnchor.constraint(equalTo: layoutGuide.leftAnchor),
            separatorView.rightAnchor.constraint(equalTo: layoutGuide.rightAnchor),
            separatorView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: separatorView.frame.height)
            ])

        NSLayoutConstraint.activate([
            richTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            richTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            richTextView.topAnchor.constraint(equalTo: view.topAnchor),
            richTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: Constants.placeholderPadding.left),
            placeholderLabel.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: -(Constants.placeholderPadding.right + richTextView.textContainer.lineFragmentPadding)),
            textPlaceholderTopConstraint,
            placeholderLabel.bottomAnchor.constraint(lessThanOrEqualTo: richTextView.bottomAnchor, constant: Constants.placeholderPadding.bottom)
            ])
    }

    private func configureDefaultProperties(for textView: UITextView, accessibilityLabel: String) {
        textView.accessibilityLabel = accessibilityLabel
        textView.keyboardDismissMode = .interactive
        textView.textColor = UIColor.darkText
        textView.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - Toolbar creation

    fileprivate func updateToolbar(_ toolbar: Aztec.FormatBar) {
        toolbar.setDefaultItems(scrollableItemsForToolbar,
                                overflowItems: overflowItemsForToolbar)
    }

    func makeToolbarButton(identifier: FormattingIdentifier) -> FormatBarItem {
        return makeToolbarButton(identifier: identifier.rawValue, provider: identifier)
    }

    func makeToolbarButton(identifier: String, provider: FormatBarItemProvider) -> FormatBarItem {
        let button = FormatBarItem(image: provider.iconImage, identifier: identifier)
        button.accessibilityLabel = provider.accessibilityLabel
        button.accessibilityIdentifier = provider.accessibilityIdentifier
        return button
    }


    func createToolbar() -> Aztec.FormatBar {
        let toolbar = Aztec.FormatBar()

        toolbar.tintColor = Colors.aztecFormatBarInactiveColor
        toolbar.highlightedTintColor = Colors.aztecFormatBarActiveColor
        toolbar.selectedTintColor = Colors.aztecFormatBarActiveColor
        toolbar.disabledTintColor = Colors.aztecFormatBarDisabledColor
        toolbar.dividerTintColor = Colors.aztecFormatBarDividerColor
        toolbar.overflowToggleIcon = Gridicon.iconOfType(.ellipsis)
        updateToolbar(toolbar)

        toolbar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: Constants.toolbarHeight)
        toolbar.formatter = self
        toolbar.barItemHandler = { [weak self] item in
            self?.handleAction(for: item)
        }
        return toolbar
    }

    var scrollableItemsForToolbar: [FormatBarItem] {
        let headerButton = makeToolbarButton(identifier: .p)

        var alternativeIcons = [String: UIImage]()
        let headings = Constants.headers.suffix(from: 1) // Remove paragraph style
        for heading in headings {
            alternativeIcons[heading.formattingIdentifier.rawValue] = heading.iconImage
        }

        headerButton.alternativeIcons = alternativeIcons


        let listButton = makeToolbarButton(identifier: .unorderedlist)
        var listIcons = [String: UIImage]()
        for list in Constants.lists {
            listIcons[list.formattingIdentifier.rawValue] = list.iconImage
        }

        listButton.alternativeIcons = listIcons

        return [
            headerButton,
            listButton,
            makeToolbarButton(identifier: .blockquote),
            makeToolbarButton(identifier: .bold),
            makeToolbarButton(identifier: .italic),
            makeToolbarButton(identifier: .link)
        ]
    }

    var overflowItemsForToolbar: [FormatBarItem] {
        return [
            makeToolbarButton(identifier: .underline),
            makeToolbarButton(identifier: .strikethrough),
            makeToolbarButton(identifier: .horizontalruler),
            makeToolbarButton(identifier: .more),
        ]
    }
}

// MARK: - Format Bar Updating

extension ShareExtensionViewController {

    func updateFormatBar() {
        updateFormatBarForVisualMode()
    }

    /// Updates the format bar for visual mode.
    ///
    private func updateFormatBarForVisualMode() {
        guard let toolbar = richTextView.inputAccessoryView as? Aztec.FormatBar else {
            return
        }

        var identifiers = [FormattingIdentifier]()

        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formatIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formatIdentifiersForTypingAttributes()
        }

        toolbar.selectItemsMatchingIdentifiers(identifiers.map({ $0.rawValue }))
    }
}

// MARK: - Private methods

extension ShareExtensionViewController {
    func refreshPlaceholderVisibility() {
        placeholderLabel.isHidden = richTextView.isHidden || !richTextView.text.isEmpty
        titlePlaceholderLabel.isHidden = !titleTextField.text.isEmpty
    }
}

// MARK: - FormatBarDelegate Conformance

extension ShareExtensionViewController: Aztec.FormatBarDelegate {
    func formatBarTouchesBegan(_ formatBar: FormatBar) {
        // TODO: Needed?
    }

    /// Called when the overflow items in the format bar are either shown or hidden
    /// as a result of the user tapping the toggle button.
    ///
    func formatBar(_ formatBar: FormatBar, didChangeOverflowState overflowState: FormatBarOverflowState) {
        // TODO: Needed?
    }
}

// MARK: FormatBar Actions

extension ShareExtensionViewController {
    func handleAction(for barItem: FormatBarItem) {
        guard let identifier = barItem.identifier else { return }

        if let formattingIdentifier = FormattingIdentifier(rawValue: identifier) {
            switch formattingIdentifier {
            case .bold:
                toggleBold()
            case .italic:
                toggleItalic()
            case .underline:
                toggleUnderline()
            case .strikethrough:
                toggleStrikethrough()
            case .blockquote:
                toggleBlockquote()
            case .unorderedlist, .orderedlist:
                toggleList(fromItem: barItem)
            case .link:
                toggleLink()
            case .p, .header1, .header2, .header3, .header4, .header5, .header6:
                toggleHeader(fromItem: barItem)
            case .horizontalruler:
                insertHorizontalRuler()
            case .more:
                insertMore()
            case .media:
                break  // Not used here
            case .sourcecode:
                break // Not used here
            }

            updateFormatBar()
        }
    }

    @objc func toggleBold() {
        richTextView.toggleBold(range: richTextView.selectedRange)
    }


    @objc func toggleItalic() {
        richTextView.toggleItalic(range: richTextView.selectedRange)
    }


    @objc func toggleUnderline() {
        richTextView.toggleUnderline(range: richTextView.selectedRange)
    }


    @objc func toggleStrikethrough() {
        richTextView.toggleStrikethrough(range: richTextView.selectedRange)
    }

    @objc func toggleOrderedList() {
        richTextView.toggleOrderedList(range: richTextView.selectedRange)
    }

    @objc func toggleUnorderedList() {
        richTextView.toggleUnorderedList(range: richTextView.selectedRange)
    }

    func toggleList(fromItem item: FormatBarItem) {

        // TODO: Fix!

//        let listOptions = Constants.lists.map { listType -> OptionsTableViewOption in
//            let title = NSAttributedString(string: listType.description, attributes: [:])
//            return OptionsTableViewOption(image: listType.iconImage,
//                                          title: title,
//                                          accessibilityLabel: listType.accessibilityLabel)
//        }
//
//        var index: Int? = nil
//        if let listType = listTypeForSelectedText() {
//            index = Constants.lists.index(of: listType)
//        }
//
//        showOptionsTableViewControllerWithOptions(listOptions,
//                                                  fromBarItem: item,
//                                                  selectedRowIndex: index,
//                                                  onSelect: { [weak self] selected in
//
//                                                    let listType = Constants.lists[selected]
//                                                    switch listType {
//                                                    case .unordered:
//                                                        self?.toggleUnorderedList()
//                                                    case .ordered:
//                                                        self?.toggleOrderedList()
//                                                    }
//        })
    }

    @objc func toggleBlockquote() {
        richTextView.toggleBlockquote(range: richTextView.selectedRange)
    }


    func listTypeForSelectedText() -> TextList.Style? {
        var identifiers = [FormattingIdentifier]()
        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formatIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formatIdentifiersForTypingAttributes()
        }
        let mapping: [FormattingIdentifier: TextList.Style] = [
            .orderedlist: .ordered,
            .unorderedlist: .unordered
        ]
        for (key, value) in mapping {
            if identifiers.contains(key) {
                return value
            }
        }

        return nil
    }

    @objc func toggleLink() {
        var linkTitle = ""
        var linkURL: URL? = nil
        var linkRange = richTextView.selectedRange
        // Let's check if the current range already has a link assigned to it.
        if let expandedRange = richTextView.linkFullRange(forRange: richTextView.selectedRange) {
            linkRange = expandedRange
            linkURL = richTextView.linkURL(forRange: expandedRange)
        }

        linkTitle = richTextView.attributedText.attributedSubstring(from: linkRange).string
        showLinkDialog(forURL: linkURL, title: linkTitle, range: linkRange)
    }

    func showLinkDialog(forURL url: URL?, title: String?, range: NSRange) {

        //TODO: Implement me!

//        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel button")
//        let removeTitle = NSLocalizedString("Remove Link", comment: "Label action for removing a link from the editor")
//        let insertTitle = NSLocalizedString("Insert Link", comment: "Label action for inserting a link on the editor")
//        let updateTitle = NSLocalizedString("Update Link", comment: "Label action for updating a link on the editor")
//
//        let isInsertingNewLink = (url == nil)
//        var urlToUse = url
//
//        if isInsertingNewLink {
//            if UIPasteboard.general.hasURLs,
//                let pastedURL = UIPasteboard.general.url {
//                urlToUse = pastedURL
//            }
//        }
//
//        let insertButtonTitle = isInsertingNewLink ? insertTitle : updateTitle
//
//        let alertController = UIAlertController(title: insertButtonTitle, message: nil, preferredStyle: .alert)
//
//        // TextField: URL
//        alertController.addTextField(configurationHandler: { [weak self] textField in
//            textField.clearButtonMode = .always
//            textField.placeholder = NSLocalizedString("URL", comment: "URL text field placeholder")
//            textField.text = urlToUse?.absoluteString
//
//            textField.addTarget(self,
//                                action: #selector(AztecPostViewController.alertTextFieldDidChange),
//                                for: UIControlEvents.editingChanged)
//        })
//
//        // TextField: Link Name
//        alertController.addTextField(configurationHandler: { textField in
//            textField.clearButtonMode = .always
//            textField.placeholder = NSLocalizedString("Link Name", comment: "Link name field placeholder")
//            textField.isSecureTextEntry = false
//            textField.autocapitalizationType = .sentences
//            textField.autocorrectionType = .default
//            textField.spellCheckingType = .default
//            textField.text = title
//        })
//
//
//        // Action: Insert
//        let insertAction = alertController.addDefaultActionWithTitle(insertButtonTitle) { [weak self] action in
//            self?.richTextView.becomeFirstResponder()
//            let linkURLString = alertController.textFields?.first?.text
//            var linkTitle = alertController.textFields?.last?.text
//
//            if linkTitle == nil || linkTitle!.isEmpty {
//                linkTitle = linkURLString
//            }
//
//            guard let urlString = linkURLString, let url = URL(string: urlString), let title = linkTitle else {
//                return
//            }
//
//            self?.richTextView.setLink(url, title: title, inRange: range)
//        }
//
//        // Disabled until url is entered into field
//        insertAction.isEnabled = urlToUse?.absoluteString.isEmpty == false
//
//        // Action: Remove
//        if !isInsertingNewLink {
//            alertController.addDestructiveActionWithTitle(removeTitle) { [weak self] action in
//                self?.trackFormatBarAnalytics(stat: .editorTappedUnlink)
//                self?.richTextView.becomeFirstResponder()
//                self?.richTextView.removeLink(inRange: range)
//            }
//        }
//
//        // Action: Cancel
//        alertController.addCancelActionWithTitle(cancelTitle) { [weak self] _ in
//            self?.richTextView.becomeFirstResponder()
//        }
//
//        present(alertController, animated: true, completion: nil)
    }

    @objc func alertTextFieldDidChange(_ textField: UITextField) {
        guard
            let alertController = presentedViewController as? UIAlertController,
            let urlFieldText = alertController.textFields?.first?.text,
            let insertAction = alertController.actions.first
            else {
                return
        }

        insertAction.isEnabled = !urlFieldText.isEmpty
    }

    func toggleHeader(fromItem item: FormatBarItem) {
        //TODO: Implement me!
    }

    func insertHorizontalRuler() {
        richTextView.replaceWithHorizontalRuler(at: richTextView.selectedRange)
    }

    func insertMore() {
        richTextView.replace(richTextView.selectedRange, withComment: Constants.moreAttachmentText)
    }

    func headerLevelForSelectedText() -> Header.HeaderType {
        var identifiers = [FormattingIdentifier]()
        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formatIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formatIdentifiersForTypingAttributes()
        }
        let mapping: [FormattingIdentifier: Header.HeaderType] = [
            .header1: .h1,
            .header2: .h2,
            .header3: .h3,
            .header4: .h4,
            .header5: .h5,
            .header6: .h6,
            ]
        for (key, value) in mapping {
            if identifiers.contains(key) {
                return value
            }
        }
        return .none
    }
}

// MARK: - UITextViewDelegate methods

extension ShareExtensionViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        switch textView {
        case titleTextField:
            return shouldChangeTitleText(in: range, replacementText: text)

        default:
            return true
        }
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        updateFormatBar()
    }

    func textViewDidChange(_ textView: UITextView) {
        refreshPlaceholderVisibility()

        switch textView {
        case titleTextField:
            updateTitleHeight()
        case richTextView:
            updateFormatBar()
        default:
            break
        }
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textView.textAlignment = .natural

        let htmlButton = formatBar.items.first(where: { $0.identifier == FormattingIdentifier.sourcecode.rawValue })

        switch textView {
        case titleTextField:
            formatBar.enabled = false
        case richTextView:
            formatBar.enabled = true
        default:
            break
        }

        htmlButton?.isEnabled = true
        textView.inputAccessoryView = formatBar

        return true
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        refreshTitlePosition()
    }

    // MARK: - Title Input Sanitization

    /// Sanitizes an input for insertion in the title text view.
    ///
    /// - Parameters:
    ///     - input: the input for the title text view.
    ///
    /// - Returns: the sanitized string
    ///
    private func sanitizeInputForTitle(_ input: String) -> String {
        var sanitizedText = input

        while let range = sanitizedText.rangeOfCharacter(from: CharacterSet.newlines, options: [], range: nil) {
            sanitizedText = sanitizedText.replacingCharacters(in: range, with: " ")
        }

        return sanitizedText
    }

    /// This method performs all necessary checks to verify if the title text can be changed,
    /// or if some other action should be performed instead.
    ///
    /// - Important: this method sanitizes newlines, since they're not allowed in the title.
    ///
    /// - Parameters:
    ///     - range: the range that would be modified.
    ///     - text: the new text for the specified range.
    ///
    /// - Returns: `true` if the modification can take place, `false` otherwise.
    ///
    private func shouldChangeTitleText(in range: NSRange, replacementText text: String) -> Bool {

        guard text.count > 1 else {
            guard text.rangeOfCharacter(from: CharacterSet.newlines, options: [], range: nil) == nil else {
                richTextView.becomeFirstResponder()
                richTextView.selectedRange = NSRange(location: 0, length: 0)
                return false
            }

            return true
        }

        let sanitizedInput = sanitizeInputForTitle(text)
        let newlinesWereRemoved = sanitizedInput != text

        guard !newlinesWereRemoved else {
            titleTextField.insertText(sanitizedInput)

            return false
        }

        return true
    }
}

// MARK: - UITextFieldDelegate methods

extension ShareExtensionViewController {
    func titleTextFieldDidChange(_ textField: UITextField) {
        // TODO
    }
}

// MARK: - TextViewFormattingDelegate methods

extension ShareExtensionViewController: Aztec.TextViewFormattingDelegate {
    func textViewCommandToggledAStyle() {
        updateFormatBar()
    }
}

// MARK: - TextViewAttachmentDelegate Conformance
//
extension ShareExtensionViewController: TextViewAttachmentDelegate {
    func textView(_ textView: TextView, attachment: NSTextAttachment, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
        // TODO: Implement me!
    }

    func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL? {
        // TODO: Implement me!
        return nil
    }

    func textView(_ textView: TextView, deletedAttachmentWith attachmentID: String) {
        // TODO: Implement me!
    }

    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) {
        // TODO: Implement me!
    }

    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) {
        // TODO: Implement me!
    }

    func selected(textAttachment attachment: MediaAttachment, atPosition position: CGPoint) {
        // TODO: Implement me!
    }

    func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage {
        return Gridicon.iconOfType(.image, withSize: Constants.mediaPlaceholderImageSize)
    }
}

// Encapsulates all of the Action Helpers.

private extension ShareExtensionViewController {
    func dismissIfNeeded() {
        guard oauth2Token == nil else {
            return
        }

        let title = NSLocalizedString("No WordPress.com Account", comment: "Extension Missing Token Alert Title")
        let message = NSLocalizedString("Launch the WordPress app and log into your WordPress.com or Jetpack site to share.", comment: "Extension Missing Token Alert Title")
        let accept = NSLocalizedString("Cancel Share", comment: "Dismiss Extension and cancel Share OP")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: accept, style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }

        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
}

// Encapsulates private helpers

private extension ShareExtensionViewController {
    func loadContent(extensionContext: NSExtensionContext?) {
        guard let extensionContext = extensionContext else {
            return
        }
        ShareExtractor(extensionContext: extensionContext)
            .loadShare { [weak self] share in
                self?.richTextView.text = share.text

                share.images.forEach({ image in
                    if let fileURL = self?.saveImageToSharedContainer(image) {
                        self?.insertImageAttachment(with: fileURL)
                    }
                })
        }
    }

    func saveImageToSharedContainer(_ image: UIImage) -> URL? {
        guard let encodedMedia = image.resizeWithMaximumSize(maximumImageSize).JPEGEncoded(),
            let mediaDirectory = ShareMediaFileManager.shared.mediaUploadDirectoryURL else {
            return nil
        }

        let fileName = "image_\(NSDate.timeIntervalSinceReferenceDate).jpg"
        let fullPath = mediaDirectory.appendingPathComponent(fileName)
        do {
            try encodedMedia.write(to: fullPath, options: [.atomic])
        } catch {
            DDLogError("Error saving \(fullPath) to shared container: \(String(describing: error))")
            return nil
        }
        return fullPath
    }

    func insertImageAttachment(with url: URL = Constants.placeholderMediaLink) {
        let attachment = richTextView.replaceWithImage(at: self.richTextView.selectedRange, sourceURL: url, placeHolderImage: Assets.defaultMissingImage)
        attachment.size = .full
        richTextView.refresh(attachment)
    }
}

// MARK: - Constants

extension ShareExtensionViewController {

    struct Assets {
        static let closeButtonModalImage    = Gridicon.iconOfType(.cross)
        static let closeButtonRegularImage  = UIImage(named: "icon-posts-editor-chevron")
        static let defaultMissingImage      = Gridicon.iconOfType(.image)
    }

    struct Constants {
        static let defaultMargin            = CGFloat(20)
        static let cancelButtonPadding      = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        static let moreAttachmentText       = "more"
        static let placeholderPadding       = UIEdgeInsets(top: 8, left: 5, bottom: 0, right: 0)
        static let headers                  = [Header.HeaderType.none, .h1, .h2, .h3, .h4, .h5, .h6]
        static let lists                    = [TextList.Style.unordered, .ordered]
        static let toolbarHeight            = CGFloat(44.0)
        static let mediaPlaceholderImageSize = CGSize(width: 128, height: 128)
        static let placeholderMediaLink = URL(string: "placeholder://")!
    }

    struct Colors {
        static let title                    = WPStyleGuide.grey()
        static let separator                = WPStyleGuide.greyLighten30()
        static let placeholder              = WPStyleGuide.grey()
        static let aztecBackground          = UIColor.clear
        static let aztecLinkColor           = WPStyleGuide.mediumBlue()
        static let aztecFormatBarInactiveColor: UIColor = UIColor(hexString: "7B9AB1")
        static let aztecFormatBarActiveColor: UIColor = UIColor(hexString: "11181D")
        static let aztecFormatBarDisabledColor = WPStyleGuide.greyLighten20()
        static let aztecFormatBarDividerColor = WPStyleGuide.greyLighten30()
        static let aztecFormatBarBackgroundColor = UIColor.white
        static var aztecFormatPickerSelectedCellBackgroundColor: UIColor {
            get {
                return (UIDevice.current.userInterfaceIdiom == .pad) ? WPStyleGuide.lightGrey() : WPStyleGuide.greyLighten30()
            }
        }
        static var aztecFormatPickerBackgroundColor: UIColor {
            get {
                return (UIDevice.current.userInterfaceIdiom == .pad) ? .white : WPStyleGuide.lightGrey()
            }
        }
    }

    struct Fonts {
        static let regular                  = WPFontManager.notoRegularFont(ofSize: 16)
        static let semiBold                 = WPFontManager.systemSemiBoldFont(ofSize: 16)
        static let title                    = WPFontManager.notoBoldFont(ofSize: 24.0)
        static let blogPicker               = Fonts.semiBold
        static let mediaPickerInsert        = WPFontManager.systemMediumFont(ofSize: 15.0)
        static let mediaOverlay             = WPFontManager.systemSemiBoldFont(ofSize: 15.0)
        static let monospace                = UIFont(name: "Menlo-Regular", size: 16.0)!
    }
}
