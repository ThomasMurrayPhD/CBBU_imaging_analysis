% script to compute pattern similarity of outcome categories in searchlight
% analysis.
% 





searchlightRad_mm = 5;
voxSize_mm = [1,1,1];

% from RSA toolbox
rad_vox=searchlightRad_mm./voxSize_mm;
minMargin_vox=floor(rad_vox);
[x,y,z]=meshgrid(-minMargin_vox(1):minMargin_vox(1),-minMargin_vox(2):minMargin_vox(2),-minMargin_vox(3):minMargin_vox(3));
sphere=((x*voxSize_mm(1)).^2+(y*voxSize_mm(2)).^2+(z*voxSize_mm(3)).^2)<=(searchlightRad_mm^2);



% practice
face_betas = rand(100, 100, 100, 70);
house_betas = rand(100, 100, 100, 70);
[xm,ym,zm]=meshgrid(-49:50,-49:50,-49:50);
mask=((xm*voxSize_mm(1)).^2+(ym*voxSize_mm(2)).^2+(zm*voxSize_mm(3)).^2)<=40^2;


% pad everything
face_betas_padded = padarray(face_betas, [minMargin_vox, 0]);
house_betas_padded = padarray(house_betas, [minMargin_vox, 0]);
mask_padded = padarray(mask, [minMargin_vox, 0]); % might need to make logical again


% idx of positive mask values
[xm,ym,zm] = ind2sub(size(mask_padded), find(mask_padded(:)>0))




% Useful... To find the original 3D x,y,z coordinates of an element in a
% matrix from the vectorised matrix, use ind2sub.
% E.g.
% a = rand(10, 10, 10);
% v = a(:);
% i = 10;
% [x, y, z] = ind2sub(size(a), i);
% v(i) = a(x, y, z)
% 
% So here - vectorise everything, then for each 1 in mask (use find), find
% corresponding x,y,z position in original volume. Then place sphere on
% this voxel, vectorise again, then these are relevant voxels
















