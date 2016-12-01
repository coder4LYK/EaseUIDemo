//
//  EaseChatHelper.h
//  teamlock-user
//
//  Created by Kongho Poon on 16/8/17.
//  Copyright © 2016年 3NCTO. All rights reserved.
//

#import <Foundation/Foundation.h>



#define kGroupMessageAtList     @"em_at_message"
#define kGroupMessageAtAll      @"all"

#define kHaveUnreadAtMessage    @"kHaveAtMessage"
#define kAtYouMessage           1
#define kAtAllMessage           2

@interface EaseChatHelper : NSObject <
    EMClientDelegate,
    EMChatManagerDelegate,
    EMContactManagerDelegate,
    EMGroupManagerDelegate
>


+ (instancetype)shareHelper;

- (void)asyncPushOptions;

- (void)asyncGroupFromServer;

- (void)asyncConversationFromDB;

- (void)loginEaseMob;

@end
