**Ask claude(max power mode) to evaluate whether: code is parameterized completely(like in if statements, for/while loops, etc.) so that it may directly work for 11\*11 window and a 1920\*1080p image or did miss somethings?**

**To do things or forgot:**

1. **lut\[D] = 905;**

**scale 1/d by 2^(24 or something else) manually, and store this in lut\[D] = scaled.**

Finally do **Fm = (N×LUT\[D])>> 24;,**

**2. read all the comments in the matlab code, they are there for you to write Verilog. Repair error prone thing as mentioned in comments**

### **Operations:**











**Learnings/Challenges:(Put some of these in synth checklist)-check reset in all blocks 1 or 0**

1. If the design is large, break it into smaller parts and write the algorithm in a concise, step-by-step manner. I found it helpful to first think through a rough layout in my mind, then quickly write it down on paper and verify it using AI debugging support.

2. Realtime mirror padding was one of the biggest challenges for me. I handled it by asking GPT to show a padded image with elements represented as 2D index values. Whenever I was confused about which number should appear at a specific index, I wrote out the required values for all loop iterations. That made the implementation much easier. I also referred to Claude’s derivation of mirror-pad row source indexing on GitHub.

3. Difference between [0:window_size-1] and [window_size-1:0]:
   For an unpacked array (dimensions written after the variable name), there is no structural or hardware difference between [0:window_size-1] and [window_size-1:0]; both synthesize to the same memory. The only difference is how the indices are numbered. With [0:window_size-1], the first element is indexed as 0 and the last as window_size-1, which matches C, MATLAB, and Python-style indexing and makes loops like for (i = 0; i < window_size; i++) natural. With [window_size-1:0], the first element has the highest index and the last element is indexed as 0. Some designers prefer this for consistency with vectors, but it does not reverse the physical memory or change the synthesized hardware.

4. In Verilog, statements such as forever, repeat, while, for, and timing controls like # and @ are procedural statements, meaning they describe behavior that executes over time. Procedural statements are only valid inside procedural blocks such as initial or always, which define when and how simulation begins. Outside these blocks, Verilog expects only module declarations such as ports, wires, registers, parameters, instances, and continuous assignments, not executable code. Since a standalone forever loop has no execution context or starting point, the language syntax forbids it. This separation keeps the distinction clear between hardware structure outside procedural blocks and behavioral execution inside them.

5. Challenge/Learning: Index logic changes in Verilog. Simply subtracting 1 from most variables does not always guarantee correct logic. This becomes especially important when using 0-based indexing for matrices or arrays in Verilog. In MATLAB, adding or subtracting 1 changes the variable by 1, but if we add or subtract 0, the value does not change, which can lead to incorrect logical expressions. To solve this, we need to add or subtract 1 separately in index positions, or create the matrix with a base index of 1 to match MATLAB.








`timescale 1ns / 1ps



//////////////////////////////////////////////////////////////////////////////////



// Company: 



// Engineer: 



// 



// Create Date: 08.07.2026 17:34:45



// Design Name: 



// Module Name: Maximum\_channel\_rgb\_input



// Project Name: 



// Target Devices: 



// Tool Versions: 



// Description: 



// 



// Dependencies: 



// 



// Revision:



// Revision 0.01 - File Created



// Additional Comments:



// 



//////////////////////////////////////////////////////////////////////////////////



module Maximum\_channel\_rgb\_input #(



&#x20;   parameter data\_width = 8,



&#x20;   parameter r\_size = 4,



&#x20;   parameter c\_size = 4,



&#x20;   parameter window\_size = 3,



&#x20;   parameter border\_pad\_width = (window\_size-1)>>1,



&#x20;   parameter r\_pad\_size = r\_size + 2\*border\_pad\_width,



&#x20;   parameter c\_pad\_size = c\_size + 2\*border\_pad\_width



)(



&#x20;   input clk,



&#x20;   input rst\_n,



&#x20;   input \[data\_width-1:0] R\_tb,// padded matrices come from TB



&#x20;   input \[data\_width-1:0] G\_tb,



&#x20;   input \[data\_width-1:0] B\_tb



);



reg \[data\_width-1:0] Gi \[0:window\_size-1]\[0:c\_pad\_size-1]; // this is simply a line buffer



integer row\_index\_for\_Gi;



integer col\_index\_for\_Gi;



integer i;



integer j;



integer u;



integer v;



endmodule



Coming back to my retinex project and its conversion from matlab to verilog. Please convert this into verilog code using always clock block. Key point to note while doing so: Remove every other assignment except for the Gi assignments present there. Keep important if/for/else statements that have Gi in them somewhere nested inside.







Logic changes needed:



%% fsm state to build the initial line buffer of Gi = max(R,G,B); till delta patch size:



Gi = zeros(window\_size,c\_pad\_size); % Gi is actually Gi\_pad



% one isssue is that it will take 10 extra clock cycles for each row of



% image as we will accelerate Gi matrix to add 2\*border\*width + 1 extra(as a part of process itself)



% lets perform right shift to fill the Gi matrix



row\_index\_for\_Gi = window\_size;



col\_index\_for\_Gi = c\_pad\_size;



for i = 1:1:window\_size\*c\_pad\_size



% this is for right shift every outer loop iteration



for u = window\_size:-1:1



for v = c\_pad\_size:-1:1



if v == 1 \&\& u \~= 1



&#x20;           Gi(u, v) = Gi(u-1, c\_pad\_size);



elseif (v-1 \~=0)



&#x20;           Gi(u, v)  = Gi(u, v-1);



end



end



end



% there is no ternary in matlab but do in hdl and try function



% To insert the max element at the



if pad\_R(row\_index\_for\_Gi,col\_index\_for\_Gi) >= pad\_G(row\_index\_for\_Gi,col\_index\_for\_Gi) \&\& pad\_R(row\_index\_for\_Gi,col\_index\_for\_Gi) >= pad\_B(row\_index\_for\_Gi,col\_index\_for\_Gi)



&#x20;       Gi(1,1) = pad\_R(row\_index\_for\_Gi,col\_index\_for\_Gi);



elseif pad\_G(row\_index\_for\_Gi,col\_index\_for\_Gi) >= pad\_R(row\_index\_for\_Gi,col\_index\_for\_Gi) \&\& pad\_G(row\_index\_for\_Gi,col\_index\_for\_Gi) >= pad\_B(row\_index\_for\_Gi,col\_index\_for\_Gi)



&#x20;       Gi(1,1) = pad\_G(row\_index\_for\_Gi,col\_index\_for\_Gi);



else



&#x20;       Gi(1,1) = pad\_B(row\_index\_for\_Gi,col\_index\_for\_Gi);



end



% this keeps the index to pull from rg and b padded matrices



if col\_index\_for\_Gi >1



&#x20;       col\_index\_for\_Gi  = col\_index\_for\_Gi - 1;



else



&#x20;       col\_index\_for\_Gi = c\_pad\_size;



&#x20;       row\_index\_for\_Gi = row\_index\_for\_Gi - 1;



end



end



% now that basic Gi is computed, we will fill the Pci matrix till omega is



% fulfilled







I want you to remove this logic. What I want to do is just do left shift instead of the initial right shift, make changes to the 2nd block so that from the beginning itself the block runs the same way(left sshift and insert) forever. TB will give me pixels one by one pad\_matrices(except for the time when Gi needs to shift 3 times). I am planning my retinex algo structurally and implementing pipelining. I will keep the logic of different functional blocks seperate and connect them in the end.



I don't want this block to depend on pci\_c\_filling\_index, I want it to depend on its own variables since I will be making the Pci logic seperate in another .v module.



if pci\_c\_filling\_index \~= c\_size - 1



This is to be replaced by col\_index\_for\_Gi logic where if  pci\_c\_filling\_index == c\_size - 1, 



Then at that moment: col\_index\_for\_Gi == c\_pad\_size - 2\*border\_pad\_width



if pci\_c\_filling\_index == 1: I don't think that this if and else are needed, you can see that inside bothof them, we have the same Gi logic implementation, only differentiated by col\_index\_for\_Gi == c\_pad\_size - 2\*border\_pad\_width, so you can remove that if and else.



Please remove redundant things in this block(present in matlab), you can remove some other if and else too if you think they are redundant.



Also, do the -1 wherever required becauese of the verilog initial start from 0 index compared '1' that is found in matlab.























Don't change any logic except for the changes that I have mentioned.

## Working code for 3\*3 window and 4\*4 image matrix.

clear; clc;



% Define RGB image

R = \[20 40 60 80; 30 50 70 90; 40 60 80 100; 50 70 90 110];

G = \[10 30 50 70; 20 40 60 80; 30 50 70 90; 40 60 80 100];

B = \[5 25 45 65; 15 35 55 75; 25 45 65 85; 35 55 75 95];

% this is present in the tb of our design and not declared in the design.v

r\_size = size(R, 1); % size of output/input image

c\_size = size(R, 2); % parameterize everything

window\_size = 3; % taken 11 in verilog

border\_pad\_width = bitshift(window\_size-1,-1);



% mirror padding

r\_pad\_size = r\_size + 2\*border\_pad\_width;

c\_pad\_size = c\_size + 2\*border\_pad\_width;

pad\_R = zeros(r\_pad\_size, c\_pad\_size);

pad\_G = zeros(r\_pad\_size, c\_pad\_size);

pad\_B = zeros(r\_pad\_size, c\_pad\_size);

% here, we fill up the actual unpadded portion directly

for i = 1:1:r\_size

&#x20;   for j = 1:1:c\_size

&#x20;       pad\_R(i+border\_pad\_width, j + border\_pad\_width) = R(i,j);

&#x20;       pad\_G(i+border\_pad\_width, j + border\_pad\_width) = G(i,j);

&#x20;       pad\_B(i+border\_pad\_width, j + border\_pad\_width) = B(i,j);

&#x20;   end

end

% proceding with mirror paddind without accounting for diagonal padding yet

% 2 reference columns for reflection(rename in verilog)

left\_ref = 1+border\_pad\_width;

right\_ref = 1+border\_pad\_width+c\_size-1;



moving\_left\_padder\_col = left\_ref-1; move\_right\_for\_leftpadder = left\_ref+1;

moving\_right\_padder\_col = right\_ref+1; move\_left\_for\_rightpadder = right\_ref-1;

% 2 ref for rows

up\_ref = 1+ border\_pad\_width;

down\_ref = r\_pad\_size - border\_pad\_width;

moving\_up\_padder\_row = up\_ref -1; move\_down\_for\_uppadder = up\_ref + 1;

moving\_down\_padder\_row = down\_ref +1; move\_up\_for\_downpadder = down\_ref - 1;

while (true)

&#x20;   if(moving\_left\_padder\_col == 0)

&#x20;       break;

&#x20;   end

&#x20;   % filling columns left and right

&#x20;   for i = 1+border\_pad\_width:1:r\_pad\_size - border\_pad\_width

&#x20;       pad\_R(i, moving\_left\_padder\_col) = pad\_R(i, move\_right\_for\_leftpadder);

&#x20;       pad\_G(i, moving\_left\_padder\_col) = pad\_G(i, move\_right\_for\_leftpadder);

&#x20;       pad\_B(i, moving\_left\_padder\_col) = pad\_B(i, move\_right\_for\_leftpadder);

&#x20;       pad\_R(i, moving\_right\_padder\_col) = pad\_R(i, move\_left\_for\_rightpadder);

&#x20;       pad\_G(i, moving\_right\_padder\_col) = pad\_G(i, move\_left\_for\_rightpadder);

&#x20;       pad\_B(i, moving\_right\_padder\_col) = pad\_B(i, move\_left\_for\_rightpadder);



&#x20;

&#x20;

&#x20;   end

&#x20;   % filling rows top and bottom

&#x20;   for j = 1+border\_pad\_width:1:c\_pad\_size - border\_pad\_width

&#x20;       pad\_R(moving\_up\_padder\_row, j) = pad\_R(move\_down\_for\_uppadder,j);

&#x20;       pad\_G(moving\_up\_padder\_row, j) = pad\_G(move\_down\_for\_uppadder,j);

&#x20;       pad\_B(moving\_up\_padder\_row, j) = pad\_B(move\_down\_for\_uppadder,j);

&#x20;       pad\_R(moving\_down\_padder\_row, j) = pad\_R(move\_up\_for\_downpadder, j);

&#x20;       pad\_G(moving\_down\_padder\_row, j) = pad\_G(move\_up\_for\_downpadder, j);

&#x20;       pad\_B(moving\_down\_padder\_row, j) = pad\_B(move\_up\_for\_downpadder, j);

&#x20;   end

&#x20;   temp = 1;

&#x20;   % handling diagonals

&#x20;   for k = left\_ref-1:1:1 % for iterating the columns

&#x20;       pad\_R(moving\_up\_padder\_row,k) = pad\_R(moving\_up\_padder\_row,left\_ref-k+2);

&#x20;       pad\_R(moving\_up\_padder\_row,right\_ref+left\_ref-k) = pad\_R(moving\_up\_padder\_row,right\_ref-temp);

&#x20;       pad\_R(moving\_down\_padder\_row,k) = pad\_R(moving\_down\_padder\_row,left\_ref-k+2);

&#x20;       pad\_R(moving\_down\_padder\_row,right\_ref+left\_ref-k) = pad\_R(moving\_down\_padder\_row,right\_ref-temp);

&#x20;       temp = temp + 1;



&#x20;   end





&#x20;   moving\_left\_padder\_col = moving\_left\_padder\_col - 1;

&#x20;   moving\_right\_padder\_col = moving\_right\_padder\_col + 1;

&#x20;   move\_right\_for\_leftpadder = move\_right\_for\_leftpadder + 1;

&#x20;   move\_left\_for\_rightpadder = move\_left\_for\_rightpadder - 1;

&#x20;   moving\_up\_padder\_row = moving\_up\_padder\_row + 1;

&#x20;   move\_down\_for\_uppadder = move\_down\_for\_uppadder -1;

&#x20;   moving\_down\_padder\_row = moving\_down\_padder\_row -1;

&#x20;   move\_up\_for\_downpadder = move\_up\_for\_downpadder + 1;



end



%% fsm state to build the initial line buffer of Gi = max(R,G,B); till delta patch size:

Gi = zeros(window\_size,c\_pad\_size); % Gi is actually Gi\_pad

% one isssue is that it will take 10 extra clock cycles for each row of

% image as we will accelerate Gi matrix to add 2\*border\*width + 1 extra(as a part of process itself)



% lets perform right shift to fill the Gi matrix



row\_index\_for\_Gi = window\_size;

col\_index\_for\_Gi = c\_pad\_size;



for i = 1:1:window\_size\*c\_pad\_size



&#x20;   % this is for right shift every outer loop iteration

&#x20;   for u = window\_size:-1:1

&#x20;       for v = c\_pad\_size:-1:1

&#x20;           if v == 1 \&\& u \~= 1

&#x20;           Gi(u, v) = Gi(u-1, c\_pad\_size);

&#x20;           elseif (v-1 \~=0)

&#x20;

&#x20;           Gi(u, v)  = Gi(u, v-1);

&#x20;           end



&#x20;        end

&#x20;   end



&#x20;   % there is no ternary in matlab but do in hdl and try function

&#x20;   % To insert the max element at the

&#x20;   if pad\_R(row\_index\_for\_Gi,col\_index\_for\_Gi) >= pad\_G(row\_index\_for\_Gi,col\_index\_for\_Gi) \&\& pad\_R(row\_index\_for\_Gi,col\_index\_for\_Gi) >= pad\_B(row\_index\_for\_Gi,col\_index\_for\_Gi)

&#x20;       Gi(1,1) = pad\_R(row\_index\_for\_Gi,col\_index\_for\_Gi);

&#x20;   elseif pad\_G(row\_index\_for\_Gi,col\_index\_for\_Gi) >= pad\_R(row\_index\_for\_Gi,col\_index\_for\_Gi) \&\& pad\_G(row\_index\_for\_Gi,col\_index\_for\_Gi) >= pad\_B(row\_index\_for\_Gi,col\_index\_for\_Gi)

&#x20;       Gi(1,1) = pad\_G(row\_index\_for\_Gi,col\_index\_for\_Gi);

&#x20;   else

&#x20;       Gi(1,1) = pad\_B(row\_index\_for\_Gi,col\_index\_for\_Gi);

&#x20;   end



&#x20;   % this keeps the index to pull from rg and b padded matrices

&#x20;   if col\_index\_for\_Gi >1

&#x20;       col\_index\_for\_Gi  = col\_index\_for\_Gi - 1;

&#x20;   else

&#x20;       col\_index\_for\_Gi = c\_pad\_size;

&#x20;       row\_index\_for\_Gi = row\_index\_for\_Gi - 1;

&#x20;   end

&#x20;

end

% now that basic Gi is computed, we will fill the Pci matrix till omega is

% fulfilled



Gi;



%% NO extra waiting state added to make it fpga clock compatible, delta window

% should be ready before the loop starts at it needs to be used in the loop



Gi\_old = zeros(window\_size -  border\_pad\_width, c\_size);

delta = zeros(window\_size, window\_size);



pci\_r\_filling\_index = 1;

pci\_c\_filling\_index = 1;

pair3\_max\_from\_col\_1 = 0; % include extra for 11\*11 matrix

register\_set\_max\_each\_col = zeros(1, window\_size);

max\_from\_registerset\_1 = 0;

Pci = zeros(window\_size,c\_size);

row\_index\_for\_Gi = 1+window\_size;

col\_index\_for\_Gi = 1;

head\_for\_registerset = 1;

flag = 1; % reset this and other things in the final done fsm state





%% next fsm state to fill Pci(course illumination) line buffer till the omega window size



while (true)

&#x20;   % filling delta window at end depending upon if values in window are

&#x20;   % completely new or not(we can use previous columns as window simply slides).



&#x20;   % this if is for complete refilling of delta matrix from start.

&#x20;   if pci\_c\_filling\_index == 1

&#x20;      head\_for\_registerset = 1;

&#x20;      if flag == 0 % to prevent this from running and computing anything yet for the first time and to wait for next edge

&#x20;       for k = 1:1:window\_size % to iterate through all the col in window

&#x20;       pair3\_max\_from\_col\_1 = Max3(delta(1,k), delta(2,k), delta(3,k));

&#x20;       % add more smaller pairs3 for 11\*11 window

&#x20;       register\_set\_max\_each\_col(k) = pair3\_max\_from\_col\_1;

&#x20;       end

&#x20;       max\_from\_registerset\_1 = Max3(register\_set\_max\_each\_col(1), register\_set\_max\_each\_col(2), register\_set\_max\_each\_col(3));

&#x20;       % now that delta window is ready +max val; we will compute a value of pci

&#x20;       % and shift Gi matrix to include a new value

&#x20;       Pci(pci\_r\_filling\_index,pci\_c\_filling\_index) = max\_from\_registerset\_1;

&#x20;       pci\_c\_filling\_index = pci\_c\_filling\_index + 1;

&#x20;      else

&#x20;          for i = 1:1:window\_size - border\_pad\_width

&#x20;              for j = 1:1:c\_size

&#x20;                  Gi\_old(i, j) = Gi(i + border\_pad\_width, j + border\_pad\_width);

&#x20;              end

&#x20;          end

&#x20;      end

&#x20;       flag = 0;

&#x20;       % making the patch: delta

&#x20;       for i = 1:1:1 + 2\*border\_pad\_width

&#x20;           for j = 1:1: 1+ 2\*border\_pad\_width

&#x20;               delta(i, j) = Gi(i, j); % patch about (2,2) or (6,6) always

&#x20;           end

&#x20;       end



&#x20;       % shift left and include a new value in the Gi matrix

&#x20;       for u = 1:1:window\_size

&#x20;           for v = 1:1:c\_pad\_size-1

&#x20;               if v == c\_pad\_size-1

&#x20;                   Gi(u,v) = Gi(u,v+1);

&#x20;                   if u+1 \~= window\_size + 1

&#x20;                       Gi(u,v+1) = Gi(u+1,1);

&#x20;                   end

&#x20;               else

&#x20;                   Gi(u,v) = Gi(u, v+1);

&#x20;               end



&#x20;           end

&#x20;       end

&#x20;       % including a new value in Gi matrix

&#x20;       Gi(window\_size,c\_pad\_size) = Max3( pad\_R(row\_index\_for\_Gi, col\_index\_for\_Gi), pad\_G(row\_index\_for\_Gi, col\_index\_for\_Gi), pad\_B(row\_index\_for\_Gi, col\_index\_for\_Gi));

&#x20;       % shifting the index for new values to be picked up from pad\_RGB

&#x20;       % for Gi

&#x20;       if row\_index\_for\_Gi \~= r\_pad\_size || col\_index\_for\_Gi \~= c\_size

&#x20;           if col\_index\_for\_Gi == c\_size



&#x20;                   col\_index\_for\_Gi = 1;

&#x20;                   row\_index\_for\_Gi = row\_index\_for\_Gi+1;

&#x20;           else

&#x20;               col\_index\_for\_Gi = col\_index\_for\_Gi + 1;

&#x20;           end

&#x20;       end



&#x20;   %% This is the case of preserving and making use of old values like DP

&#x20;   else







&#x20;       % now we compute max values for efficient register set(add more for

&#x20;       % 11\*11 future matrix

&#x20;       temp\_pair3\_forefficient\_colmax = Max3(delta(1, window\_size), delta(2, window\_size), delta(3, window\_size));



&#x20;       register\_set\_max\_each\_col(head\_for\_registerset) = temp\_pair3\_forefficient\_colmax;

&#x20;       % might need to add head var in comb block itself

&#x20;       if head\_for\_registerset == window\_size % this was made for pipelining, does not work properly in fsm, might need to add extra code or recalc all in verilog comb block

&#x20;           head\_for\_registerset = 1;

&#x20;       else

&#x20;           head\_for\_registerset = head\_for\_registerset + 1;

&#x20;       end

&#x20;       % add more max\_temp\_registers more for 11\*11 matrix

&#x20;       max\_from\_registerset\_1 = Max3(register\_set\_max\_each\_col(1), register\_set\_max\_each\_col(2), register\_set\_max\_each\_col(3));

&#x20;       % now that delta window is ready +max val; we will compute a value of pci

&#x20;       % and shift Gi matrix to include a new value

&#x20;       Pci(pci\_r\_filling\_index,pci\_c\_filling\_index) = max\_from\_registerset\_1;

&#x20;      % If the delta matrix end of a row then it needs to precompute all

&#x20;      % the values from Gi as it will go to the begin of the next row and

&#x20;      % so the head pointer will point to the first index

&#x20;      if (pci\_c\_filling\_index \~= c\_size)

&#x20;       for i = 1:1:window\_size

&#x20;           for j = 1:1:window\_size

&#x20;               if j <= window\_size -1

&#x20;                   delta(i, j) = delta(i, j+1);

&#x20;               end

&#x20;           end

&#x20;       end

&#x20;       % filling the last col with new values

&#x20;       for i = 1:1:window\_size

&#x20;           delta(i, window\_size) = Gi(i, 1+ 2\*border\_pad\_width);

&#x20;       end

&#x20;      else

&#x20;

&#x20;          head\_for\_registerset = 1; % take care of this in verilog

&#x20;       % making the patch: delta

&#x20;       for i = 1:1:1 + 2\*border\_pad\_width

&#x20;           for j = 1:1: 1+ 2\*border\_pad\_width

&#x20;               delta(i, j) = Gi(i, j); % patch about (2,2) or (6,6) always

&#x20;           end

&#x20;       end



&#x20;      end

&#x20;     %% to decide whether to shift left and include a new value in the Gi matrix

&#x20;     % or shift left 3 times so other things in this fsm states need to be

&#x20;     % paused

&#x20;      if pci\_c\_filling\_index \~= c\_size - 1

&#x20;       % we are somewhere in middle of the Gi line buff values. One new

&#x20;       % delta col in place of old one only in registerset for now. We

&#x20;       % don't shift 3 times here.





&#x20;       % to shift and include new value for Gi

&#x20;       for u = 1:1:window\_size

&#x20;           for v = 1:1:c\_pad\_size-1

&#x20;               if v == c\_pad\_size-1

&#x20;                   Gi(u,v) = Gi(u,v+1);

&#x20;                   if u+1 \~= 1 + window\_size

&#x20;                       Gi(u,v+1) = Gi(u+1,1);

&#x20;                   end

&#x20;               else

&#x20;                   Gi(u,v) = Gi(u, v+1);

&#x20;               end



&#x20;           end

&#x20;       end

&#x20;       % including a new value in Gi matrix



&#x20;       Gi(window\_size,c\_pad\_size) = Max3( pad\_R(row\_index\_for\_Gi, col\_index\_for\_Gi), pad\_G(row\_index\_for\_Gi, col\_index\_for\_Gi), pad\_B(row\_index\_for\_Gi, col\_index\_for\_Gi));

&#x20;       % shifting the index for new values to be picked up from pad\_RGB

&#x20;       % for Gi

&#x20;       if row\_index\_for\_Gi \~= r\_pad\_size || col\_index\_for\_Gi \~= c\_size

&#x20;           if col\_index\_for\_Gi == c\_size

&#x20;               col\_index\_for\_Gi = 1;

&#x20;               row\_index\_for\_Gi = row\_index\_for\_Gi+1;

&#x20;           else

&#x20;               col\_index\_for\_Gi = col\_index\_for\_Gi + 1;

&#x20;           end

&#x20;       end

&#x20;       if pci\_c\_filling\_index == c\_size

&#x20;           pci\_c\_filling\_index = 1;

&#x20;           pci\_r\_filling\_index = pci\_r\_filling\_index + 1;

&#x20;       else

&#x20;           pci\_c\_filling\_index = pci\_c\_filling\_index + 1  ;

&#x20;       end

&#x20;      else

&#x20;       %% Now we need to shift Gi buffer 3 times

&#x20;



&#x20;       % this is for one output per clock cycle shift technique

&#x20;       for u = 1:1:window\_size

&#x20;           for v = 1:1:c\_pad\_size

&#x20;               if u == window\_size \&\& v> c\_pad\_size - (1+2\*border\_pad\_width)

&#x20;               ;

&#x20;               else

&#x20;                   if v + (1+2\*border\_pad\_width) <= c\_pad\_size

&#x20;                       Gi(u,v) = Gi(u, v + (1+2\*border\_pad\_width));

&#x20;                   else

&#x20;                       Gi(u, v) = Gi(u+1, (1+2\*border\_pad\_width) - (c\_pad\_size-v));

&#x20;                   end



&#x20;               end



&#x20;           end

&#x20;       end

&#x20;       % including a new value in Gi matrix

&#x20;       % IMP: For this to be success, have many i/p ports that give out

&#x20;       % ahead/future values of pad matrices. ALso, on this operation, give an

&#x20;       % output with extra output port to tell it to the consumer that you

&#x20;       % need to shift your streaming by 1+2\*border\_width too.

&#x20;       temp = c\_pad\_size - (2\*border\_pad\_width); % this is error prone, if pad\_R goes next row, check for 11\*11

&#x20;       Gi;

&#x20;       Pci;

&#x20;       for i = c\_pad\_size - (2\*border\_pad\_width) : 1 : (c\_pad\_size)

&#x20;           Gi(window\_size, i) = Max3( pad\_R(row\_index\_for\_Gi, col\_index\_for\_Gi +(i - temp)), pad\_G(row\_index\_for\_Gi, col\_index\_for\_Gi +(i - temp)), pad\_B(row\_index\_for\_Gi, col\_index\_for\_Gi + (i - temp)));

&#x20;       end

&#x20;

&#x20;       % Error prone: I am not sure about this

&#x20;       if row\_index\_for\_Gi \~= r\_pad\_size

&#x20;           row\_index\_for\_Gi = row\_index\_for\_Gi + 1;

&#x20;           col\_index\_for\_Gi = 1;

&#x20;       end

&#x20;       if pci\_c\_filling\_index == c\_size

&#x20;           pci\_c\_filling\_index = 1;

&#x20;           pci\_r\_filling\_index = pci\_r\_filling\_index + 1;

&#x20;       else

&#x20;           pci\_c\_filling\_index = pci\_c\_filling\_index + 1  ;

&#x20;       end



&#x20;      end

&#x20;



&#x20;   end

&#x20;   head\_for\_registerset;

&#x20;   register\_set\_max\_each\_col;

&#x20;   Pci;

&#x20;   Gi;

&#x20;   delta;

&#x20;   if pci\_r\_filling\_index > window\_size

&#x20;       break; % Exit the loop if we have filled all rows

&#x20;   end

end



Pci;

Gi;

delta;

;

Gi\_old;

Pci\_bigger = zeros(window\_size + 1 + border\_pad\_width, c\_size);

%% extra fsm state added to construct a Pci\_bigger matrix out of Pci matrix

% in order to have x,y for output evaluation always at 1+border\_pad\_width

% position

temp\_index\_r = 1;  temp\_index\_c = 1;

for i = 1 : 1 : window\_size + 1 + border\_pad\_width

&#x20;   for j = 1 : 1 : c\_size

&#x20;

&#x20;       if (i >= border\_pad\_width)

&#x20;           if i == border\_pad\_width + 1 \&\& j >= border\_pad\_width + 1

&#x20;               Pci\_bigger(i, j) = Pci(temp\_index\_r, temp\_index\_c);

&#x20;               if temp\_index\_c < c\_size

&#x20;                   temp\_index\_c = temp\_index\_c + 1;

&#x20;               elseif  (temp\_index\_r + 1) <= (window\_size)

&#x20;                   temp\_index\_r = temp\_index\_r + 1;

&#x20;                   temp\_index\_c = 1;

&#x20;               end

&#x20;           elseif i>= border\_pad\_width + 2 \&\& i <= window\_size + border\_pad\_width

&#x20;               Pci\_bigger(i, j) = Pci(temp\_index\_r, temp\_index\_c);

&#x20;               if temp\_index\_c < c\_size

&#x20;                   temp\_index\_c = temp\_index\_c + 1;

&#x20;               elseif  (temp\_index\_r + 1) <= (window\_size)

&#x20;                   temp\_index\_r = temp\_index\_r + 1;

&#x20;                   temp\_index\_c = 1;

&#x20;               end

&#x20;           elseif i ==  window\_size + border\_pad\_width + 1 \&\& j <= border\_pad\_width

&#x20;               Pci\_bigger(i, j) = Pci(temp\_index\_r, temp\_index\_c);

&#x20;               if temp\_index\_c < c\_size

&#x20;                   temp\_index\_c = temp\_index\_c + 1;

&#x20;               elseif  (temp\_index\_r + 1) <= (window\_size)

&#x20;                   temp\_index\_r = temp\_index\_r + 1;

&#x20;                   temp\_index\_c = 1;

&#x20;               end

&#x20;           else

&#x20;               Pci\_bigger(i, j) = 0;

&#x20;           end

&#x20;       else

&#x20;           Pci\_bigger(i, j) = 0;

&#x20;       end

&#x20;   end

end



Pci\_bigger;

%% Final FSM state: compute output final image matrix and transfer the pixels one by one as an output to the testbench and store for reference.

omega  = zeros(window\_size, window\_size);

flag2 = 0;

Pci\_min = zeros(1, window\_size);

d = zeros(1, window\_size);

Beta = zeros(1, window\_size);

Y\_m  = zeros(1, window\_size);

output\_R = zeros(r\_size, c\_size);

output\_G = zeros(r\_size, c\_size);

output\_B = zeros(r\_size, c\_size);

output\_index\_r = 1;

output\_index\_c = 1;

%% We will make Pci bigger in rows manner only and change its centre accessing index so do the same here in while everywhere(a lot of places)

while (true)



&#x20;   %% block that is important to compute final image matrix using mostly

&#x20;   % combinational nets and just one non-blocking assignment

&#x20;   % Assuming that omega matrix is ready from the prev clock cycle and we can directly implement

&#x20;   % operations to compute image



&#x20;   % for now, Pci\_min optimization like Fig. 3c is not implemented but it

&#x20;   % can be done later. Add more pair3\_min vars to compute for 11\*11



&#x20;   % Step 6: Pci\_min and col\_mins

&#x20;  if flag2 == 1 % this output is not calculated the first iteration of the state

&#x20;      omega;

&#x20;   for k = 1:1:window\_size % to iterate through all the col in window

&#x20;       pair3\_min\_from\_col\_1 = Min3(omega(1,k), omega(2,k), omega(3,k));

&#x20;       % add more smaller pairs3 for 11\*11 window

&#x20;       Pci\_min(k) = pair3\_min\_from\_col\_1;

&#x20;   end

&#x20;

&#x20;   % Step 7 \& 8: Compute D and Beta

&#x20;   for l = 1:1:window\_size

&#x20;       if (Pci\_min(l) >= Gi\_old(1 , 1))

&#x20;           Beta(l) = 1;

&#x20;           d(l) = Pci\_min(l) - Gi\_old(1 , 1);

&#x20;       else

&#x20;           Beta(l) = 0;

&#x20;           d(l) = Gi\_old(1 , 1 ) - Pci\_min(l);

&#x20;

&#x20;       end

&#x20;   end



&#x20;   % Step 9: Select linear segment:

&#x20;   for m = 1:1:window\_size

&#x20;       if d(m) >= 0 \&\& d(m) <= 14.3

&#x20;           Y\_m(m) = 16384 - (bitshift(d(m),8) + bitshift(d(m),7) + bitshift(d(m),5));



&#x20;       elseif d(m) > 14.3 \&\& d(m) <= 38

&#x20;           Y\_m(m) = 13631 - (bitshift(d(m),7) + bitshift(d(m),6) + bitshift(d(m),5));



&#x20;       elseif d(m) > 38 \&\& d(m) <= 46.4

&#x20;           Y\_m(m) = 10747 - (bitshift(d(m),7) + bitshift(d(m),4) + bitshift(d(m),2));



&#x20;       elseif d(m) > 46.4 \&\& d(m) <= 67

&#x20;           Y\_m(m) = 7966 - (bitshift(d(m),6) + bitshift(d(m),4) + bitshift(d(m),3));



&#x20;       elseif d(m) > 67 \&\& d(m) <= 95

&#x20;           Y\_m(m) = 5017 - (bitshift(d(m),5) + bitshift(d(m),3) + bitshift(d(m),2));



&#x20;       elseif d(m) > 95 \&\& d(m) <= 135

&#x20;           Y\_m(m) = 2265 - (bitshift(d(m),2) + bitshift(d(m),3) + bitshift(d(m),1)) - d(m);



&#x20;       elseif d(m) > 135 \&\& d(m) <= 175

&#x20;           Y\_m(m) = 822 - bitshift(d(m),2);



&#x20;       else

&#x20;           Y\_m(m) = 416;

&#x20;       end

&#x20;   end



&#x20;   % step 10 Calculate Refined Illumination:

&#x20;   sum\_N = 0;

&#x20;   sum\_D = 0;

&#x20;   for m = 1:1:window\_size

&#x20;       sum\_N = sum\_N + (Beta(m)\*Y\_m(m)\*Pci\_min(m));

&#x20;   end

&#x20;   for m = 1:1:window\_size

&#x20;       sum\_D = sum\_D + (Beta(m)\*Y\_m(m));

&#x20;   end

&#x20;   Fm = (sum\_N/sum\_D);  % implement a lut + multiplier based on AI's method i.e scale this up too

&#x20;



&#x20;   % Step 11: Calculate Reflectance for R, G and B, will do this later as

&#x20;   % it comes out as decimal value (0 to 1) and handling that is tedious

&#x20;



&#x20;   % Step 12: Normalization of Fm is skipped as it will make 0 to 1 too



&#x20;   % Step 13: Modified Illumination for gamma correction \& contrast

&#x20;   % balancing without Fnorm for now(no change in accuracy)

&#x20;   Emod = sqrt(Fm)\*(sqrt(2\*255 - Fm)); % use lut approximation for root

&#x20;   temp\_emod\_by\_Fm = Emod/Fm; % implement division by lut memory



&#x20;   % Final Step 14: Enhanced output pixel, in verilog, just send the 3

&#x20;   % computed pixels to the output testbench and testbench will store the

&#x20;   % image



&#x20;   if output\_index\_c == 1

&#x20;       output\_R(output\_index\_r-1, c\_size) = temp\_emod\_by\_Fm \* R(output\_index\_r-1, c\_size);

&#x20;       output\_G(output\_index\_r-1, c\_size) = temp\_emod\_by\_Fm \* G(output\_index\_r-1, c\_size);

&#x20;       output\_B(output\_index\_r-1, c\_size) = temp\_emod\_by\_Fm \* B(output\_index\_r-1, c\_size);

&#x20;   else

&#x20;       output\_R(output\_index\_r, output\_index\_c-1) = temp\_emod\_by\_Fm \* R(output\_index\_r, output\_index\_c-1);

&#x20;       output\_G(output\_index\_r, output\_index\_c-1) = temp\_emod\_by\_Fm \* G(output\_index\_r, output\_index\_c-1);

&#x20;       output\_B(output\_index\_r, output\_index\_c-1) = temp\_emod\_by\_Fm \* B(output\_index\_r, output\_index\_c-1);



&#x20;   end



&#x20;   %% Shifting Gi\_old and filling in new value

&#x20;       for u = 1:1: window\_size - border\_pad\_width

&#x20;           for v = 1:1:c\_size-1

&#x20;               if v == c\_size-1

&#x20;                   Gi\_old(u,v) = Gi\_old(u,v+1);

&#x20;                   if u+1 \~= window\_size  - border\_pad\_width + 1

&#x20;                       Gi\_old(u,v+1) = Gi\_old(u+1,1);

&#x20;                   end

&#x20;               else

&#x20;                   Gi\_old(u,v) = Gi\_old(u, v+1);

&#x20;               end



&#x20;           end

&#x20;       end

&#x20;       % including a new value in Gi\_old matrix, in verilog the index

&#x20;       % logic is handled by the testbench user to pick things up from the

&#x20;       % pad\_R matrix that they have

&#x20;       Gi\_old(window\_size - border\_pad\_width,c\_size) = Max3( pad\_R(row\_index\_for\_Gi\_old, col\_index\_for\_Gi\_old), pad\_G(row\_index\_for\_Gi\_old, col\_index\_for\_Gi\_old), pad\_B(row\_index\_for\_Gi\_old, col\_index\_for\_Gi\_old));

&#x20;

&#x20;       if row\_index\_for\_Gi\_old \~= r\_pad\_size || col\_index\_for\_Gi\_old \~= c\_pad\_size - border\_pad\_width

&#x20;           if col\_index\_for\_Gi\_old == c\_pad\_size - border\_pad\_width



&#x20;                   col\_index\_for\_Gi\_old = 1 + border\_pad\_width;

&#x20;                   row\_index\_for\_Gi\_old = row\_index\_for\_Gi\_old + 1;

&#x20;           else

&#x20;               col\_index\_for\_Gi\_old = col\_index\_for\_Gi\_old + 1;

&#x20;           end

&#x20;       end



&#x20;  else

&#x20;       row\_index\_for\_Gi\_old = window\_size + 1;



&#x20;       col\_index\_for\_Gi\_old = 1 + border\_pad\_width;

&#x20;  end

&#x20;  flag2 = 1;

&#x20;

&#x20;  %% (Mirror padding) Pulling omega matrix correctly from the Pci matrix before Pci is changed at the end of clk cycle

&#x20;   % use the index of output\_ var instead of Pci broken var after Pci

&#x20;   % filled

&#x20;

&#x20;   % buffer zero pads replace Pci with clone

&#x20;   if output\_index\_c == 1 % need to compute many thing along with top and bottom left:diagonals

&#x20;       if output\_index\_r <= border\_pad\_width % need to compute upper left diagonals

&#x20;           for i = 1 : 1 :  border\_pad\_width + output\_index\_r % simply copying real values from Pci

&#x20;               for j = 1 : 1 : border\_pad\_width + 1

&#x20;                   omega(i + border\_pad\_width - output\_index\_r + 1, j + border\_pad\_width) = Pci\_bigger(i + border\_pad\_width - output\_index\_r + 1, j + border\_pad\_width);

&#x20;



&#x20;               end

&#x20;           end

&#x20;           for i = 1 : 1 : border\_pad\_width - output\_index\_r + 1 % computing upper mirror pad rows

&#x20;               for j = 1 : 1 : 1 + border\_pad\_width

&#x20;                   omega(i, j + border\_pad\_width) = Pci\_bigger(4 + 2\*border\_pad\_width - 2\*output\_index\_r - i, j + border\_pad\_width);

&#x20;               end

&#x20;           end

&#x20;

&#x20;           for i = 1 : 1 :  border\_pad\_width + output\_index\_r % computing left side mirror pad columns

&#x20;               for j = 1 : 1 :  border\_pad\_width

&#x20;                   omega(i + border\_pad\_width - output\_index\_r + 1, j) = Pci\_bigger(i + border\_pad\_width - output\_index\_r + 1,  2\*border\_pad\_width + 2 -j);

&#x20;               end

&#x20;           end



&#x20;           for i = 1 : 1 : border\_pad\_width - output\_index\_r + 1 % computing diagonal elements up left

&#x20;               for j = 1 : 1 : border\_pad\_width

&#x20;                   omega(i, j) = Pci\_bigger(4 + 2\*border\_pad\_width - 2\*output\_index\_r - i, 2\*border\_pad\_width + 2 -j);

&#x20;               end

&#x20;           end

&#x20;       elseif output\_index\_r <= r\_size - border\_pad\_width % no need to compute left bottom/upper diagonals/padrows top/bottom till here

&#x20;           for i = 1 : 1 :  2\*border\_pad\_width + 1 % simply copying real values from Pci

&#x20;               for j = 1 : 1 : border\_pad\_width + 1

&#x20;                   omega(i, j + border\_pad\_width) = Pci\_bigger(i, j + border\_pad\_width);

&#x20;



&#x20;               end

&#x20;           end



&#x20;           for i = 1 : 1 :  2\*border\_pad\_width + 1 % computing left side mirror pad columns

&#x20;               for j = 1 : 1 :  border\_pad\_width

&#x20;                   omega(i , j) = Pci\_bigger(i ,  2\*border\_pad\_width + 2 -j);

&#x20;               end

&#x20;           end

&#x20;

&#x20;       else % need to compute bottom left diagonals here

&#x20;           for i = 1 : 1 :  border\_pad\_width + r\_size - output\_index\_r+1 % simply copying real values from Pci

&#x20;               for j = 1 : 1 : border\_pad\_width + 1

&#x20;                   omega(i , j + border\_pad\_width) = Pci\_bigger(i, j + border\_pad\_width);

&#x20;

&#x20;               end

&#x20;           end

&#x20;           for i = 1 : 1 : + border\_pad\_width - r\_size + output\_index\_r % computing bottom mirror pad rows

&#x20;               for j = 1 : 1 : 1 + border\_pad\_width

&#x20;                   omega(2\*border\_pad\_width + 2 - i, j + border\_pad\_width) = Pci\_bigger(i + 2\*(r\_size - output\_index\_r), j + border\_pad\_width);

&#x20;               end

&#x20;           end

&#x20;

&#x20;           for i = 1 : 1 :  border\_pad\_width + r\_size - output\_index\_r+1 % computing left side mirror pad columns

&#x20;               for j = 1 : 1 :  border\_pad\_width

&#x20;                   omega(i , j) = Pci\_bigger(i ,  2\*border\_pad\_width + 2 -j);

&#x20;               end

&#x20;           end



&#x20;           for i = 1 : 1 : +border\_pad\_width - r\_size + output\_index\_r % computing bottom mirror pad diagonals

&#x20;               for j = 1 : 1 : border\_pad\_width

&#x20;                   omega(2\*border\_pad\_width + 2 - i, j) = Pci\_bigger(i + 2\*(r\_size - output\_index\_r),  2\*border\_pad\_width + 2 -j);

&#x20;               end

&#x20;           end

&#x20;       end



&#x20;   elseif output\_index\_c <= c\_size - border\_pad\_width % no diagonal issue here from right side

&#x20;       if output\_index\_r <= border\_pad\_width % top pad rows fix

&#x20;           for i = 1:1:window\_size

&#x20;               for j = 1:1:window\_size

&#x20;                   if j <= window\_size -1

&#x20;                       omega(i, j) = omega(i, j+1);

&#x20;                   end

&#x20;               end

&#x20;           end

&#x20;           % filling the last col with new real values

&#x20;           for i = 1:1: border\_pad\_width + output\_index\_r

&#x20;               omega(i + border\_pad\_width - output\_index\_r + 1, window\_size) = Pci\_bigger(i + border\_pad\_width - output\_index\_r + 1, 1+ 2\*border\_pad\_width);

&#x20;           end

&#x20;           % filling the last col with mirror values

&#x20;           for i = 1:1: border\_pad\_width - output\_index\_r + 1

&#x20;               omega(i, window\_size) = Pci\_bigger(4 + 2\*border\_pad\_width - 2\*output\_index\_r - i , 1+ 2\*border\_pad\_width);

&#x20;           end

&#x20;       elseif output\_index\_r <= r\_size - border\_pad\_width % no top\_pad or bottom\_pad rows

&#x20;           for i = 1:1:window\_size

&#x20;               for j = 1:1:window\_size

&#x20;                   if j <= window\_size -1

&#x20;                       omega(i, j) = omega(i, j+1);

&#x20;                   end

&#x20;               end

&#x20;           end

&#x20;           % filling the last col with new real values

&#x20;           for i = 1:1: 2\*border\_pad\_width + 1

&#x20;               omega(i, window\_size) = Pci\_bigger(i, 1+ 2\*border\_pad\_width);

&#x20;           end



&#x20;       else % pad bottom rows

&#x20;            for i = 1:1:window\_size

&#x20;               for j = 1:1:window\_size

&#x20;                   if j <= window\_size -1

&#x20;                       omega(i, j) = omega(i, j+1);

&#x20;                   end

&#x20;               end

&#x20;           end

&#x20;           % filling the last col with new real values

&#x20;           for i = 1:1: border\_pad\_width + r\_size - output\_index\_r+1

&#x20;               omega(i, window\_size) = Pci\_bigger(i, 1+ 2\*border\_pad\_width);

&#x20;           end

&#x20;           % filling the last col with mirror values

&#x20;           for i = 1:1: border\_pad\_width + output\_index\_r -r\_size

&#x20;               omega(2\*border\_pad\_width + 2 - i, window\_size) = Pci\_bigger(i + 2\*(r\_size - output\_index\_r), 1+ 2\*border\_pad\_width);

&#x20;           end

&#x20;       end



&#x20;   else % there might be a diagonal issue here(internal ifs) from right side

&#x20;       if output\_index\_r <= border\_pad\_width % top right diagonal

&#x20;            for i = 1:1:window\_size

&#x20;               for j = 1:1:window\_size

&#x20;                   if j <= window\_size -1

&#x20;                       omega(i, j) = omega(i, j+1);

&#x20;                   end

&#x20;               end

&#x20;           end

&#x20;           % filling the last col with mirror values

&#x20;           for i = 1:1: border\_pad\_width + output\_index\_r

&#x20;               omega(i + border\_pad\_width - output\_index\_r + 1, window\_size) = Pci\_bigger(i + border\_pad\_width - output\_index\_r + 1, 1 + 2\*(c\_size - output\_index\_c));

&#x20;           end



&#x20;           for i = 1 : 1 : border\_pad\_width - output\_index\_r + 1 % computing diagonal elements up right

&#x20;

&#x20;               omega(i, window\_size) = Pci\_bigger(4 + 2\*border\_pad\_width - 2\*output\_index\_r - i, 1 + 2\*(c\_size - output\_index\_c));

&#x20;

&#x20;           end

&#x20;       elseif output\_index\_r <= r\_size - border\_pad\_width % no diagonal issue

&#x20;            for i = 1:1:window\_size

&#x20;               for j = 1:1:window\_size

&#x20;                   if j <= window\_size -1

&#x20;                       omega(i, j) = omega(i, j+1);

&#x20;                   end

&#x20;               end

&#x20;           end

&#x20;           % filling the last col with mirror values

&#x20;           for i = 1:1: window\_size

&#x20;               omega(i, window\_size) = Pci\_bigger(i, 1 + 2\*(c\_size - output\_index\_c));

&#x20;           end

&#x20;

&#x20;

&#x20;       else % diagonal issue from bottom right

&#x20;            for i = 1:1:window\_size

&#x20;               for j = 1:1:window\_size

&#x20;                   if j <= window\_size -1

&#x20;                       omega(i, j) = omega(i, j+1);

&#x20;                   end

&#x20;               end

&#x20;            end

&#x20;           % filling the last col with mirror values

&#x20;           for i = 1:1: border\_pad\_width + r\_size - output\_index\_r+1

&#x20;               omega(i, window\_size) = Pci\_bigger(i, 1 + 2\*(c\_size - output\_index\_c));

&#x20;           end



&#x20;           for i = 1 : 1 : + border\_pad\_width - r\_size + output\_index\_r % computing diagonal elements bottom right

&#x20;

&#x20;               omega(2\*border\_pad\_width + 2 - i, window\_size) = Pci\_bigger(i + 2\*(r\_size - output\_index\_r), 1 + 2\*(c\_size - output\_index\_c));

&#x20;

&#x20;           end





&#x20;       end



&#x20;

&#x20;   end



&#x20;   if output\_index\_c < c\_size

&#x20;       output\_index\_c = output\_index\_c + 1;

&#x20;   else

&#x20;       output\_index\_c = 1;

&#x20;       output\_index\_r = output\_index\_r + 1;

&#x20;   end



&#x20;   %% Output is finally produced



&#x20;

&#x20;   % filling delta window at end depending upon if values in window are

&#x20;   % completely new or not(we can use previous columns as window simply slides).



&#x20;   % this if is for complete refilling of delta matrix from start.

&#x20;   if pci\_c\_filling\_index == 1

&#x20;      head\_for\_registerset = 1;

&#x20;       for k = 1:1:window\_size % to iterate through all the col in window

&#x20;       pair3\_max\_from\_col\_1 = Max3(delta(1,k), delta(2,k), delta(3,k));

&#x20;       % add more smaller pairs3 for 11\*11 window

&#x20;       register\_set\_max\_each\_col(k) = pair3\_max\_from\_col\_1;

&#x20;       end

&#x20;       max\_from\_registerset\_1 = Max3(register\_set\_max\_each\_col(1), register\_set\_max\_each\_col(2), register\_set\_max\_each\_col(3));

&#x20;       % now that delta window is ready +max val; we will compute a value of pci

&#x20;       % and shift Gi matrix to include a new value





&#x20;       % First shift the Pci matrix and include a new value in it:

&#x20;       for u = 1:1:window\_size + border\_pad\_width + 1

&#x20;           for v = 1:1:c\_size-1

&#x20;               if v == c\_size-1

&#x20;                   Pci\_bigger(u,v) = Pci\_bigger(u,v+1);

&#x20;                   if u+1 \~= window\_size + border\_pad\_width + 1 + 1

&#x20;                       Pci\_bigger(u,v+1) = Pci\_bigger(u+1,1);

&#x20;                   end

&#x20;               else

&#x20;                   Pci\_bigger(u,v) = Pci\_bigger(u, v+1);

&#x20;               end



&#x20;           end

&#x20;       end

&#x20;

&#x20;       Pci\_bigger(window\_size + border\_pad\_width + 1, border\_pad\_width) = max\_from\_registerset\_1;

&#x20;

&#x20;

&#x20;       pci\_c\_filling\_index = pci\_c\_filling\_index + 1;

&#x20;

&#x20;

&#x20;

&#x20;       % making the patch: delta

&#x20;       for i = 1:1:1 + 2\*border\_pad\_width

&#x20;           for j = 1:1: 1+ 2\*border\_pad\_width

&#x20;               delta(i, j) = Gi(i, j); % patch about (2,2) or (6,6) always

&#x20;           end

&#x20;       end



&#x20;       % shift left and include a new value in the Gi matrix

&#x20;       for u = 1:1:window\_size

&#x20;           for v = 1:1:c\_pad\_size-1

&#x20;               if v == c\_pad\_size-1

&#x20;                   Gi(u,v) = Gi(u,v+1);

&#x20;                   if u+1 \~= window\_size + 1

&#x20;                       Gi(u,v+1) = Gi(u+1,1);

&#x20;                   end

&#x20;               else

&#x20;                   Gi(u,v) = Gi(u, v+1);

&#x20;               end



&#x20;           end

&#x20;       end

&#x20;       % including a new value in Gi matrix

&#x20;       Gi(window\_size,c\_pad\_size) = Max3( pad\_R(row\_index\_for\_Gi, col\_index\_for\_Gi), pad\_G(row\_index\_for\_Gi, col\_index\_for\_Gi), pad\_B(row\_index\_for\_Gi, col\_index\_for\_Gi));

&#x20;       % shifting the index for new values to be picked up from pad\_RGB

&#x20;       % for Gi

&#x20;       if row\_index\_for\_Gi \~= r\_pad\_size || col\_index\_for\_Gi \~= c\_size

&#x20;           if col\_index\_for\_Gi == c\_size



&#x20;                   col\_index\_for\_Gi = 1;

&#x20;                   row\_index\_for\_Gi = row\_index\_for\_Gi+1;

&#x20;           else

&#x20;               col\_index\_for\_Gi = col\_index\_for\_Gi + 1;

&#x20;           end

&#x20;       end



&#x20;   %% This is the case of preserving and making use of old values like DP

&#x20;   else







&#x20;       % now we compute max values for efficient register set(add more for

&#x20;       % 11\*11 future matrix

&#x20;       temp\_pair3\_forefficient\_colmax = Max3(delta(1, window\_size), delta(2, window\_size), delta(3, window\_size));



&#x20;       register\_set\_max\_each\_col(head\_for\_registerset) = temp\_pair3\_forefficient\_colmax;

&#x20;       % might need to add head var in comb block itself

&#x20;       if head\_for\_registerset == window\_size % this was made for pipelining, does not work properly in fsm, might need to add extra code or recalc all in verilog comb block

&#x20;           head\_for\_registerset = 1;

&#x20;       else

&#x20;           head\_for\_registerset = head\_for\_registerset + 1;

&#x20;       end

&#x20;       % add more max\_temp\_registers more for 11\*11 matrix

&#x20;       max\_from\_registerset\_1 = Max3(register\_set\_max\_each\_col(1), register\_set\_max\_each\_col(2), register\_set\_max\_each\_col(3));

&#x20;       % now that delta window is ready +max val; we will compute a value of pci

&#x20;       % and shift Gi matrix to include a new value





&#x20;       % First shift the Pci matrix and include a new value in it:

&#x20;       for u = 1:1:window\_size + border\_pad\_width + 1

&#x20;           for v = 1:1:c\_size-1

&#x20;               if v == c\_size-1

&#x20;                   Pci\_bigger(u,v) = Pci\_bigger(u,v+1);

&#x20;                   if u+1 \~= window\_size + border\_pad\_width + 1 + 1

&#x20;                       Pci\_bigger(u,v+1) = Pci\_bigger(u+1,1);

&#x20;                   end

&#x20;               else

&#x20;                   Pci\_bigger(u,v) = Pci\_bigger(u, v+1);

&#x20;               end



&#x20;           end

&#x20;       end

&#x20;

&#x20;       Pci\_bigger(window\_size + border\_pad\_width + 1, border\_pad\_width) = max\_from\_registerset\_1;





&#x20;      % If the delta matrix end of a row then it needs to precompute all

&#x20;      % the values from Gi as it will go to the begin of the next row and

&#x20;      % so the head pointer will point to the first index

&#x20;      if (pci\_c\_filling\_index \~= c\_size)

&#x20;       for i = 1:1:window\_size

&#x20;           for j = 1:1:window\_size

&#x20;               if j <= window\_size -1

&#x20;                   delta(i, j) = delta(i, j+1);

&#x20;               end

&#x20;           end

&#x20;       end

&#x20;       % filling the last col with new values

&#x20;       for i = 1:1:window\_size

&#x20;           delta(i, window\_size) = Gi(i, 1+ 2\*border\_pad\_width);

&#x20;       end

&#x20;      else

&#x20;          head\_for\_registerset = 1; % take care of this in verilog

&#x20;       % making the patch: delta

&#x20;       for i = 1:1:1 + 2\*border\_pad\_width

&#x20;           for j = 1:1: 1+ 2\*border\_pad\_width

&#x20;               delta(i, j) = Gi(i, j); % patch about (2,2) or (6,6) always

&#x20;           end

&#x20;       end



&#x20;      end

&#x20;     %% to decide whether to shift left and include a new value in the Gi matrix

&#x20;     % or shift left 3 times so other things in this fsm states need to be

&#x20;     % paused

&#x20;      if pci\_c\_filling\_index \~= c\_size - 1

&#x20;       % we are somewhere in middle of the Gi line buff values. One new

&#x20;       % delta col in place of old one only in registerset for now. We

&#x20;       % don't shift 3 times here.





&#x20;       % to shift and include new value for Gi

&#x20;       for u = 1:1:window\_size

&#x20;           for v = 1:1:c\_pad\_size-1

&#x20;               if v == c\_pad\_size-1

&#x20;                   Gi(u,v) = Gi(u,v+1);

&#x20;                   if u+1 \~= 1 + window\_size

&#x20;                       Gi(u,v+1) = Gi(u+1,1);

&#x20;                   end

&#x20;               else

&#x20;                   Gi(u,v) = Gi(u, v+1);

&#x20;               end



&#x20;           end

&#x20;       end

&#x20;       % including a new value in Gi matrix



&#x20;       Gi(window\_size,c\_pad\_size) = Max3( pad\_R(row\_index\_for\_Gi, col\_index\_for\_Gi), pad\_G(row\_index\_for\_Gi, col\_index\_for\_Gi), pad\_B(row\_index\_for\_Gi, col\_index\_for\_Gi));

&#x20;       % shifting the index for new values to be picked up from pad\_RGB

&#x20;       % for Gi

&#x20;       if row\_index\_for\_Gi \~= r\_pad\_size || col\_index\_for\_Gi \~= c\_size

&#x20;           if col\_index\_for\_Gi == c\_size

&#x20;               col\_index\_for\_Gi = 1;

&#x20;               row\_index\_for\_Gi = row\_index\_for\_Gi+1;

&#x20;           else

&#x20;               col\_index\_for\_Gi = col\_index\_for\_Gi + 1;

&#x20;           end

&#x20;       end

&#x20;       if pci\_c\_filling\_index == c\_size \&\& (pci\_r\_filling\_index + 1 <= r\_size)

&#x20;           pci\_c\_filling\_index = 1;

&#x20;           pci\_r\_filling\_index = pci\_r\_filling\_index + 1;

&#x20;       elseif pci\_c\_filling\_index + 1 <= c\_size

&#x20;           pci\_c\_filling\_index = pci\_c\_filling\_index + 1  ;

&#x20;       end

&#x20;      else

&#x20;       %% Now we need to shift Gi buffer 3 times

&#x20;



&#x20;       % this is for one output per clock cycle shift technique

&#x20;       for u = 1:1:window\_size

&#x20;           for v = 1:1:c\_pad\_size

&#x20;               if u == window\_size \&\& v> c\_pad\_size - (1+2\*border\_pad\_width)

&#x20;               ;

&#x20;               else

&#x20;                   if v + (1+2\*border\_pad\_width) <= c\_pad\_size

&#x20;                       Gi(u,v) = Gi(u, v + (1+2\*border\_pad\_width));

&#x20;                   else

&#x20;                       Gi(u, v) = Gi(u+1, (1+2\*border\_pad\_width) - (c\_pad\_size-v));

&#x20;                   end



&#x20;               end



&#x20;           end

&#x20;       end

&#x20;       % including a new value in Gi matrix

&#x20;       % IMP: For this to be success, have many i/p ports that give out

&#x20;       % ahead/future values of pad matrices. ALso, on this operation, give an

&#x20;       % output with extra output port to tell it to the consumer that you

&#x20;       % need to shift your streaming by 1+2\*border\_width too.

&#x20;       temp = c\_pad\_size - (2\*border\_pad\_width); % this is error prone, if pad\_R goes next row, check for 11\*11

&#x20;       Gi;

&#x20;       Pci\_bigger;

&#x20;       for i = c\_pad\_size - (2\*border\_pad\_width) : 1 : (c\_pad\_size)

&#x20;           Gi(window\_size, i) = Max3( pad\_R(row\_index\_for\_Gi, col\_index\_for\_Gi +(i - temp)), pad\_G(row\_index\_for\_Gi, col\_index\_for\_Gi +(i - temp)), pad\_B(row\_index\_for\_Gi, col\_index\_for\_Gi + (i - temp)));

&#x20;       end

&#x20;

&#x20;       % Error prone: I am not sure about this

&#x20;       if row\_index\_for\_Gi \~= r\_pad\_size

&#x20;           row\_index\_for\_Gi = row\_index\_for\_Gi + 1;

&#x20;           col\_index\_for\_Gi = 1;

&#x20;       end

&#x20;       if pci\_c\_filling\_index == c\_size \&\& (pci\_r\_filling\_index + 1 <= r\_size)

&#x20;           pci\_c\_filling\_index = 1;

&#x20;           pci\_r\_filling\_index = pci\_r\_filling\_index + 1;

&#x20;       elseif pci\_c\_filling\_index + 1 <= c\_size

&#x20;           pci\_c\_filling\_index = pci\_c\_filling\_index + 1  ;

&#x20;       end



&#x20;      end

&#x20;



&#x20;   end

&#x20;   head\_for\_registerset;

&#x20;   register\_set\_max\_each\_col;

&#x20;   Pci\_bigger;

&#x20;   Gi;

&#x20;   delta;

&#x20;   if output\_index\_r > r\_size   % implement it as if conditional for "done" fsm state

&#x20;       break; % Exit the loop if we have filled all rows

&#x20;   end

&#x20;

end







function result = Max3(R, G, B)

if R >= G \&\& R >= B

&#x20;   result = R;

elseif G >= B

&#x20;   result = G;

else

&#x20;   result = B;

end

end

function result2 = Min3(x, y, z)

if x<= y \&\& x<= z

&#x20;   result2 = x;

elseif y<=z

&#x20;   result2 = y;

else

&#x20;   result2 = z;

end

end

output\_R

output\_G

output\_B









## Updated for 11\*11 image

clear; clc;



img = imread('511.png');

R = img(:,:,1);

G = img(:,:,2);

B = img(:,:,3);



% Define RGB image

% R = \[20 40 60 80; 30 50 70 90; 40 60 80 100; 50 70 90 110];

% G = \[10 30 50 70; 20 40 60 80; 30 50 70 90; 40 60 80 100];

% B = \[5 25 45 65; 15 35 55 75; 25 45 65 85; 35 55 75 95];

% this is present in the tb of our design and not declared in the design.v

r\_size = size(R, 1); % size of output/input image

c\_size = size(R, 2); % parameterize everything

window\_size = 11; % taken 11 in verilog

border\_pad\_width = bitshift(window\_size-1,-1);



% mirror padding

r\_pad\_size = r\_size + 2\*border\_pad\_width;

c\_pad\_size = c\_size + 2\*border\_pad\_width;

pad\_R = zeros(r\_pad\_size, c\_pad\_size);

pad\_G = zeros(r\_pad\_size, c\_pad\_size);

pad\_B = zeros(r\_pad\_size, c\_pad\_size);

% here, we fill up the actual unpadded portion directly

for i = 1:1:r\_size

&#x20;   for j = 1:1:c\_size

&#x20;       pad\_R(i+border\_pad\_width, j + border\_pad\_width) = R(i,j);

&#x20;       pad\_G(i+border\_pad\_width, j + border\_pad\_width) = G(i,j);

&#x20;       pad\_B(i+border\_pad\_width, j + border\_pad\_width) = B(i,j);

&#x20;   end

end

% proceding with mirror paddind without accounting for diagonal padding yet

% 2 reference columns for reflection(rename in verilog)

left\_ref = 1+border\_pad\_width;

right\_ref = 1+border\_pad\_width+c\_size-1;



moving\_left\_padder\_col = left\_ref-1; move\_right\_for\_leftpadder = left\_ref+1;

moving\_right\_padder\_col = right\_ref+1; move\_left\_for\_rightpadder = right\_ref-1;

% 2 ref for rows

up\_ref = 1+ border\_pad\_width;

down\_ref = r\_pad\_size - border\_pad\_width;

moving\_up\_padder\_row = up\_ref -1; move\_down\_for\_uppadder = up\_ref + 1;

moving\_down\_padder\_row = down\_ref +1; move\_up\_for\_downpadder = down\_ref - 1;

while (true)

&#x20;   if(moving\_left\_padder\_col == 0)

&#x20;       break;

&#x20;   end

&#x20;   % filling columns left and right

&#x20;   for i = 1+border\_pad\_width:1:r\_pad\_size - border\_pad\_width

&#x20;       pad\_R(i, moving\_left\_padder\_col) = pad\_R(i, move\_right\_for\_leftpadder);

&#x20;       pad\_G(i, moving\_left\_padder\_col) = pad\_G(i, move\_right\_for\_leftpadder);

&#x20;       pad\_B(i, moving\_left\_padder\_col) = pad\_B(i, move\_right\_for\_leftpadder);

&#x20;       pad\_R(i, moving\_right\_padder\_col) = pad\_R(i, move\_left\_for\_rightpadder);

&#x20;       pad\_G(i, moving\_right\_padder\_col) = pad\_G(i, move\_left\_for\_rightpadder);

&#x20;       pad\_B(i, moving\_right\_padder\_col) = pad\_B(i, move\_left\_for\_rightpadder);



&#x20;

&#x20;

&#x20;   end

&#x20;   % filling rows top and bottom

&#x20;   for j = 1+border\_pad\_width:1:c\_pad\_size - border\_pad\_width

&#x20;       pad\_R(moving\_up\_padder\_row, j) = pad\_R(move\_down\_for\_uppadder,j);

&#x20;       pad\_G(moving\_up\_padder\_row, j) = pad\_G(move\_down\_for\_uppadder,j);

&#x20;       pad\_B(moving\_up\_padder\_row, j) = pad\_B(move\_down\_for\_uppadder,j);

&#x20;       pad\_R(moving\_down\_padder\_row, j) = pad\_R(move\_up\_for\_downpadder, j);

&#x20;       pad\_G(moving\_down\_padder\_row, j) = pad\_G(move\_up\_for\_downpadder, j);

&#x20;       pad\_B(moving\_down\_padder\_row, j) = pad\_B(move\_up\_for\_downpadder, j);

&#x20;   end

&#x20;   temp = 1;

&#x20;   % handling diagonals

&#x20;   for k = left\_ref-1:1:1 % for iterating the columns

&#x20;       pad\_R(moving\_up\_padder\_row,k) = pad\_R(moving\_up\_padder\_row,left\_ref-k+2);

&#x20;       pad\_R(moving\_up\_padder\_row,right\_ref+left\_ref-k) = pad\_R(moving\_up\_padder\_row,right\_ref-temp);

&#x20;       pad\_R(moving\_down\_padder\_row,k) = pad\_R(moving\_down\_padder\_row,left\_ref-k+2);

&#x20;       pad\_R(moving\_down\_padder\_row,right\_ref+left\_ref-k) = pad\_R(moving\_down\_padder\_row,right\_ref-temp);

&#x20;       temp = temp + 1;



&#x20;   end





&#x20;   moving\_left\_padder\_col = moving\_left\_padder\_col - 1;

&#x20;   moving\_right\_padder\_col = moving\_right\_padder\_col + 1;

&#x20;   move\_right\_for\_leftpadder = move\_right\_for\_leftpadder + 1;

&#x20;   move\_left\_for\_rightpadder = move\_left\_for\_rightpadder - 1;

&#x20;   moving\_up\_padder\_row = moving\_up\_padder\_row + 1;

&#x20;   move\_down\_for\_uppadder = move\_down\_for\_uppadder -1;

&#x20;   moving\_down\_padder\_row = moving\_down\_padder\_row -1;

&#x20;   move\_up\_for\_downpadder = move\_up\_for\_downpadder + 1;



end



%% fsm state to build the initial line buffer of Gi = max(R,G,B); till delta patch size:

Gi = zeros(window\_size,c\_pad\_size); % Gi is actually Gi\_pad

% one isssue is that it will take 10 extra clock cycles for each row of

% image as we will accelerate Gi matrix to add 2\*border\*width + 1 extra(as a part of process itself)



% lets perform right shift to fill the Gi matrix



row\_index\_for\_Gi = window\_size;

col\_index\_for\_Gi = c\_pad\_size;



for i = 1:1:window\_size\*c\_pad\_size



&#x20;   % this is for right shift every outer loop iteration

&#x20;   for u = window\_size:-1:1

&#x20;       for v = c\_pad\_size:-1:1

&#x20;           if v == 1 \&\& u \~= 1

&#x20;           Gi(u, v) = Gi(u-1, c\_pad\_size);

&#x20;           elseif (v-1 \~=0)

&#x20;

&#x20;           Gi(u, v)  = Gi(u, v-1);

&#x20;           end



&#x20;        end

&#x20;   end



&#x20;   % there is no ternary in matlab but do in hdl and try function

&#x20;   % To insert the max element at the

&#x20;   if pad\_R(row\_index\_for\_Gi,col\_index\_for\_Gi) >= pad\_G(row\_index\_for\_Gi,col\_index\_for\_Gi) \&\& pad\_R(row\_index\_for\_Gi,col\_index\_for\_Gi) >= pad\_B(row\_index\_for\_Gi,col\_index\_for\_Gi)

&#x20;       Gi(1,1) = pad\_R(row\_index\_for\_Gi,col\_index\_for\_Gi);

&#x20;   elseif pad\_G(row\_index\_for\_Gi,col\_index\_for\_Gi) >= pad\_R(row\_index\_for\_Gi,col\_index\_for\_Gi) \&\& pad\_G(row\_index\_for\_Gi,col\_index\_for\_Gi) >= pad\_B(row\_index\_for\_Gi,col\_index\_for\_Gi)

&#x20;       Gi(1,1) = pad\_G(row\_index\_for\_Gi,col\_index\_for\_Gi);

&#x20;   else

&#x20;       Gi(1,1) = pad\_B(row\_index\_for\_Gi,col\_index\_for\_Gi);

&#x20;   end



&#x20;   % this keeps the index to pull from rg and b padded matrices

&#x20;   if col\_index\_for\_Gi >1

&#x20;       col\_index\_for\_Gi  = col\_index\_for\_Gi - 1;

&#x20;   else

&#x20;       col\_index\_for\_Gi = c\_pad\_size;

&#x20;       row\_index\_for\_Gi = row\_index\_for\_Gi - 1;

&#x20;   end

&#x20;

end

% now that basic Gi is computed, we will fill the Pci matrix till omega is

% fulfilled



Gi;



%% NO extra waiting state added to make it fpga clock compatible, delta window

% should be ready before the loop starts at it needs to be used in the loop



Gi\_old = zeros(window\_size -  border\_pad\_width, c\_size);

delta = zeros(window\_size, window\_size);



pci\_r\_filling\_index = 1;

pci\_c\_filling\_index = 1;

pair3\_max\_from\_col\_1 = 0; % include extra for 11\*11 matrix

register\_set\_max\_each\_col = zeros(1, window\_size);

max\_from\_registerset\_1 = 0;

Pci = zeros(window\_size,c\_size);

row\_index\_for\_Gi = 1+window\_size;

col\_index\_for\_Gi = 1;

head\_for\_registerset = 1;

flag = 1; % reset this and other things in the final done fsm state





%% next fsm state to fill Pci(course illumination) line buffer till the omega window size



while (true)

&#x20;   % filling delta window at end of timestep depending upon if values in window are

&#x20;   % completely new or not(we can use previous columns as window simply slides).



&#x20;   % this if is for complete refilling of delta matrix from start.

&#x20;   if pci\_c\_filling\_index == 1

&#x20;      head\_for\_registerset = 1;

&#x20;      if flag == 0 % to prevent this from running and computing anything yet for the first time and to wait for next edge

&#x20;       for k = 1:1:window\_size % to iterate through all the col in window

&#x20;       pair3\_max\_from\_col\_1 = Max3(delta(1,k), delta(2,k), delta(3,k));

&#x20;       pair3\_max\_from\_col\_2 = Max3(delta(4, k), delta(5, k), delta(6, k));

&#x20;       pair3\_max\_from\_col\_3 = Max3(delta(7, k), delta(8, k), delta(9, k));

&#x20;       pair3\_max\_from\_col\_collect = Max3(pair3\_max\_from\_col\_1, pair3\_max\_from\_col\_2, pair3\_max\_from\_col\_3);

&#x20;       pair3\_max\_from\_col\_final = Max3(pair3\_max\_from\_col\_collect, delta(10, k), delta(11, k));

&#x20;       % add more smaller pairs3 for 11\*11 window

&#x20;       register\_set\_max\_each\_col(k) = pair3\_max\_from\_col\_final;

&#x20;       end

&#x20;       max\_from\_registerset\_1 = Max3(register\_set\_max\_each\_col(1), register\_set\_max\_each\_col(2), register\_set\_max\_each\_col(3));

&#x20;       max\_from\_registerset\_2 = Max3(register\_set\_max\_each\_col(4), register\_set\_max\_each\_col(5), register\_set\_max\_each\_col(6));

&#x20;       max\_from\_registerset\_3 = Max3(register\_set\_max\_each\_col(7), register\_set\_max\_each\_col(8), register\_set\_max\_each\_col(9));

&#x20;       max\_from\_registerset\_collect = Max3(max\_from\_registerset\_1,max\_from\_registerset\_2 ,max\_from\_registerset\_3 );

&#x20;       max\_from\_registerset\_final = Max3(register\_set\_max\_each\_col(10), register\_set\_max\_each\_col(11), max\_from\_registerset\_collect);

&#x20;       % now that delta window is ready +max val; we will compute a value of pci

&#x20;       % and shift Gi matrix to include a new value

&#x20;       Pci(pci\_r\_filling\_index,pci\_c\_filling\_index) = max\_from\_registerset\_final;

&#x20;       pci\_c\_filling\_index = pci\_c\_filling\_index + 1;

&#x20;      else

&#x20;          for i = 1:1:window\_size - border\_pad\_width

&#x20;              for j = 1:1:c\_size

&#x20;                  Gi\_old(i, j) = Gi(i + border\_pad\_width, j + border\_pad\_width);

&#x20;              end

&#x20;          end

&#x20;      end

&#x20;       flag = 0;

&#x20;       % making the patch: delta

&#x20;       for i = 1:1:1 + 2\*border\_pad\_width

&#x20;           for j = 1:1: 1+ 2\*border\_pad\_width

&#x20;               delta(i, j) = Gi(i, j); % patch about (2,2) or (6,6) always

&#x20;           end

&#x20;       end



&#x20;       % shift left and include a new value in the Gi matrix

&#x20;       for u = 1:1:window\_size

&#x20;           for v = 1:1:c\_pad\_size-1

&#x20;               if v == c\_pad\_size-1

&#x20;                   Gi(u,v) = Gi(u,v+1);

&#x20;                   if u+1 \~= window\_size + 1

&#x20;                       Gi(u,v+1) = Gi(u+1,1);

&#x20;                   end

&#x20;               else

&#x20;                   Gi(u,v) = Gi(u, v+1);

&#x20;               end



&#x20;           end

&#x20;       end

&#x20;       % including a new value in Gi matrix

&#x20;       Gi(window\_size,c\_pad\_size) = Max3( pad\_R(row\_index\_for\_Gi, col\_index\_for\_Gi), pad\_G(row\_index\_for\_Gi, col\_index\_for\_Gi), pad\_B(row\_index\_for\_Gi, col\_index\_for\_Gi));

&#x20;       % shifting the index for new values to be picked up from pad\_RGB

&#x20;       % for Gi

&#x20;       if row\_index\_for\_Gi \~= r\_pad\_size || col\_index\_for\_Gi \~= c\_size

&#x20;           if col\_index\_for\_Gi == c\_size



&#x20;                   col\_index\_for\_Gi = 1;

&#x20;                   row\_index\_for\_Gi = row\_index\_for\_Gi+1;

&#x20;           else

&#x20;               col\_index\_for\_Gi = col\_index\_for\_Gi + 1;

&#x20;           end

&#x20;       end



&#x20;   %% This is the case of preserving and making use of old values like DP

&#x20;   else







&#x20;       % now we compute max values for efficient register set(add more for

&#x20;       % 11\*11 future matrix

&#x20;       temp\_pair3\_forefficient\_colmax\_1 = Max3(delta(1, window\_size), delta(2, window\_size), delta(3, window\_size));

&#x20;       temp\_pair3\_forefficient\_colmax\_2 = Max3(delta(4, window\_size), delta(5, window\_size), delta(6, window\_size));

&#x20;       temp\_pair3\_forefficient\_colmax\_3 = Max3(delta(7, window\_size), delta(8, window\_size), delta(9, window\_size));

&#x20;       temp\_pair3\_forefficient\_colmax\_collect = Max3(temp\_pair3\_forefficient\_colmax\_1, temp\_pair3\_forefficient\_colmax\_2, temp\_pair3\_forefficient\_colmax\_3);

&#x20;       temp\_pair3\_forefficient\_colmax\_final = Max3(temp\_pair3\_forefficient\_colmax\_collect, delta(10, window\_size), delta(11, window\_size));



&#x20;       register\_set\_max\_each\_col(head\_for\_registerset) = temp\_pair3\_forefficient\_colmax\_final;

&#x20;       % might need to add head var in comb block itself

&#x20;       if head\_for\_registerset == window\_size % this was made for pipelining, does not work properly in fsm, might need to add extra code or recalc all in verilog comb block

&#x20;           head\_for\_registerset = 1;

&#x20;       else

&#x20;           head\_for\_registerset = head\_for\_registerset + 1;

&#x20;       end

&#x20;       % add more max\_temp\_registers more for 11\*11 matrix

&#x20;       max\_from\_registerset\_1 = Max3(register\_set\_max\_each\_col(1), register\_set\_max\_each\_col(2), register\_set\_max\_each\_col(3));

&#x20;       max\_from\_registerset\_2 = Max3(register\_set\_max\_each\_col(4), register\_set\_max\_each\_col(5), register\_set\_max\_each\_col(6));

&#x20;       max\_from\_registerset\_3 = Max3(register\_set\_max\_each\_col(7), register\_set\_max\_each\_col(8), register\_set\_max\_each\_col(9));

&#x20;       max\_from\_registerset\_collect = Max3(max\_from\_registerset\_1,max\_from\_registerset\_2 ,max\_from\_registerset\_3 );

&#x20;       max\_from\_registerset\_final = Max3(register\_set\_max\_each\_col(10), register\_set\_max\_each\_col(11), max\_from\_registerset\_collect);



&#x20;       % now that delta window is ready +max val; we will compute a value of pci

&#x20;       % and shift Gi matrix to include a new value

&#x20;       Pci(pci\_r\_filling\_index,pci\_c\_filling\_index) = max\_from\_registerset\_final;

&#x20;      % If the delta matrix end of a row then it needs to precompute all

&#x20;      % the values from Gi as it will go to the begin of the next row and

&#x20;      % so the head pointer will point to the first index

&#x20;      if (pci\_c\_filling\_index \~= c\_size)

&#x20;       for i = 1:1:window\_size

&#x20;           for j = 1:1:window\_size

&#x20;               if j <= window\_size -1

&#x20;                   delta(i, j) = delta(i, j+1);

&#x20;               end

&#x20;           end

&#x20;       end

&#x20;       % filling the last col with new values

&#x20;       for i = 1:1:window\_size

&#x20;           delta(i, window\_size) = Gi(i, 1+ 2\*border\_pad\_width);

&#x20;       end

&#x20;      else

&#x20;

&#x20;          head\_for\_registerset = 1; % take care of this in verilog

&#x20;       % making the patch: delta

&#x20;       for i = 1:1:1 + 2\*border\_pad\_width

&#x20;           for j = 1:1: 1+ 2\*border\_pad\_width

&#x20;               delta(i, j) = Gi(i, j); % patch about (2,2) or (6,6) always

&#x20;           end

&#x20;       end



&#x20;      end

&#x20;     %% to decide whether to shift left and include a new value in the Gi matrix

&#x20;     % or shift left 3 times so other things in this fsm states need to be

&#x20;     % paused

&#x20;      if pci\_c\_filling\_index \~= c\_size - 1

&#x20;       % we are somewhere in middle of the Gi line buff values. One new

&#x20;       % delta col in place of old one only in registerset for now. We

&#x20;       % don't shift 3 times here.





&#x20;       % to shift and include new value for Gi

&#x20;       for u = 1:1:window\_size

&#x20;           for v = 1:1:c\_pad\_size-1

&#x20;               if v == c\_pad\_size-1

&#x20;                   Gi(u,v) = Gi(u,v+1);

&#x20;                   if u+1 \~= 1 + window\_size

&#x20;                       Gi(u,v+1) = Gi(u+1,1);

&#x20;                   end

&#x20;               else

&#x20;                   Gi(u,v) = Gi(u, v+1);

&#x20;               end



&#x20;           end

&#x20;       end

&#x20;       % including a new value in Gi matrix



&#x20;       Gi(window\_size,c\_pad\_size) = Max3( pad\_R(row\_index\_for\_Gi, col\_index\_for\_Gi), pad\_G(row\_index\_for\_Gi, col\_index\_for\_Gi), pad\_B(row\_index\_for\_Gi, col\_index\_for\_Gi));

&#x20;       % shifting the index for new values to be picked up from pad\_RGB

&#x20;       % for Gi

&#x20;       if row\_index\_for\_Gi \~= r\_pad\_size || col\_index\_for\_Gi \~= c\_size

&#x20;           if col\_index\_for\_Gi == c\_size

&#x20;               col\_index\_for\_Gi = 1;

&#x20;               row\_index\_for\_Gi = row\_index\_for\_Gi+1;

&#x20;           else

&#x20;               col\_index\_for\_Gi = col\_index\_for\_Gi + 1;

&#x20;           end

&#x20;       end

&#x20;       if pci\_c\_filling\_index == c\_size

&#x20;           pci\_c\_filling\_index = 1;

&#x20;           pci\_r\_filling\_index = pci\_r\_filling\_index + 1;

&#x20;       else

&#x20;           pci\_c\_filling\_index = pci\_c\_filling\_index + 1  ;

&#x20;       end

&#x20;      else

&#x20;       %% Now we need to shift Gi buffer 3 times

&#x20;



&#x20;       % this is for one output per clock cycle shift technique

&#x20;       for u = 1:1:window\_size

&#x20;           for v = 1:1:c\_pad\_size

&#x20;               if u == window\_size \&\& v> c\_pad\_size - (1+2\*border\_pad\_width)

&#x20;               ;

&#x20;               else

&#x20;                   if v + (1+2\*border\_pad\_width) <= c\_pad\_size

&#x20;                       Gi(u,v) = Gi(u, v + (1+2\*border\_pad\_width));

&#x20;                   else

&#x20;                       Gi(u, v) = Gi(u+1, (1+2\*border\_pad\_width) - (c\_pad\_size-v));

&#x20;                   end



&#x20;               end



&#x20;           end

&#x20;       end

&#x20;       % including a new value in Gi matrix

&#x20;       % IMP: For this to be success, have many i/p ports that give out

&#x20;       % ahead/future values of pad matrices. ALso, on this operation, give an

&#x20;       % output with extra output port to tell it to the consumer that you

&#x20;       % need to shift your streaming by 1+2\*border\_width too.

&#x20;       temp = c\_pad\_size - (2\*border\_pad\_width); % this is error prone, if pad\_R goes next row, check for 11\*11

&#x20;       Gi;

&#x20;       Pci;

&#x20;       for i = c\_pad\_size - (2\*border\_pad\_width) : 1 : (c\_pad\_size)

&#x20;           Gi(window\_size, i) = Max3( pad\_R(row\_index\_for\_Gi, col\_index\_for\_Gi +(i - temp)), pad\_G(row\_index\_for\_Gi, col\_index\_for\_Gi +(i - temp)), pad\_B(row\_index\_for\_Gi, col\_index\_for\_Gi + (i - temp)));

&#x20;       end

&#x20;       row\_index\_for\_Gi

&#x20;       col\_index\_for\_Gi

&#x20;       % Error prone: I am not sure about this

&#x20;       if row\_index\_for\_Gi \~= r\_pad\_size

&#x20;           row\_index\_for\_Gi = row\_index\_for\_Gi + 1;

&#x20;           col\_index\_for\_Gi = 1;

&#x20;       end

&#x20;       if pci\_c\_filling\_index == c\_size

&#x20;           pci\_c\_filling\_index = 1;

&#x20;           pci\_r\_filling\_index = pci\_r\_filling\_index + 1;

&#x20;       else

&#x20;           pci\_c\_filling\_index = pci\_c\_filling\_index + 1  ;

&#x20;       end



&#x20;      end

&#x20;



&#x20;   end

&#x20;   head\_for\_registerset;

&#x20;   register\_set\_max\_each\_col;

&#x20;   Pci;

&#x20;   Gi;

&#x20;   delta;

&#x20;   if pci\_r\_filling\_index > window\_size

&#x20;       break; % Exit the loop if we have filled all rows

&#x20;   end

end



Pci;

Gi;

delta ;



Gi\_old;

Pci\_bigger = zeros(window\_size + 1 + border\_pad\_width, c\_size);

%% extra fsm state added to construct a Pci\_bigger matrix out of Pci matrix

% in order to have x,y for output evaluation always at 1+border\_pad\_width

% position

temp\_index\_r = 1;  temp\_index\_c = 1;

for i = 1 : 1 : window\_size + 1 + border\_pad\_width

&#x20;   for j = 1 : 1 : c\_size

&#x20;

&#x20;       if (i >= border\_pad\_width)

&#x20;           if i == border\_pad\_width + 1 \&\& j >= border\_pad\_width + 1

&#x20;               Pci\_bigger(i, j) = Pci(temp\_index\_r, temp\_index\_c);

&#x20;               if temp\_index\_c < c\_size

&#x20;                   temp\_index\_c = temp\_index\_c + 1;

&#x20;               elseif  (temp\_index\_r + 1) <= (window\_size)

&#x20;                   temp\_index\_r = temp\_index\_r + 1;

&#x20;                   temp\_index\_c = 1;

&#x20;               end

&#x20;           elseif i>= border\_pad\_width + 2 \&\& i <= window\_size + border\_pad\_width

&#x20;               Pci\_bigger(i, j) = Pci(temp\_index\_r, temp\_index\_c);

&#x20;               if temp\_index\_c < c\_size

&#x20;                   temp\_index\_c = temp\_index\_c + 1;

&#x20;               elseif  (temp\_index\_r + 1) <= (window\_size)

&#x20;                   temp\_index\_r = temp\_index\_r + 1;

&#x20;                   temp\_index\_c = 1;

&#x20;               end

&#x20;           elseif i ==  window\_size + border\_pad\_width + 1 \&\& j <= border\_pad\_width

&#x20;               Pci\_bigger(i, j) = Pci(temp\_index\_r, temp\_index\_c);

&#x20;               if temp\_index\_c < c\_size

&#x20;                   temp\_index\_c = temp\_index\_c + 1;

&#x20;               elseif  (temp\_index\_r + 1) <= (window\_size)

&#x20;                   temp\_index\_r = temp\_index\_r + 1;

&#x20;                   temp\_index\_c = 1;

&#x20;               end

&#x20;           else

&#x20;               Pci\_bigger(i, j) = 0;

&#x20;           end

&#x20;       else

&#x20;           Pci\_bigger(i, j) = 0;

&#x20;       end

&#x20;   end

end



Pci\_bigger;

%% Final FSM state: compute output final image matrix and transfer the pixels one by one as an output to the testbench and store for reference.

omega  = zeros(window\_size, window\_size);

flag2 = 0;

Pci\_min = zeros(1, window\_size);

d = zeros(1, window\_size);

Beta = zeros(1, window\_size);

Y\_m  = zeros(1, window\_size);

output\_R = zeros(r\_size, c\_size);

output\_G = zeros(r\_size, c\_size);

output\_B = zeros(r\_size, c\_size);

output\_index\_r = 1;

output\_index\_c = 1;

%% We will make Pci bigger in rows manner only and change its centre accessing index so do the same here in while everywhere(a lot of places)

while (true)



&#x20;   %% block that is important to compute final image matrix using mostly

&#x20;   % combinational nets and just one non-blocking assignment

&#x20;   % Assuming that omega matrix is ready from the prev clock cycle and we can directly implement

&#x20;   % operations to compute image



&#x20;   % for now, Pci\_min optimization like Fig. 3c is not implemented but it

&#x20;   % can be done later. Add more pair3\_min vars to compute for 11\*11



&#x20;   % Step 6: Pci\_min and col\_mins

&#x20;  if flag2 == 1 % this output is not calculated the first iteration of the state

&#x20;      omega;

&#x20;   for k = 1:1:window\_size % to iterate through all the col in window

&#x20;       pair3\_min\_from\_col\_1 = Min3(omega(1,k), omega(2,k), omega(3,k));

&#x20;       pair3\_min\_from\_col\_2 = Min3(omega(4,k), omega(5,k), omega(6,k));

&#x20;       pair3\_min\_from\_col\_3 = Min3(omega(7,k), omega(8,k), omega(9,k));

&#x20;       pair3\_min\_from\_col\_collect = Min3(pair3\_min\_from\_col\_1, pair3\_min\_from\_col\_2, pair3\_min\_from\_col\_3);

&#x20;       pair3\_min\_from\_col\_final = Min3(pair3\_min\_from\_col\_collect, omega(10, k), omega(11, k));

&#x20;       % add more smaller pairs3 for 11\*11 window

&#x20;       Pci\_min(k) = pair3\_min\_from\_col\_final;

&#x20;   end

&#x20;

&#x20;   % Step 7 \& 8: Compute D and Beta

&#x20;   for l = 1:1:window\_size

&#x20;       if (Pci\_min(l) >= Gi\_old(1 , 1))

&#x20;           Beta(l) = 1;

&#x20;           d(l) = Pci\_min(l) - Gi\_old(1 , 1);

&#x20;       else

&#x20;           Beta(l) = 0;

&#x20;           d(l) = Gi\_old(1 , 1 ) - Pci\_min(l);

&#x20;

&#x20;       end

&#x20;   end



&#x20;   % Step 9: Select linear segment:

&#x20;   for m = 1:1:window\_size

&#x20;       if d(m) >= 0 \&\& d(m) <= 14.3

&#x20;           Y\_m(m) = 16384 - (bitshift(d(m),8) + bitshift(d(m),7) + bitshift(d(m),5));



&#x20;       elseif d(m) > 14.3 \&\& d(m) <= 38

&#x20;           Y\_m(m) = 13631 - (bitshift(d(m),7) + bitshift(d(m),6) + bitshift(d(m),5));



&#x20;       elseif d(m) > 38 \&\& d(m) <= 46.4

&#x20;           Y\_m(m) = 10747 - (bitshift(d(m),7) + bitshift(d(m),4) + bitshift(d(m),2));



&#x20;       elseif d(m) > 46.4 \&\& d(m) <= 67

&#x20;           Y\_m(m) = 7966 - (bitshift(d(m),6) + bitshift(d(m),4) + bitshift(d(m),3));



&#x20;       elseif d(m) > 67 \&\& d(m) <= 95

&#x20;           Y\_m(m) = 5017 - (bitshift(d(m),5) + bitshift(d(m),3) + bitshift(d(m),2));



&#x20;       elseif d(m) > 95 \&\& d(m) <= 135

&#x20;           Y\_m(m) = 2265 - (bitshift(d(m),2) + bitshift(d(m),3) + bitshift(d(m),1)) - d(m);



&#x20;       elseif d(m) > 135 \&\& d(m) <= 175

&#x20;           Y\_m(m) = 822 - bitshift(d(m),2);



&#x20;       else

&#x20;           Y\_m(m) = 416;

&#x20;       end

&#x20;   end



&#x20;   % step 10 Calculate Refined Illumination:

&#x20;   sum\_N = 0;

&#x20;   sum\_D = 0;

&#x20;   for m = 1:1:window\_size

&#x20;       sum\_N = sum\_N + (Beta(m)\*Y\_m(m)\*Pci\_min(m));

&#x20;   end



&#x20;   for m = 1:1:window\_size

&#x20;       sum\_D = sum\_D + (Beta(m)\*Y\_m(m));

&#x20;   end

&#x20;   Fm = (sum\_N/sum\_D);  % implement a lut + multiplier based on AI's method i.e scale this up too

&#x20;



&#x20;   % Step 11: Calculate Reflectance for R, G and B, will do this later as

&#x20;   % it comes out as decimal value (0 to 1) and handling that is tedious

&#x20;



&#x20;   % Step 12: Normalization of Fm is skipped as it will make 0 to 1 too



&#x20;   % Step 13: Modified Illumination for gamma correction \& contrast

&#x20;   % balancing without Fnorm for now(no change in accuracy)

&#x20;   Emod = sqrt(Fm)\*(sqrt(2\*255 - Fm)); % use lut approximation for root

&#x20;   temp\_emod\_by\_Fm = Emod/Fm; % implement division by lut memory



&#x20;   % Final Step 14: Enhanced output pixel, in verilog, just send the 3

&#x20;   % computed pixels to the output testbench and testbench will store the

&#x20;   % image



&#x20;   if output\_index\_c == 1

&#x20;       output\_R(output\_index\_r-1, c\_size) = temp\_emod\_by\_Fm \* R(output\_index\_r-1, c\_size);

&#x20;       output\_G(output\_index\_r-1, c\_size) = temp\_emod\_by\_Fm \* G(output\_index\_r-1, c\_size);

&#x20;       output\_B(output\_index\_r-1, c\_size) = temp\_emod\_by\_Fm \* B(output\_index\_r-1, c\_size);

&#x20;   else

&#x20;       output\_R(output\_index\_r, output\_index\_c-1) = temp\_emod\_by\_Fm \* R(output\_index\_r, output\_index\_c-1);

&#x20;       output\_G(output\_index\_r, output\_index\_c-1) = temp\_emod\_by\_Fm \* G(output\_index\_r, output\_index\_c-1);

&#x20;       output\_B(output\_index\_r, output\_index\_c-1) = temp\_emod\_by\_Fm \* B(output\_index\_r, output\_index\_c-1);



&#x20;   end



&#x20;   %% Shifting Gi\_old and filling in new value

&#x20;       for u = 1:1: window\_size - border\_pad\_width

&#x20;           for v = 1:1:c\_size-1

&#x20;               if v == c\_size-1

&#x20;                   Gi\_old(u,v) = Gi\_old(u,v+1);

&#x20;                   if u+1 \~= window\_size  - border\_pad\_width + 1

&#x20;                       Gi\_old(u,v+1) = Gi\_old(u+1,1);

&#x20;                   end

&#x20;               else

&#x20;                   Gi\_old(u,v) = Gi\_old(u, v+1);

&#x20;               end



&#x20;           end

&#x20;       end

&#x20;       % including a new value in Gi\_old matrix, in verilog the index

&#x20;       % logic is handled by the testbench user to pick things up from the

&#x20;       % pad\_R matrix that they have

&#x20;       Gi\_old(window\_size - border\_pad\_width,c\_size) = Max3( pad\_R(row\_index\_for\_Gi\_old, col\_index\_for\_Gi\_old), pad\_G(row\_index\_for\_Gi\_old, col\_index\_for\_Gi\_old), pad\_B(row\_index\_for\_Gi\_old, col\_index\_for\_Gi\_old));

&#x20;

&#x20;       if row\_index\_for\_Gi\_old \~= r\_pad\_size || col\_index\_for\_Gi\_old \~= c\_pad\_size - border\_pad\_width

&#x20;           if col\_index\_for\_Gi\_old == c\_pad\_size - border\_pad\_width



&#x20;                   col\_index\_for\_Gi\_old = 1 + border\_pad\_width;

&#x20;                   row\_index\_for\_Gi\_old = row\_index\_for\_Gi\_old + 1;

&#x20;           else

&#x20;               col\_index\_for\_Gi\_old = col\_index\_for\_Gi\_old + 1;

&#x20;           end

&#x20;       end



&#x20;  else

&#x20;       row\_index\_for\_Gi\_old = window\_size + 1;

&#x20;       col\_index\_for\_Gi\_old = 1 + border\_pad\_width;

&#x20;  end

&#x20;  flag2 = 1;

&#x20;

&#x20;  %% (Mirror padding) Pulling omega matrix correctly from the Pci matrix before Pci is changed at the end of clk cycle

&#x20;   % use the index of output\_ var instead of Pci broken var after Pci

&#x20;   % filled

&#x20;

&#x20;   % buffer zero pads replace Pci with clone

&#x20;   if output\_index\_c == 1 % need to compute many thing along with top and bottom left:diagonals

&#x20;       if output\_index\_r <= border\_pad\_width % need to compute upper left diagonals

&#x20;           for i = 1 : 1 :  border\_pad\_width + output\_index\_r % simply copying real values from Pci

&#x20;               for j = 1 : 1 : border\_pad\_width + 1

&#x20;                   omega(i + border\_pad\_width - output\_index\_r + 1, j + border\_pad\_width) = Pci\_bigger(i + border\_pad\_width - output\_index\_r + 1, j + border\_pad\_width);

&#x20;



&#x20;               end

&#x20;           end

&#x20;           for i = 1 : 1 : border\_pad\_width - output\_index\_r + 1 % computing upper mirror pad rows

&#x20;               for j = 1 : 1 : 1 + border\_pad\_width

&#x20;                   omega(i, j + border\_pad\_width) = Pci\_bigger(4 + 2\*border\_pad\_width - 2\*output\_index\_r - i, j + border\_pad\_width);

&#x20;               end

&#x20;           end

&#x20;

&#x20;           for i = 1 : 1 :  border\_pad\_width + output\_index\_r % computing left side mirror pad columns

&#x20;               for j = 1 : 1 :  border\_pad\_width

&#x20;                   omega(i + border\_pad\_width - output\_index\_r + 1, j) = Pci\_bigger(i + border\_pad\_width - output\_index\_r + 1,  2\*border\_pad\_width + 2 -j);

&#x20;               end

&#x20;           end



&#x20;           for i = 1 : 1 : border\_pad\_width - output\_index\_r + 1 % computing diagonal elements up left

&#x20;               for j = 1 : 1 : border\_pad\_width

&#x20;                   omega(i, j) = Pci\_bigger(4 + 2\*border\_pad\_width - 2\*output\_index\_r - i, 2\*border\_pad\_width + 2 -j);

&#x20;               end

&#x20;           end

&#x20;       elseif output\_index\_r <= r\_size - border\_pad\_width % no need to compute left bottom/upper diagonals/padrows top/bottom till here

&#x20;           for i = 1 : 1 :  2\*border\_pad\_width + 1 % simply copying real values from Pci

&#x20;               for j = 1 : 1 : border\_pad\_width + 1

&#x20;                   omega(i, j + border\_pad\_width) = Pci\_bigger(i, j + border\_pad\_width);

&#x20;



&#x20;               end

&#x20;           end



&#x20;           for i = 1 : 1 :  2\*border\_pad\_width + 1 % computing left side mirror pad columns

&#x20;               for j = 1 : 1 :  border\_pad\_width

&#x20;                   omega(i , j) = Pci\_bigger(i ,  2\*border\_pad\_width + 2 -j);

&#x20;               end

&#x20;           end

&#x20;

&#x20;       else % need to compute bottom left diagonals here

&#x20;           for i = 1 : 1 :  border\_pad\_width + r\_size - output\_index\_r+1 % simply copying real values from Pci

&#x20;               for j = 1 : 1 : border\_pad\_width + 1

&#x20;                   omega(i , j + border\_pad\_width) = Pci\_bigger(i, j + border\_pad\_width);

&#x20;

&#x20;               end

&#x20;           end

&#x20;           for i = 1 : 1 : + border\_pad\_width - r\_size + output\_index\_r % computing bottom mirror pad rows

&#x20;               for j = 1 : 1 : 1 + border\_pad\_width

&#x20;                   omega(2\*border\_pad\_width + 2 - i, j + border\_pad\_width) = Pci\_bigger(i + 2\*(r\_size - output\_index\_r), j + border\_pad\_width);

&#x20;               end

&#x20;           end

&#x20;

&#x20;           for i = 1 : 1 :  border\_pad\_width + r\_size - output\_index\_r+1 % computing left side mirror pad columns

&#x20;               for j = 1 : 1 :  border\_pad\_width

&#x20;                   omega(i , j) = Pci\_bigger(i ,  2\*border\_pad\_width + 2 -j);

&#x20;               end

&#x20;           end



&#x20;           for i = 1 : 1 : +border\_pad\_width - r\_size + output\_index\_r % computing bottom mirror pad diagonals

&#x20;               for j = 1 : 1 : border\_pad\_width

&#x20;                   omega(2\*border\_pad\_width + 2 - i, j) = Pci\_bigger(i + 2\*(r\_size - output\_index\_r),  2\*border\_pad\_width + 2 -j);

&#x20;               end

&#x20;           end

&#x20;       end



&#x20;   elseif output\_index\_c <= c\_size - border\_pad\_width % no diagonal issue here from right side

&#x20;       if output\_index\_r <= border\_pad\_width % top pad rows fix

&#x20;           for i = 1:1:window\_size

&#x20;               for j = 1:1:window\_size

&#x20;                   if j <= window\_size -1

&#x20;                       omega(i, j) = omega(i, j+1);

&#x20;                   end

&#x20;               end

&#x20;           end

&#x20;           % filling the last col with new real values

&#x20;           for i = 1:1: border\_pad\_width + output\_index\_r

&#x20;               omega(i + border\_pad\_width - output\_index\_r + 1, window\_size) = Pci\_bigger(i + border\_pad\_width - output\_index\_r + 1, 1+ 2\*border\_pad\_width);

&#x20;           end

&#x20;           % filling the last col with mirror values

&#x20;           for i = 1:1: border\_pad\_width - output\_index\_r + 1

&#x20;               omega(i, window\_size) = Pci\_bigger(4 + 2\*border\_pad\_width - 2\*output\_index\_r - i , 1+ 2\*border\_pad\_width);

&#x20;           end

&#x20;       elseif output\_index\_r <= r\_size - border\_pad\_width % no top\_pad or bottom\_pad rows

&#x20;           for i = 1:1:window\_size

&#x20;               for j = 1:1:window\_size

&#x20;                   if j <= window\_size -1

&#x20;                       omega(i, j) = omega(i, j+1);

&#x20;                   end

&#x20;               end

&#x20;           end

&#x20;           % filling the last col with new real values

&#x20;           for i = 1:1: 2\*border\_pad\_width + 1

&#x20;               omega(i, window\_size) = Pci\_bigger(i, 1+ 2\*border\_pad\_width);

&#x20;           end



&#x20;       else % pad bottom rows

&#x20;            for i = 1:1:window\_size

&#x20;               for j = 1:1:window\_size

&#x20;                   if j <= window\_size -1

&#x20;                       omega(i, j) = omega(i, j+1);

&#x20;                   end

&#x20;               end

&#x20;           end

&#x20;           % filling the last col with new real values

&#x20;           for i = 1:1: border\_pad\_width + r\_size - output\_index\_r+1

&#x20;               omega(i, window\_size) = Pci\_bigger(i, 1+ 2\*border\_pad\_width);

&#x20;           end

&#x20;           % filling the last col with mirror values

&#x20;           for i = 1:1: border\_pad\_width + output\_index\_r -r\_size

&#x20;               omega(2\*border\_pad\_width + 2 - i, window\_size) = Pci\_bigger(i + 2\*(r\_size - output\_index\_r), 1+ 2\*border\_pad\_width);

&#x20;           end

&#x20;       end



&#x20;   else % there might be a diagonal issue here(internal ifs) from right side

&#x20;       if output\_index\_r <= border\_pad\_width % top right diagonal

&#x20;            for i = 1:1:window\_size

&#x20;               for j = 1:1:window\_size

&#x20;                   if j <= window\_size -1

&#x20;                       omega(i, j) = omega(i, j+1);

&#x20;                   end

&#x20;               end

&#x20;           end

&#x20;           % filling the last col with mirror values

&#x20;           for i = 1:1: border\_pad\_width + output\_index\_r

&#x20;               omega(i + border\_pad\_width - output\_index\_r + 1, window\_size) = Pci\_bigger(i + border\_pad\_width - output\_index\_r + 1, 1 + 2\*(c\_size - output\_index\_c));

&#x20;           end



&#x20;           for i = 1 : 1 : border\_pad\_width - output\_index\_r + 1 % computing diagonal elements up right

&#x20;

&#x20;               omega(i, window\_size) = Pci\_bigger(4 + 2\*border\_pad\_width - 2\*output\_index\_r - i, 1 + 2\*(c\_size - output\_index\_c));

&#x20;

&#x20;           end

&#x20;       elseif output\_index\_r <= r\_size - border\_pad\_width % no diagonal issue

&#x20;            for i = 1:1:window\_size

&#x20;               for j = 1:1:window\_size

&#x20;                   if j <= window\_size -1

&#x20;                       omega(i, j) = omega(i, j+1);

&#x20;                   end

&#x20;               end

&#x20;           end

&#x20;           % filling the last col with mirror values

&#x20;           for i = 1:1: window\_size

&#x20;               omega(i, window\_size) = Pci\_bigger(i, 1 + 2\*(c\_size - output\_index\_c));

&#x20;           end

&#x20;

&#x20;

&#x20;       else % diagonal issue from bottom right

&#x20;            for i = 1:1:window\_size

&#x20;               for j = 1:1:window\_size

&#x20;                   if j <= window\_size -1

&#x20;                       omega(i, j) = omega(i, j+1);

&#x20;                   end

&#x20;               end

&#x20;            end

&#x20;           % filling the last col with mirror values

&#x20;           for i = 1:1: border\_pad\_width + r\_size - output\_index\_r+1

&#x20;               omega(i, window\_size) = Pci\_bigger(i, 1 + 2\*(c\_size - output\_index\_c));

&#x20;           end



&#x20;           for i = 1 : 1 : + border\_pad\_width - r\_size + output\_index\_r % computing diagonal elements bottom right

&#x20;

&#x20;               omega(2\*border\_pad\_width + 2 - i, window\_size) = Pci\_bigger(i + 2\*(r\_size - output\_index\_r), 1 + 2\*(c\_size - output\_index\_c));

&#x20;

&#x20;           end





&#x20;       end



&#x20;

&#x20;   end



&#x20;   if output\_index\_c < c\_size

&#x20;       output\_index\_c = output\_index\_c + 1;

&#x20;   else

&#x20;       output\_index\_c = 1;

&#x20;       output\_index\_r = output\_index\_r + 1;

&#x20;   end



&#x20;   %% Output is finally produced



&#x20;

&#x20;   % filling delta window at end depending upon if values in window are

&#x20;   % completely new or not(we can use previous columns as window simply slides).



&#x20;   % this if is for complete refilling of delta matrix from start.

&#x20;   if pci\_c\_filling\_index == 1

&#x20;      head\_for\_registerset = 1;

&#x20;       for k = 1:1:window\_size % to iterate through all the col in window

&#x20;       pair3\_max\_from\_col\_1 = Max3(delta(1,k), delta(2,k), delta(3,k));

&#x20;       pair3\_max\_from\_col\_2 = Max3(delta(4, k), delta(5, k), delta(6, k));

&#x20;       pair3\_max\_from\_col\_3 = Max3(delta(7, k), delta(8, k), delta(9, k));

&#x20;       pair3\_max\_from\_col\_collect = Max3(pair3\_max\_from\_col\_1, pair3\_max\_from\_col\_2, pair3\_max\_from\_col\_3);

&#x20;       pair3\_max\_from\_col\_final = Max3(pair3\_max\_from\_col\_collect, delta(10, k), delta(11, k));

&#x20;       % add more smaller pairs3 for 11\*11 window

&#x20;       register\_set\_max\_each\_col(k) = pair3\_max\_from\_col\_final;

&#x20;       end

&#x20;       max\_from\_registerset\_1 = Max3(register\_set\_max\_each\_col(1), register\_set\_max\_each\_col(2), register\_set\_max\_each\_col(3));

&#x20;       max\_from\_registerset\_2 = Max3(register\_set\_max\_each\_col(4), register\_set\_max\_each\_col(5), register\_set\_max\_each\_col(6));

&#x20;       max\_from\_registerset\_3 = Max3(register\_set\_max\_each\_col(7), register\_set\_max\_each\_col(8), register\_set\_max\_each\_col(9));

&#x20;       max\_from\_registerset\_collect = Max3(max\_from\_registerset\_1,max\_from\_registerset\_2 ,max\_from\_registerset\_3 );

&#x20;       max\_from\_registerset\_final = Max3(register\_set\_max\_each\_col(10), register\_set\_max\_each\_col(11), max\_from\_registerset\_collect);

&#x20;       % now that delta window is ready +max val; we will compute a value of pci

&#x20;       % and shift Gi matrix to include a new value





&#x20;       % First shift the Pci matrix and include a new value in it:

&#x20;       for u = 1:1:window\_size + border\_pad\_width + 1

&#x20;           for v = 1:1:c\_size-1

&#x20;               if v == c\_size-1

&#x20;                   Pci\_bigger(u,v) = Pci\_bigger(u,v+1);

&#x20;                   if u+1 \~= window\_size + border\_pad\_width + 1 + 1

&#x20;                       Pci\_bigger(u,v+1) = Pci\_bigger(u+1,1);

&#x20;                   end

&#x20;               else

&#x20;                   Pci\_bigger(u,v) = Pci\_bigger(u, v+1);

&#x20;               end



&#x20;           end

&#x20;       end

&#x20;

&#x20;       Pci\_bigger(window\_size + border\_pad\_width + 1, border\_pad\_width) = max\_from\_registerset\_final;

&#x20;

&#x20;

&#x20;       pci\_c\_filling\_index = pci\_c\_filling\_index + 1;

&#x20;

&#x20;

&#x20;

&#x20;       % making the patch: delta

&#x20;       for i = 1:1:1 + 2\*border\_pad\_width

&#x20;           for j = 1:1: 1+ 2\*border\_pad\_width

&#x20;               delta(i, j) = Gi(i, j); % patch about (2,2) or (6,6) always

&#x20;           end

&#x20;       end



&#x20;       % shift left and include a new value in the Gi matrix

&#x20;       for u = 1:1:window\_size

&#x20;           for v = 1:1:c\_pad\_size-1

&#x20;               if v == c\_pad\_size-1

&#x20;                   Gi(u,v) = Gi(u,v+1);

&#x20;                   if u+1 \~= window\_size + 1

&#x20;                       Gi(u,v+1) = Gi(u+1,1);

&#x20;                   end

&#x20;               else

&#x20;                   Gi(u,v) = Gi(u, v+1);

&#x20;               end



&#x20;           end

&#x20;       end

&#x20;       % including a new value in Gi matrix

&#x20;       Gi(window\_size,c\_pad\_size) = Max3( pad\_R(row\_index\_for\_Gi, col\_index\_for\_Gi), pad\_G(row\_index\_for\_Gi, col\_index\_for\_Gi), pad\_B(row\_index\_for\_Gi, col\_index\_for\_Gi));

&#x20;       % shifting the index for new values to be picked up from pad\_RGB

&#x20;       % for Gi

&#x20;       if row\_index\_for\_Gi \~= r\_pad\_size || col\_index\_for\_Gi \~= c\_size

&#x20;           if col\_index\_for\_Gi == c\_size



&#x20;                   col\_index\_for\_Gi = 1;

&#x20;                   row\_index\_for\_Gi = row\_index\_for\_Gi+1;

&#x20;           else

&#x20;               col\_index\_for\_Gi = col\_index\_for\_Gi + 1;

&#x20;           end

&#x20;       end



&#x20;   %% This is the case of preserving and making use of old values like DP

&#x20;   else







&#x20;       % now we compute max values for efficient register set(add more for

&#x20;       % 11\*11 future matrix

&#x20;       % now we compute max values for efficient register set(add more for

&#x20;       % 11\*11 future matrix

&#x20;       temp\_pair3\_forefficient\_colmax\_1 = Max3(delta(1, window\_size), delta(2, window\_size), delta(3, window\_size));

&#x20;       temp\_pair3\_forefficient\_colmax\_2 = Max3(delta(4, window\_size), delta(5, window\_size), delta(6, window\_size));

&#x20;       temp\_pair3\_forefficient\_colmax\_3 = Max3(delta(7, window\_size), delta(8, window\_size), delta(9, window\_size));

&#x20;       temp\_pair3\_forefficient\_colmax\_collect = Max3(temp\_pair3\_forefficient\_colmax\_1, temp\_pair3\_forefficient\_colmax\_2, temp\_pair3\_forefficient\_colmax\_3);

&#x20;       temp\_pair3\_forefficient\_colmax\_final = Max3(temp\_pair3\_forefficient\_colmax\_collect, delta(10, window\_size), delta(11, window\_size));



&#x20;       register\_set\_max\_each\_col(head\_for\_registerset) = temp\_pair3\_forefficient\_colmax\_final;

&#x20;       % might need to add head var in comb block itself

&#x20;       if head\_for\_registerset == window\_size % this was made for pipelining, does not work properly in fsm, might need to add extra code or recalc all in verilog comb block

&#x20;           head\_for\_registerset = 1;

&#x20;       else

&#x20;           head\_for\_registerset = head\_for\_registerset + 1;

&#x20;       end

&#x20;       % add more max\_temp\_registers more for 11\*11 matrix

&#x20;       max\_from\_registerset\_1 = Max3(register\_set\_max\_each\_col(1), register\_set\_max\_each\_col(2), register\_set\_max\_each\_col(3));

&#x20;       max\_from\_registerset\_2 = Max3(register\_set\_max\_each\_col(4), register\_set\_max\_each\_col(5), register\_set\_max\_each\_col(6));

&#x20;       max\_from\_registerset\_3 = Max3(register\_set\_max\_each\_col(7), register\_set\_max\_each\_col(8), register\_set\_max\_each\_col(9));

&#x20;       max\_from\_registerset\_collect = Max3(max\_from\_registerset\_1,max\_from\_registerset\_2 ,max\_from\_registerset\_3 );

&#x20;       max\_from\_registerset\_final = Max3(register\_set\_max\_each\_col(10), register\_set\_max\_each\_col(11), max\_from\_registerset\_collect);







&#x20;       % First shift the Pci matrix and include a new value in it:

&#x20;       for u = 1:1:window\_size + border\_pad\_width + 1

&#x20;           for v = 1:1:c\_size-1

&#x20;               if v == c\_size-1

&#x20;                   Pci\_bigger(u,v) = Pci\_bigger(u,v+1);

&#x20;                   if u+1 \~= window\_size + border\_pad\_width + 1 + 1

&#x20;                       Pci\_bigger(u,v+1) = Pci\_bigger(u+1,1);

&#x20;                   end

&#x20;               else

&#x20;                   Pci\_bigger(u,v) = Pci\_bigger(u, v+1);

&#x20;               end



&#x20;           end

&#x20;       end

&#x20;

&#x20;       Pci\_bigger(window\_size + border\_pad\_width + 1, border\_pad\_width) = max\_from\_registerset\_final;





&#x20;      % If the delta matrix end of a row then it needs to precompute all

&#x20;      % the values from Gi as it will go to the begin of the next row and

&#x20;      % so the head pointer will point to the first index

&#x20;      if (pci\_c\_filling\_index \~= c\_size)

&#x20;       for i = 1:1:window\_size

&#x20;           for j = 1:1:window\_size

&#x20;               if j <= window\_size -1

&#x20;                   delta(i, j) = delta(i, j+1);

&#x20;               end

&#x20;           end

&#x20;       end

&#x20;       % filling the last col with new values

&#x20;       for i = 1:1:window\_size

&#x20;           delta(i, window\_size) = Gi(i, 1+ 2\*border\_pad\_width);

&#x20;       end

&#x20;      else

&#x20;          head\_for\_registerset = 1; % take care of this in verilog

&#x20;       % making the patch: delta

&#x20;       for i = 1:1:1 + 2\*border\_pad\_width

&#x20;           for j = 1:1: 1+ 2\*border\_pad\_width

&#x20;               delta(i, j) = Gi(i, j); % patch about (2,2) or (6,6) always

&#x20;           end

&#x20;       end



&#x20;      end

&#x20;     %% to decide whether to shift left and include a new value in the Gi matrix

&#x20;     % or shift left 3 times so other things in this fsm states need to be

&#x20;     % paused

&#x20;      if pci\_c\_filling\_index \~= c\_size - 1

&#x20;       % we are somewhere in middle of the Gi line buff values. One new

&#x20;       % delta col in place of old one only in registerset for now. We

&#x20;       % don't shift 3 times here.





&#x20;       % to shift and include new value for Gi

&#x20;       for u = 1:1:window\_size

&#x20;           for v = 1:1:c\_pad\_size-1

&#x20;               if v == c\_pad\_size-1

&#x20;                   Gi(u,v) = Gi(u,v+1);

&#x20;                   if u+1 \~= 1 + window\_size

&#x20;                       Gi(u,v+1) = Gi(u+1,1);

&#x20;                   end

&#x20;               else

&#x20;                   Gi(u,v) = Gi(u, v+1);

&#x20;               end



&#x20;           end

&#x20;       end

&#x20;       % including a new value in Gi matrix



&#x20;       Gi(window\_size,c\_pad\_size) = Max3( pad\_R(row\_index\_for\_Gi, col\_index\_for\_Gi), pad\_G(row\_index\_for\_Gi, col\_index\_for\_Gi), pad\_B(row\_index\_for\_Gi, col\_index\_for\_Gi));

&#x20;       % shifting the index for new values to be picked up from pad\_RGB

&#x20;       % for Gi

&#x20;       if row\_index\_for\_Gi \~= r\_pad\_size || col\_index\_for\_Gi \~= c\_size

&#x20;           if col\_index\_for\_Gi == c\_size

&#x20;               col\_index\_for\_Gi = 1;

&#x20;               row\_index\_for\_Gi = row\_index\_for\_Gi+1;

&#x20;           else

&#x20;               col\_index\_for\_Gi = col\_index\_for\_Gi + 1;

&#x20;           end

&#x20;       end

&#x20;       if pci\_c\_filling\_index == c\_size \&\& (pci\_r\_filling\_index + 1 <= r\_size)

&#x20;           pci\_c\_filling\_index = 1;

&#x20;           pci\_r\_filling\_index = pci\_r\_filling\_index + 1;

&#x20;       elseif pci\_c\_filling\_index + 1 <= c\_size

&#x20;           pci\_c\_filling\_index = pci\_c\_filling\_index + 1  ;

&#x20;       end

&#x20;      else

&#x20;       %% Now we need to shift Gi buffer 3 times

&#x20;



&#x20;       % this is for one output per clock cycle shift technique

&#x20;       for u = 1:1:window\_size

&#x20;           for v = 1:1:c\_pad\_size

&#x20;               if u == window\_size \&\& v> c\_pad\_size - (1+2\*border\_pad\_width)

&#x20;               ;

&#x20;               else

&#x20;                   if v + (1+2\*border\_pad\_width) <= c\_pad\_size

&#x20;                       Gi(u,v) = Gi(u, v + (1+2\*border\_pad\_width));

&#x20;                   else

&#x20;                       Gi(u, v) = Gi(u+1, (1+2\*border\_pad\_width) - (c\_pad\_size-v));

&#x20;                   end



&#x20;               end



&#x20;           end

&#x20;       end

&#x20;       % including a new value in Gi matrix

&#x20;       % IMP: For this to be success, have many i/p ports that give out

&#x20;       % ahead/future values of pad matrices. ALso, on this operation, give an

&#x20;       % output with extra output port to tell it to the consumer that you

&#x20;       % need to shift your streaming by 1+2\*border\_width too.

&#x20;       temp = c\_pad\_size - (2\*border\_pad\_width); % this is error prone, if pad\_R goes next row, check for 11\*11

&#x20;       Gi;

&#x20;       Pci\_bigger;

&#x20;       for i = c\_pad\_size - (2\*border\_pad\_width) : 1 : (c\_pad\_size)

&#x20;           Gi(window\_size, i) = Max3( pad\_R(row\_index\_for\_Gi, col\_index\_for\_Gi +(i - temp)), pad\_G(row\_index\_for\_Gi, col\_index\_for\_Gi +(i - temp)), pad\_B(row\_index\_for\_Gi, col\_index\_for\_Gi + (i - temp)));

&#x20;       end

&#x20;

&#x20;       % Error prone: I am not sure about this

&#x20;       if row\_index\_for\_Gi \~= r\_pad\_size

&#x20;           row\_index\_for\_Gi = row\_index\_for\_Gi + 1;

&#x20;           col\_index\_for\_Gi = 1;

&#x20;       end

&#x20;       if pci\_c\_filling\_index == c\_size \&\& (pci\_r\_filling\_index + 1 <= r\_size)

&#x20;           pci\_c\_filling\_index = 1;

&#x20;           pci\_r\_filling\_index = pci\_r\_filling\_index + 1;

&#x20;       elseif pci\_c\_filling\_index + 1 <= c\_size

&#x20;           pci\_c\_filling\_index = pci\_c\_filling\_index + 1  ;

&#x20;       end



&#x20;      end

&#x20;



&#x20;   end

&#x20;   head\_for\_registerset;

&#x20;   register\_set\_max\_each\_col;

&#x20;   Pci\_bigger;

&#x20;   Gi;

&#x20;   delta;

&#x20;   if output\_index\_r > r\_size   % implement it as if conditional for "done" fsm state

&#x20;       break; % Exit the loop if we have filled all rows

&#x20;   end

&#x20;

end







function result = Max3(R, G, B)

if R >= G \&\& R >= B

&#x20;   result = R;

elseif G >= B

&#x20;   result = G;

else

&#x20;   result = B;

end

end

function result2 = Min3(x, y, z)

if x<= y \&\& x<= z

&#x20;   result2 = x;

elseif y<=z

&#x20;   result2 = y;

else

&#x20;   result2 = z;

end

end

output\_R = uint8(output\_R);

output\_G = uint8(output\_G);

output\_B = uint8(output\_B);



output\_img(:,:,1) = output\_R;

output\_img(:,:,2) = output\_G;

output\_img(:,:,3) = output\_B;



figure;

imshow(img);

title('original');



figure;

imshow(output\_img);

title('processed output');

