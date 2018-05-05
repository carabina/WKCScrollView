//
//  WKCScrollView.h
//  WKCDevelop
//
//  Created by 魏昆超 on 2018/4/30.
//  Copyright © 2018年 WeiKunChao. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,scrollDirection) {
    /**水平方向铺展*/
    scrollDirectionHorizontal = 0,
     /**竖直方向铺展*/
    scrollDirectionVertical //竖直方向
};

typedef NS_ENUM(NSInteger,WKCScrollViewAutoScrollDirection) {
    /**图片向左滑*/
    WKCScrollViewAutoScrollDirectionLeft,
    /**图片向右滑*/
    WKCScrollViewAutoScrollDirectionRight,
    /**图片向上滑*/
    WKCScrollViewAutoScrollDirectionUp,
    /**图片向下滑*/
    WKCScrollViewAutoScrollDirectionDown
};
@protocol WKCScrollViewDelegate, WKCScrollViewDataSource;

@interface WKCScrollView : UIView
/**代理流*/
@property (nonatomic, weak) id<WKCScrollViewDelegate> delegate;
/**布局流*/
@property (nonatomic, weak) id<WKCScrollViewDataSource> dataSource;
/**是否在拖拽*/
@property (nonatomic, assign, readonly) BOOL isDragging;
/**是否快减速*/
@property (nonatomic, assign, readonly) BOOL isDecelerating;
/**当前最末端坐标*/
@property (nonatomic, assign, readonly) NSInteger currentIndex;
/**范围内的可视视图*/
@property (nonatomic, strong, readonly) NSArray <UIView *>* visibleViews;
/**返回顶部*/
@property (nonatomic, assign) BOOL scrollToTop;
/**是否居中显示,默认NO*/
@property (nonatomic, assign) BOOL isAlignmentCenter;
/**是否翻页,默认NO*/
@property (nonatomic, assign) BOOL pagingEnabled;
/**是否无限循环, 默认NO*/
@property (nonatomic, assign) BOOL loopEnabled;
/**滑动方向, 默认水平*/
@property (nonatomic, assign) scrollDirection direction;
/**是否自动轮播,默认NO;如果开启了自动轮播,loopEnabled一直为YES*/
@property (nonatomic, assign) BOOL isAutoScroll;
/**自动轮播时间间隔,默认两秒*/
@property (nonatomic, assign) NSTimeInterval autoScrollDuration;
/**自动滚动方向,横向默认向左;竖向默认向上*/
@property (nonatomic, assign) WKCScrollViewAutoScrollDirection  autoScrollDirection;

/**注册*/
- (void)registerClass:(Class)aClass forItemReuseIdentifier:(NSString *)identify;
/**取视图*/
- (__kindof UIView *)dequeueReusableItemWithIdentifier:(NSString *)identify;
/**刷新*/
- (void)reloadData;
@end

@protocol WKCScrollViewDataSource<NSObject>

@required;
/**视图个数*/
- (NSInteger)numberOfViewsInWKCScrollView:(WKCScrollView *)scrollview;
/**视图*/
- (__kindof UIView *)WKCScrollView:(WKCScrollView *)scrollview viewAtIndex:(NSInteger)index;
/**视图大小*/
- (CGSize)WKCScrollViewItemSize:(WKCScrollView *)scrollview;

@optional;
/**水平间距*/
- (CGFloat)interitemSpacingInWKCScrollView:(WKCScrollView *)scrollview;
/**竖直间距*/
- (CGFloat)lineSpacingInWKCScrollView:(WKCScrollView *)scrollview;
@end

@protocol WKCScrollViewDelegate<NSObject>
@optional;
/**滑动*/
- (void)WKCScrollViewDidScroll:(WKCScrollView *)scrollView contentOffset:(CGPoint)offset;
/**将要拖拽*/
- (void)WKCScrollViewWillBeginDragging:(WKCScrollView *)scrollView;
/**已经停止拖拽*/
- (void)WKCScrollViewDidEndDragging:(WKCScrollView *)scrollView willDecelerate:(BOOL)decelerate;
/**将要开始滑行*/
- (void)WKCScrollViewWillBeginDecelerating:(WKCScrollView *)scrollView;
/**已经结束滑行*/
- (void)WKCScrollViewDidEndDecelerating:(WKCScrollView *)scrollView;
/**滑回到顶部*/
- (void)WKCScrollViewDidScrollToTop:(WKCScrollView *)scrollView;
/**点击*/
- (void)WKCScrollView:(WKCScrollView *)scrollView didSelectItemAtIndex:(NSInteger)index;
@end
