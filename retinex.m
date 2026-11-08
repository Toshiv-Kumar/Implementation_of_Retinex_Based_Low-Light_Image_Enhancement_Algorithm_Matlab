clear; clc;

img = imread('testing_image.jpeg');
R = img(:,:,1);
G = img(:,:,2);
B = img(:,:,3);

% Define RGB image
% R = [20 40 60 80; 30 50 70 90; 40 60 80 100; 50 70 90 110];
% G = [10 30 50 70; 20 40 60 80; 30 50 70 90; 40 60 80 100];
% B = [5 25 45 65; 15 35 55 75; 25 45 65 85; 35 55 75 95];
% this is present in the tb of our design and not declared in the design.v
r_size = size(R, 1); % size of output/input image
c_size = size(R, 2); % parameterize everything
window_size = 11; % taken 11 in verilog
border_pad_width = bitshift(window_size-1,-1);

% mirror padding
r_pad_size = r_size + 2*border_pad_width;
c_pad_size = c_size + 2*border_pad_width;
pad_R = zeros(r_pad_size, c_pad_size);
pad_G = zeros(r_pad_size, c_pad_size);
pad_B = zeros(r_pad_size, c_pad_size);
% here, we fill up the actual unpadded portion directly
for i = 1:1:r_size
    for j = 1:1:c_size
        pad_R(i+border_pad_width, j + border_pad_width) = R(i,j);
        pad_G(i+border_pad_width, j + border_pad_width) = G(i,j);
        pad_B(i+border_pad_width, j + border_pad_width) = B(i,j);
    end
end
% proceding with mirror paddind without accounting for diagonal padding yet
% 2 reference columns for reflection(rename in verilog)
left_ref = 1+border_pad_width;
right_ref = 1+border_pad_width+c_size-1;

moving_left_padder_col = left_ref-1; move_right_for_leftpadder = left_ref+1;
moving_right_padder_col = right_ref+1; move_left_for_rightpadder = right_ref-1;
% 2 ref for rows
up_ref = 1+ border_pad_width;
down_ref = r_pad_size - border_pad_width;
moving_up_padder_row = up_ref -1; move_down_for_uppadder = up_ref + 1;
moving_down_padder_row = down_ref +1; move_up_for_downpadder = down_ref - 1;
while (true)
    if(moving_left_padder_col == 0) 
        break;
    end
    % filling columns left and right
    for i = 1+border_pad_width:1:r_pad_size - border_pad_width
        pad_R(i, moving_left_padder_col) = pad_R(i, move_right_for_leftpadder);
        pad_G(i, moving_left_padder_col) = pad_G(i, move_right_for_leftpadder);
        pad_B(i, moving_left_padder_col) = pad_B(i, move_right_for_leftpadder);
        pad_R(i, moving_right_padder_col) = pad_R(i, move_left_for_rightpadder);
        pad_G(i, moving_right_padder_col) = pad_G(i, move_left_for_rightpadder);
        pad_B(i, moving_right_padder_col) = pad_B(i, move_left_for_rightpadder);

        
        
    end
    % filling rows top and bottom
    for j = 1+border_pad_width:1:c_pad_size - border_pad_width
        pad_R(moving_up_padder_row, j) = pad_R(move_down_for_uppadder,j);
        pad_G(moving_up_padder_row, j) = pad_G(move_down_for_uppadder,j);
        pad_B(moving_up_padder_row, j) = pad_B(move_down_for_uppadder,j);
        pad_R(moving_down_padder_row, j) = pad_R(move_up_for_downpadder, j);
        pad_G(moving_down_padder_row, j) = pad_G(move_up_for_downpadder, j);
        pad_B(moving_down_padder_row, j) = pad_B(move_up_for_downpadder, j);        
    end 
    temp = 1;
    % handling diagonals
    for k = left_ref-1:1:1

        pad_R(moving_up_padder_row,k) = pad_R(moving_up_padder_row,left_ref-k+2);
        pad_G(moving_up_padder_row,k) = pad_G(moving_up_padder_row,left_ref-k+2);
        pad_B(moving_up_padder_row,k) = pad_B(moving_up_padder_row,left_ref-k+2);

        pad_R(moving_up_padder_row,right_ref+left_ref-k) = pad_R(moving_up_padder_row,right_ref-temp);
        pad_G(moving_up_padder_row,right_ref+left_ref-k) = pad_G(moving_up_padder_row,right_ref-temp);
        pad_B(moving_up_padder_row,right_ref+left_ref-k) = pad_B(moving_up_padder_row,right_ref-temp);

        pad_R(moving_down_padder_row,k) = pad_R(moving_down_padder_row,left_ref-k+2);
        pad_G(moving_down_padder_row,k) = pad_G(moving_down_padder_row,left_ref-k+2);
        pad_B(moving_down_padder_row,k) = pad_B(moving_down_padder_row,left_ref-k+2);

        pad_R(moving_down_padder_row,right_ref+left_ref-k) = pad_R(moving_down_padder_row,right_ref-temp);
        pad_G(moving_down_padder_row,right_ref+left_ref-k) = pad_G(moving_down_padder_row,right_ref-temp);
        pad_B(moving_down_padder_row,right_ref+left_ref-k) = pad_B(moving_down_padder_row,right_ref-temp);

        temp = temp + 1;
    end


    moving_left_padder_col = moving_left_padder_col - 1;
    moving_right_padder_col = moving_right_padder_col + 1;
    move_right_for_leftpadder = move_right_for_leftpadder + 1;
    move_left_for_rightpadder = move_left_for_rightpadder - 1;
    moving_up_padder_row = moving_up_padder_row + 1;
    move_down_for_uppadder = move_down_for_uppadder -1;
    moving_down_padder_row = moving_down_padder_row -1;
    move_up_for_downpadder = move_up_for_downpadder + 1;

end

%% fsm state to build the initial line buffer of Gi = max(R,G,B); till delta patch size:
Gi = zeros(window_size,c_pad_size); % Gi is actually Gi_pad
% one isssue is that it will take 10 extra clock cycles for each row of
% image as we will accelerate Gi matrix to add 2*border*width + 1 extra(as a part of process itself)

% lets perform right shift to fill the Gi matrix

row_index_for_Gi = window_size;
col_index_for_Gi = c_pad_size;

for i = 1:1:window_size*c_pad_size

    % this is for right shift every outer loop iteration
    for u = window_size:-1:1
        for v = c_pad_size:-1:1
            if v == 1 && u ~= 1
            Gi(u, v) = Gi(u-1, c_pad_size);
            elseif (v-1 ~=0)
            
            Gi(u, v)  = Gi(u, v-1);
            end

         end
    end

    % there is no ternary in matlab but do in hdl and try function
    % To insert the max element at the 
    if pad_R(row_index_for_Gi,col_index_for_Gi) >= pad_G(row_index_for_Gi,col_index_for_Gi) && pad_R(row_index_for_Gi,col_index_for_Gi) >= pad_B(row_index_for_Gi,col_index_for_Gi)
        Gi(1,1) = pad_R(row_index_for_Gi,col_index_for_Gi);
    elseif pad_G(row_index_for_Gi,col_index_for_Gi) >= pad_R(row_index_for_Gi,col_index_for_Gi) && pad_G(row_index_for_Gi,col_index_for_Gi) >= pad_B(row_index_for_Gi,col_index_for_Gi)
        Gi(1,1) = pad_G(row_index_for_Gi,col_index_for_Gi);
    else
        Gi(1,1) = pad_B(row_index_for_Gi,col_index_for_Gi);
    end

    % this keeps the index to pull from rg and b padded matrices
    if col_index_for_Gi >1
        col_index_for_Gi  = col_index_for_Gi - 1;
    else
        col_index_for_Gi = c_pad_size;
        row_index_for_Gi = row_index_for_Gi - 1;
    end
    
end
% now that basic Gi is computed, we will fill the Pci matrix till omega is
% fulfilled

Gi;

%% The first loop makes sure that delta window is filled with valid values which needs to be used in the next clock cycle

Gi_old = zeros(window_size -  border_pad_width, c_size);
delta = zeros(window_size, window_size);

pci_r_filling_index = 1;
pci_c_filling_index = 1;
pair3_max_from_col_1 = 0; % include extra for 11*11 matrix                                                                                                                                                                                                                      
register_set_max_each_col = zeros(1, window_size);
max_from_registerset_1 = 0;
Pci = zeros(window_size,c_size);
row_index_for_Gi = 1+window_size;
col_index_for_Gi = 1;
head_for_registerset = 1;
flag = 1; % reset this and other things in the final done fsm state


%% next fsm state to fill Pci(course illumination) line buffer till the omega window size

while (true)
    % filling delta window at end of timestep depending upon if values in window are
    % completely new or not(we can use previous columns as window simply slides).

    % this if is for complete refilling of delta matrix from start.
    if pci_c_filling_index == 1
       head_for_registerset = 1;
       if flag == 0 % to prevent this from running and computing anything yet for the first time and to wait for next edge
        for k = 1:1:window_size % to iterate through all the col in window
        pair3_max_from_col_1 = Max3(delta(1,k), delta(2,k), delta(3,k));
        pair3_max_from_col_2 = Max3(delta(4, k), delta(5, k), delta(6, k));
        pair3_max_from_col_3 = Max3(delta(7, k), delta(8, k), delta(9, k));
        pair3_max_from_col_collect = Max3(pair3_max_from_col_1, pair3_max_from_col_2, pair3_max_from_col_3);
        pair3_max_from_col_final = Max3(pair3_max_from_col_collect, delta(10, k), delta(11, k));
        % add more smaller pairs3 for 11*11 window
        register_set_max_each_col(k) = pair3_max_from_col_final;
        end
        max_from_registerset_1 = Max3(register_set_max_each_col(1), register_set_max_each_col(2), register_set_max_each_col(3));
        max_from_registerset_2 = Max3(register_set_max_each_col(4), register_set_max_each_col(5), register_set_max_each_col(6));
        max_from_registerset_3 = Max3(register_set_max_each_col(7), register_set_max_each_col(8), register_set_max_each_col(9));
        max_from_registerset_collect = Max3(max_from_registerset_1,max_from_registerset_2 ,max_from_registerset_3 );
        max_from_registerset_final = Max3(register_set_max_each_col(10), register_set_max_each_col(11), max_from_registerset_collect);
        % now that delta window is ready +max val; we will compute a value of pci
        % and shift Gi matrix to include a new value
        Pci(pci_r_filling_index,pci_c_filling_index) = max_from_registerset_final;
        pci_c_filling_index = pci_c_filling_index + 1;
       else
           for i = 1:1:window_size - border_pad_width
               for j = 1:1:c_size
                   Gi_old(i, j) = Gi(i + border_pad_width, j + border_pad_width);
               end
           end
       end
        flag = 0;
        % making the patch: delta
        for i = 1:1:1 + 2*border_pad_width
            for j = 1:1: 1+ 2*border_pad_width
                delta(i, j) = Gi(i, j); % patch about (2,2) or (6,6) always
            end
        end

        % shift left and include a new value in the Gi matrix
        for u = 1:1:window_size
            for v = 1:1:c_pad_size-1
                if v == c_pad_size-1
                    Gi(u,v) = Gi(u,v+1);
                    if u+1 ~= window_size + 1
                        Gi(u,v+1) = Gi(u+1,1);
                    end
                else
                    Gi(u,v) = Gi(u, v+1);
                end

            end
        end
        % including a new value in Gi matrix
        Gi(window_size,c_pad_size) = Max3( pad_R(row_index_for_Gi, col_index_for_Gi), pad_G(row_index_for_Gi, col_index_for_Gi), pad_B(row_index_for_Gi, col_index_for_Gi));
        % shifting the index for new values to be picked up from pad_RGB
        % for Gi
        if row_index_for_Gi ~= r_pad_size || col_index_for_Gi ~= c_size
            if col_index_for_Gi == c_size

                    col_index_for_Gi = 1;
                    row_index_for_Gi = row_index_for_Gi+1;
            else
                col_index_for_Gi = col_index_for_Gi + 1;
            end
        end

    %% This is the case of preserving and making use of old values like DP
    else



        % now we compute max values for efficient register set(add more for
        % 11*11 future matrix
        temp_pair3_forefficient_colmax_1 = Max3(delta(1, window_size), delta(2, window_size), delta(3, window_size));
        temp_pair3_forefficient_colmax_2 = Max3(delta(4, window_size), delta(5, window_size), delta(6, window_size));
        temp_pair3_forefficient_colmax_3 = Max3(delta(7, window_size), delta(8, window_size), delta(9, window_size));
        temp_pair3_forefficient_colmax_collect = Max3(temp_pair3_forefficient_colmax_1, temp_pair3_forefficient_colmax_2, temp_pair3_forefficient_colmax_3);
        temp_pair3_forefficient_colmax_final = Max3(temp_pair3_forefficient_colmax_collect, delta(10, window_size), delta(11, window_size));

        register_set_max_each_col(head_for_registerset) = temp_pair3_forefficient_colmax_final;
        % might need to add head var in comb block itself
        if head_for_registerset == window_size % this was made for pipelining, does not work properly in fsm, might need to add extra code or recalc all in verilog comb block
            head_for_registerset = 1;
        else
            head_for_registerset = head_for_registerset + 1;
        end
        % add more max_temp_registers more for 11*11 matrix
        max_from_registerset_1 = Max3(register_set_max_each_col(1), register_set_max_each_col(2), register_set_max_each_col(3));
        max_from_registerset_2 = Max3(register_set_max_each_col(4), register_set_max_each_col(5), register_set_max_each_col(6));
        max_from_registerset_3 = Max3(register_set_max_each_col(7), register_set_max_each_col(8), register_set_max_each_col(9));
        max_from_registerset_collect = Max3(max_from_registerset_1,max_from_registerset_2 ,max_from_registerset_3 );
        max_from_registerset_final = Max3(register_set_max_each_col(10), register_set_max_each_col(11), max_from_registerset_collect);

        % now that delta window is ready +max val; we will compute a value of pci
        % and shift Gi matrix to include a new value
        Pci(pci_r_filling_index,pci_c_filling_index) = max_from_registerset_final;
       % If the delta matrix end of a row then it needs to precompute all
       % the values from Gi as it will go to the begin of the next row and
       % so the head pointer will point to the first index
       if (pci_c_filling_index ~= c_size)
        for i = 1:1:window_size
            for j = 1:1:window_size
                if j <= window_size -1
                    delta(i, j) = delta(i, j+1);
                end
            end
        end
        % filling the last col with new values
        for i = 1:1:window_size
            delta(i, window_size) = Gi(i, 1+ 2*border_pad_width);
        end
       else
           
           head_for_registerset = 1; % take care of this in verilog
        % making the patch: delta
        for i = 1:1:1 + 2*border_pad_width
            for j = 1:1: 1+ 2*border_pad_width
                delta(i, j) = Gi(i, j); % patch about (2,2) or (6,6) always
            end
        end

       end
      %% to decide whether to shift left and include a new value in the Gi matrix
      % or shift left 3 times so other things in this fsm states need to be
      % paused
       if pci_c_filling_index ~= c_size - 1
        % we are somewhere in middle of the Gi line buff values. One new
        % delta col in place of old one only in registerset for now. We
        % don't shift 3 times here.


        % to shift and include new value for Gi
        for u = 1:1:window_size
            for v = 1:1:c_pad_size-1
                if v == c_pad_size-1
                    Gi(u,v) = Gi(u,v+1);
                    if u+1 ~= 1 + window_size
                        Gi(u,v+1) = Gi(u+1,1);
                    end
                else
                    Gi(u,v) = Gi(u, v+1);
                end

            end
        end
        % including a new value in Gi matrix

        Gi(window_size,c_pad_size) = Max3( pad_R(row_index_for_Gi, col_index_for_Gi), pad_G(row_index_for_Gi, col_index_for_Gi), pad_B(row_index_for_Gi, col_index_for_Gi));
        % shifting the index for new values to be picked up from pad_RGB
        % for Gi
        if row_index_for_Gi ~= r_pad_size || col_index_for_Gi ~= c_size
            if col_index_for_Gi == c_size
                col_index_for_Gi = 1;
                row_index_for_Gi = row_index_for_Gi+1;
            else
                col_index_for_Gi = col_index_for_Gi + 1;
            end
        end
        if pci_c_filling_index == c_size
            pci_c_filling_index = 1;
            pci_r_filling_index = pci_r_filling_index + 1;
        else
            pci_c_filling_index = pci_c_filling_index + 1  ;
        end
       else
        %% Now we need to shift Gi buffer 3 times
           

        % this is for one output per clock cycle shift technique
        for u = 1:1:window_size
            for v = 1:1:c_pad_size
                if u == window_size && v> c_pad_size - (1+2*border_pad_width)
                ;
                else
                    if v + (1+2*border_pad_width) <= c_pad_size
                        Gi(u,v) = Gi(u, v + (1+2*border_pad_width));
                    else
                        Gi(u, v) = Gi(u+1, (1+2*border_pad_width) - (c_pad_size-v));
                    end                                                                                                                                                   

                end

            end
        end
        % including a new value in Gi matrix
        % IMP: For this to be success, have many i/p ports that give out
        % ahead/future values of pad matrices. ALso, on this operation, give an
        % output with extra output port to tell it to the consumer that you
        % need to shift your streaming by 1+2*border_width too.
        temp = c_pad_size - (2*border_pad_width); % this is error prone, if pad_R goes next row, check for 11*11
        Gi;
        Pci;
        for i = c_pad_size - (2*border_pad_width) : 1 : (c_pad_size)
            Gi(window_size, i) = Max3( pad_R(row_index_for_Gi, col_index_for_Gi +(i - temp)), pad_G(row_index_for_Gi, col_index_for_Gi +(i - temp)), pad_B(row_index_for_Gi, col_index_for_Gi + (i - temp)));
        end

        % Error prone: I am not sure about this
        if row_index_for_Gi ~= r_pad_size
            row_index_for_Gi = row_index_for_Gi + 1;
            col_index_for_Gi = 1;
        end
        if pci_c_filling_index == c_size
            pci_c_filling_index = 1;
            pci_r_filling_index = pci_r_filling_index + 1;
        else
            pci_c_filling_index = pci_c_filling_index + 1  ;
        end

       end
  

    end
    head_for_registerset;
    register_set_max_each_col;
    Pci;
    Gi;
    delta;
    if pci_r_filling_index > window_size
        break; % Exit the loop if we have filled all rows
    end
end

Pci;
Gi;
delta ;

Gi_old;
Pci_bigger = zeros(window_size + 1 + border_pad_width, c_size);
%% extra fsm state added to construct a Pci_bigger matrix out of Pci matrix
% in order to have x,y for output evaluation always at 1+border_pad_width
% position
temp_index_r = 1;  temp_index_c = 1;
for i = 1 : 1 : window_size + 1 + border_pad_width
    for j = 1 : 1 : c_size
        
        if (i >= border_pad_width)
            if i == border_pad_width + 1 && j >= border_pad_width + 1
                Pci_bigger(i, j) = Pci(temp_index_r, temp_index_c);
                if temp_index_c < c_size
                    temp_index_c = temp_index_c + 1;
                elseif  (temp_index_r + 1) <= (window_size)
                    temp_index_r = temp_index_r + 1;
                    temp_index_c = 1;
                end
            elseif i>= border_pad_width + 2 && i <= window_size + border_pad_width
                Pci_bigger(i, j) = Pci(temp_index_r, temp_index_c);
                if temp_index_c < c_size
                    temp_index_c = temp_index_c + 1;
                elseif  (temp_index_r + 1) <= (window_size)
                    temp_index_r = temp_index_r + 1;
                    temp_index_c = 1;
                end
            elseif i ==  window_size + border_pad_width + 1 && j <= border_pad_width
                Pci_bigger(i, j) = Pci(temp_index_r, temp_index_c);
                if temp_index_c < c_size
                    temp_index_c = temp_index_c + 1;
                elseif  (temp_index_r + 1) <= (window_size)
                    temp_index_r = temp_index_r + 1;
                    temp_index_c = 1;
                end
            else
                Pci_bigger(i, j) = 0;
            end
        else
            Pci_bigger(i, j) = 0;
        end
    end
end

Pci_bigger;
%% Final FSM state: compute output final image matrix and transfer the pixels one by one as an output to the testbench and store for reference.
omega  = zeros(window_size, window_size);
flag2 = 0;
Pci_min = zeros(1, window_size);
d = zeros(1, window_size);
Beta = zeros(1, window_size);
Y_m  = zeros(1, window_size);
output_R = zeros(r_size, c_size);
output_G = zeros(r_size, c_size);
output_B = zeros(r_size, c_size);
output_index_r = 1;
output_index_c = 1; 
%% We will make Pci bigger in rows manner only and change its centre accessing index so do the same here in while everywhere(a lot of places)
while (true) 

    %% block that is important to compute final image matrix using mostly
    % combinational nets and just one non-blocking assignment
    % Assuming that omega matrix is ready from the prev clock cycle and we can directly implement
    % operations to compute image

    % for now, Pci_min optimization like Fig. 3c is not implemented but it
    % can be done later. Add more pair3_min vars to compute for 11*11

    % Step 6: Pci_min and col_mins
   if flag2 == 1 % this output is not calculated the first iteration of the state
       omega;
    for k = 1:1:window_size % to iterate through all the col in window
        pair3_min_from_col_1 = Min3(omega(1,k), omega(2,k), omega(3,k));
        pair3_min_from_col_2 = Min3(omega(4,k), omega(5,k), omega(6,k));
        pair3_min_from_col_3 = Min3(omega(7,k), omega(8,k), omega(9,k));
        pair3_min_from_col_collect = Min3(pair3_min_from_col_1, pair3_min_from_col_2, pair3_min_from_col_3);
        pair3_min_from_col_final = Min3(pair3_min_from_col_collect, omega(10, k), omega(11, k));
        % add more smaller pairs3 for 11*11 window
        Pci_min(k) = pair3_min_from_col_final;
    end
    
    % Step 7 & 8: Compute D and Beta
    for l = 1:1:window_size
        if (Pci_min(l) >= Gi_old(1 , 1))
            Beta(l) = 1;
            d(l) = Pci_min(l) - Gi_old(1 , 1);
        else 
            Beta(l) = 0;
            d(l) = Gi_old(1 , 1 ) - Pci_min(l);
        
        end
    end

    % Step 9: Select linear segment:
    for m = 1:1:window_size
        if d(m) >= 0 && d(m) <= 14.3
            Y_m(m) = 16384 - (bitshift(d(m),8) + bitshift(d(m),7) + bitshift(d(m),5));

        elseif d(m) > 14.3 && d(m) <= 38
            Y_m(m) = 13631 - (bitshift(d(m),7) + bitshift(d(m),6) + bitshift(d(m),5));

        elseif d(m) > 38 && d(m) <= 46.4
            Y_m(m) = 10747 - (bitshift(d(m),7) + bitshift(d(m),4) + bitshift(d(m),2));

        elseif d(m) > 46.4 && d(m) <= 67
            Y_m(m) = 7966 - (bitshift(d(m),6) + bitshift(d(m),4) + bitshift(d(m),3));

        elseif d(m) > 67 && d(m) <= 95
            Y_m(m) = 5017 - (bitshift(d(m),5) + bitshift(d(m),3) + bitshift(d(m),2));

        elseif d(m) > 95 && d(m) <= 135
            Y_m(m) = 2265 - (bitshift(d(m),2) + bitshift(d(m),3) + bitshift(d(m),1)) - d(m);

        elseif d(m) > 135 && d(m) <= 175
            Y_m(m) = 822 - bitshift(d(m),2);

        else
            Y_m(m) = 416;
        end
    end

    % step 10 Calculate Refined Illumination:
    sum_N = 0;
    sum_D = 0;
    for m = 1:1:window_size
        sum_N = sum_N + (Beta(m)*Y_m(m)*Pci_min(m));
    end

    for m = 1:1:window_size
        sum_D = sum_D + (Beta(m)*Y_m(m));
    end
    Fm = (sum_N/sum_D);  % implement a lut + multiplier based on AI's method i.e scale this up too
    

    % Step 11: Calculate Reflectance for R, G and B, will do this later as
    % it comes out as decimal value (0 to 1) and handling that is tedious
    

    % Step 12: Normalization of Fm is skipped as it will make 0 to 1 too

    % Step 13: Modified Illumination for gamma correction & contrast
    % balancing without Fnorm for now(no change in accuracy)
    Emod = sqrt(Fm)*(sqrt(2*255 - Fm)); % use lut approximation for root
    temp_emod_by_Fm = Emod/Fm; % implement division by lut memory

    % Final Step 14: Enhanced output pixel, in verilog, just send the 3
    % computed pixels to the output testbench and testbench will store the
    % image

    if output_index_c == 1
        output_R(output_index_r-1, c_size) = temp_emod_by_Fm * R(output_index_r-1, c_size); 
        output_G(output_index_r-1, c_size) = temp_emod_by_Fm * G(output_index_r-1, c_size); 
        output_B(output_index_r-1, c_size) = temp_emod_by_Fm * B(output_index_r-1, c_size); 
    else
        output_R(output_index_r, output_index_c-1) = temp_emod_by_Fm * R(output_index_r, output_index_c-1); 
        output_G(output_index_r, output_index_c-1) = temp_emod_by_Fm * G(output_index_r, output_index_c-1); 
        output_B(output_index_r, output_index_c-1) = temp_emod_by_Fm * B(output_index_r, output_index_c-1); 

    end

    %% Shifting Gi_old and filling in new value
        for u = 1:1: window_size - border_pad_width
            for v = 1:1:c_size-1
                if v == c_size-1
                    Gi_old(u,v) = Gi_old(u,v+1);
                    if u+1 ~= window_size  - border_pad_width + 1
                        Gi_old(u,v+1) = Gi_old(u+1,1);
                    end
                else
                    Gi_old(u,v) = Gi_old(u, v+1);
                end

            end
        end
        % including a new value in Gi_old matrix, in verilog the index
        % logic is handled by the testbench user to pick things up from the
        % pad_R matrix that they have
        Gi_old(window_size - border_pad_width,c_size) = Max3( pad_R(row_index_for_Gi_old, col_index_for_Gi_old), pad_G(row_index_for_Gi_old, col_index_for_Gi_old), pad_B(row_index_for_Gi_old, col_index_for_Gi_old));
        
        if row_index_for_Gi_old ~= r_pad_size || col_index_for_Gi_old ~= c_pad_size - border_pad_width
            if col_index_for_Gi_old == c_pad_size - border_pad_width

                    col_index_for_Gi_old = 1 + border_pad_width;
                    row_index_for_Gi_old = row_index_for_Gi_old + 1;
            else
                col_index_for_Gi_old = col_index_for_Gi_old + 1;
            end
        end

   else
        row_index_for_Gi_old = window_size + 1;
        col_index_for_Gi_old = 1 + border_pad_width;
   end
   flag2 = 1;
    
   %% (Mirror padding) Pulling omega matrix correctly from the Pci matrix before Pci is changed at the end of clk cycle
    % use the index of output_ var instead of Pci broken var after Pci
    % filled
    
    % buffer zero pads replace Pci with clone
    if output_index_c == 1 % need to compute many thing along with top and bottom left:diagonals
        if output_index_r <= border_pad_width % need to compute upper left diagonals
            for i = 1 : 1 :  border_pad_width + output_index_r % simply copying real values from Pci
                for j = 1 : 1 : border_pad_width + 1
                    omega(i + border_pad_width - output_index_r + 1, j + border_pad_width) = Pci_bigger(i + border_pad_width - output_index_r + 1, j + border_pad_width);
                    

                end
            end
            for i = 1 : 1 : border_pad_width - output_index_r + 1 % computing upper mirror pad rows
                for j = 1 : 1 : 1 + border_pad_width
                    omega(i, j + border_pad_width) = Pci_bigger(4 + 2*border_pad_width - 2*output_index_r - i, j + border_pad_width);                
                end
            end
            
            for i = 1 : 1 :  border_pad_width + output_index_r % computing left side mirror pad columns
                for j = 1 : 1 :  border_pad_width 
                    omega(i + border_pad_width - output_index_r + 1, j) = Pci_bigger(i + border_pad_width - output_index_r + 1,  2*border_pad_width + 2 -j);
                end
            end

            for i = 1 : 1 : border_pad_width - output_index_r + 1 % computing diagonal elements up left
                for j = 1 : 1 : border_pad_width
                    omega(i, j) = Pci_bigger(4 + 2*border_pad_width - 2*output_index_r - i, 2*border_pad_width + 2 -j);                
                end
            end
        elseif output_index_r <= r_size - border_pad_width % no need to compute left bottom/upper diagonals/padrows top/bottom till here
            for i = 1 : 1 :  2*border_pad_width + 1 % simply copying real values from Pci
                for j = 1 : 1 : border_pad_width + 1
                    omega(i, j + border_pad_width) = Pci_bigger(i, j + border_pad_width);
                    

                end
            end

            for i = 1 : 1 :  2*border_pad_width + 1 % computing left side mirror pad columns
                for j = 1 : 1 :  border_pad_width 
                    omega(i , j) = Pci_bigger(i ,  2*border_pad_width + 2 -j);
                end
            end
           
        else % need to compute bottom left diagonals here
            for i = 1 : 1 :  border_pad_width + r_size - output_index_r+1 % simply copying real values from Pci
                for j = 1 : 1 : border_pad_width + 1
                    omega(i , j + border_pad_width) = Pci_bigger(i, j + border_pad_width);
                    
                end
            end
            for i = 1 : 1 : + border_pad_width - r_size + output_index_r % computing bottom mirror pad rows
                for j = 1 : 1 : 1 + border_pad_width
                    omega(2*border_pad_width + 2 - i, j + border_pad_width) = Pci_bigger(i + 2*(r_size - output_index_r), j + border_pad_width);                
                end
            end
            
            for i = 1 : 1 :  border_pad_width + r_size - output_index_r+1 % computing left side mirror pad columns
                for j = 1 : 1 :  border_pad_width 
                    omega(i , j) = Pci_bigger(i ,  2*border_pad_width + 2 -j);
                end
            end

            for i = 1 : 1 : +border_pad_width - r_size + output_index_r % computing bottom mirror pad diagonals
                for j = 1 : 1 : border_pad_width
                    omega(2*border_pad_width + 2 - i, j) = Pci_bigger(i + 2*(r_size - output_index_r),  2*border_pad_width + 2 -j);                
                end
            end            
        end

    elseif output_index_c <= c_size - border_pad_width % no diagonal issue here from right side
        if output_index_r <= border_pad_width % top pad rows fix
            for i = 1:1:window_size
                for j = 1:1:window_size
                    if j <= window_size -1
                        omega(i, j) = omega(i, j+1);
                    end
                end
            end
            % filling the last col with new real values
            for i = 1:1: border_pad_width + output_index_r
                omega(i + border_pad_width - output_index_r + 1, window_size) = Pci_bigger(i + border_pad_width - output_index_r + 1, 1+ 2*border_pad_width);
            end
            % filling the last col with mirror values
            for i = 1:1: border_pad_width - output_index_r + 1
                omega(i, window_size) = Pci_bigger(4 + 2*border_pad_width - 2*output_index_r - i , 1+ 2*border_pad_width);
            end
        elseif output_index_r <= r_size - border_pad_width % no top_pad or bottom_pad rows
            for i = 1:1:window_size
                for j = 1:1:window_size
                    if j <= window_size -1
                        omega(i, j) = omega(i, j+1);
                    end
                end
            end
            % filling the last col with new real values
            for i = 1:1: 2*border_pad_width + 1
                omega(i, window_size) = Pci_bigger(i, 1+ 2*border_pad_width);
            end

        else % pad bottom rows
             for i = 1:1:window_size
                for j = 1:1:window_size
                    if j <= window_size -1
                        omega(i, j) = omega(i, j+1);
                    end
                end
            end
            % filling the last col with new real values
            for i = 1:1: border_pad_width + r_size - output_index_r+1
                omega(i, window_size) = Pci_bigger(i, 1+ 2*border_pad_width);
            end
            % filling the last col with mirror values
            for i = 1:1: border_pad_width + output_index_r -r_size
                omega(2*border_pad_width + 2 - i, window_size) = Pci_bigger(i + 2*(r_size - output_index_r), 1+ 2*border_pad_width);
            end          
        end

    else % there might be a diagonal issue here(internal ifs) from right side
        if output_index_r <= border_pad_width % top right diagonal
             for i = 1:1:window_size
                for j = 1:1:window_size
                    if j <= window_size -1
                        omega(i, j) = omega(i, j+1);
                    end
                end
            end
            % filling the last col with mirror values
            for i = 1:1: border_pad_width + output_index_r
                omega(i + border_pad_width - output_index_r + 1, window_size) = Pci_bigger(i + border_pad_width - output_index_r + 1, 1 + 2*(c_size - output_index_c));
            end          

            for i = 1 : 1 : border_pad_width - output_index_r + 1 % computing diagonal elements up right
                
                omega(i, window_size) = Pci_bigger(4 + 2*border_pad_width - 2*output_index_r - i, 1 + 2*(c_size - output_index_c));                
                
            end            
        elseif output_index_r <= r_size - border_pad_width % no diagonal issue 
             for i = 1:1:window_size
                for j = 1:1:window_size
                    if j <= window_size -1
                        omega(i, j) = omega(i, j+1);
                    end
                end
            end
            % filling the last col with mirror values
            for i = 1:1: window_size
                omega(i, window_size) = Pci_bigger(i, 1 + 2*(c_size - output_index_c));
            end          
        
            
        else % diagonal issue from bottom right
             for i = 1:1:window_size
                for j = 1:1:window_size
                    if j <= window_size -1
                        omega(i, j) = omega(i, j+1);
                    end
                end
             end
            % filling the last col with mirror values
            for i = 1:1: border_pad_width + r_size - output_index_r+1
                omega(i, window_size) = Pci_bigger(i, 1 + 2*(c_size - output_index_c));
            end          

            for i = 1 : 1 : + border_pad_width - r_size + output_index_r % computing diagonal elements bottom right
                
                omega(2*border_pad_width + 2 - i, window_size) = Pci_bigger(i + 2*(r_size - output_index_r), 1 + 2*(c_size - output_index_c));                
                
            end                    


        end

    
    end

    if output_index_c < c_size
        output_index_c = output_index_c + 1;
    else
        output_index_c = 1;
        output_index_r = output_index_r + 1;
    end

    %% Output is finally produced

    
    % filling delta window at end depending upon if values in window are
    % completely new or not(we can use previous columns as window simply slides).

    % this if is for complete refilling of delta matrix from start.
    if pci_c_filling_index == 1
       head_for_registerset = 1;
        for k = 1:1:window_size % to iterate through all the col in window
        pair3_max_from_col_1 = Max3(delta(1,k), delta(2,k), delta(3,k));
        pair3_max_from_col_2 = Max3(delta(4, k), delta(5, k), delta(6, k));
        pair3_max_from_col_3 = Max3(delta(7, k), delta(8, k), delta(9, k));
        pair3_max_from_col_collect = Max3(pair3_max_from_col_1, pair3_max_from_col_2, pair3_max_from_col_3);
        pair3_max_from_col_final = Max3(pair3_max_from_col_collect, delta(10, k), delta(11, k));
        % add more smaller pairs3 for 11*11 window
        register_set_max_each_col(k) = pair3_max_from_col_final;
        end
        max_from_registerset_1 = Max3(register_set_max_each_col(1), register_set_max_each_col(2), register_set_max_each_col(3));
        max_from_registerset_2 = Max3(register_set_max_each_col(4), register_set_max_each_col(5), register_set_max_each_col(6));
        max_from_registerset_3 = Max3(register_set_max_each_col(7), register_set_max_each_col(8), register_set_max_each_col(9));
        max_from_registerset_collect = Max3(max_from_registerset_1,max_from_registerset_2 ,max_from_registerset_3 );
        max_from_registerset_final = Max3(register_set_max_each_col(10), register_set_max_each_col(11), max_from_registerset_collect);
        % now that delta window is ready +max val; we will compute a value of pci
        % and shift Gi matrix to include a new value


        % First shift the Pci matrix and include a new value in it:
        for u = 1:1:window_size + border_pad_width + 1
            for v = 1:1:c_size-1
                if v == c_size-1
                    Pci_bigger(u,v) = Pci_bigger(u,v+1);
                    if u+1 ~= window_size + border_pad_width + 1 + 1
                        Pci_bigger(u,v+1) = Pci_bigger(u+1,1);
                    end
                else
                    Pci_bigger(u,v) = Pci_bigger(u, v+1);
                end

            end
        end
        
        Pci_bigger(window_size + border_pad_width + 1, border_pad_width) = max_from_registerset_final;
        
        
        pci_c_filling_index = pci_c_filling_index + 1;
        
       
        
        % making the patch: delta
        for i = 1:1:1 + 2*border_pad_width
            for j = 1:1: 1+ 2*border_pad_width
                delta(i, j) = Gi(i, j); % patch about (2,2) or (6,6) always
            end
        end

        % shift left and include a new value in the Gi matrix
        for u = 1:1:window_size
            for v = 1:1:c_pad_size-1
                if v == c_pad_size-1
                    Gi(u,v) = Gi(u,v+1);
                    if u+1 ~= window_size + 1
                        Gi(u,v+1) = Gi(u+1,1);
                    end
                else
                    Gi(u,v) = Gi(u, v+1);
                end

            end
        end
        % including a new value in Gi matrix
        Gi(window_size,c_pad_size) = Max3( pad_R(row_index_for_Gi, col_index_for_Gi), pad_G(row_index_for_Gi, col_index_for_Gi), pad_B(row_index_for_Gi, col_index_for_Gi));
        % shifting the index for new values to be picked up from pad_RGB
        % for Gi
        if row_index_for_Gi ~= r_pad_size || col_index_for_Gi ~= c_size
            if col_index_for_Gi == c_size

                    col_index_for_Gi = 1;
                    row_index_for_Gi = row_index_for_Gi+1;
            else
                col_index_for_Gi = col_index_for_Gi + 1;
            end
        end

    %% This is the case of preserving and making use of old values like DP
    else



        % now we compute max values for efficient register set(add more for
        % 11*11 future matrix
        % now we compute max values for efficient register set(add more for
        % 11*11 future matrix
        temp_pair3_forefficient_colmax_1 = Max3(delta(1, window_size), delta(2, window_size), delta(3, window_size));
        temp_pair3_forefficient_colmax_2 = Max3(delta(4, window_size), delta(5, window_size), delta(6, window_size));
        temp_pair3_forefficient_colmax_3 = Max3(delta(7, window_size), delta(8, window_size), delta(9, window_size));
        temp_pair3_forefficient_colmax_collect = Max3(temp_pair3_forefficient_colmax_1, temp_pair3_forefficient_colmax_2, temp_pair3_forefficient_colmax_3);
        temp_pair3_forefficient_colmax_final = Max3(temp_pair3_forefficient_colmax_collect, delta(10, window_size), delta(11, window_size));

        register_set_max_each_col(head_for_registerset) = temp_pair3_forefficient_colmax_final;
        % might need to add head var in comb block itself
        if head_for_registerset == window_size % this was made for pipelining, does not work properly in fsm, might need to add extra code or recalc all in verilog comb block
            head_for_registerset = 1;
        else
            head_for_registerset = head_for_registerset + 1;
        end
        % add more max_temp_registers more for 11*11 matrix
        max_from_registerset_1 = Max3(register_set_max_each_col(1), register_set_max_each_col(2), register_set_max_each_col(3));
        max_from_registerset_2 = Max3(register_set_max_each_col(4), register_set_max_each_col(5), register_set_max_each_col(6));
        max_from_registerset_3 = Max3(register_set_max_each_col(7), register_set_max_each_col(8), register_set_max_each_col(9));
        max_from_registerset_collect = Max3(max_from_registerset_1,max_from_registerset_2 ,max_from_registerset_3 );
        max_from_registerset_final = Max3(register_set_max_each_col(10), register_set_max_each_col(11), max_from_registerset_collect);



        % First shift the Pci matrix and include a new value in it:
        for u = 1:1:window_size + border_pad_width + 1
            for v = 1:1:c_size-1
                if v == c_size-1
                    Pci_bigger(u,v) = Pci_bigger(u,v+1);
                    if u+1 ~= window_size + border_pad_width + 1 + 1
                        Pci_bigger(u,v+1) = Pci_bigger(u+1,1);
                    end
                else
                    Pci_bigger(u,v) = Pci_bigger(u, v+1);
                end

            end
        end
        
        Pci_bigger(window_size + border_pad_width + 1, border_pad_width) = max_from_registerset_final;


       % If the delta matrix end of a row then it needs to precompute all
       % the values from Gi as it will go to the begin of the next row and
       % so the head pointer will point to the first index
       if (pci_c_filling_index ~= c_size)
        for i = 1:1:window_size
            for j = 1:1:window_size
                if j <= window_size -1
                    delta(i, j) = delta(i, j+1);
                end
            end
        end
        % filling the last col with new values
        for i = 1:1:window_size
            delta(i, window_size) = Gi(i, 1+ 2*border_pad_width);
        end
       else
           head_for_registerset = 1; % take care of this in verilog
        % making the patch: delta
        for i = 1:1:1 + 2*border_pad_width
            for j = 1:1: 1+ 2*border_pad_width
                delta(i, j) = Gi(i, j); % patch about (2,2) or (6,6) always
            end
        end

       end
      %% to decide whether to shift left and include a new value in the Gi matrix
      % or shift left 3 times so other things in this fsm states need to be
      % paused
       if pci_c_filling_index ~= c_size - 1
        % we are somewhere in middle of the Gi line buff values. One new
        % delta col in place of old one only in registerset for now. We
        % don't shift 3 times here.


        % to shift and include new value for Gi
        for u = 1:1:window_size
            for v = 1:1:c_pad_size-1
                if v == c_pad_size-1
                    Gi(u,v) = Gi(u,v+1);
                    if u+1 ~= 1 + window_size
                        Gi(u,v+1) = Gi(u+1,1);
                    end
                else
                    Gi(u,v) = Gi(u, v+1);
                end

            end
        end
        % including a new value in Gi matrix

        Gi(window_size,c_pad_size) = Max3( pad_R(row_index_for_Gi, col_index_for_Gi), pad_G(row_index_for_Gi, col_index_for_Gi), pad_B(row_index_for_Gi, col_index_for_Gi));
        % shifting the index for new values to be picked up from pad_RGB
        % for Gi
        if row_index_for_Gi ~= r_pad_size || col_index_for_Gi ~= c_size
            if col_index_for_Gi == c_size
                col_index_for_Gi = 1;
                row_index_for_Gi = row_index_for_Gi+1;
            else
                col_index_for_Gi = col_index_for_Gi + 1;
            end
        end
        if pci_c_filling_index == c_size && (pci_r_filling_index + 1 <= r_size)
            pci_c_filling_index = 1;
            pci_r_filling_index = pci_r_filling_index + 1;
        elseif pci_c_filling_index + 1 <= c_size
            pci_c_filling_index = pci_c_filling_index + 1  ;
        end
       else
        %% Now we need to shift Gi buffer 3 times
           col_index_for_Gi 

        % this is for one output per clock cycle shift technique
        for u = 1:1:window_size
            for v = 1:1:c_pad_size
                if u == window_size && v> c_pad_size - (1+2*border_pad_width)
                ;
                else
                    if v + (1+2*border_pad_width) <= c_pad_size
                        Gi(u,v) = Gi(u, v + (1+2*border_pad_width));
                    else
                        Gi(u, v) = Gi(u+1, (1+2*border_pad_width) - (c_pad_size-v));
                    end                                                                                                                                                   

                end

            end
        end
        % including a new value in Gi matrix
        % IMP: For this to be success, have many i/p ports that give out
        % ahead/future values of pad matrices. ALso, on this operation, give an
        % output with extra output port to tell it to the consumer that you
        % need to shift your streaming by 1+2*border_width too.
        temp = c_pad_size - (2*border_pad_width); % this is error prone, if pad_R goes next row, check for 11*11
        Gi;
        Pci_bigger;
        for i = c_pad_size - (2*border_pad_width) : 1 : (c_pad_size)
            Gi(window_size, i) = Max3( pad_R(row_index_for_Gi, col_index_for_Gi +(i - temp)), pad_G(row_index_for_Gi, col_index_for_Gi +(i - temp)), pad_B(row_index_for_Gi, col_index_for_Gi + (i - temp)));
        end
        
        % Error prone: I am not sure about this
        if row_index_for_Gi ~= r_pad_size
            row_index_for_Gi = row_index_for_Gi + 1;
            col_index_for_Gi = 1;
        end
        if pci_c_filling_index == c_size && (pci_r_filling_index + 1 <= r_size)
            pci_c_filling_index = 1;
            pci_r_filling_index = pci_r_filling_index + 1;
        elseif pci_c_filling_index + 1 <= c_size
            pci_c_filling_index = pci_c_filling_index + 1  ;
        end

       end
  

    end
    head_for_registerset;
    register_set_max_each_col;
    Pci_bigger;
    Gi;
    delta;
    if output_index_r > r_size   % implement it as if conditional for "done" fsm state
        break; % Exit the loop if we have filled all rows
    end
    
end



function result = Max3(R, G, B)
if R >= G && R >= B
    result = R;
elseif G >= B
    result = G;
else
    result = B;
end
end
function result2 = Min3(x, y, z)
if x<= y && x<= z
    result2 = x;
elseif y<=z
    result2 = y;
else 
    result2 = z;
end
end
output_R = uint8(output_R);
output_G = uint8(output_G);
output_B = uint8(output_B);

output_img(:,:,1) = output_R;
output_img(:,:,2) = output_G;
output_img(:,:,3) = output_B;

figure;
imshow(img);
title('original');

figure;
imshow(output_img);
title('processed output');
