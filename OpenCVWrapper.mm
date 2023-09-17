#import "OpenCVWrapper.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>

@implementation OpenCVWrapper

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    cv::Mat cvMat(rows, cols, CV_8UC4); // Allocate the cv::Mat with the proper dimensions and type
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data, cols, rows, 8, cvMat.step[0], colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    cv::cvtColor(cvMat, cvMat, cv::COLOR_RGBA2BGR); // Convert from RGBA to BGR
    return cvMat;
}

+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat {
    cv::Mat rgbMat;
    cv::cvtColor(cvMat, rgbMat, cv::COLOR_BGR2RGB);
    NSData *imageData = [NSData dataWithBytes:rgbMat.data length:rgbMat.elemSize() * rgbMat.total()];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)imageData);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef imageRef = CGImageCreate(cvMat.cols, cvMat.rows, 8, 24, cvMat.step[0], colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaNone, provider, NULL, false, kCGRenderingIntentDefault);
    UIImage *resultImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    return resultImage;
}

+ (cv::Mat)rotate_bound:(cv::Mat)image angle:(double)angle {
    double h = image.rows;
    double w = image.cols;
    double cX = w / 2;
    double cY = h / 2;
    cv::Mat M = cv::getRotationMatrix2D(cv::Point2f(cX, cY), -angle, 1.0);
    double cos = std::abs(M.at<double>(0, 0));
    double sin = std::abs(M.at<double>(0, 1));
    int nW = static_cast<int>((h * sin) + (w * cos));
    int nH = static_cast<int>((h * cos) + (w * sin));
    M.at<double>(0, 2) += (nW / 2) - cX;
    M.at<double>(1, 2) += (nH / 2) - cY;
    cv::Mat result;
    cv::warpAffine(image, result, M, cv::Size(nW, nH));
    return result;
}

+ (cv::Mat)find_contour:(cv::Mat)pic {
    cv::Mat gray;
    cv::cvtColor(pic, gray, cv::COLOR_BGR2GRAY);
    cv::Mat binary;
    cv::threshold(gray, binary, 140, 255, cv::THRESH_BINARY);
    cv::Mat img = pic.clone();
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(binary, contours, hierarchy, cv::RETR_TREE, cv::CHAIN_APPROX_SIMPLE);
    int row = binary.rows;
    int col = binary.cols;
    cv::Mat result;
    for (int i = 0; i < contours.size(); i++) {
        if (cv::arcLength(contours[i], true) > col / 2 && cv::arcLength(contours[i], true) < 1.9 * (col + row)) {
            cv::drawContours(img, contours, i, cv::Scalar(0, 0, 255), 2);
            cv::RotatedRect rect = cv::minAreaRect(contours[i]);
            double angle = rect.angle;
            if (angle < -45){
                angle = -(angle + 90);
            } else {
                angle = -angle;
            }
            img = [self rotate_bound:img angle:angle];
            break;
        }
    }
    return img;
}

+ (UIImage *)rectifyBiasWithImage:(UIImage *)image {
    cv::Mat cvMat = [self cvMatFromUIImage:image];
    cv::Mat rotated = [self find_contour:cvMat];
    UIImage *resultImage = [self UIImageFromCVMat:rotated];
    return resultImage;
}
    
@end
