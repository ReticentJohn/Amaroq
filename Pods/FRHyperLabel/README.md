# FRHyperLabel

FRHyperLabel is a subclass of UILabel, which powers you the capablilty to add one or more hyperlinks to your label texts. With FRHyperLabel, You can define different style, handler and highlight appearance for difference hyperlinks in a super-easy way.

#####CocoaPods

```
pod 'FRHyperLabel'
```

![demo](https://cloud.githubusercontent.com/assets/4215068/10045372/cd468804-6234-11e5-80dd-46f02a758f53.gif)


#### Usage 
###### (For Swift, please refer to the sample code FRHyperLabelDemoSwift)
The code to define a bunch of hyperlinks can be as short as one statement, just use the API: `setLinkForSubstring:withLinkHandler:`, which takes in an substring and a tap handler as input and setup the links with an element touch feedback.

##### Example:
```objc
//Step 1: Define a normal attributed string for non-link texts
NSString *string = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque quis blandit eros, sit amet vehicula justo. Nam at urna neque. Maecenas ac sem eu sem porta dictum nec vel tellus.";
NSDictionary *attributes = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]};

label.attributedText = [[NSAttributedString alloc]initWithString:string attributes:attributes];


//Step 2: Define a selection handler block
void(^handler)(FRHyperLabel *label, NSString *substring) = ^(FRHyperLabel *label, NSString *substring){
	NSLog(@"Selected: %@", substring);
};


//Step 3: Add link substrings
[label setLinksForSubstrings:@[@"Lorem", @"Pellentesque", @"blandit", @"Maecenas"] withLinkHandler:handler];
```

#### APIs

```objc
@property (nonatomic) NSDictionary *linkAttributeDefault;
@property (nonatomic) NSDictionary *linkAttributeHighlight;
```

These two dictionaries specify the default attributes for different states of a link.

------------------------

```objc
- (void)setLinkForRange:(NSRange)range withAttributes:(NSDictionary *)attributes andLinkHandler:(void (^)(FRHyperLabel *label, NSRange selectedRange))handler;
```

add a link by giving the range of the link substring, the desired attribute for normal state and a selection handler.

------------------------
```objc
- (void)setLinkForRange:(NSRange)range withLinkHandler:(void(^)(FRHyperLabel *label, NSRange selectedRange))handler;
```
Same as `setLinkForRange:withAttributes:andLinkHandler:`, expect this will feed the attribute parameter with 
`linkAttributeDefault`

------------------------

```objc
- (void)setLinkForSubstring:(NSString *)substring withAttribute:(NSDictionary *)attribute andLinkHandler:(void(^)(FRHyperLabel *label, NSString *substring))handler;
```
Add a link by giving the link substring, the desired attribute for normal state and a selection handler. This will only add links for the first appearance of the substring. If you need add links for others, please use `setLinkForRange:withAttributes:andLinkHandler:`.

------------------------

```objc
- (void)setLinkForSubstring:(NSString *)substring withLinkHandler:(void(^)(FRHyperLabel *label, NSString *substring))handler;
```
Same as `setLinkForSubstring:withAttributes:andLinkHandler:`, expect this will feed the attribute parameter with 
`linkAttributeDefault`

------------------------

```objc
- (void)setLinksForSubstrings:(NSArray *)substrings withLinkHandler:(void(^)(FRHyperLabel *label, NSString *substring))handler;
```

Add am array of links by giving an array of substrings. The selection handler has to the same for all links in the array, only first appreance will be take care.

#### Known Issues
Please refer to the [Known Issues](https://github.com/null09264/FRHyperLabel/wiki/Known-Issues) page in the wiki.
