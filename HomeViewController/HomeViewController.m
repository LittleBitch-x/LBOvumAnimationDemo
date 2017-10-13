//
//  HomeViewController.m
//  HomeViewController
//
//  Created by zhangyi on 15/9/14.
//  Copyright (c) 2015年 zhangyi. All rights reserved.
//

#import "HomeViewController.h"

#define r  self.blackView.frame.size.width/2

@interface HomeViewController ()


<UICollisionBehaviorDelegate>
{
    UICollisionBehavior *collisionBehavior;//碰撞

    UIDynamicItemBehavior *itemBehavior;//物理
}
@property (strong, nonatomic)  UIDynamicAnimator *animator;//仿真器

@property (strong, nonatomic) NSArray *dataCenters;//初始点
@property (strong, nonatomic) NSMutableDictionary *itemCenterDic;//动态变化点


@property (assign, nonatomic) BOOL isAnimation;//动画标记
@property (strong, nonatomic) UIView *item1;//移动的
@property (strong, nonatomic) UIView *item2;//被装的

@property (strong, nonatomic) IBOutlet UIView *blackView;
@property (strong, nonatomic) IBOutlet UIView *redView;
@property (strong, nonatomic) IBOutlet UIView *blueView;
@property (strong, nonatomic) IBOutlet UIView *greenView;


@end

@implementation HomeViewController
- (void)viewDidLoad {
    [super viewDidLoad];

    //圆－ － （可以循环 自己改）
    self.isAnimation = NO;//初始为no

    self.blackView.layer.cornerRadius = r;
    self.blackView.layer.masksToBounds = YES;
    self.blackView.clipsToBounds = YES;
    
    self.redView.layer.cornerRadius = r;
    self.redView.layer.masksToBounds = YES;
    self.redView.clipsToBounds = YES;
    
    self.greenView.layer.cornerRadius = r;
    self.greenView.layer.masksToBounds = YES;
    self.greenView.clipsToBounds = YES;
    
    self.blueView.layer.cornerRadius = r;
    self.blueView.layer.masksToBounds = YES;
    self.blueView.clipsToBounds = YES;
    
    //初始坐标
    self.dataCenters = @[NSStringFromCGPoint(self.blackView.center),NSStringFromCGPoint(self.redView.center),NSStringFromCGPoint(self.blueView.center),NSStringFromCGPoint(self.greenView.center)];
    
    //初始坐标字典
    self.itemCenterDic = [NSMutableDictionary dictionary];
    for (NSInteger i = 0; i < 4; i ++) {
        [self.itemCenterDic setObject:self.dataCenters[i] forKey:[NSString stringWithFormat:@"%ld",i]];
    }
    
    
    //初始碰撞
    collisionBehavior = [[UICollisionBehavior alloc]initWithItems:@[self.redView,self.blackView,self.greenView,self.blueView]];
    collisionBehavior.collisionDelegate = self;
    
    [self.animator addBehavior:collisionBehavior];
    
    //初始捕捉
    for (NSInteger i = 0; i < 4;i++ ) {
        UIView *view = [self.view viewWithTag:1000+i];
        NSString *key = [NSString stringWithFormat:@"%ld",view.tag - 1000];
        NSString *pointStr = self.itemCenterDic[key];
        UISnapBehavior *snapBehavior = [[UISnapBehavior alloc]initWithItem:view snapToPoint:CGPointFromString(pointStr)];
        snapBehavior.damping = 1;
        [self.animator addBehavior:snapBehavior];
        //初始手势
        UIPanGestureRecognizer *panGestur = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGestureRecognizer:)];
        [view addGestureRecognizer:panGestur];
    }
    
    //这个并没什么卵用  写着好看。。
    itemBehavior = [[UIDynamicItemBehavior alloc]initWithItems:@[self.redView,self.blackView]];
    itemBehavior.elasticity = 0;
    [self.animator addBehavior:itemBehavior];
    
}


//碰撞时
- (void)collisionBehavior:(UICollisionBehavior*)behavior beganContactForItem:(id <UIDynamicItem>)item1 withItem:(id <UIDynamicItem>)item2 atPoint:(CGPoint)p
{
    //碰撞时获取item2
    UIView *tempView1 = (UIView *)item1;
    UIView *tempView2 = (UIView *)item2;
    if (tempView1.tag == self.item1.tag) {
        self.item2 = tempView2;
    }
    if (tempView2.tag == self.item1.tag) {
        self.item2 = tempView1;
    }
}

//碰撞结束
- (void)collisionBehavior:(UICollisionBehavior*)behavior endedContactForItem:(id <UIDynamicItem>)item1 withItem:(id <UIDynamicItem>)item2
{
    [self animationWithGesture:nil];//解决出界问题
}

//初始仿真器，（重写getter，这样挺好）
- (UIDynamicAnimator *)animator
{
    if (!_animator) {
        _animator = [[UIDynamicAnimator alloc]initWithReferenceView:self.view];
    }
    return _animator;
}

//重点来了
- (void)panGestureRecognizer:(UIPanGestureRecognizer *)sender
{
    //获取item1
    self.item1 = sender.view;
    
    CGPoint start = [sender locationInView:self.view];
    
    //当手势改变
    if (sender.state == UIGestureRecognizerStateChanged) {
        
        if (!self.isAnimation) {//如果没有进行动画
            self.item1.center = start;//设置中心点看得懂吧
            [self.animator removeAllBehaviors];//先移除所有物理仿真（保险）
            [self.animator addBehavior:collisionBehavior];//添加碰撞
            [self.animator addBehavior:itemBehavior];//添加物理强度
            NSString *key2 = [NSString stringWithFormat:@"%ld",self.item2.tag - 1000];//用于取点（item2）
            //如果说距离大于直径
            if ([self distanceWithItem1:self.item1.center item2:self.item2.center] > self.item2.frame.size.width) {
                if (self.item2) {//如果item2存在
                    UISnapBehavior *snapBehavior = [[UISnapBehavior alloc]initWithItem:self.item2 snapToPoint:CGPointFromString(self.itemCenterDic[key2])];
                    snapBehavior.damping = 0.3;
                    [self.animator addBehavior:snapBehavior];
                }//其实就是让他返回原处
                
            }
            //如果item2移动了自己的半径这么远  就可以动画了（所以什么时候动画 可以在这里改）
            else if ([self distanceWithItem1:CGPointFromString(self.itemCenterDic[key2]) item2:self.item2.center] >= self.item2.frame.size.width/2){
                
                NSInteger index = self.item1.tag;//获取item1的tag（用来取坐标和判断怎么变）
                if ((index + 1)%4+1000 == self.item2.tag) {//如果是顺时针
                    
                    NSDictionary *tempDic = [NSDictionary dictionaryWithDictionary:self.itemCenterDic];
                    [self.itemCenterDic removeAllObjects];
                    //重新设置坐标。逻辑就是顺时针逆时针移动。。 根据tag来设key对应到每个视图
                    for (NSInteger i = 0; i < 4; i ++) {
                        NSInteger n = (index + i + 2)%4;
                        NSString *nkey = [NSString stringWithFormat:@"%ld",n];
                        NSInteger keyIndex = ((self.item2.tag-1000)+i) % 4 ;
                        
                        [self.itemCenterDic setObject:tempDic[nkey] forKey:[NSString stringWithFormat:@"%ld",keyIndex]];
                    }
                    [self animationWithGesture:sender];//添加捕捉 动画－ －
                    
                }
                else if ((index + 2)%4+1000 == self.item2.tag) {//如果对位
                    NSString *item1Center = self.itemCenterDic[[NSString stringWithFormat:@"%ld",self.item1.tag-1000]];
                    NSString *item2Center = self.itemCenterDic[[NSString stringWithFormat:@"%ld",self.item2.tag-1000]];
                    [self.itemCenterDic setObject:item1Center forKey:[NSString stringWithFormat:@"%ld",self.item2.tag-1000]];
                    [self.itemCenterDic setObject:item2Center forKey:[NSString stringWithFormat:@"%ld",self.item1.tag-1000]];
                    [self animationWithGesture:sender];
                }
                else if ((index - 1)%4+1000 == self.item2.tag){//如果逆时针
                    NSDictionary *tempDic = [NSDictionary dictionaryWithDictionary:self.itemCenterDic];
                    [self.itemCenterDic removeAllObjects];
                    for (NSInteger i = 4; i > 0; i --) {
                        NSInteger n = (index + i - 2)%4;
                        NSString *nkey = [NSString stringWithFormat:@"%ld",n];
                        NSInteger keyIndex = ((self.item2.tag-1000)+i) % 4 ;
                        
                        [self.itemCenterDic setObject:tempDic[nkey] forKey:[NSString stringWithFormat:@"%ld",keyIndex]];
                    }
                    [self animationWithGesture:sender];
                }
            }
            
            
        }
        
    }
    
    
    
    //结束
    else if (sender.state == UIGestureRecognizerStateEnded){
        
        if (!self.isAnimation) {//如果没有动画  归位
            for (NSInteger i = 0; i < 4;i++ ) {
                UIView *view = [self.view viewWithTag:1000+i];
                NSString *key = [NSString stringWithFormat:@"%ld",view.tag - 1000];
                NSString *pointStr = self.itemCenterDic[key];
                UISnapBehavior *snapBehavior = [[UISnapBehavior alloc]initWithItem:view snapToPoint:CGPointFromString(pointStr)];
                snapBehavior.damping = 1;
                [self.animator addBehavior:snapBehavior];
            }
        }else{//否则重置为no
            self.isAnimation = NO;
        }
        //清零
        self.item1 = nil;
        self.item2 = nil;
        [self.animator removeBehavior:collisionBehavior];
        
    }
    
}



//两点距离
- (CGFloat)distanceWithItem1:(CGPoint)item1 item2:(CGPoint)item2
{
    CGFloat xDist = (item1.x - item2.x);
    
    CGFloat yDist = (item1.y - item2.y);
    
    CGFloat distance = sqrt((xDist * xDist) + (yDist * yDist));
    
    return distance;
}


//添加捕捉，进行动画
- (void)animationWithGesture:(UIPanGestureRecognizer *)sender
{
    self.isAnimation = YES;
    sender.delaysTouchesEnded = YES;
    for (NSInteger i = 0; i < 4;i++ ) {
        UIView *view = [self.view viewWithTag:1000+i];
        NSString *key = [NSString stringWithFormat:@"%ld",view.tag - 1000];
        UISnapBehavior *snapBehavior = [[UISnapBehavior alloc]initWithItem:view snapToPoint:CGPointFromString(self.itemCenterDic[key])];
        [self.animator addBehavior:snapBehavior];
    }
}

//点击事件
- (IBAction)buttonPressed:(UIButton *)sender {
    NSLog(@"%@",sender.titleLabel.text);
}


//如果要捏合手势  自己直接加就可以了 。看了你们的首页，是个单独的controller所以就不另外封装了 xib直接拖进去就可以了。
//如果实在想要封装，新建view 复制代码就行了,这么点操作。。 就不要再叫我了吧，求理解 ，叫我我又要拖到下班才帮你们弄了。没必要啊。
//如果要动态变大变小，提供一个思路，计算插值。。（不知道插值百度去）   然后根据坐标来就可以了,snapBehaivor好像有个action监听。如果没有，就自己给视图加监听  也是可以的。  就这样。。你们加油。。。


@end
