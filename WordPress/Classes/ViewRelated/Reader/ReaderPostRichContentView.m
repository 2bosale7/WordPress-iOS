#import "ReaderPostRichContentView.h"
#import "WPRichTextView.h"
#import <DTCoreText/DTCoreText.h>
#import "OriginalSiteAttributionView.h"

@interface ReaderPostRichContentView()<WPRichTextViewDelegate>

@property (nonatomic, readonly) WPRichTextView *richTextView;

@end

@implementation ReaderPostRichContentView

@dynamic delegate;

#pragma mark - Life Cycle Methods

- (void)dealloc
{
    ((WPRichTextView *)self.contentView).delegate = nil;
}

#pragma mark - Public Methods

- (void)refreshMediaLayout
{
    [self.richTextView refreshMediaLayout];
}

#pragma mark - Private Methods
- (void)buildTitleLabel
{
    [super buildTitleLabel];
    self.titleLabel.numberOfLines = 0;
}

- (void)buildContentView
{
    // Minimal frame so internal DTAttriutedTextContentView gets layout.
    CGRect frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.bounds), 1.0);
    CGFloat horizontalInnerPadding = WPContentViewHorizontalInnerPadding - 4.0;
    WPRichTextView *richTextView = [[WPRichTextView alloc] initWithFrame:frame];
    richTextView.translatesAutoresizingMaskIntoConstraints = NO;
    richTextView.delegate = self;
    richTextView.edgeInsets = UIEdgeInsetsMake(0.0, horizontalInnerPadding, 0.0, horizontalInnerPadding);

    self.contentView = richTextView;
    [self addSubview:self.contentView];
}

- (void)buildFeaturedImageview
{
    [super buildFeaturedImageview];
    self.featuredImageView.userInteractionEnabled = YES;
}

- (void)buildDiscoverAttributionView
{
    // Return a ui lable subclass implementing the necessary protocol
    OriginalSiteAttributionView *originalAttributionView = [OriginalSiteAttributionView new];
    originalAttributionView.translatesAutoresizingMaskIntoConstraints = NO;
    originalAttributionView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapDiscoverAttribution:)];
    [originalAttributionView addGestureRecognizer:tgr];

    self.discoverPostAttributionView = originalAttributionView;
    [self addSubview:self.discoverPostAttributionView];
}

- (void)configureContentView
{
    NSString *content = [self.contentProvider contentForDisplay];
    self.richTextView.content = content;
    self.richTextView.privateContent = [self privateContent];
}

- (WPRichTextView *)richTextView
{
    return (WPRichTextView *)self.contentView;
}

- (CGSize)sizeThatFitsContent:(CGSize)size
{
    return self.richTextView.intrinsicContentSize;
}

- (CGFloat)horizontalMarginForContent
{
    return 0;
}

- (NSDictionary *)attributesForAttributedStringForTitle
{
    CGFloat fontSize = [UIDevice isPad] ? 32.0 : 18.0;
    UIFont *font = [WPFontManager merriweatherBoldFontOfSize:fontSize];

    CGFloat lineHeight = [UIDevice isPad] ? 40.0 : 24.0;
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    [paragraphStyle setMaximumLineHeight:lineHeight];
    [paragraphStyle setMinimumLineHeight:lineHeight];

    return @{NSParagraphStyleAttributeName : paragraphStyle,
             NSFontAttributeName : font};
}

#pragma mark - Action Methods

- (void)richTextView:(WPRichTextView *)richTextView didReceiveLinkAction:(NSURL *)linkURL
{
    if ([self.delegate respondsToSelector:@selector(richTextView:didReceiveLinkAction:)]) {
        [self.delegate richTextView:richTextView didReceiveLinkAction:linkURL];
    }
}

- (void)richTextView:(WPRichTextView *)richTextView didReceiveImageLinkAction:(WPRichTextImage *)imageControl
{
    if ([self.delegate respondsToSelector:@selector(richTextView:didReceiveImageLinkAction:)]) {
        [self.delegate richTextView:richTextView didReceiveImageLinkAction:imageControl];
    }
}

- (void)richTextViewDidLoadMediaBatch:(WPRichTextView *)richTextView
{
    if ([self.delegate respondsToSelector:@selector(richTextViewDidLoadMediaBatch:)]) {
        [self.delegate richTextViewDidLoadMediaBatch:richTextView];
    }
}

@end