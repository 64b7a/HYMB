//
//  DouBanViewController.m
//  HYMB
//
//  Created by 863Soft on 2019/4/16.
//  Copyright © 2019 hymb. All rights reserved.
//

#import "DouBanViewController.h"
#import "RefreshModel.h"
#import "RefreshCell.h"
#import "DouBanGifHeader.h"
#import "DouBanGifFooter.h"

@interface DouBanViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) NSInteger pageNumber;//页码
@property (nonatomic, strong) NSMutableArray *dataArr;//数据
@property (nonatomic, strong) NoDataBackgroundView *noDataView;
@property (nonatomic, strong) UILabel *headerL;

@end

@implementation DouBanViewController

#pragma mark - 生命周期
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUI];
    
    [self initToast];
    
    self.dataArr = [NSMutableArray array];
    
    [self setRefreshHeaderAndFooter];
    [self.tableView.mj_header beginRefreshing];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
}

- (void)setRefreshHeaderAndFooter {
    
    // 设置回调（一旦进入刷新状态，就调用target的action，也就是调用self的loadNewData方法）
    self.tableView.mj_header = [DouBanGifHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewData)];
    // 设置回调（一旦进入刷新状态，就调用target的action，也就是调用self的loadMoreData方法）
    self.tableView.mj_footer = [DouBanGifFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
    
}


- (void)loadNewData {
    
    
    
    self.pageNumber = 1;
    // 请求地址
    NSString *url = api_v1_channels_111_items;
    // 请求参数
    NSDictionary *parameters = @{
                                 @"limit":@"10",
                                 @"offset":[NSString stringWithFormat:@"%ld", self.pageNumber],
                                 };
    
    [[NetworkService sharedNetworkService] getRequestWithTarget:self url:url parameters:parameters showHud:NO block:^(id responseObject, NSError *error) {
        
        [self.tableView.mj_header endRefreshing];
        [self.tableView.mj_footer resetNoMoreData];
        int code = [responseObject[@"code"] intValue];
        if (code == 200) {
            [self.dataArr removeAllObjects];
            if ([responseObject[@"data"][@"items"] count] > 0) {
                self.noDataView.hidden = YES;
                for (NSDictionary *dict in responseObject[@"data"][@"items"]) {
                    RefreshModel *model = [RefreshModel mj_objectWithKeyValues:dict];
                    [self.dataArr addObject:model];
                    self.pageNumber = self.pageNumber + 1;
                }
                
                
                [self showToastWithMes:@"已为您更新一组内容"];
                
                
            } else {
                self.noDataView.hidden = NO;
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
            }
            [self.tableView reloadData];
        }
    }];
}

- (void)loadMoreData {
    
    // 请求地址
    NSString *url = api_v1_channels_111_items;
    // 请求参数
    NSDictionary *parameters = @{
                                 @"limit":@"10",
                                 @"offset":[NSString stringWithFormat:@"%ld", self.pageNumber],
                                 };
    
    [[NetworkService sharedNetworkService] getRequestWithTarget:self url:url parameters:parameters showHud:NO block:^(id responseObject, NSError *error) {
        [self.tableView.mj_footer endRefreshing];
        int code = [responseObject[@"code"] intValue];
        if (code == 200) {
            if ([responseObject[@"data"][@"items"] count]> 0) {
                for (NSDictionary *dict in responseObject[@"data"][@"items"]) {
                    RefreshModel *model = [RefreshModel mj_objectWithKeyValues:dict];
                    [self.dataArr addObject:model];
                    self.pageNumber = self.pageNumber + 1;
                }
                [self.tableView reloadData];
            }else {
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
            }
        }
    }];
    
}



#pragma mark - 构建视图
- (void)setUI {
    
    self.title = @"仿豆瓣";
    self.view.backgroundColor = [UIColor whiteColor];
    
    //添加tableView
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kScreen_Width, kScreen_Height-NaviH) style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = DefaultColor;
    [self.view addSubview:self.tableView];
    
    self.noDataView = [[NoDataBackgroundView alloc]initWithFrame:CGRectMake(0, 0, kScreen_Width, kScreen_Height-NaviH)];
    self.noDataView.tipsText = @"暂无数据";
    self.noDataView.hidden = YES;
    [self.tableView addSubview:self.noDataView];
    
}

#pragma mark - tableView代理方法
/**
 * tableView的分区数
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return self.dataArr.count;
}


/**
 * tableView分区里的行数
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 1;
}

/**
 * tableViewCell的相关属性
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.tableView registerNib:[UINib nibWithNibName:@"RefreshCell" bundle:nil] forCellReuseIdentifier:@"cellId"];
    RefreshCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellId" forIndexPath:indexPath];
    
    //修改cell属性，使其在选中时无色
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    RefreshModel *model = self.dataArr[indexPath.section];
    cell.titleL.text = model.title;
    NSURL *url = [NSURL URLWithString:model.cover_image_url];
    [cell.imageV sd_setImageWithURL:url];
    
    return cell;
}

/**
 * tableViewCell的高度
 */
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 160;
}

/**
 * 分区头的高度
 */
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

/**
 * 分区脚的高度
 */
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 10;
}

/**
 * 分区头
 */
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    return view;
}

/**
 * 分区脚
 */
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = DefaultColor;
    return view;
}


/**
 * tableViewCell的点击事件
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MYLog(@"%@", indexPath);
}

#pragma mark 提示框（仿豆瓣）初始化
- (void)initToast {
    //提示框
    self.headerL = [[UILabel alloc] init];
    self.headerL.backgroundColor = ColorWithRGB(9, 173, 0);
    self.headerL.textAlignment = NSTextAlignmentCenter;
    self.headerL.layer.cornerRadius = 20;
    self.headerL.layer.masksToBounds = YES;
    self.headerL.textColor = [UIColor whiteColor];
    [kKeyWindow addSubview:self.headerL];
}

#pragma mark 提示框（仿豆瓣）展示
- (void)showToastWithMes:(NSString *)mes {
    
    self.headerL.text = mes;
    
    //headerL展示用
    self.headerL.alpha = 0.0;
    self.headerL.frame = CGRectMake(50, 20, kSCREEN_WIDTH-100, 40);
    //出现
    [UIView animateWithDuration:0.3 animations:^{
        //headerL展示用
        self.headerL.alpha = 1;
        self.headerL.frame = CGRectMake(50, NaviH, kSCREEN_WIDTH-100, 40);
    }];
    //消失
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [UIView animateWithDuration:0.3 animations:^{
            //headerL展示用
            self.headerL.alpha = 0.0;
            self.headerL.frame = CGRectMake(50, 20, kSCREEN_WIDTH-100, 40);
        }];
        
    });
}

@end





