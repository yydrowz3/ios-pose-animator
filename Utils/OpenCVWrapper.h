////
////  OpenCVWrapper.h
////  PoseEstimationTest
////
////  Created by 殷卓尔 on 2023/2/21.
////
//
//#import <Foundation/Foundation.h>
//#import <UIKit/UIKit.h>
//
//NS_ASSUME_NONNULL_BEGIN
//
//@interface OpenCVWrapper : NSObject
//
//- (void) matrixMin: (double *) data
//         data_size: (int) data_size
//         data_rows: (int) data_rows
//         heat_rows: (int) heat_rows
//;
//
//- (void) maximum_filter: (double *) data
//             data_size: (int) data_size
//             data_rows: (int) data_rows
//             mask_size: (int) mask_size
//             threshold: (double) threshold
//;
//
//- (UIImage *) renderKeyPoint: (CGRect) bounds
//                   keypoints: (int *) keypoints
//              keypoints_size: (int) keypoints_size
//                         pos: (CGPoint *) pos
//;
//
//
//@end
//
//NS_ASSUME_NONNULL_END
//
//




#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



@interface OpenCVWrapper : NSObject


-(void) matrixMin: (double *) data
        data_size:(int)data_size
        data_rows:(int)data_rows
        heat_rows:(int)heat_rows
;

-(void) maximum_filter: (double *) data
             data_size:(int)data_size
             data_rows:(int)data_rows
             mask_size:(int)mask_size
             threshold:(double)threshold
;


-(UIImage*) renderKeypoint:(int*) keypoints
             keypoint_size:(int) keypoints_size
                       pos:(CGPoint*) pos
                  rawImage:(UIImage*) rawImage
;


-(UIImage*) renderMaskKeypoint:(int*) keypoints
            keypoint_size:(int) keypoints_size
            pos:(CGPoint*) pos
            rawImageWidth:(int) rawImageWidth
            rawImageHeight:(int) rawImageHeight
;


-(UIImage*) renderKeypointAction:(int*) keypoints
                   keypoint_size:(int) keypoints_size
                             pos:(CGPoint*) pos
                        rawImage:(UIImage*) rawImage
                       rectarray:(int*) rectarray
                         actions:(int*) actions
                        humanNum:(int) humanNum
;


+(UIImage *) imageResizeWithOpencv: (UIImage *) rawImage
                          new_size: (CGSize) new_size;



@end

