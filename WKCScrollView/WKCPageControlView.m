//
//  WKCPageControlView.m
//  WKCDevelop
//
//  Created by 魏昆超 on 2018/5/5.
//  Copyright © 2018年 WeiKunChao. All rights reserved.
//

#import "WKCPageControlView.h"
@interface WKCPageControlView(){
    NSInteger  _numberOfItems;
    UIView *_currentPageView;
}

@property (nonatomic, strong) UIImageView * backgroundImageView;
@property (nonatomic, strong) NSMutableArray <UIView *>* views;
@property (nonatomic, assign) CGFloat start_X;

@end
@implementation WKCPageControlView

- (instancetype)init {
    if (self = [super init]) {
        [self setUpSubViews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setUpSubViews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setUpSubViews];
    }
    return self;
}

- (void)setUpSubViews {
    self.alignment = WKCPageControlViewPageAlignmentCenter;
    self.currentItemSize = CGSizeZero;;
    self.extraItemSize = CGSizeZero;
    self.itemSpacing = 8.f;
    self.edgeSpaing = 15.f;
    self.currentIndex = 0;
    
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor clearColor];
    [self addSubview:self.backgroundImageView];
}

- (void)layoutSubviews {
     [self replaceCurrentIndexItem];
}

#pragma mark ----<setter、getter>------

- (void)setDataSource:(id<WKCPageControlViewDataSource>)dataSource {
    _dataSource = dataSource;
    [self postNumberDelegate];
    [self postCurrentViewDelegate];
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    _backgroundImage = backgroundImage;
    if (backgroundImage) self.backgroundImageView.image = backgroundImage;
}

- (void)setCurrentIndex:(NSInteger)currentIndex {
    _currentIndex = currentIndex;
    [self replaceCurrentIndexItem];
}

#pragma mark -----<内部方法>------

- (void)reloadData {
    [self postNumberDelegate];
    [self resetPropertys];
    [self replaceCurrentIndexItem];
}

- (void)resetPropertys {
    self.currentIndex = 0;
}

- (void)replaceCurrentIndexItem {
    [self cleanView];
    for (NSInteger i = 0; i < _numberOfItems; i ++) {
        if (i < self.currentIndex) {
            [self setUpExtraViewWithStartX:self.start_X withIndex:i];
        }
        
        if (i == self.currentIndex) {
            [self setUpCurrentView];
        }
        
        if (i > self.currentIndex) {
            
            CGFloat x = CGRectGetMaxX(_currentPageView.frame) + self.itemSpacing;
            [self setUpExtraViewWithStartX:x withIndex:(i - self.currentIndex - 1)];
        }
    }
}

- (void)setUpExtraViewWithStartX:(CGFloat)x withIndex:(NSInteger)index {
    UIView *extraView = [self postExtraViewDelegate];
    extraView.frame = CGRectMake(x + (self.extraItemSize.width + self.itemSpacing) * index, (self.bounds.size.height - self.extraItemSize.height) / 2, self.extraItemSize.width, self.extraItemSize.height);
    [self.views addObject:extraView];
    [self.backgroundImageView addSubview:extraView];
}

- (void)setUpCurrentView {
    CGFloat x = 0.f;
    CGFloat y = (self.bounds.size.height - self.currentItemSize.height) / 2;
    CGFloat width = self.currentItemSize.width;
    CGFloat height = self.currentItemSize.height;
    if (self.currentIndex == 0) {
        x = self.start_X;
    }
    
    if (self.currentIndex > 0) {
       x = CGRectGetMaxX(self.views[self.currentIndex - 1].frame) + self.itemSpacing;
    }
    _currentPageView.frame = CGRectMake(x, y, width, height);
    if (!_currentPageView.superview) [self.backgroundImageView addSubview:_currentPageView];
}

- (void)cleanView {
    for (UIView *view in self.views) {
        [view removeFromSuperview];
    }
    [self.views removeAllObjects];
}

- (void)postNumberDelegate {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfViewsInWKCPageControlView:)]) {
       _numberOfItems = [self.dataSource numberOfViewsInWKCPageControlView:self];
    }
}

- (void)postCurrentViewDelegate {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(WKCPageControlViewForCurrentItem:)]) {
        _currentPageView = [self.dataSource WKCPageControlViewForCurrentItem:self];
    }
}

- (UIView *)postExtraViewDelegate {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(WKCPageControlViewForExtraItem:)]) {
        return [self.dataSource WKCPageControlViewForExtraItem:self];
    }
    return nil;
}

#pragma mark -----<属性>------

- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        _backgroundImageView.backgroundColor = [UIColor clearColor];
        _backgroundImageView.clipsToBounds = YES;
    }
    return _backgroundImageView;
}

- (NSMutableArray<UIView *> *)views {
    if (!_views) {
        _views = [NSMutableArray array];
    }
    return _views;
}

- (CGFloat)start_X {
    switch (self.alignment) {
        case WKCPageControlViewPageAlignmentLeft:
        {
           return self.edgeSpaing;
        }
            break;
        case WKCPageControlViewPageAlignmentRight:
        {
            return self.bounds.size.width - self.edgeSpaing - self.currentItemSize.width - (_numberOfItems - 1) * (self.extraItemSize.width + self.itemSpacing);
        }
            break;
        case WKCPageControlViewPageAlignmentCenter:
        {
            return (self.bounds.size.width - (self.currentItemSize.width + (_numberOfItems - 1) * (self.extraItemSize.width + self.itemSpacing))) / 2;
        }
            break;
    }
}
@end
