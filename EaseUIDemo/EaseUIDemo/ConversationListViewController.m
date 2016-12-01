//
//  ConversationListViewController.m
//  teamlock-user
//
//  Created by Kongho Poon on 16/8/17.
//  Copyright © 2016年 3NCTO. All rights reserved.
//

#import "ConversationListViewController.h"
#import "EaseChatHelper.h"
#import <EMConversation.h>
#import "ChatViewController.h"
#import <EMSDK.h>

#define FuncViewHeight 45
@interface ConversationListViewController ()<EaseConversationListViewControllerDelegate, EaseConversationListViewControllerDataSource>

@property (nonatomic, strong) UIView *networkStateView;

@property (nonatomic, strong) UILabel *timeLabel;

@property (nonatomic, strong) UILabel  *unreadCountLabel;

@property (nonatomic, weak) UITableView *funcTableView;

/** 后台返回列表 */
@property (nonatomic, strong) NSArray *chatList;

@end

@implementation ConversationListViewController


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    self.title = @"会话列表";
    
    self.showRefreshHeader = YES;
    self.delegate = self;
    self.dataSource = self;
    
    [self tableViewDidTriggerHeaderRefresh];
    
    [self networkStateView];
    
    [self removeEmptyConversationsFromDB];
    
    //iOS8、9需要添加此行代码设置分割线样式。
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
        
    }
    
    [self setupRightNavBtn];
}

- (void)setupRightNavBtn{
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 20)];
    btn.titleLabel.font = [UIFont systemFontOfSize:14];
    [btn setTitle:@"好友列表" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(rightBtnClick) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
}
- (void)rightBtnClick{
    EaseUsersListViewController *userList = [[EaseUsersListViewController alloc] init];
    userList.title = @"好友列表";
    [self.navigationController pushViewController:userList animated:YES];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - viewWillAppear
- (void)viewWillAppear:(BOOL)animated
{
    [self loginEaseMob];
    [super viewWillAppear:animated];
}

#pragma mark - viewWillLayoutSubviews
- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)removeEmptyConversationsFromDB {
    NSArray *conversations = [[EMClient sharedClient].chatManager getAllConversations];
    NSMutableArray *needRemoveConversations;
    for (EMConversation *conversation in conversations) {
        if (!conversation.latestMessage || (conversation.type == EMConversationTypeChatRoom)) {
            if (!needRemoveConversations) {
                needRemoveConversations = [[NSMutableArray alloc] initWithCapacity:0];
            }
            
            [needRemoveConversations addObject:conversation];
        }
    }
    
    if (needRemoveConversations && needRemoveConversations.count > 0) {
        [[EMClient sharedClient].chatManager deleteConversations:needRemoveConversations deleteMessages:YES];
    }
}


#pragma mark - 登录环信

- (void)loginEaseMob {
    BOOL isAutoLogin = [EMClient sharedClient].options.isAutoLogin;
    if (!isAutoLogin) {
#ifdef DEBUG
        EMError *error = [[EMClient sharedClient] loginWithUsername:@"用户名" password:COMMON_EASEMOB_PASSWORD];
#else
        EMError *error = [[EMClient sharedClient] loginWithUsername:[AccountModel currentAccount].chat_account password:COMMON_EASEMOB_PASSWORD];
#endif
        if (!error) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                EMPushOptions *options = [[EMClient sharedClient] pushOptions];
                options.displayStyle = EMPushDisplayStyleMessageSummary;
                [[EMClient sharedClient] updatePushOptionsToServer];
            });
            [[EMClient sharedClient].options setIsAutoLogin:YES];
        } else {
            
        }
    }else{
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            EMPushOptions *options = [[EMClient sharedClient] pushOptions];
            options.displayStyle = EMPushDisplayStyleMessageSummary;
            [[EMClient sharedClient] updatePushOptionsToServer];
        });
    }
}

#pragma mark - getter
- (UIView *)networkStateView
{
    if (_networkStateView == nil) {
        _networkStateView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 44)];
        _networkStateView.backgroundColor = [UIColor colorWithRed:255 / 255.0 green:199 / 255.0 blue:199 / 255.0 alpha:0.5];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, (_networkStateView.frame.size.height - 20) / 2, 20, 20)];
        imageView.image = [UIImage imageNamed:@"messageSendFail"];
        [_networkStateView addSubview:imageView];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(imageView.frame) + 5, 0, _networkStateView.frame.size.width - (CGRectGetMaxX(imageView.frame) + 15), _networkStateView.frame.size.height)];
        label.font = [UIFont systemFontOfSize:15.0];
        label.textColor = [UIColor grayColor];
        label.backgroundColor = [UIColor clearColor];
        label.text = NSLocalizedString(@"network.disconnection", @"Network disconnection");
        [_networkStateView addSubview:label];
    }
    
    return _networkStateView;
}



#pragma mark - EaseConversationListViewControllerDelegate

- (void)conversationListViewController:(EaseConversationListViewController *)conversationListViewController didSelectConversationModel:(id<IConversationModel>)conversationModel
{
    if (conversationModel) {
        EMConversation *conversation = conversationModel.conversation;
        if (conversation) {
            ChatViewController *chatController = [[ChatViewController alloc]                                                                                                     initWithConversationChatter:conversation.conversationId conversationType:conversation.type];
            chatController.title = conversationModel.title;
            [self.navigationController pushViewController:chatController animated:YES];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setupUnreadMessageCount" object:nil];
    }
}


#pragma mark - EaseConversationListViewControllerDataSource

- (id<IConversationModel>)conversationListViewController:(EaseConversationListViewController *)conversationListViewController modelForConversation:(EMConversation *)conversation
{
    EaseConversationModel *model = [[EaseConversationModel alloc] initWithConversation:conversation];
//    NSString *imageName = @"groupPublicHeader";
//    if (![conversation.ext objectForKey:@"subject"])
//    {
//        NSArray *groupArray = [[EMClient sharedClient].groupManager getAllGroups];
//        for (EMGroup *group in groupArray) {
//            if ([group.groupId isEqualToString:conversation.conversationId]) {
//                NSMutableDictionary *ext = [NSMutableDictionary dictionaryWithDictionary:conversation.ext];
//                [ext setObject:group.subject forKey:@"subject"];
//                [ext setObject:[NSNumber numberWithBool:group.isPublic] forKey:@"isPublic"];
//                conversation.ext = ext;
//                break;
//            }
//        }
//    }
//    NSDictionary *ext = conversation.ext;
//    model.title = [ext objectForKey:@"subject"];
//    imageName = [[ext objectForKey:@"isPublic"] boolValue] ? @"groupPublicHeader" : @"groupPrivateHeader";
//    model.avatarImage = [UIImage imageNamed:imageName];
    return model;
}



- (NSAttributedString *)conversationListViewController:(EaseConversationListViewController *)conversationListViewController latestMessageTitleForConversationModel:(id<IConversationModel>)conversationModel
{
    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:@""];
    EMMessage *lastMessage = [conversationModel.conversation latestMessage];
    if (lastMessage) {
        NSString *latestMessageTitle = @"";
        EMMessageBody *messageBody = lastMessage.body;
        switch (messageBody.type) {
            case EMMessageBodyTypeImage:{
                latestMessageTitle = NSLocalizedString(@"message.image1", @"[image]");
            } break;
            case EMMessageBodyTypeText:{
                // 表情映射。
                NSString *didReceiveText = [EaseConvertToCommonEmoticonsHelper
                                            convertToSystemEmoticons:((EMTextMessageBody *)messageBody).text];
                latestMessageTitle = didReceiveText;
                if ([lastMessage.ext objectForKey:MESSAGE_ATTR_IS_BIG_EXPRESSION]) {
                    latestMessageTitle = @"[动画表情]";
                }
            } break;
            case EMMessageBodyTypeVoice:{
                latestMessageTitle = NSLocalizedString(@"message.voice1", @"[voice]");
            } break;
            case EMMessageBodyTypeLocation: {
                latestMessageTitle = NSLocalizedString(@"message.location1", @"[location]");
            } break;
            case EMMessageBodyTypeVideo: {
                latestMessageTitle = NSLocalizedString(@"message.video1", @"[video]");
            } break;
            case EMMessageBodyTypeFile: {
                latestMessageTitle = NSLocalizedString(@"message.file1", @"[file]");
            } break;
            default: {
            } break;
        }
        
        NSDictionary *ext = conversationModel.conversation.ext;
        if (ext && [ext[kHaveUnreadAtMessage] intValue] == kAtAllMessage) {
            latestMessageTitle = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"group.atAll", nil), latestMessageTitle];
            attributedStr = [[NSMutableAttributedString alloc] initWithString:latestMessageTitle];
            [attributedStr setAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:1.0 green:.0 blue:.0 alpha:0.5]} range:NSMakeRange(0, NSLocalizedString(@"@all：", nil).length)];
            
        }
        else if (ext && [ext[kHaveUnreadAtMessage] intValue] == kAtYouMessage) {
            latestMessageTitle = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"group.atMe", @"[Somebody @ me]"), latestMessageTitle];
            attributedStr = [[NSMutableAttributedString alloc] initWithString:latestMessageTitle];
            [attributedStr setAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:1.0 green:.0 blue:.0 alpha:0.5]} range:NSMakeRange(0, NSLocalizedString(@"group.atMe", @"[Somebody @ me]").length)];
        }
        else {
            attributedStr = [[NSMutableAttributedString alloc] initWithString:latestMessageTitle];
        }
    }
    
    return attributedStr;
}

- (NSString *)conversationListViewController:(EaseConversationListViewController *)conversationListViewController
       latestMessageTimeForConversationModel:(id<IConversationModel>)conversationModel
{
    NSString *latestMessageTime = @"";
    EMMessage *lastMessage = [conversationModel.conversation latestMessage];;
    if (lastMessage) {
        latestMessageTime = [NSDate formattedTimeFromTimeInterval:lastMessage.timestamp];
    }
    
    
    return latestMessageTime;
}

#pragma mark - public


-(void)refreshDataSource
{
    [self tableViewDidTriggerHeaderRefresh];
}

- (void)isConnect:(BOOL)isConnect{
    if (!isConnect) {
        self.tableView.tableHeaderView = _networkStateView;
    }
    else{
        self.tableView.tableHeaderView = nil;
    }
    
}

- (void)networkChanged:(EMConnectionState)connectionState
{
    if (connectionState == EMConnectionDisconnected) {
        self.tableView.tableHeaderView = _networkStateView;
    }
    else{
        self.tableView.tableHeaderView = nil;
    }
}


#pragma mark -- tableView相关

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
}


- (void)tableViewDidTriggerHeaderRefresh{
    [super tableViewDidTriggerHeaderRefresh];
    

}

#pragma mark -- 推送跳转

- (void)pushChatVCWithID:(NSString *)ID{
   
    
}
@end
