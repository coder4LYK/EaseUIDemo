//
//  Config.h
//  teamlock-user
//
//  Created by Kongho Poon on 16/7/2.
//  Copyright © 2016年 3NCTO. All rights reserved.
//

#ifndef Config_h
#define Config_h

#define CONFIG_PLIST [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]
#define CONFIG_DICTIONARY [[NSDictionary alloc] initWithContentsOfFile:CONFIG_PLIST]

/**
 *    服务器环境设置
 *      1）开发环境：Develop
 *      2）测试环境：Testing
 *      3）正式环境：Product
 */
#ifdef DEBUG
#define SERVER_ENVIRONMENT @"Develop"
#else

#warning 记得修改环境

#define SERVER_ENVIRONMENT @"Product"
#endif

// 触发token自动更新的剩余有效时长，默认2小时，设置成1小时
#define kTokenValidTime 3600

#define COMMON_EASEMOB_PASSWORD @"12345678"


// 解压后文件路径
#define UN_ZIP_FILE_FULL_PATH(fileName) [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingString:[NSString stringWithFormat:@"/%@", fileName]]

// 测试开发使用
#ifdef DEBUG

// 是否开启免输入帐号登录
#define FAST_LOGIN 1


//#define TEST_PHONE @"18620096154"

#define TEST_PHONE @"13428281880"

#define TEST_PASSWORD @"111111"

#endif


/** keyChain */
#define  KEY_USERNAME_PASSWORD @"cn.teamlock.user"
#define  KEY_USERNAME @"cn.teamlock.user"
#define  KEY_PASSWORD @"cn.teamlock.user"

#endif /* Config_h */
