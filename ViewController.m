//
//  ViewController.m
//  Client
//
//  Created by qq on 2017/3/15.
//  Copyright © 2017年 qq. All rights reserved.
//
//  实现功能：
//  1. ASTableNode+MJRefresh(上拉加载、下拉刷新)
//  2. 无数据时显示”已经全部加载完毕“

#import "ViewController.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "MJRefresh.h"


@interface ViewController ()<ASTableDelegate,ASTableDataSource>{
    NSInteger currentPage;
    NSInteger pageSize;
    NSInteger maxRows;
}
@property(strong,nonatomic)ASTableNode* tableNode;
@property(strong,nonatomic)NSMutableArray* models;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 1
    _tableNode = [[ASTableNode alloc]initWithStyle:UITableViewStylePlain];
    // 2
    self.tableNode.dataSource = self;
    self.tableNode.delegate = self;
    // 3
    self.tableNode.view.separatorStyle = UITableViewCellSeparatorStyleNone;
    // 4
    self.tableNode.view.leadingScreensForBatching = 1.0;
    // 5
    [self.view addSubnode:self.tableNode];
    
    _models= [NSMutableArray new];
    currentPage = 0;
    pageSize = 10;
    maxRows = 82;
    [self addMJ];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.tableNode.frame = self.view.bounds;
}


-(void)dealloc{
    self.tableNode.delegate = nil;
    self.tableNode.dataSource = nil;
}

// MARK: - ASTableDelegate & ASTableDataSource
- (NSInteger)tableNode:(ASTableNode *)tableNode numberOfRowsInSection:(NSInteger)section {
    // 1
    return self.models.count;
}

- (ASCellNodeBlock)tableNode:(ASTableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 2
    NSString* model = _models[indexPath.row];
    
    // 3
    ASCellNode *(^ASCellNodeBlock)() = ^ASCellNode *() {
        ASTextCellNode *cellNode = [[ASTextCellNode alloc] init];
        cellNode.text = model;
        return cellNode;
    };
    
    return ASCellNodeBlock;
}
- (NSInteger)numberOfSectionsInTableNode:(ASTableNode *)tableNode{
    // 4
    return 1;
}
- (BOOL)shouldBatchFetchForTableNode:(ASTableNode *)tableNode {
    return [self hasMoreData];
}
//2
- (void)tableNode:(ASTableNode *)tableNode willBeginBatchFetchWithContext:(ASBatchContext *)context
{
    [context beginBatchFetching];
    [self loadPageWithContext:context];
}
// 3
- (void)tableNode:(ASTableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableNode deselectRowAtIndexPath:indexPath animated:YES];
    
    // 你自己的代码
    
}
// 1
- (void)loadPageWithContext:(ASBatchContext *)context
{
    if([self hasMoreData]){
        NSArray *array= [self loadNextBatchData];
        [_models addObjectsFromArray:array];
        currentPage ++;
        [self insertNewRowsInTableNode:array];
        [context completeBatchFetching:YES];
    }
}
-(NSArray*)loadNextBatchData{

    NSMutableArray* array=[NSMutableArray new];
    
    for(NSInteger i = _models.count ;i< maxRows && i< _models.count+pageSize;i++){
        NSString *str = [NSString stringWithFormat:@"第%ld行",i];
        [array addObject:str];
        NSLog(@"%@",str);
        
    }
    return array;
}
// 7
- (void)insertNewRowsInTableNode:(NSArray*)array
{
    NSInteger section = 0;
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSUInteger row = _models.count-array.count; row < _models.count; row++) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:section];
        [indexPaths addObject:path];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [_tableNode insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    });
    
}

// MARK: - 上拉加载/下拉刷新

-(void) addMJ{
    
    __weak __typeof(self) weakSelf= self;
    self.tableNode.view.mj_header=[MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [_tableNode.view.mj_header endRefreshing];
        if(![self hasMoreData]){// 无数据显示
            self.tableNode.view.mj_footer.state = MJRefreshStateNoMoreData;
        }else{
            currentPage = 0;
            
            [_models removeAllObjects];
//            [_models addObjectsFromArray:[self loadNextBatchData]];//这句不需要 ASDK 会自己加载第一页
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableNode reloadData];
            });
        }
    }];
    
   self.tableNode.view.mj_footer=[MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
       
       if(![self hasMoreData]){// 无数据显示
           self.tableNode.view.mj_footer.state = MJRefreshStateNoMoreData;
           NSLog(@"no more data");
       }else{
           [self.tableNode.view.mj_footer endRefreshing];
       }
       
    }];
}
-(BOOL)hasMoreData{
    NSArray* nextPage = [self loadNextBatchData];
    return nextPage.count > 0 ;
}
@end
