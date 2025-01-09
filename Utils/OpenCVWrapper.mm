//
//  OpenCVWrapper.m
//  PoseEstimationTest
//
//  Created by 殷卓尔 on 2023/2/21.
//



#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>

#import "OpenCVWrapper.h"

#include <vector>


#define COCO_COLORS \
255.f,    0.f,    0.f, \
255.f,   85.f,    0.f, \
255.f,  170.f,    0.f, \
255.f,  255.f,    0.f, \
170.f,  255.f,    0.f, \
85.f,   255.f,    0.f, \
0.f,    255.f,    0.f, \
0.f,    255.f,   85.f, \
0.f,    255.f,  170.f, \
0.f,    255.f,  255.f, \
0.f,    170.f,  255.f, \
0.f,    85.f,   255.f, \
0.f,     0.f,   255.f, \
85.f,    0.f,   255.f, \
170.f,   0.f,   255.f, \
255.f,   0.f,   255.f, \
255.f,   0.f,   170.f, \
255.f,   0.f,    85.f



@implementation OpenCVWrapper


- (void) matrixMin:(double *)data data_size:(int)data_size data_rows:(int)data_rows heat_rows:(int)heat_rows {
    // 处理19张pcm
    std::vector<double> vec = std::vector<double>(data, data + data_size);
    cv::Mat m1(vec), m2;
    m1 = m1.reshape(0, data_rows); // m1 为19行 每行是46*46的数据
    // m2为 19行1列 每行为一个最小值
    cv::reduce(m1, m2, 1, cv::REDUCE_MIN);
    for(int i = 0; i < m1.rows; i++)
        m1.row(i) -= m2.row(i);

    // m1 为 874 * 46 m2 为 874 * 1
    m1 = m1.reshape(0,data_rows*heat_rows);
    cv::reduce(m1, m2, 1, cv::REDUCE_MIN);
    for(int i = 0; i < m1.rows; i++)
        m1.row(i) -= m2.row(i);


    auto temp_size = sizeof(double) * data_size;
    std::memcpy(data, m1.data, temp_size);
    std::vector<double>().swap(vec);
    m1.release();
    m2.release();

}



- (void) maximum_filter:(double *)data data_size:(int)data_size data_rows:(int)data_rows mask_size:(int)mask_size threshold:(double)threshold {

    std::vector<double> vec = std::vector<double>(data, data + data_size);
    cv::Mat m1(vec);
    m1 = m1.reshape(0, data_rows);

    cv::Mat bg;
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT,
                                               cv::Size(mask_size,mask_size),
                                               cv::Point(-1,-1));
    //选出大于某个阈值的点 放入m2
    cv::Mat m2;
    m1.copyTo(m2,m1 > threshold);

    // 高斯化
    cv::dilate(m2, bg, kernel);

    cv::Mat bg2;
    m2.copyTo(bg2,m2 == bg);

    size_t size2 = data_size * sizeof(double);
    std::memcpy(data, bg2.data, size2);

    std::vector<double>().swap(vec);
    m1.release();
    m2.release();
    bg.release();
    bg2.release();
    kernel.release();
}


-(UIImage*) renderKeypoint:(int*) keypoints
             keypoint_size:(int) keypoints_size
                       pos:(CGPoint*) pos
                  rawImage:(UIImage*) rawImage
{
    
    double COCO_COLORS_ARRAY[18][3] = {255, 0, 0, 255, 85, 0, 255, 170, 0, 255, 255, 0, 170, 255, 0, 85, 255, 0, 0, 255, 0, 0, 255, 85, 0, 255, 170, 0, 255, 255, 0, 170, 255, 0, 85, 255, 0, 0, 255, 85, 0, 255, 170, 0, 255, 255, 0, 255, 255, 0, 170, 255, 0, 85};

    // 画所有检测出来的关键点
    std::vector<int> key(keypoints, keypoints + keypoints_size);
    std::vector<CGPoint> position(pos, pos + keypoints_size * 2);
    
    

//    const auto exp = 4;
//    const auto width = bounds.size.width * exp;
//    const auto height = bounds.size.height * exp;
    
    const auto width = rawImage.size.width;
    const auto height = rawImage.size.height;
    const auto stand = (width <= height ? width : height);
    
    int stickwidth = int(stand / 150);
    int circlewidth = int(stand / 150);
    // 画布
//    cv::Mat mat(width, height, CV_8UC4);
//    mat = cv::Scalar(0);
    cv::Mat mat;
    UIImageToMat(rawImage, mat, true);
//    std::cout << mat.size << std::endl;
    
    for(int i = 0; i < keypoints_size; i++) {
        const auto current_limb_index = key[i];
        const cv::Scalar color{(COCO_COLORS_ARRAY[current_limb_index][0]), (COCO_COLORS_ARRAY[current_limb_index][1]), (COCO_COLORS_ARRAY[current_limb_index][2]), 255};

        CGPoint p1 = position[i*2];
        p1.x *= width + 0.5;
        p1.y *= height + 0.5;

        CGPoint p2 = position[i*2+1];
        p2.x *= width + 0.5;
        p2.y *= height + 0.5;
        
//        std::cout << "index: " << i << " p1.x: " << p1.x << " p1.y: " << p1.y << std::endl;
//        std::cout << "index: " << i << " p2.x: " << p2.x << " p2.y: " << p2.y << std::endl;
//        std::cout << "---------" << std::endl;
        

        cv::Point point1 = cv::Point(int(p1.x), int(p1.y));
        cv::circle(mat,point1,circlewidth,color,-1);

        cv::Point point2 = cv::Point(int(p2.x), int(p2.y));
//        cv::circle(mat,point2,stickwidth,color,-1);

        cv::line(mat, point1, point2, color, stickwidth);

        //        cout << color << endl;
        //        p1 = position[i*2];
        //        p2 = position[i*2+1];
        //        cv::line(mat,
        //                 cv::Point(int(p1.x * width + 0.5), int(p1.y * height + 0.5)),
        //                 cv::Point(int(p2.x * width + 0.5), int(p2.y * height + 0.5)),
        //                 color,5,CV_8UC4);

    }
    
    

    UIImage *preview = MatToUIImage(mat);
    std::vector<int>().swap(key);
    std::vector<CGPoint>().swap(position);
    mat.release();

    return preview;
    
}

-(UIImage*) renderMaskKeypoint:(int*) keypoints
            keypoint_size:(int) keypoints_size
            pos:(CGPoint*) pos
            rawImageWidth:(int) rawImageWidth
            rawImageHeight:(int) rawImageHeight
{
    double COCO_COLORS_ARRAY[18][3] = {255, 0, 0, 255, 85, 0, 255, 170, 0, 255, 255, 0, 170, 255, 0, 85, 255, 0, 0, 255, 0, 0, 255, 85, 0, 255, 170, 0, 255, 255, 0, 170, 255, 0, 85, 255, 0, 0, 255, 85, 0, 255, 170, 0, 255, 255, 0, 255, 255, 0, 170, 255, 0, 85};

    // 画所有检测出来的关键点
    std::vector<int> key(keypoints, keypoints + keypoints_size);
    std::vector<CGPoint> position(pos, pos + keypoints_size * 2);
    
    const auto stand = (rawImageWidth <= rawImageHeight ? rawImageWidth : rawImageHeight);
    int stickwidth = int(stand / 150);
    int circlewidth = int(stand / 150);
    
//    cv::Mat mat(rawImageHeight, rawImageWidth, CV_8UC4, cv::Scalar(0, 255, 0, 50));
    cv::Mat mat(rawImageHeight, rawImageWidth, CV_8UC4, cv::Scalar(0, 0, 0, 0));
//    mat = cv::Scalar(0, 255, 0);
//    std::cout << mat.size << std::endl;
    
    
    for(int i = 0; i < keypoints_size; i++) {
        const auto current_limb_index = key[i];
        const cv::Scalar color{(COCO_COLORS_ARRAY[current_limb_index][0]), (COCO_COLORS_ARRAY[current_limb_index][1]), (COCO_COLORS_ARRAY[current_limb_index][2]), 255};

        CGPoint p1 = position[i*2];
        p1.x *= rawImageWidth + 0.5;
        p1.y *= rawImageHeight + 0.5;

        CGPoint p2 = position[i*2+1];
        p2.x *= rawImageWidth + 0.5;
        p2.y *= rawImageHeight + 0.5;
        
        

        cv::Point point1 = cv::Point(int(p1.x), int(p1.y));
        cv::circle(mat,point1,circlewidth,color,-1);

        cv::Point point2 = cv::Point(int(p2.x), int(p2.y));

        cv::line(mat, point1, point2, color, stickwidth, CV_8UC4);


    }

    UIImage *preview = MatToUIImage(mat);
    std::vector<int>().swap(key);
    std::vector<CGPoint>().swap(position);
    mat.release();

    return preview;
    
    
}



+ (UIImage *)imageResizeWithOpencv:(UIImage *)rawImage
                          new_size: (CGSize) new_size
{
    
    cv::Mat temp, output;
    UIImageToMat(rawImage, temp);
    cv::resize(temp, output, cv::Size(new_size.width, new_size.height));
    return MatToUIImage(output);
}



-(UIImage*) renderKeypointAction:(int*) keypoints
                   keypoint_size:(int) keypoints_size
                             pos:(CGPoint*) pos
                        rawImage:(UIImage*) rawImage
                       rectarray:(int*) rectarray
                         actions:(int*) actions
                        humanNum:(int) humanNum
{
    
    double COCO_COLORS_ARRAY[18][3] = {255, 0, 0, 255, 85, 0, 255, 170, 0, 255, 255, 0, 170, 255, 0, 85, 255, 0, 0, 255, 0, 0, 255, 85, 0, 255, 170, 0, 255, 255, 0, 170, 255, 0, 85, 255, 0, 0, 255, 85, 0, 255, 170, 0, 255, 255, 0, 255, 255, 0, 170, 255, 0, 85};

    // 画所有检测出来的关键点
    std::vector<int> key(keypoints, keypoints + keypoints_size);
    std::vector<CGPoint> position(pos, pos + keypoints_size * 2);
    
    std::vector<int> rect(rectarray, rectarray + humanNum * 4);

//    const auto exp = 4;
//    const auto width = bounds.size.width * exp;
//    const auto height = bounds.size.height * exp;
    
    const auto width = rawImage.size.width;
    const auto height = rawImage.size.height;
    const auto stand = (width <= height ? width : height);
    
    int stickwidth = int(stand / 150);
    int circlewidth = int(stand / 150);
    // 画布
//    cv::Mat mat(width, height, CV_8UC4);
//    mat = cv::Scalar(0);
    cv::Mat mat;
    UIImageToMat(rawImage, mat, true);
//    std::cout << mat.size << std::endl;
    
    for(int i = 0; i < keypoints_size; i++) {
        const auto current_limb_index = key[i];
        const cv::Scalar color{(COCO_COLORS_ARRAY[current_limb_index][0]), (COCO_COLORS_ARRAY[current_limb_index][1]), (COCO_COLORS_ARRAY[current_limb_index][2]), 255};

        CGPoint p1 = position[i*2];
        p1.x *= width + 0.5;
        p1.y *= height + 0.5;

        CGPoint p2 = position[i*2+1];
        p2.x *= width + 0.5;
        p2.y *= height + 0.5;
        

        cv::Point point1 = cv::Point(int(p1.x), int(p1.y));
        cv::circle(mat,point1,circlewidth,color,-1);

        cv::Point point2 = cv::Point(int(p2.x), int(p2.y));

        cv::line(mat, point1, point2, color, stickwidth);

    }
    
    
    
    cv::RNG rng(time(0));
    double font_scale = stand / 180;
    
    
    for(int i = 0; i < humanNum; i++) {
        const cv::Scalar color{double(rng.uniform(0, 255)), double(rng.uniform(0, 255)), double(rng.uniform(0, 255)), 255};
        cv::rectangle(mat, cv::Point(rectarray[4 * i + 0], rectarray[4 * i + 2]), cv::Point(rectarray[4 * i + 1], rectarray[4 * i + 3]), color, stickwidth + stickwidth / 2);
        
        if(actions[i] == 1) {
            cv::putText(mat, "stand", cv::Point(rectarray[4 * i + 0], rectarray[4 * i + 2]), cv::FONT_HERSHEY_PLAIN, font_scale, color, stickwidth);
        }
        else if (actions[i] == 2) {
            cv::putText(mat, "sit", cv::Point(rectarray[4 * i + 0], rectarray[4 * i + 2]), cv::FONT_HERSHEY_PLAIN, font_scale, color, stickwidth);
        }
        
    }
    
    

    UIImage *preview = MatToUIImage(mat);
    std::vector<int>().swap(key);
    std::vector<CGPoint>().swap(position);
    mat.release();

    return preview;
    
}



@end



