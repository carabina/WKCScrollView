//
//  WKCPageControlView.h
//  WKCDevelop
//
//  Created by 魏昆超 on 2018/5/5.
//  Copyright © 2018年 WeiKunChao. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,WKCPageControlViewPageAlignment) {
    WKCPageControlViewPageAlignmentCenter, //居中
    WKCPageControlViewPageAlignmentLeft, //左
    WKCPageControlViewPageAlignmentRight //靠右
};

@protocol WKCPageControlViewDataSource;

@interface WKCPageControlView : UIView
/**布局流*/
@property (nonatomic, weak) id<WKCPageControlViewDataSource> dataSource;
/**对齐方式, 默认居中*/
@property (nonatomic, assign) WKCPageControlViewPageAlignment alignment;
/**背景图*/
@property (nonatomic, strong) UIImage * backgroundImage;
/**总个数*/
@property (nonatomic, assign) NSInteger numberOfItem;
/**正显示的宽度, 默认0*/
@property (nonatomic, assign) CGSize currentItemSize;
/**其余宽度, 默认0*/
@property (nonatomic, assign) CGSize extraItemSize;
/**item间距, 默认8*/
@property (nonatomic, assign) CGFloat itemSpacing;
/**边距, 默认15*/
@property (nonatomic, assign) CGFloat edgeSpaing;
/**当前下标*/
@property (nonatomic, assign) NSInteger currentIndex;

/**刷新*/
- (void)reloadData;
@end

@protocol WKCPageControlViewDataSource<NSObject>
/**视图个数*/
- (NSInteger)numberOfViewsInWKCPageControlView:(WKCPageControlView *)pageControlView;
/**当前视图*/
- (__kindof UIView *)WKCPageControlViewForCurrentItem:(WKCPageControlView *)pageControlView;
/**其余视图*/
- (__kindof UIView *)WKCPageControlViewForExtraItem:(WKCPageControlView *)pageControlView;
@end
