%% Written by Muhammet Balcilar, France, muhammetbalcilar@gmail.com
% All rights reserved
%%%%%%%%%%%%

clear all
close all

% file1 = {'Inputs/USBCamera1.bmp',...
%     'Inputs/USBCamera2.bmp',...
%     'Inputs/USBCamera3.bmp',...
%     'Inputs/USBCamera4.bmp',...
%     'Inputs/USBCamera5.bmp',...
%     'Inputs/USBCamera6.bmp',...
%     'Inputs/USBCamera7.bmp',...
%     };
% file2={'Inputs/PTZCamera1.bmp',...
%     'Inputs/PTZCamera2.bmp',...
%     'Inputs/PTZCamera3.bmp',...
%     'Inputs/PTZCamera4.bmp',...
%     'Inputs/PTZCamera5.bmp',...
%     'Inputs/PTZCamera6.bmp',...
%     'Inputs/PTZCamera7.bmp',...
%     };
% 

file1 = {'Occipitial/test2.ppm',...
    'Occipitial/test3.ppm',...
    'Occipitial/test4.ppm',...
    'Occipitial/test5.ppm',...
    'Occipitial/test6.ppm',...
    'Occipitial/test8.ppm',...
    'Occipitial/test9.ppm',...
    'Occipitial/test10.ppm',...
    'Occipitial/test13.ppm',...
    'Occipitial/test14.ppm',...
    'Occipitial/test15.ppm',...
    'Occipitial/test17.ppm',...
    'Occipitial/test18.ppm',...
    'Occipitial/test19.ppm',...
    'Occipitial/test20.ppm',...
    };
file2={'Car/2.bmp',...
    'Car/3.bmp',...
    'Car/4.bmp',...
    'Car/5.bmp',...
    'Car/6.bmp',...
    'Car/8.bmp',...
    'Car/9.bmp',...
    'Car/10.bmp',...
    'Car/13.bmp',...
    'Car/14.bmp',...
    'Car/15.bmp',...
    'Car/17.bmp',...
    'Car/18.bmp',...
    'Car/19.bmp',...
    'Car/20.bmp',...
    };


% Detect checkerboards in images
[imagePoints{1}, boardSize, imagesUsed1] = detectCheckerboardPoints(file1);
[imagePoints{2}, boardSize, imagesUsed2] = detectCheckerboardPoints(file2);

% Generate world coordinates of the checkerboards keypoints
squareSize = 23;  %23 in units of 'mm'
worldPoints = generateCheckerboardPoints(boardSize, squareSize);


% imagePoints = cat(4, imagePoints{1}, imagePoints{2});
% [param,pairsUsed,estimationErrors] = estimateCameraParameters(imagePoints,...
%     worldPoints,'EstimateSkew', false, 'EstimateTangentialDistortion', false, ...
%     'NumRadialDistortionCoefficients', 2, 'WorldUnits', 'mm');

[param, pairsUsed, estimationErrors] = my_estimateCameraParameters(imagePoints, worldPoints, ...
    'EstimateSkew', false, 'EstimateTangentialDistortion', false, ...
    'NumRadialDistortionCoefficients', 2, 'WorldUnits', 'mm', ...
    'InitialIntrinsicMatrix', [], 'InitialRadialDistortion', []);


% View reprojection errors
h1=figure; showReprojectionErrors(param);

% Visualize pattern locations
h2=figure; showExtrinsics(param, 'CameraCentric');

% Display parameter estimation errors
displayErrors(estimationErrors, param);

% You can use the calibration data to undistort images
I1 = imread(file1{1});
I2 = imread(file2{1});

D1 = undistortImage(I1, param.CameraParameters1);
D2 = undistortImage(I2, param.CameraParameters2);

figure;subplot(1,2,1);imshow(I1);
subplot(1,2,2);imshow(I2);
figure;subplot(1,2,1);imshow(D1);
subplot(1,2,2);imshow(D2);

% You can use the calibration data to rectify stereo images.
[J1, J2] = my_rectifyStereoImages(I1, I2, param,'OutputView','full');
figure;imshowpair(J1,J2,'falsecolor','ColorChannels','red-cyan');


% select displayed checkeroard detection point grount truth 
% estimated point positions and camera positions.
cno=1;

Wpoints=[worldPoints zeros(size(worldPoints,1),1)];
figure;hold on;
axis vis3d; axis image;
grid on;
plot3(Wpoints(:,1),Wpoints(:,2),Wpoints(:,3),'b.','MarkerSize',20)

K1=param.CameraParameters1.IntrinsicMatrix';
R1=param.CameraParameters1.RotationMatrices(:,:,cno)';
T1=param.CameraParameters1.TranslationVectors(cno,:)';

Lcam=K1*[R1 T1];

K2=param.CameraParameters2.IntrinsicMatrix';
R2=param.CameraParameters2.RotationMatrices(:,:,cno)';
T2=param.CameraParameters2.TranslationVectors(cno,:)';


Rcam=K2*[R2 T2];

[points3d] = mytriangulate(imagePoints{1}(:,:,cno), imagePoints{2}(:,:,cno), Lcam,Rcam );
plot3(points3d(:,1),points3d(:,2),points3d(:,3),'r.')


% referencePoint(0,0,0)= R*Camera+T, So Camera=-inv(R)*T;
CL=-R1'*T1;
CR=-R2'*T2;

plot3(CR(1),CR(2),CR(3),'gs','MarkerFaceColor','g');
plot3(CL(1),CL(2),CL(3),'cs','MarkerFaceColor','c');
legend({'ground truth point locations','Calculated point locations','Camera2 position','Camera1 Position'});


% calculate relative distance from camera1 to camera2 in two different way
dist_1=norm(param.TranslationOfCamera2)
dist_2=norm(CR-CL)









