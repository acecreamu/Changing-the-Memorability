%% main
for i = 1:2000
    name = names2000(i);
    Im = imread(char(name));
    
    %uncomment needed operation
    
    % Im_ = temperature(Im);
    % Im_ = contrast(Im);
    % Im_ = sharp(Im);
    % Im_ = gray(Im);
    % Im_ = imgaussfilt(Im, 5);
    % Im_ = vibrance(Im);
    % Im_ = clarity(Im);  
    % Im_ = vignetting(Im);
    
    filename = char(strcat('output\',name));
    imwrite(Im_,filename);
end

%% BG bluring/darkening
% 'maps\' folder contains attention maps as a grayscale images,
% where 0 value correspond to no attention.
% any third-party algorithm can be used for their creation.

for i = 1:2000
    name = char(names2000(i));
    Im = imread(name);
    map = imread(['maps\' name]);
    map = double(map)/255;
    Imblur = imgaussfilt(Im, 10);
    % bluring
    Im_ = uint8(double(Im).*map + double(Imblur).*(1-map) );
    
    % for darkening
    %Im_ = uint8(double(Im) .* (0.5*map+0.5));
    
    filename = char(strcat('output\',name));
    imwrite(Im_,filename);
end

%% Color temperature
function Im_ = temperature(Im)
    %Im = chromadapt(Im, [...], 'method', 'vonkries');

    % table of rgb coordinates of black body radiation color
    %http://www.vendian.org/mncharity/dir3/blackbody/UnstableURLs/bbr_color.html

    %t4500K = [1.0000 0.7111 0.4919];
    t5000K = [1.0000 0.7792 0.6180];
    %t5500K = [1.0000 0.8403 0.7437];

    %t8500K = [0.7123 0.7815 1.0000];
    t9000K = [0.6693 0.7541 1.0000];
    %t9500K = [0.6335 0.7308 1.0000];

    if size(Im,3) == 1
        Im = repmat(Im,[1 1 3]);
    end

    Im_double = im2double(Im);
    Im_xyz = rgb2xyz(Im_double);
    Im_xyz_flat = reshape(permute(Im_xyz, [3 2 1]), 3, []);

    M_CAT02 = [0.7328 0.4296 -0.1624
            -0.7036 1.6975 0.0061
            0.0030 0.0136 0.9834];
    Im_lms_flat = M_CAT02 * Im_xyz_flat;

    wh2_rgb = t5000K;
    wh2_xyz = rgb2xyz(wh2_rgb)';
    wh2_lms = M_CAT02 * wh2_xyz;

    wh2_gray = [0.2989 0.5870 0.1140] * wh2_rgb';
    wh1_xyz = rgb2xyz(repmat(wh2_gray,1,3))';
    wh1_lms = M_CAT02 * wh1_xyz;

    Im_lms_flat = Im_lms_flat .* wh2_lms ./ wh1_lms;
    Im_xyz_flat =  M_CAT02 \ Im_lms_flat;
    Im_xyz = reshape(Im_xyz_flat, size(permute(Im,[3 2 1])));
    Im_xyz = permute(Im_xyz, [3 2 1]);
    Im_rgb = xyz2rgb(Im_xyz);
    Im_ = uint8(Im_rgb*255);
    %figure; imshow(Im_)
end

%% Contrast
function Im_ = contrast(Im)
    % x = 0:1:255;
    % y = (x-127).*exp(-(x-127).^2*0.0004);
    % plot(x,y); hold on; plot([0 255],[0 0]);
    % xlim([0 255]);

    Im_ = double(Im);
    Im_ = uint8(Im_ + 1.5*(Im_-127).*exp(-(Im_-127).^2*0.0004));
    %figure; imshow(Im_)
end

%% Vignetting 
function Im_ = vignetting(Im)
    % change of sigma influence height of distribution peak
    % to make it robust to image size, the mask of size 500x500 is created
    % and then just resized according to image size

    mu = [250 250];
    sigma = [40000 0; 0 40000];
    [X,Y] = meshgrid(1:500,1:500);
    nDist = mvnpdf([X(:) Y(:)], mu, sigma);
    nDist = reshape(nDist, 500, 500);
    %nDist = nDist - min(nDist(:));
    nDist = nDist / max(nDist(:));
    vignette = imresize(nDist, [size(Im,1) size(Im,2)]);
    Im_ = uint8(double(Im) .* vignette);
    %imshow(Im_)
end

%% Sharpening
function Im_ = sharp(Im)

    filteredIm = double(imgaussfilt(Im, 1.5));
    unsharpMask = double(Im) - filteredIm;
    Im_ = double(Im) + 2.0 * unsharpMask;
    Im_ = uint8(Im_);
    %imshow(Im_)
end

%% rgb2gray
function Im_ = gray(Im)

    Im_ = Im;
    if size(Im_,3) == 3
        Im_ = rgb2gray(Im_);
    end
end

%% Clarity (Structure)
function Im_ = clarity(Im)
    edgeThreshold = 0.8; 
    amount = 0.2;  
    Im_ = localcontrast(Im, edgeThreshold, amount);
    %imshow(Im_)
end

%% Vibrance
function Im_ = vibrance(Im)
    %x = 0:100;
    %y = x + 30 * exp(-0.5 *( (x-50)/20 ).^2);
    %plot(x,y); hold on; plot([0 1],[0 0]);
    %xlim([0 100]);

    if size(Im,3) == 1
        Im = repmat(Im,[1 1 3]);
    end

    Imlab = rgb2lab(im2double(Im));
    C = sqrt(Imlab(:,:,2).^2 +  Imlab(:,:,3).^2);
    h = atan2(Imlab(:,:,3),Imlab(:,:,2));
    C = C + 30 * exp(-0.5 *( (C-50)/20 ).^2);

    a = C .* cos(h);
    b = C .* sin(h);
    Imlab = cat(3, Imlab(:,:,1), a, b);
    Im_ = lab2rgb(Imlab);
    Im_ = uint8(Im_*255);

end
