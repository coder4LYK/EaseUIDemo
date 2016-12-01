//
//  ConversationListViewController.h
//  teamlock-user
//
//  Created by Kongho Poon on 16/8/17.
//  Copyright © 2016年 3NCTO. All rights reserved.
//

#import <EaseUI/EaseUI.h>

@interface ConversationListViewController : EaseConversationListViewController

@property (strong, nonatomic) NSMutableArray *conversationsArray;

/** key=conversionID vale=model */
@property (nonatomic, strong) NSMutableDictionary *chatDic;
@property (nonatomic, strong) NSMutableDictionary *defaultUserModel;

@property (nonatomic, copy) NSString *willPushID;

- (void)refreshDataSource;

- (void)isConnect:(BOOL)isConnect;
- (void)networkChanged:(EMConnectionState)connectionState;

- (void)pushChatVCWithID:(NSString *)ID;
@end
