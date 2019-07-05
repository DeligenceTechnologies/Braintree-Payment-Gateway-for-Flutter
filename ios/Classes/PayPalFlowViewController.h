//
//  PayPalFlowViewController.h
//  Pods
//
//  Created by Michael Polt on 04.07.19.
//

#import <Foundation/Foundation.h>

@protocol PayPalFlowDelegate <NSObject>
@required
- (void)resultDataFromPayPalFlow:(NSMutableDictionary *)data;
@end


@interface PayPalFlowViewController : UIViewController
@property (nonatomic, retain) NSString *clientToken;
@property (nonatomic, retain) NSString *amount;
@property (nonatomic, retain) NSString *currency;
@property (nonatomic, weak) id<PayPalFlowDelegate> delegate;

@end
