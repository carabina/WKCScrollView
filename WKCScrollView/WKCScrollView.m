//
//  WKCScrollView.m
//  WKCDevelop
//
//  Created by 魏昆超 on 2018/4/30.
//  Copyright © 2018年 WeiKunChao. All rights reserved.
//

#import "WKCScrollView.h"
#import <objc/message.h>
#import <Availability.h>

#ifndef loopItems
#define loopItems 10000
#endif

typedef NS_ENUM(NSInteger,currentScrollDirection) {
    currentScrollDirectionRight,
    currentScrollDirectionLeft,
    currentScrollDirectionUp,
    currentScrollDirectionBottom
};

@interface WKCScrollView()<UIScrollViewDelegate>{
    
    NSInteger _numberOfItems;
    CGSize _itemSize;
    CGFloat _currentInteritemSpacing;
    CGFloat _currentLineSpacing;
    CGPoint _currentStartPoint;
    CGPoint _currentEndPoint;
    currentScrollDirection _currentDirection;
    BOOL _isSetLoopOffset;
    NSInteger _recordStartLeft;
}

@property (nonatomic, strong) UIImageView * backgroundImageView;
@property (nonatomic, assign) CGFloat pageWidth;
@property (nonatomic, assign) CGFloat pageHeight;
@property (nonatomic, strong) UIScrollView * scrollView;
@property (nonatomic, strong) NSMutableDictionary * totalViews;
@property (nonatomic, strong) NSMutableDictionary * registerPool;
@property (nonatomic, strong) NSMutableArray * viewsPool;
@property (nonatomic, assign) NSInteger previousItemIndex;
@property (nonatomic, assign) CGFloat fixedCenterSpacing;
@property (nonatomic, assign) CGPoint recordContentOffset;
@property (nonatomic, strong) NSTimer * autoScrollTimer;

@end

@implementation WKCScrollView

- (instancetype)init {
    if (self = [super init]) {
        [self setUp];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setUp];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setUp];
    }
    return self;
}

- (void)setUp {
    self.previousItemIndex = 0;
    self.direction = scrollDirectionHorizontal;
    self.loopEnabled = NO;
    self.isAlignmentCenter = NO;
    self.recordContentOffset = CGPointZero;
    self.autoScrollDuration = 2.0f;
    self.isAutoScroll = NO;
    _currentLineSpacing = 0;
    _currentInteritemSpacing = 0;
    _currentStartPoint = CGPointZero;
    _currentEndPoint = CGPointZero;
    _isSetLoopOffset = NO;
    _recordStartLeft = 0;
    
    self.clipsToBounds = YES;
    [self addSubview:self.backgroundImageView];
}

- (void)setUpScrollView {
    if (self.direction == scrollDirectionHorizontal) {
        self.scrollView.frame = CGRectMake(self.fixedCenterSpacing, _currentLineSpacing, self.pageWidth, _itemSize.height);
    }
    if (self.direction == scrollDirectionVertical) {
        self.scrollView.frame = CGRectMake(_currentInteritemSpacing, self.fixedCenterSpacing, _itemSize.width, self.pageHeight);
    }
    
    if (!self.scrollView.superview) [self addSubview:self.scrollView];
}

- (void)layoutSubviews {
    [self setUpScrollView];
    if (self.loopEnabled) {
        if (_isSetLoopOffset) [self initWithViewsIndex:0]; //偏移完再初始化视图
    }
    if (!self.loopEnabled) [self initWithViewsIndex:0]; //直接初始化视图
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
     [self initWithContentSizeAndContentOffset:self.loopEnabled];
}

#pragma mark  ------<初始化视图>-------

- (void)initWithViewsIndex:(NSInteger)index {
    if (!self.loopEnabled) {
        if (self.previousItemIndex >= _numberOfItems) return;
    }
    
    if (self.loopEnabled) {
        index = index % _numberOfItems;
    }
    
    UIView *recodeView = [self postDelegateViewsWithIndex:index];
    BOOL isViewContains = [self.totalViews.allValues containsObject:recodeView]; // 取相应index的view
    if (!isViewContains) { //没记录
        [self recordContentSizeAndPoint]; //记录contentSize和_currentPoint
        [self getWillShowViewFrame:recodeView]; //获取坐标
        [self queueItemView:recodeView withindex:index]; //缓存
        [self.scrollView addSubview:recodeView]; //加载
        [self limitFirsIntoWithIndex:index]; //设置初次进入的限制条件
    }
    
    if (isViewContains) { //有记录
        
        recodeView = [self.totalViews objectForKey:@(index)]; //去取相应的view
        [self recordContentSizeAndPoint]; //记录contentSize和_currentPoint
        if (self.loopEnabled) { //不循环直接取,循环需要重新赋坐标
            [self getWillShowViewFrame:recodeView]; //获取坐标
            [self queueItemView:recodeView withindex:index];//再变化再缓存
        }
        [self.scrollView addSubview:recodeView];
    }
}

#pragma mark  ------<UIScrollViewDelegate>------

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.loopEnabled) {
        if (_isSetLoopOffset) [self judgeScrollDirection:scrollView];
    }
    
    if (!self.loopEnabled) [self judgeScrollDirection:scrollView];
    if (self.delegate && [self.delegate respondsToSelector:@selector(WKCScrollViewDidScroll:contentOffset:currentIndex:)]) {
        [self.delegate WKCScrollViewDidScroll:self contentOffset:self.recordContentOffset currentIndex:self.currentIndex];
    }

}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(WKCScrollViewWillBeginDragging:)]) {
        [self.delegate WKCScrollViewWillBeginDragging:self];
    }
    if (self.isAutoScroll) [self removeTimer];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(WKCScrollViewDidScrollToTop:)]) {
        [self.delegate WKCScrollViewDidScrollToTop:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(WKCScrollViewDidEndDecelerating:)]) {
        [self.delegate WKCScrollViewDidEndDecelerating:self];
    }
    
    if (self.isAutoScroll) [self startAutoTimer];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(WKCScrollViewWillBeginDecelerating:)]) {
        [self.delegate WKCScrollViewWillBeginDecelerating:self];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.delegate && [self.delegate respondsToSelector:@selector(WKCScrollViewDidEndDragging:willDecelerate:)]) {
        [self.delegate WKCScrollViewDidEndDragging:self willDecelerate:decelerate];
    }
}

- (void)judgeScrollDirection:(UIScrollView *)scrollView {
    if (self.direction == scrollDirectionHorizontal) {
        static float newx = 0;
        static float oldx = 0;
        newx = scrollView.contentOffset.x ;
        if (newx != oldx ) {
            CGFloat scrollRight_X = 0;
            CGFloat scrollLeft_X = 0;
            if (self.isAlignmentCenter) {
                scrollRight_X = scrollView.contentOffset.x + self.bounds.size.width - self.fixedCenterSpacing; //屏幕右端X值
               scrollLeft_X = scrollView.contentOffset.x - self.fixedCenterSpacing; //屏幕左端X值
            }
            if (!self.isAlignmentCenter) {
                scrollRight_X = scrollView.contentOffset.x + self.bounds.size.width;
                scrollLeft_X  = scrollView.contentOffset.x;
            }
            
            if (newx > oldx) {
                _currentDirection = currentScrollDirectionRight;
                [self handleWithDirectionRight:scrollRight_X leftValue:scrollLeft_X];
            }else {
                _currentDirection = currentScrollDirectionLeft;
                [self handleWithDirectionLeft:scrollRight_X leftValue:scrollLeft_X];
            }
            oldx = newx;
        }
    }

    if (self.direction == scrollDirectionVertical) {
        static float newY = 0;
        static float oldY = 0;
        newY = scrollView.contentOffset.y;
        if (newY != oldY) {
            CGFloat scrollBottom_Y = 0;
            CGFloat scrollUp_Y = 0;
            if (self.isAlignmentCenter) {
                scrollBottom_Y = scrollView.contentOffset.y + self.bounds.size.height - self.fixedCenterSpacing; //屏幕底端Y值
                scrollUp_Y = scrollView.contentOffset.y - self.fixedCenterSpacing; //屏幕顶端Y值
            }
            if (!self.isAlignmentCenter) {
                scrollBottom_Y = scrollView.contentOffset.y + self.bounds.size.height;
                scrollUp_Y = scrollView.contentOffset.y;
            }
            if (newY > oldY) {
                _currentDirection = currentScrollDirectionBottom;
                [self handleWithDirectionBottom:scrollBottom_Y upValue:scrollUp_Y];
            }else {
                _currentDirection = currentScrollDirectionUp;
                [self handleWithDirectionUp:scrollBottom_Y upValue:scrollUp_Y];
            }
            oldY = newY;
        }
    }
}

//右
- (void)handleWithDirectionRight:(CGFloat)right leftValue:(CGFloat)left {
    UIView *willDismissView = [self findLeftOne];
    BOOL willDimiss = (left >= CGRectGetMaxX(willDismissView.frame)); //符合左端视图将要消失的条件
    if (willDimiss) {
        [self dequeueItemWithView:willDismissView];
    }
    
    NSInteger willShowViewIndex = 0;
    NSNumber *key = [self findKeyWithView:[self findRightOne]];
    if (key) {
        willShowViewIndex = key.integerValue + 1; //找到右端即将出现的视图所属坐标值
        if (self.loopEnabled) {
            if (willShowViewIndex > (_numberOfItems - 1)) {
                willShowViewIndex = 0;
            }
        }
        if (!self.loopEnabled) {
            if (willShowViewIndex > (_numberOfItems - 1)) return;
        }
        BOOL willRightViewShow = right > ((CGRectGetMaxX([self findRightOne].frame) + _currentInteritemSpacing));
        if (willRightViewShow) {
            
            self.previousItemIndex = willShowViewIndex;
            [self initWithViewsIndex:self.previousItemIndex];
        }
    }
}

//左
- (void)handleWithDirectionLeft:(CGFloat)right leftValue:(CGFloat)left {
    UIView *view = [self findRightOne];
    BOOL willDimiss = (right <= CGRectGetMinX(view.frame)); //右端即将消失的条件
    if (willDimiss) {
        [self dequeueItemWithView:view];
    }
    
    NSInteger willShowViewIndex = 0;
    NSNumber *key = [self findKeyWithView:[self findLeftOne]];
    if (key) {
        willShowViewIndex = key.integerValue - 1; //找到左端即将出现的视图所属坐标值
        //限制条件
        if (self.loopEnabled) {
            if (willShowViewIndex < 0) willShowViewIndex = _numberOfItems - 1;
        }
        if (!self.loopEnabled) {
            if (willShowViewIndex < 0) return;
        }
        
        BOOL willLeftViewShow  = left < (CGRectGetMinX([self findLeftOne].frame) - _currentInteritemSpacing);
        if (willLeftViewShow) {
            NSNumber *number = [self findKeyWithView:[self findRightOne]];
            self.previousItemIndex = [number integerValue];
            [self initWithViewsIndex:willShowViewIndex];
        }
    }
}

//底
- (void)handleWithDirectionBottom:(CGFloat)bottom upValue:(CGFloat)up {
    UIView *willDismissView = [self findUpOne];
    BOOL willDimiss = (up >= CGRectGetMaxY(willDismissView.frame)); //符合顶端视图将要消失的条件
    if (willDimiss) [self dequeueItemWithView:willDismissView];
    
    NSInteger willShowViewIndex = 0;
    NSNumber *key = [self findKeyWithView:[self findBottomOne]];
    if (key) {
        willShowViewIndex = key.integerValue + 1; //找到底端即将出现的视图所属坐标值
        if (self.loopEnabled) {
            if (willShowViewIndex > (_numberOfItems - 1)) {
                willShowViewIndex = 0;
            }
        }
        if (!self.loopEnabled) {
            if (willShowViewIndex > (_numberOfItems - 1)) return;
        }
        BOOL willBottomViewShow = bottom > (CGRectGetMaxY([self findBottomOne].frame) + _currentLineSpacing);
        if (willBottomViewShow) {
            self.previousItemIndex = willShowViewIndex;
            [self initWithViewsIndex:self.previousItemIndex];
        }
    }
}

//上
- (void)handleWithDirectionUp:(CGFloat)bottom upValue:(CGFloat)up {
    UIView *view = [self findBottomOne];
    BOOL willDimiss = (bottom <= CGRectGetMinY(view.frame)); //底端即将消失的条件
    if (willDimiss) [self dequeueItemWithView:view];
    
    NSInteger willShowViewIndex = 0;
    NSNumber *key = [self findKeyWithView:[self findUpOne]];
    if (key) {
        willShowViewIndex = key.integerValue - 1; //找到顶端即将出现的视图所属坐标值
        //限制条件
        if (self.loopEnabled) {
            if (willShowViewIndex < 0) willShowViewIndex = _numberOfItems - 1;
        }
        if (!self.loopEnabled) {
            if (willShowViewIndex < 0) return;
        }
        BOOL willUpViewShow  = up < (CGRectGetMinY([self findUpOne].frame) - _currentLineSpacing);
        if (willUpViewShow) {
            NSNumber *number = [self findKeyWithView:[self findBottomOne]];
            self.previousItemIndex = [number integerValue];
            [self initWithViewsIndex:willShowViewIndex];
        }
    }
}

#pragma mark  ------<注册和取视图>------
- (void)registerClass:(Class)aClass forItemReuseIdentifier:(NSString *)identify {
    NSAssert(identify, @"标识不能为空");
    NSAssert([aClass isSubclassOfClass:[UIView class]], @"注册的视图不是UIView类,请确认");
    [self.registerPool setValue:aClass forKey:identify];
}

- (__kindof UIView *)dequeueReusableItemWithIdentifier:(NSString *)identify {
    NSAssert(identify, @"标识不能为空");
    Class aClass= [self.registerPool valueForKey:identify];
    NSAssert([aClass isSubclassOfClass:[UIView class]], @"取出的视图不是UIView类,请确认");
    return [aClass new];
}

#pragma mark  ------<setter和getter>------

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    _backgroundImage = backgroundImage;
    if (backgroundImage) self.backgroundImageView.image = self.backgroundImage;
}

- (NSInteger)currentIndex {
    return [self findCurrentIndex];
}

- (void)setDataSource:(id<WKCScrollViewDataSource>)dataSource {
    _dataSource = dataSource;
    [self postDelegates];
}

- (void)postDelegates {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfViewsInWKCScrollView:)]) {
        _numberOfItems = [self.dataSource numberOfViewsInWKCScrollView:self];
    }

    if (self.dataSource && [self.dataSource respondsToSelector:@selector(WKCScrollViewItemSize:)]) {
        _itemSize = [self.dataSource WKCScrollViewItemSize:self];
    }
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(interitemSpacingInWKCScrollView:)]) {
        _currentInteritemSpacing= [self.dataSource interitemSpacingInWKCScrollView:self];
    }
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(lineSpacingInWKCScrollView:)]) {
        _currentLineSpacing = [self.dataSource lineSpacingInWKCScrollView:self];
    }
}

- (void)setScrollToTop:(BOOL)scrollToTop {
    _scrollToTop = scrollToTop;
    self.scrollView.scrollsToTop = scrollToTop;
}

- (void)setPagingEnabled:(BOOL)pagingEnabled {
    _pagingEnabled = pagingEnabled;
    self.scrollView.pagingEnabled = pagingEnabled;
}

- (void)setLoopEnabled:(BOOL)loopEnabled {
    _loopEnabled = loopEnabled;
    if (self.isAutoScroll) _loopEnabled = YES;
}

- (void)setIsAutoScroll:(BOOL)isAutoScroll {
    _isAutoScroll = isAutoScroll;
    if (isAutoScroll) [self startAutoTimer];
}

- (void)setIsAlignmentCenter:(BOOL)isAlignmentCenter {
    _isAlignmentCenter = isAlignmentCenter;
    [self setUpScrollView];
}

- (void)setDirection:(scrollDirection)direction {
    _direction = direction;
    switch (direction) {
        case scrollDirectionHorizontal:
            self.scrollView.alwaysBounceHorizontal = YES;
            self.scrollView.alwaysBounceVertical = NO;
            _currentDirection = currentScrollDirectionRight;
            self.autoScrollDirection = WKCScrollViewAutoScrollDirectionLeft;
            break;
        case scrollDirectionVertical:
            self.scrollView.alwaysBounceVertical = YES;
            self.scrollView.alwaysBounceHorizontal = NO;
            _currentDirection = currentScrollDirectionBottom;
            self.autoScrollDirection = WKCScrollViewAutoScrollDirectionUp;
            break;
    }
}

- (BOOL)isDragging {
    return self.scrollView.isDragging;
}

- (BOOL)isDecelerating {
    return self.scrollView.isDecelerating;
}

- (CGPoint)recordContentOffset {
    if (self.loopEnabled) {
        if (self.direction == scrollDirectionHorizontal) {
            return CGPointMake(self.scrollView.contentOffset.x - self.pageWidth * (loopItems - 1), 0);
        }
        if (self.direction == scrollDirectionVertical) {
            return CGPointMake(0, self.scrollView.contentOffset.y - self.pageHeight * (loopItems - 1));
        }
    }
    return self.scrollView.contentOffset;
}

- (CGFloat)fixedCenterSpacing {
    if (self.isAlignmentCenter) {
        if (self.direction == scrollDirectionHorizontal) {//水平居中
            return (self.bounds.size.width - _itemSize.width) / 2 - _currentInteritemSpacing;
        }
        if (self.direction == scrollDirectionVertical) { //垂直居中
            return (self.bounds.size.height - _itemSize.height) / 2 - _currentLineSpacing;
        }
    }
    
    return 0; //其他
}

#pragma mark ------<内部使用方法>------

//获取视图
- (UIView *)postDelegateViewsWithIndex:(NSInteger)index {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(WKCScrollView:viewAtIndex:)]) {
        return [self.dataSource WKCScrollView:self viewAtIndex:index];
    }
    return nil;
}

- (UIView *)queueItemView:(UIView *)view withindex:(NSInteger)index{
    if (view) {
        if (![self.viewsPool containsObject:view]) {
            [self.viewsPool addObject:view];
        }
        if (![self.totalViews.allValues containsObject:view]) { //只加载新生成的视图
        [self.totalViews setObject:view forKey:@(index)];
        }else {
            return view;
        }
    }
    return nil;
}

- (void)dequeueItemWithView:(UIView *)view {
    [view removeFromSuperview];
    [self.viewsPool removeObject:view];
}

//初次进入的限制条件
- (void)limitFirsIntoWithIndex:(NSInteger)index {
    if (self.direction == scrollDirectionHorizontal) {
        if (self.loopEnabled) {
            if (_currentDirection == currentScrollDirectionRight) {
                if ((CGRectGetMaxX([self findRightOne].frame) - self.scrollView.contentOffset.x + self.fixedCenterSpacing + _currentInteritemSpacing) < self.bounds.size.width) {
                    //设置初次加载屏幕内显示的
                    _currentDirection = currentScrollDirectionRight;
                    index += 1;
                    [self initWithViewsIndex:index];
                }
            }

            if ((CGRectGetMinX([self findLeftOne].frame) - self.scrollView.contentOffset.x + self.fixedCenterSpacing - _currentInteritemSpacing) > 0) {
                _currentDirection = currentScrollDirectionLeft;
                _recordStartLeft -= 1;
                if (_recordStartLeft < 0) _recordStartLeft = _numberOfItems - 1;
                [self initWithViewsIndex:_recordStartLeft];
            }
        }

        if (!self.loopEnabled) {
            if (_currentDirection == currentScrollDirectionRight) {
                if ((CGRectGetMaxX([self findRightOne].frame)) - self.scrollView.contentOffset.x + self.fixedCenterSpacing + _currentInteritemSpacing  < self.bounds.size.width) {
                    //设置初次加载屏幕内显示的
                    index += 1;
                    [self initWithViewsIndex:index];
                }
            }
        }
    }

    if (self.direction == scrollDirectionVertical) {
        if (self.loopEnabled) {
            if (_currentDirection == currentScrollDirectionBottom) {
                if ((CGRectGetMaxY([self findBottomOne].frame) - self.scrollView.contentOffset.y +  self.fixedCenterSpacing + _currentLineSpacing) < self.bounds.size.height) {
                    //设置初次加载屏幕内显示的
                    _currentDirection = currentScrollDirectionBottom;
                    index += 1;
                    [self initWithViewsIndex:index];
                }
            }

            if ((CGRectGetMinY([self findUpOne].frame) - self.scrollView.contentOffset.y + self.fixedCenterSpacing - _currentLineSpacing) > 0) {
                _currentDirection = currentScrollDirectionUp;
                _recordStartLeft -= 1;
                if (_recordStartLeft < 0) _recordStartLeft = _numberOfItems - 1;
                [self initWithViewsIndex:_recordStartLeft];
            }
        }

        if (!self.loopEnabled) {
            if (_currentDirection == currentScrollDirectionBottom) {
                if ((CGRectGetMaxY([self findBottomOne].frame) - self.scrollView.contentOffset.y +  self.fixedCenterSpacing + _currentLineSpacing) < self.bounds.size.height) {
                    //设置初次加载屏幕内显示的
                    index += 1;
                    [self initWithViewsIndex:index];
                }
            }
        }
    }
}

//设置初始允许的总偏移量和初始位置
- (void)initWithContentSizeAndContentOffset:(BOOL)isLoop {
    if (self.direction == scrollDirectionHorizontal) {
        if (!isLoop) { //不循环
            self.scrollView.contentSize = CGSizeZero;
            self.scrollView.contentOffset = CGPointZero;
            _currentStartPoint = CGPointZero;
            _currentEndPoint = CGPointZero;
            _isSetLoopOffset = NO;
        }
        
        if (isLoop) { //循环
            self.scrollView.contentSize = CGSizeMake(self.pageWidth * loopItems, 0);
            self.scrollView.contentOffset = CGPointMake(self.pageWidth * (loopItems - 1), 0);
            _currentStartPoint = CGPointMake(self.scrollView.contentOffset.x, 0);
            _currentEndPoint = CGPointMake(self.scrollView.contentOffset.x, 0);
            _isSetLoopOffset = YES;
        }
    }

    if (self.direction == scrollDirectionVertical) {
        if (!isLoop) { //不循环
            self.scrollView.contentSize = CGSizeZero;
            self.scrollView.contentOffset = CGPointZero;
            _currentStartPoint = CGPointZero;
            _currentEndPoint = CGPointZero;
            _isSetLoopOffset = NO;
        }
        
        if (isLoop) { //循环
            self.scrollView.contentSize = CGSizeMake(0, self.pageHeight * loopItems);
            self.scrollView.contentOffset = CGPointMake(0, self.pageHeight * (loopItems - 1));
            _currentStartPoint = CGPointMake(0, self.scrollView.contentOffset.y);
            _currentEndPoint = CGPointMake(0, self.scrollView.contentOffset.y);
            _isSetLoopOffset = YES;
        }
    }
}

//设置整体可偏移量以及记录的最右端point
- (void)recordContentSizeAndPoint {
    if (self.direction == scrollDirectionHorizontal) {
        if ([self findRightOne] && [self findLeftOne]) {
            if (self.loopEnabled) {
            self.scrollView.contentSize = CGSizeMake(CGRectGetMaxX([self findRightOne].frame) + self.pageWidth, 0);
            }
            if (!self.loopEnabled) {
                self.scrollView.contentSize = CGSizeMake(self.pageWidth * _numberOfItems + _currentInteritemSpacing, 0);
            }
            _currentEndPoint = CGPointMake(CGRectGetMaxX([self findRightOne].frame), 0);
            _currentStartPoint = CGPointMake(CGRectGetMinX([self findLeftOne].frame), 0);
        }
    }
    
    if (self.direction == scrollDirectionVertical) {
        if ([self findBottomOne] && [self findUpOne]) {
            if (self.loopEnabled) {
                self.scrollView.contentSize = CGSizeMake(0, CGRectGetMaxY([self findBottomOne].frame) + self.pageHeight);
            }
            if (!self.loopEnabled) {
                self.scrollView.contentSize = CGSizeMake(0, self.pageHeight * _numberOfItems + _currentLineSpacing);
            }
            _currentEndPoint = CGPointMake(0, CGRectGetMaxY([self findBottomOne].frame));
            _currentStartPoint = CGPointMake(0, CGRectGetMinY([self findUpOne].frame));
        }
    }
    
}

//赋坐标
- (void)getWillShowViewFrame:(UIView *)view {
    
    switch (_currentDirection) {
        case currentScrollDirectionLeft:
        {
            CGFloat x = _currentStartPoint.x - self.pageWidth;
            CGFloat y = 0;
            CGFloat width = _itemSize.width;
            CGFloat height = _itemSize.height;
            view.frame = CGRectMake(x, y, width, height);
        }
            break;
        case currentScrollDirectionRight:
        {
            CGFloat x = _currentEndPoint.x + _currentInteritemSpacing;
            CGFloat y = 0;
            CGFloat width = _itemSize.width;
            CGFloat height = _itemSize.height;
            view.frame = CGRectMake(x, y, width, height);
        }
            break;
        case currentScrollDirectionUp:
        {
            CGFloat x = 0;
            CGFloat y = _currentStartPoint.y - self.pageHeight;
            CGFloat width = _itemSize.width;
            CGFloat height = _itemSize.height;
            view.frame = CGRectMake(x, y, width, height);
        }
            break;
        case currentScrollDirectionBottom:
        {
            CGFloat x = 0;
            CGFloat y = _currentEndPoint.y + _currentLineSpacing;
            CGFloat width = _itemSize.width;
            CGFloat height = _itemSize.height;
            view.frame = CGRectMake(x, y, width, height);
        }
            break;
    }
}

//找到所属的key
- (NSNumber *)findKeyWithView:(UIView *)view {
    __block NSNumber *findKey = nil;
    [self.totalViews enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isEqual:view]) {
            findKey = key;
            * stop = YES;
        }
    }];
    return findKey;
}

//找到最左端视图
- (UIView *)findLeftOne {
    CGFloat x = MAXFLOAT;
    UIView *leftView = nil;
    for (UIView *cache in self.viewsPool) {
        x = MIN(x, CGRectGetMinX(cache.frame));
    }
    for (UIView *cache in self.viewsPool) {
        if (CGRectGetMinX(cache.frame) == x) {
            leftView = cache;
            break ;
        }
    }
    return leftView;
}

//找到最右端视图
- (UIView *)findRightOne {
    CGFloat x = 0;
    UIView *rightView = nil;
    for (UIView *cache in self.viewsPool) {
        x = MAX(x, CGRectGetMaxX(cache.frame));
    }
    
    for (UIView *cache in self.viewsPool) {
        if (CGRectGetMaxX(cache.frame) == x) {
            rightView = cache;
            break ;
        }
    }
    return rightView;
}

//找到顶端视图
- (UIView *)findUpOne {
    CGFloat y = MAXFLOAT;
    UIView *upView = nil;
    for (UIView *cache in self.viewsPool) {
        y = MIN(y, CGRectGetMinY(cache.frame));
    }
    for (UIView *cache in self.viewsPool) {
        if (CGRectGetMinY(cache.frame) == y) {
            upView = cache;
            break ;
        }
    }
    return upView;
}

//找到底部视图
- (UIView *)findBottomOne {
    CGFloat y = 0;
    UIView *bottomView = nil;
    for (UIView *cache in self.viewsPool) {
        y = MAX(y, CGRectGetMaxY(cache.frame));
    }
    
    for (UIView *cache in self.viewsPool) {
        if (CGRectGetMaxY(cache.frame) == y) {
            bottomView = cache;
            break ;
        }
    }
    return bottomView;
}

- (NSInteger)findCurrentIndex {
    CGFloat middle = MAXFLOAT;
    NSInteger middleIndex = 0;
    if (self.isAlignmentCenter) {
        if (self.direction == scrollDirectionHorizontal) {
            for (UIView * view in self.viewsPool) {
                middle = MIN(middle, fabs(view.center.x - self.scrollView.contentOffset.x - self.scrollView.center.x));
            }
            for (UIView *view in self.viewsPool) {
                if (fabs(view.center.x - self.scrollView.contentOffset.x - self.scrollView.center.x) == middle) {
                    middleIndex = [[self findKeyWithView:view] integerValue];
                }
            }
        }

        if (self.direction == scrollDirectionVertical) {
            for (UIView * view in self.viewsPool) {
                middle = MIN(middle, fabs(view.center.y - self.scrollView.contentOffset.y - self.scrollView.center.y));
            }
            for (UIView *view in self.viewsPool) {
                if (fabs(view.center.y - self.scrollView.contentOffset.y - self.scrollView.center.y) == middle) {
                    middleIndex = [[self findKeyWithView:view] integerValue];
                }
            }
        }
    }
    
    if (!self.isAlignmentCenter) {
        if (self.direction == scrollDirectionHorizontal) {
            middleIndex = [[self findKeyWithView:[self findLeftOne]] integerValue];
        }
        
        if (self.direction == scrollDirectionVertical) {
            middleIndex = [[self findKeyWithView:[self findUpOne]] integerValue];
        }
    }
    
    return middleIndex;
}

- (void)reloadData {
    self.previousItemIndex = 0;
    self.recordContentOffset = CGPointZero;
    _currentStartPoint = CGPointZero;
    _currentEndPoint = CGPointZero;
    _isSetLoopOffset = NO;
    _recordStartLeft = 0;
    if (self.direction == scrollDirectionHorizontal) {
        _currentDirection = currentScrollDirectionRight;
    }
    if (self.direction == scrollDirectionVertical) {
        _currentDirection = currentScrollDirectionBottom;
    }
    for (UIView *view in self.viewsPool){
        if (view.superview) [view removeFromSuperview];
    }
    for (UIView *value in self.totalViews.allValues) {
        if (value.superview) [value removeFromSuperview];
    }
    [self.totalViews removeAllObjects];
    [self.viewsPool removeAllObjects];
    [self postDelegates];
    [self initWithContentSizeAndContentOffset:self.loopEnabled];
    [self setNeedsLayout];
}

//加手势
- (void)addTapGestureWithView:(UIView *)view {
    view.userInteractionEnabled = YES;
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    [view addGestureRecognizer:gesture];
}

- (void)didTap:(UITapGestureRecognizer *)tapGesture {
    CGPoint point = [tapGesture locationInView:self.scrollView];
    NSInteger index = 0;
    
    for (UIView *view in self.viewsPool) {
        CGRect newFrame = CGRectZero;
        if (self.direction == scrollDirectionHorizontal) {
            newFrame = CGRectMake(view.frame.origin.x, 0, view.frame.size.width, self.bounds.size.height);
        }
        if (self.direction == scrollDirectionVertical) {
            newFrame = CGRectMake(0, view.frame.origin.y, self.bounds.size.width, view.frame.size.height);
        }
        if (CGRectContainsPoint(newFrame, point)) {
           index = [[self findKeyWithView:view] integerValue];
        }
    }
    
    if (index >= 0 && index < _numberOfItems) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(WKCScrollView:didSelectItemAtIndex:)]) {
            [self.delegate WKCScrollView:self didSelectItemAtIndex:index];
        }
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if ([self pointInside:point withEvent:event]) {
        return self.scrollView;
    }
    return [super hitTest:point withEvent:event];
}

- (void)startAutoTimer {
    self.autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:self.autoScrollDuration target:self selector:@selector(autoAnimation) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.autoScrollTimer forMode:NSRunLoopCommonModes];
}

- (void)autoAnimation {
    if (self.direction == scrollDirectionHorizontal) {
        if (self.autoScrollDirection == WKCScrollViewAutoScrollDirectionLeft) {
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x + self.pageWidth, 0) animated:YES];
        }
        if (self.autoScrollDirection == WKCScrollViewAutoScrollDirectionRight) {
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x - self.pageWidth, 0) animated:YES];
        }
    }
    
    if (self.direction == scrollDirectionVertical) {
        if (self.autoScrollDirection == WKCScrollViewAutoScrollDirectionUp) {
            [self.scrollView setContentOffset:CGPointMake(0, self.scrollView.contentOffset.y + self.pageHeight) animated:YES];
        }
        if (self.autoScrollDirection == WKCScrollViewAutoScrollDirectionDown) {
            [self.scrollView setContentOffset:CGPointMake(0, self.scrollView.contentOffset.y - self.pageHeight) animated:YES];
        }
    }
}

- (void)removeTimer {
    [self.autoScrollTimer invalidate];
    self.autoScrollTimer = nil;
}

- (void)dealloc {
    [self removeTimer];
}

#pragma mark ------<量初始化>-------

- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        _backgroundImageView.backgroundColor = [UIColor clearColor];
        _backgroundImageView.clipsToBounds = YES;
    }
    return _backgroundImageView;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.contentSize = CGSizeZero;
        _scrollView.contentOffset = CGPointZero;
        _scrollView.delegate = self;
        _scrollView.delaysContentTouches = NO;
        _scrollView.scrollEnabled = YES;
        _scrollView.scrollsToTop = NO;
        _scrollView.clipsToBounds = NO;
        _scrollView.bounces = YES;
        _scrollView.userInteractionEnabled = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.backgroundColor = [UIColor clearColor];
        [self addTapGestureWithView:_scrollView];
    }
    return _scrollView;
}

- (NSMutableDictionary *)registerPool {
    if (!_registerPool) {
        _registerPool = [NSMutableDictionary dictionary];
    }
    return _registerPool;
}

- (NSMutableArray *)viewsPool {
    if (!_viewsPool) {
        _viewsPool = [NSMutableArray arrayWithCapacity:_numberOfItems];
    }
    return _viewsPool;
}

- (NSMutableDictionary *)totalViews {
    if (!_totalViews) {
        _totalViews = [NSMutableDictionary dictionary];
    }
    return _totalViews;
}

- (CGFloat)pageWidth {
    return _currentInteritemSpacing + _itemSize.width;
}

- (CGFloat)pageHeight {
    return _currentLineSpacing + _itemSize.height;
}

@end
