
clearvars
tic
disp("Step 1: loading the image...");


img = imread('test_figuren/cropped_doos_1.png'); % Load picture (1080 rows * 1920 col)

THRESHOLD_VALUE = 2;

MIN_ROW_LINES_BETWEEN_GROUPS = 25; %25
% Once the groups are found, the algorithm searches for groups too close
% near each other
% This is defined as the min distance between two groups (only searched
% vertical)
SAME_PIXELS_SEARCH_GRID_SIZE = 25;
% Grid size = this variable *2, it searches for pixels with the same value
% in this grid.
GROUP_SEARCH_GRID_SIZE = 25; %25
% Grid size = this variable * 2, it searches for pixels with a group number
% (not 0) in this grid.
MIN_NB_SURROUNDING_PIXELS = 125;
% The minimum number of pixels with the same value that are in the grid
% size defined by SAME_PIXELS_SEARCH_GRID
% The pixels that have a less number of surrounding pixels, are not defined
% as a group but as noise.
disp("Minimum distance between 2 objects (only straight vertical or straight horizontal = " + max([MIN_ROW_LINES_BETWEEN_GROUPS SAME_PIXELS_SEARCH_GRID_SIZE MIN_NB_SURROUNDING_PIXELS;]) + " pixels");

hoekpnt = [980 100 100 980;100 100 1820 1820;];
disp("Step 2: converting the image to greyscale...");
disp("Starting calculations..");

A = greyscale(img); % Convert image to grayscale

%A = simon_crop(A, 100,100,980,1820, 1); % USE FOR foto RGB X
%top_left_row, top_left_col, bottom_right_row, bottom_right_col
disp("Step 3: cropping the image...");
%A = simon_crop(A, 200,850,750, 1850,1); % USE FOR foto XX RGB
disp("Step 4: blurring the image...");
A = gaussian_blur(mean_blur(A)); % Filters
% Method 3: First greyscale, then blur, then edge detect then threshold and then noise removal
disp("Step 5: edge detecting...");
first_edge_detect = edge_detect(A); % Laplacian edge detection
disp("Step 6: thresholding edge");
without_noise_removal = threshold_edge(remove_boundary(first_edge_detect, 15), THRESHOLD_VALUE); % Remove boundary around image & threshold the edges.
disp("Step 7: noise removing...");
with_noise_removal = noise_deletion(without_noise_removal,5); % Noise removal
disp("Step 8: grouping...");
[grouped, nb_of_groups] = group(~with_noise_removal, SAME_PIXELS_SEARCH_GRID_SIZE, GROUP_SEARCH_GRID_SIZE, MIN_NB_SURROUNDING_PIXELS); % Group pixels together
disp("Step 9: regrouping...");
[regrouped, nb_of_groups2] = regroup(grouped, nb_of_groups, MIN_ROW_LINES_BETWEEN_GROUPS); % Regroup (nessicary because group function works from top left to bottom right

%Find corner points of object (not really corner points on the boundary,
%but corner points for the boundary box)
disp("Step 10: calculating corner points...");
corner_points = find_corner_points(regrouped, nb_of_groups); % Make sure to use nb_of_groups and not groups 2 because some groups don't exist anymore!

disp("Step 11: removing objects within objects...");
[updated_corner_points, nb_of_groups3] = remove_corner_points_within_corner_points(corner_points, nb_of_groups2); % To remove objects within objects

disp("Step 12: drawing boundary boxes...");
boundary_box = draw_boundary_box(A, updated_corner_points);
disp("Step 13: Done!!!");
toc
cropped_img = generic_crop(A, updated_corner_points);
disp("Done!!!");


%% Show cropped image
imshow(cropped_img, []);
title("Cropped around crate");
%% Original image
imshow(img, []);
title("Original image");
%% After edge detection
imshow(first_edge_detect, []);
title("Edge detection");
%% Grouped image
imagesc(grouped(:,:,2));
title("Groups, #nb_objects = " + nb_of_groups);
%% Regrouped image
imagesc(regrouped(:,:,2));
title("Regrouped, Number of objects = " + nb_of_groups2);
%% Result
imshow(boundary_box, []);
title("Boundary box + removed objects within objects, Number of objects = "+ nb_of_groups3);



function [updated_corner_points, nb_of_groups] = remove_corner_points_within_corner_points(corner_points, nb_groups)
    mat_size = size(corner_points);
    groups = mat_size(2); % This is the original number_of_groups
    nb_of_groups = nb_groups; % This is the number_of_groups after regroup
    updated_corner_points = corner_points;
    
    for first=1:groups
        % Loop through every group
        % Now draw boundary box
        min_row_first = corner_points(1,first);
        min_col_first = corner_points(2,first);
        max_row_first = corner_points(3,first);
        max_col_first = corner_points(4,first);
        for second = 1:groups
            if first ~= second && max_row_first ~= 0 && corner_points(4, second) ~= 0 % If the max values would be 0, this won't be a group
            if first ~= second && max_row_first == 0 && corner_points(4, second) ~= 0 % If the max values would be 0, this won't be a group
                % Same groups, cant lay within eachother
                min_row_second = corner_points(1,second);
                min_col_second = corner_points(2,second);
                max_row_second = corner_points(3,second);
                max_col_second = corner_points(4,second);
                
                % Check if second lays within first
                
                if min_row_second >= min_row_first && min_col_second >= min_col_first && max_row_second <= max_row_first && max_col_second <= max_col_first
                    % Second object lays within first object
                    % Remouve this object
                    updated_corner_points(:, second) = zeros(4,1);

                    nb_of_groups = nb_of_groups - 1;
                end
            end
        end
    end
    end
end

function result = simon_crop(img, top_left_row, top_left_col, bottom_right_row, bottom_right_col, dimension)
    
    result = zeros(bottom_right_row - top_left_row, bottom_right_col - top_left_col, dimension);
    
    for row = top_left_row:bottom_right_row
        for col = top_left_col:bottom_right_col
            for dim = 1:dimension
                result(row - top_left_row + 1, col - top_left_col +1 , dim) = img(row, col, dim);
            end
        end
    end
end

function img_crop = generic_crop(img, fourp)
    % A function which crops the given image so that the edges are
    % definened by the four point given in fourp.
    mat_size = size(fourp);
    groups = mat_size(2);

    for i=1:groups
        if fourp(1,i)~=0
        MIN_ROW = fourp(1,i);
        MIN_COL = fourp(2,i);
        MAX_ROW = fourp(3,i);
        MAX_COL = fourp(4,i);
        end
    end

    img_crop = zeros(MAX_ROW-MIN_ROW+1,MAX_COL-MIN_COL+1,1);
        for row = MIN_ROW:MAX_ROW
            for col = MIN_COL:MAX_COL

                img_crop(row - MIN_ROW + 1,col - MIN_COL + 1,1) = img(row,col);
            end
        end

    
end

function result = is_valid_position(max_row, max_col, row, col)
    if row <= max_row && row >= 1 && col <= max_col && col > 1
        result = 1;
    else
        result = 0;
    end
end

function nes = noise_deletion(img,window)
    matrix_size = size(img);
    MAX_ROW = matrix_size(1);
    MAX_COLUMN = matrix_size(2);
    side = floor(window/2);
    nes = img;
    
    for col=side+1:MAX_COLUMN-side
        for row=side+1:MAX_ROW-side
            list=zeros(window);
            q=1;
            for i=-side:side
                for j=-side:side
                    list(q) = img(row+i,col+j);
                    q = q+1;
                end
            end
            list=sort(list);
            nes(row,col) = list(floor((window^2)/2)+1);
        end
    end
end

function result = same_pixels_in_range(img, row, col, SEARCH_GRID_SIZE);
    
    required_color = img(row, col);
    matrix_size = size(img);
    MAX_ROW = matrix_size(1);
    MAX_COLUMN = matrix_size(2);
    
    result = 0; % = # pixels of the same value in a grid size of -SEARCH_GRID_SIZE to SEARCH_GRID_SIZE
    
    for row_i = -SEARCH_GRID_SIZE:SEARCH_GRID_SIZE
        for col_i = -SEARCH_GRID_SIZE:SEARCH_GRID_SIZE
            if is_valid_position(MAX_ROW, MAX_COLUMN, row + row_i, col + col_i) == 1 && img(row + row_i, col + col_i) == required_color
                result = result + 1; % Found pixel with same value in range
            end
        end
    end
    
    
end

function result = find_group_in_range(img, row, col, SEARCH_GRID_SIZE)
    
    matrix_size = size(img);
    MAX_ROW = matrix_size(1);
    MAX_COLUMN = matrix_size(2);
    
    result = 0; 
    % Because the algorithm works from top-left to bottom-right, we now
    % that after (row, col), every pixel is useless.
    for row_i=-SEARCH_GRID_SIZE:0 % So we only need to go to the row that the pixel is on
        for col_i=-SEARCH_GRID_SIZE:SEARCH_GRID_SIZE % Here we make the mistake that we search in (MAX_COL - col) pixels too much
            % Search in a grid around the pixel
            % This searches too much pixels, need to change that
            if is_valid_position(MAX_ROW, MAX_COLUMN, row +row_i, col +col_i) == 1 && img(row + row_i, col + col_i, 2) ~= 0
                result = img(row+row_i, col + col_i, 2); 
                break; % Stop algorithm if a group is found.
                
                % We dont work from row, row-1, row-2,... (further from
                % pixel) because it is slower.
            end
            
        end
    end
end

function [result, nb_of_groups] = group(img, SAME_PIXEL_SEARCH_GRID_SIZE, GROUP_SEARCH_GRID_SIZE, MIN_NB_SURROUNDING_PIXELS)
    % Goal, group pixels.
    % First loop from left to right to find an object
    % Check if it's connected
    % Number connected pixels in the second dimension
    WHITE = 1;
    BLACK = 0;
    matrix_size = size(img);
    MAX_ROW = matrix_size(1);
    MAX_COLUMN = matrix_size(2);
    
    groups = 0;
    
    result = zeros(MAX_ROW,MAX_COLUMN,2); % Dimension 2 is for the group number.
    for row=1:MAX_ROW
        for col=1:MAX_COLUMN
          pixel_value = img(row, col);
          result(row, col,1) = pixel_value; % Transfer picture to result variable (in dim 1)
          if pixel_value == BLACK
              % This is an edge
              connecting_pixels = same_pixels_in_range(img, row, col, SAME_PIXEL_SEARCH_GRID_SIZE);
              
              if connecting_pixels > MIN_NB_SURROUNDING_PIXELS
                  % This is defined as an object outline.
                  group_number = find_group_in_range(result, row, col, GROUP_SEARCH_GRID_SIZE);
                  
                  if group_number == 0
                      % assign new group
                      groups = groups + 1;
                      group_number = groups;
                  end
                  %disp("connecting pixels=" + connecting_pixels + " group number=" + group_number + " pos=" + row + ", " + col);
                  result(row, col, 2) = group_number;
              end
          end
          %imagesc(result(:,:,2));
          
        end
    end    
    nb_of_groups = groups;
end

function result = group_replace(grouped_img, to_replace, replace_with)
    matrix_size = size(grouped_img);
    MAX_ROW = matrix_size(1);
    MAX_COLUMN = matrix_size(2);

    result = grouped_img;
    for row=1:MAX_ROW
        for col=1:MAX_COLUMN
           if grouped_img(row, col,2) == to_replace
               result(row, col,2) = replace_with;
           end
        end
    end
end

function [result, nb_groups] = regroup(grouped_img, nb_of_groups, MIN_ROW_LINES_BETWEEN_GROUPS)
    % Loop from (right)top to (left)bottom
    % Check if there are connecting groups.
    
    matrix_size = size(grouped_img);
    MAX_ROW = matrix_size(1);
    MAX_COLUMN = matrix_size(2);
    
    nb_groups = nb_of_groups;
    for col_i=1:MAX_COLUMN
        for row=1:MAX_ROW
            col = MAX_COLUMN - col_i+1;
            group_nb = grouped_img(row, col, 2);
            if group_nb ~= 0
                for row_i=1:MIN_ROW_LINES_BETWEEN_GROUPS
                    if is_valid_position(MAX_ROW, MAX_COLUMN, row + row_i, col) == 1 && grouped_img(row + row_i, col, 2) ~= 0 && grouped_img(row+row_i, col,2) ~= group_nb
                        % Found a different group in the next 5 pixels
                        % below this one
                        % Replace next group with previous group number
                        grouped_img = group_replace(grouped_img, grouped_img(row+row_i, col, 2), group_nb);
                        nb_groups = nb_groups - 1;
                        break;
                    end
                end
            end
        end
    end
    
    result = grouped_img;
end

function img = draw_red_boundary_box(img, corner_points)
    mat_size = size(corner_points);
    groups = mat_size(2);
    THICKNESS = 5;
    
    matrix_size = size(img);
    MAX_ROW = matrix_size(1);
    MAX_COLUMN = matrix_size(2);
    for i=1:groups
        % Loop through every group
        % Now draw boundary box
        min_row = corner_points(1,i);
        min_col = corner_points(2,i);
        max_row = corner_points(3,i);
        max_col = corner_points(4,i);
        % First draw horizontal lines
        for col=min_col:max_col
            for e=0:THICKNESS
                if is_valid_position(MAX_ROW, MAX_COLUMN, min_row+e, col) == 1
                    img(min_row+e, col, 1) = 255;
                    img(min_row+e, col, 2) = 1;
                    img(min_row+e, col, 3) = 1;
                end
                if is_valid_position(MAX_ROW, MAX_COLUMN, max_row-e, col) == 1
                    img(max_row-e, col,1) = 255;
                    img(max_row-e, col,2) = 1;
                    img(max_row-e, col,3) = 1;
                end
            end
        end
        
        % Vertical lines
        for row=min_row:max_row
            for e=0:THICKNESS
                if is_valid_position(MAX_ROW, MAX_COLUMN, row, min_col + e) == 1
                    img(row, min_col+e, 1) = 255;
                    img(row, min_col+e, 2) = 1;
                    img(row, min_col+e, 3) = 1;
                end
                if is_valid_position(MAX_ROW, MAX_COLUMN, row, max_col - e) == 1
                    img(row, max_col-e, 1) = 255;
                    img(row, max_col-e, 2) = 1;
                    img(row, max_col-e, 3) = 1;
                end
            end
            
        end
    end
    result = img;
end

function result = draw_boundary_box(img, corner_points)
    mat_size = size(corner_points);
    groups = mat_size(2);
    THICKNESS = 5;
    
    
    matrix_size = size(img);
    MAX_ROW = matrix_size(1);
    MAX_COLUMN = matrix_size(2);
    for i=1:groups
        % Loop through every group
        % Now draw boundary box
        
        min_row = corner_points(1,i);
        min_col = corner_points(2,i);
        max_row = corner_points(3,i);
        max_col = corner_points(4,i);
        
        COLOR = -10;
        % First draw horizontal lines
        for col=min_col:max_col
            for e=0:THICKNESS
                if is_valid_position(MAX_ROW, MAX_COLUMN, min_row+e, col) == 1
                    img(min_row+e, col) = COLOR;
                end
                if is_valid_position(MAX_ROW, MAX_COLUMN, max_row-e, col) == 1
                    img(max_row-e, col) = COLOR;
                end
            end
        end
        
        % Vertical lines
        for row=min_row:max_row
            for e=0:THICKNESS
                if is_valid_position(MAX_ROW, MAX_COLUMN, row, min_col + e) == 1
                    img(row, min_col+e) = COLOR;
                end
                if is_valid_position(MAX_ROW, MAX_COLUMN, row, max_col - e) == 1
                    img(row, max_col-e) = COLOR;
                end
            end
            
        end
    end
    result = img;
end

function result = find_corner_points(img, nb_groups)
    % Loop through grouped image
    % find MIN_ROW & MIN_COL and MAX_ROW & MAX_COL
    matrix_size = size(img);
    MAX_ROW = matrix_size(1);
    MAX_COLUMN = matrix_size(2);

    GROUP_MAX_ROW = zeros(1,nb_groups);
    GROUP_MAX_COL = zeros(1,nb_groups);
    GROUP_MIN_ROW = zeros(1,nb_groups);
    GROUP_MIN_COL = zeros(1,nb_groups);
           
    for row=1:MAX_ROW
        for col=1:MAX_COLUMN
            group_nb = img(row, col, 2);
            if group_nb ~= 0 
                % Group found (==0 means nothing is set)
                if GROUP_MAX_ROW(1,group_nb) == 0 || GROUP_MAX_ROW(1,group_nb) < row
                    GROUP_MAX_ROW(1,group_nb) = row;
                end
                
                if GROUP_MAX_COL(1,group_nb) == 0 || GROUP_MAX_COL(1,group_nb) < col
                    GROUP_MAX_COL(1,group_nb) = col;
                end
                
                if GROUP_MIN_ROW(1,group_nb) == 0 || GROUP_MIN_ROW(1,group_nb) > row
                    GROUP_MIN_ROW(1,group_nb) = row;
                end
                if GROUP_MIN_COL(1,group_nb) == 0 || GROUP_MIN_COL(1,group_nb) > col
                    GROUP_MIN_COL(1,group_nb) = col;
                end                
            end
           
        end
        result = [GROUP_MIN_ROW; GROUP_MIN_COL; GROUP_MAX_ROW; GROUP_MAX_COL];
    end
    
end

function cropped_img = symImgCrop(img,cutted_edge_size)
    original_img_size = size(img);
    original_max_row = original_img_size(1);
    original_max_column = original_img_size(2);
    
    cropped_img = zeros(original_max_row - 2*cutted_edge_size,original_max_column - 2*cutted_edge_size,1);
    
    for row=cutted_edge_size:original_max_row - cutted_edge_size
        for col=cutted_edge_size:original_max_column - cutted_edge_size
            cropped_img(row - cutted_edge_size + 1,col - cutted_edge_size + 1) = img(row,col);
        end
    end
end

function result = remove_boundary(img, remove_size)
    matrix_size = size(img);
    MAX_ROW = matrix_size(1);
    MAX_COLUMN = matrix_size(2);

    result = zeros(MAX_ROW,MAX_COLUMN,1);
    for row=1:MAX_ROW
        for col=1:MAX_COLUMN
           if row < remove_size || col < remove_size || row > (MAX_ROW - remove_size) || col > (MAX_COLUMN - remove_size)
               % Inside boundary ==> needs to be white (= 1)
               result(row, col) = 1;
           else
               result(row, col) = img(row, col);
           end
           
        end
    end
end

function thresholded_img = threshold_edge(img, THRESHOLD_VALUE)
    THRESHOLD_VALUE = 2;
    %most_occuring =mode(img) +100;
    %threshold_value = most_occuring(1);
   
    matrix_size = size(img);
    MAX_ROW = matrix_size(1);
    MAX_COLUMN = matrix_size(2);
    THICKNESS = 3;
    
    thresholded_img = zeros(MAX_ROW,MAX_COLUMN,1);
    for row=1:MAX_ROW
        for col=1:MAX_COLUMN
            if img(row, col) > THRESHOLD_VALUE
                value = 1;
                for i=1:THICKNESS
                    % Create thicker edges (edges of THICKNESS pixels thick)
                    if (col - i) > 0
                        thresholded_img(row, col-i) = 1;
                    end
                    
                    if (col + i) <= MAX_COLUMN
                        thresholded_img(row, col+i) = 1;
                    end
                    
                    if (row - i) > 0
                        thresholded_img(row -i, col) = 1;
                    end
                    
                    if (row + i) <+ MAX_ROW
                        thresholded_img(row +i, col) = 1;
                    end
                   
                end
            else
                value = 0;
            end
            thresholded_img(row, col) = value;
        end
    end
end

function mean_blurred = mean_blur(img)
    mean = (1/9) * [ 1 1 1; 1 1 1; 1 1 1];
    mean_blurred = conv2(img, mean);
end

function gaussian_blurred = gaussian_blur(img)
    gaussian = (1/159) * [2 4 5 4 2; 4 9 12 9 4; 5 12 15 12 5; 4 9 12 9 4; 2 4 5 4 2;];
    gaussian_blurred = conv2(img, gaussian);
end

function edge = edge_detect(img)
    klaplace=[0 -1 0; -1 4 -1;  0 -1 0];             % Laplacian filter kernel
    edge=conv2(img,klaplace);                         % convolve test img with
end

function grey = greyscale(img)
    matrix_size = size(img);
    MAX_ROW = matrix_size(1);
    MAX_COLUMN = matrix_size(2);

    grey = zeros(MAX_ROW,MAX_COLUMN,1);
    for row=1:MAX_ROW
        for col=1:MAX_COLUMN
            R = img(row, col, 1);
            G = img(row, col, 2);
            B = img(row, col, 3);
            grey(row, col) = 0.2989 * R + 0.5870 * G + 0.1140 * B ;  
            %These are two methods for grayscaling.
            %grey(row, col) = (R + G + B)/3;
        end
    end
end


