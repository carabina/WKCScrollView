# WKCScrollView
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application) [![CocoaPods compatible](https://img.shields.io/cocoapods/v/WKCScrollView.svg?style=flat)](https://cocoapods.org/pods/WKCScrollView) [![License: MIT](https://img.shields.io/cocoapods/l/WKCScrollView.svg?style=flat)](http://opensource.org/licenses/MIT)

## What is WKCScrollView used for ?
1. WKCScrollView is a view based on UIScrollView,and the principle is
similar to UITableView.It only load subViews within allowed rect,and it has a viewsPool to store the visibleViews.
2. It can easily init a card view,Whether the direction is  horizontal or vertical.At the same time, it also can be alignmentCenter, just set the property `isAlignmentCenter` is `YES`.
3. It can scroll in a loopMode when you set the property `loopEnabled` is `YES`.Also pagingEnabled when the property `pagingEnabled` is `YES`.
4. It has the property `isAutoScroll`, when is's `Yes`.WKCScrollView will autoScroll.The same is,you can easily set the interval and scroll direction.In this case, news scrolling can also be achieved.
## What is the main principle of WKCScrollView?
As mentioned above, the emphasis is on its caching.The subViews are loaded base on observing the egde view's appear and disappear.And when the subView are loaded, it is also be added into viewsPool.When the subView are dealloced,it's removed form SuperView and viewsPool.
## How to use WKCScrollView?
It's used as same as UITableView.
` #import <WKCScrollView/WKCScrollView.h>`
1. When you init the WKCScrollView,you shuld register the type of Class.
```
_scrollView = [[WKCScrollView alloc] initWithFrame:CGRectMake(0, 200, 375, 300)];
_scrollView.backgroundColor = [UIColor whiteColor];
[_scrollView registerClass:[UIImageView class] forItemReuseIdentifier:@"view"];
[_scrollView registerClass:[UIImageView class] forItemReuseIdentifier:@"new"];
```
2. you need to set the `delegate` and `dataSource` to your controller or anyObject you want,and conform it's Protocol.
```
_scrollView.dataSource = self;
_scrollView.delegate = self;
```
```
@interface WKCCommunityViewController ()<WKCScrollViewDelegate,WKCScrollViewDataSource>
```
3. There three methods are required.Their functions ars to set the number, size, and loadedViews.
```
- (NSInteger)numberOfViewsInWKCScrollView:(WKCScrollView *)scrollview;
- (CGSize)WKCScrollViewItemSize:(WKCScrollView *)scrollview;
- (__kindof UIView *)WKCScrollView:(WKCScrollView *)scrollview viewAtIndex:(NSInteger)index;
```
In the Method `WKCScrollView:viewAtIndex:`,you can use another method `dequeueReusableItemWithIdentifier:` to get the registered view.
```
UIImageView *view = [scrollview dequeueReusableItemWithIdentifier:@"view"];
```
And, you can set different view within different `index`.
```
if (index == 0) {
      UIImageView *view = [scrollview dequeueReusableItemWithIdentifier:@"view"];
      view.contentMode = UIViewContentModeScaleAspectFill;
      view.backgroundColor = [UIColor yellowColor];
      view.layer.cornerRadius = 8;
      view.layer.masksToBounds = YES;
      return view;
   }else {
      UIImageView *view = [scrollview dequeueReusableItemWithIdentifier:@"new"];       view.backgroundColor = [UIColor redColor];
     view.contentMode = UIViewContentModeScaleAspectFill;
     view.image = [UIImage imageNamed:self.dataSource[index]];
     view.clipsToBounds = YES;
     return view;
}
```
4. When your dataSource, reload the view.
```
 [self.scrollView reloadData];
```
5. What's more convenient is that, there two optional methods set your interitem and line spacing like UICollectionView.
```
- (CGFloat)interitemSpacingInWKCScrollView:(WKCScrollView *)scrollview {
return 20;
}

- (CGFloat)lineSpacingInWKCScrollView:(WKCScrollView *)scrollview {
return 25;
}
```
6. You can use extra methods to ,such as selectedItem.
```
- (void)WKCScrollViewDidScroll:(WKCScrollView *)scrollView contentOffset:(CGPoint)offset;
- (void)WKCScrollViewWillBeginDragging:(WKCScrollView *)scrollView;
- (void)WKCScrollViewDidEndDragging:(WKCScrollView *)scrollView willDecelerate:(BOOL)decelerate;
- (void)WKCScrollViewWillBeginDecelerating:(WKCScrollView *)scrollView;
- (void)WKCScrollViewDidEndDecelerating:(WKCScrollView *)scrollView;
- (void)WKCScrollViewDidScrollToTop:(WKCScrollView *)scrollView;
- (void)WKCScrollView:(WKCScrollView *)scrollView didSelectItemAtIndex:(NSInteger)index;
```
### In this case, you had setted the view up.
- [x] When you set the property `isAlignmentCenter` is `YES`.

![Alt text](https://github.com/WeiKunChao/WKCScrollView/raw/master/screenShort/2.gif).

- [x] When you set the property `loopEnabled` is `YES`.

![Alt text](https://github.com/WeiKunChao/WKCScrollView/raw/master/screenShort/3.gif).
 - [x] When you set the property `pagingEnabled` is `YES`.
 
![Alt text](https://github.com/WeiKunChao/WKCScrollView/raw/master/screenShort/4.gif).

- [x] When you set the property `isAutoScroll` is `YES`.

![Alt text](https://github.com/WeiKunChao/WKCScrollView/raw/master/screenShort/6.gif).

- [x] When you set a different `autoScrollDirection`.
```
  _scrollView.autoScrollDirection = WKCScrollViewAutoScrollDirectionRight;
```
![Alt text](https://github.com/WeiKunChao/WKCScrollView/raw/master/screenShort/7.gif).

For convenience，it has a WKCPageControlView which could be used as same as WKCScrollView.

`#import <WKCScrollView/WKCPageControlView.h>`

The propertys are below.
```
@property (nonatomic, weak) id<WKCPageControlViewDataSource> dataSource;
@property (nonatomic, assign) WKCPageControlViewPageAlignment alignment;
@property (nonatomic, strong) UIImage * backgroundImage;
@property (nonatomic, assign) NSInteger numberOfItem;
@property (nonatomic, assign) CGSize currentItemSize;
@property (nonatomic, assign) CGSize extraItemSize;
@property (nonatomic, assign) CGFloat itemSpacing;
@property (nonatomic, assign) CGFloat edgeSpaing;
@property (nonatomic, assign) NSInteger currentIndex;
```
But the difference is it only has dataSource to set view up,no delegate methos called back.You can set  different view within `current` and `extra`.
```
- (NSInteger)numberOfViewsInWKCPageControlView:(WKCPageControlView *)pageControlView;
- (__kindof UIView *)WKCPageControlViewForCurrentItem:(WKCPageControlView *)pageControlView;
- (__kindof UIView *)WKCPageControlViewForExtraItem:(WKCPageControlView *)pageControlView;
```
1. setUp
```
- (WKCPageControlView *)pageControlView {
    if (!_pageControlView) {
       _pageControlView = [[WKCPageControlView alloc] initWithFrame:CGRectMake(0, 500, 375, 60)];
       _pageControlView.dataSource = self;
       _pageControlView.currentItemSize = CGSizeMake(50, 50);
       _pageControlView.extraItemSize = CGSizeMake(30, 30);
       _pageControlView.itemSpacing = 8;
       _pageControlView.edgeSpaing = 15;
       _pageControlView.alignment = WKCPageControlViewPageAlignmentCenter;
      _pageControlView.backgroundColor = [UIColor greenColor];
  }
    return _pageControlView;
}
```
2.  dataSource call back
```
- (NSInteger)numberOfViewsInWKCPageControlView:(WKCPageControlView *)pageControlView {
     return self.dataSource.count;
}

- (UIView *)WKCPageControlViewForCurrentItem:(WKCPageControlView *)pageControlView {
     UIView *view = [UIView new];
     view.backgroundColor = [UIColor redColor];
     return view;
}

- (UIView *)WKCPageControlViewForExtraItem:(WKCPageControlView *)pageControlView {
     UIView *view = [UIView new];
     view.backgroundColor = [UIColor grayColor];
     return view;
}
```
3. set `CurrentIndex` depend on your WKCScrollView.
```
- (void)WKCScrollViewDidEndDecelerating:(WKCScrollView *)scrollView {
    [self.pageControlView setCurrentIndex:scrollView.currentIndex];
}
```

![Alt text](https://github.com/WeiKunChao/WKCScrollView/raw/master/screenShort/8.gif).





  
  
 


