//
//  EaseChatHelper.m
//  teamlock-user
//
//  Created by Kongho Poon on 16/8/17.
//  Copyright © 2016年 3NCTO. All rights reserved.
//

#import "EaseChatHelper.h"
#import "ConversationListViewController.h"


static EaseChatHelper *helper = nil;

@implementation EaseChatHelper

+ (instancetype)shareHelper {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[EaseChatHelper alloc] init];
    });
    return helper;
}

- (id)init {
    self = [super init];
    if (self) {
        [self initHelper];
    }
    return self;
}

- (void)initHelper {
    
    
    [[EMClient sharedClient] addDelegate:self delegateQueue:nil];
    [[EMClient sharedClient].groupManager addDelegate:self delegateQueue:nil];
    [[EMClient sharedClient].chatManager addDelegate:self delegateQueue:nil];
}

- (void)dealloc {
    [[EMClient sharedClient] removeDelegate:self];
    [[EMClient sharedClient].groupManager removeDelegate:self];
    [[EMClient sharedClient].chatManager removeDelegate:self];
}

#pragma mark - 登录环信

- (void)loginEaseMob {
    BOOL isAutoLogin = [EMClient sharedClient].options.isAutoLogin;
    if (!isAutoLogin) {
#ifdef DEBUG
        EMError *error = [[EMClient sharedClient] loginWithUsername:TEST_PHONE password:COMMON_EASEMOB_PASSWORD];
#else
        EMError *error = [[EMClient sharedClient] loginWithUsername:TEST_PHONE password:COMMON_EASEMOB_PASSWORD];
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

- (void)asyncPushOptions {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        EMError *error = nil;
        [[EMClient sharedClient] getPushOptionsFromServerWithError:&error];
    });
}

- (void)asyncGroupFromServer {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[EMClient sharedClient].groupManager loadAllMyGroupsFromDB];
        EMError *error = nil;
        [[EMClient sharedClient].groupManager getMyGroupsFromServerWithError:&error];
        if (!error) {
            
        }
    });
}

- (void)asyncConversationFromDB {
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *array = [[EMClient sharedClient].chatManager loadAllConversationsFromDB];
        [array enumerateObjectsUsingBlock:^(EMConversation *conversation, NSUInteger idx, BOOL *stop){
            if(conversation.latestMessage == nil){
                [[EMClient sharedClient].chatManager deleteConversation:conversation.conversationId deleteMessages:NO];
            }
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
        
            //TODO:刷新未读消息

        });
    });
}

#pragma mark - EMClientDelegate

// 网络状态变化回调
- (void)didConnectionStateChanged:(EMConnectionState)connectionState {
    
}

- (void)didAutoLoginWithError:(EMError *)error
{
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"自动登录失败，请重新登录" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        alertView.tag = 100;
        [alertView show];
    } else if([[EMClient sharedClient] isConnected]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BOOL flag = [[EMClient sharedClient] dataMigrationTo3];
            if (flag) {
                [self asyncGroupFromServer];
                [self asyncConversationFromDB];
            }
        });
    }
}

- (void)didLoginFromOtherDevice
{
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"prompt", @"Prompt") message:NSLocalizedString(@"loginAtOtherDevice", @"your login account has been in other places") delegate:self cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
    [alertView show];
    [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_LOGINCHANGE object:@NO];
}

- (void)didRemovedFromServer
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"prompt", @"Prompt") message:NSLocalizedString(@"loginUserRemoveFromServer", @"your account has been removed from the server side") delegate:self cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
    [alertView show];
    [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_LOGINCHANGE object:@NO];
    
}


#pragma mark - EMChatManagerDelegate

- (void)didUpdateConversationList:(NSArray *)aConversationList
{
    //TODO:更新会话列表
}
- (void)didReceiveCmdMessages:(NSArray *)aCmdMessages{
    //TODO:收到CMD消息处理
}
- (void)didReceiveMessages:(NSArray *)aMessages
{
    //TODO:收到消息处理
}


#pragma mark - private
- (BOOL)_needShowNotification:(NSString *)fromChatter
{
    BOOL ret = YES;
    NSArray *igGroupIds = [[EMClient sharedClient].groupManager getAllIgnoredGroupIds];
    for (NSString *str in igGroupIds) {
        if ([str isEqualToString:fromChatter]) {
            ret = NO;
            break;
        }
    }
    return ret;
}


- (void)_handleReceivedAtMessage:(EMMessage *)aMessage
{
    if (aMessage.chatType != EMChatTypeGroupChat || aMessage.direction != EMMessageDirectionReceive) {
        return;
    }
    
    NSString *loginUser = [EMClient sharedClient].currentUsername;
    NSDictionary *ext = aMessage.ext;
    EMConversation *conversation = [[EMClient sharedClient].chatManager getConversation:aMessage.conversationId type:EMConversationTypeGroupChat createIfNotExist:NO];
    if (loginUser && conversation && ext && [ext objectForKey:kGroupMessageAtList]) {
        id target = [ext objectForKey:kGroupMessageAtList];
        if ([target isKindOfClass:[NSString class]] && [(NSString*)target compare:kGroupMessageAtAll options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            NSNumber *atAll = conversation.ext[kHaveUnreadAtMessage];
            if ([atAll intValue] != kAtAllMessage) {
                NSMutableDictionary *conversationExt = conversation.ext ? [conversation.ext mutableCopy] : [NSMutableDictionary dictionary];
                [conversationExt removeObjectForKey:kHaveUnreadAtMessage];
                [conversationExt setObject:@kAtAllMessage forKey:kHaveUnreadAtMessage];
                conversation.ext = conversationExt;
            }
        } else if ([target isKindOfClass:[NSArray class]]) {
            if ([target containsObject:loginUser]) {
                if (conversation.ext[kHaveUnreadAtMessage] == nil) {
                    NSMutableDictionary *conversationExt = conversation.ext ? [conversation.ext mutableCopy] : [NSMutableDictionary dictionary];
                    [conversationExt setObject:@kAtYouMessage forKey:kHaveUnreadAtMessage];
                    conversation.ext = conversationExt;
                }
            }
        }
    }
}
- (void)didUpdateGroupList:(NSArray *)aGroupList{
    //群列表发生变话
}
/*!
 @method
 @brief 接收到离开群组，群组被销毁或者被从群中移除
 */
- (void)didReceiveLeavedGroup:(EMGroup *)aGroup
                       reason:(EMGroupLeaveReason)aReason{
    
    
}
@end
