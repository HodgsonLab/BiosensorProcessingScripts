%%%%%%%%%%%%%%%%%%%%
% Automatic tracking-based morphing control point determination.
% Requires calibration sets of images using fluorescent beads.
% creates Excel files "base_points.xls" and "input_points" containing
% required coordinate transformation data pair for morph.m program
% It also creates Shift.xls containing the initial shift and the final
% shift
%
% Louis Hodgson 2019
%%%%%%%%%%%
clear all;

warning off;

%D=input('Enter duration:	');
%lead0=ceil(log10(D+1));

fnameCFP=input('Enter calibration file name for reference CFP channel (master channel):  ','s');
fnameFRET=input('Enter calibration file name for RED/DIC channel (slave channel):  ','s');
Factor=input('Enter how far to look(probably 20-30 is recommended):   ');
X=input('Enter Horizontal X shift to start;approx. -5 is usual:    ');
Y=input('Enter Vertical Y shift; approx. +25 is usual:    ');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% First shift by specific amount
    xOffsetval = X;
    yOffsetval = Y;

FNAMEINFRET = sprintf('%s.tif', fnameFRET);  % reading bottom image
a= imread (FNAMEINFRET, 'tif'); 
    
    
        xoffset=floor(xOffsetval);
        yoffset=floor(yOffsetval);
        % whole pixel shift first:
        se = translate(strel(1), [yoffset xoffset]);
        a = imdilate(uint16(a),se);
        % then subpixel shift:
        a = subalign(a,xOffsetval-xoffset,yOffsetval-yoffset);
        a=uint16(a);  % a is now shifted
        Shift(1,1)= xOffsetval;
        Shift(1,2)= yOffsetval;
        clear xOffsetval; 
        clear yOffsetval;        

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Start processing for tracking


se=strel('disk',10);

a=medfilt2(a, [3 3]);
FRET=a; %this is bottom
a=double(a)+250;
a1=imopen(a,se);
a=1000*(a./a1);
a = bpass(a,1,6);

pk = pkfnd(a,20,7);
cnt = cntrd(a,pk,3);
listF=cnt(:,1:2);
listF(:,3)=1;

FNAMEINCFP = sprintf('%s.tif', fnameCFP);
b= imread (FNAMEINCFP, 'tif'); 
b=medfilt2(b, [3 3]);
CFP=b;
b=double(b)+250;
b1=imopen(b,se);
b=1000*(b./b1);
b=bpass(b,1,6);

pk2 = pkfnd(b,20,7);
cnt = cntrd(b,pk2,3);
listC=cnt(:,1:2);
listC(:,3)=0;

aSize=size(listF);
bSize=size(listC);

listStart=bSize(1)+1;
listEnd=bSize(1)+aSize(1);

listC(listStart:listEnd,1)=listF(:,1);
listC(listStart:listEnd,2)=listF(:,2);
listC(listStart:listEnd,3)=listF(:,3);
param.mem=0;param.dim=2;param.good=2;param.quiet=0;
tr = track(listC, Factor, param);
xlswrite('track.xls',tr);

A=size(tr);
B=A(1)/2;
for I=1:B
    tr1=(2*I)-1;
    tr2=(2*I);
    base_points(1,I)=tr(tr1,1);
    input_points(1,I)=tr(tr2,1);
    base_points(2,I)=tr(tr1,2);
    input_points(2,I)=tr(tr2,2);
end
base_points=base_points';
input_points=input_points';
xlswrite('base_points.xls',base_points);
xlswrite('input_points.xls',input_points);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Morphing to test start here:

BNAMEIN=sprintf('base_points.xls');
           base_points = double(xlsread(BNAMEIN));  %this is CFP channel as master
           INAMEIN=sprintf('input_points.xls');
           input_points = double(xlsread(INAMEIN));  % this is FRET channel as slave
           
    %  tform = cp2tform(input_points, base_points, 'polynomial',2); 
           
     tform = cp2tform(input_points, base_points, 'affine');

   % tform = cp2tform(input_points, base_points, 'polynomial',3);

   % tform = cp2tform(input_points, base_points, 'polynomial',4);
        
    %     tform = cp2tform(input_points, base_points, 'lwm');
    
%       tform = cp2tform(input_points, base_points, 'nonreflective similarity');
    
        aa2=FRET;  %FRET image
        aa3=CFP;  %reference CFP image
        SS=size(aa3);
        registered = imtransform(aa2,tform);
        SS1=size(registered);
        if (SS1(1)>=SS(1));
            H=SS(1);
        else
            H=SS1(1);
        end
        if (SS1(2)>=SS(2));
            W=SS(2);
        else
            W=SS1(2);
        end        
        
        %W=SS(2)-10;
        %H=SS(1)-10;
        
        registCrop = imcrop(registered, [0 0 W H]); %FRET
        registCrop2= imcrop(aa3,[0 0 W H]);  %CFP
        
         
       

        ffname=sprintf('m%s.tif',fnameFRET);
        ff2name=sprintf('m%s.tif',fnameCFP);
      
        imwrite(registCrop,ffname,'tif','Compression','none');  %FRET
        imwrite(registCrop2,ff2name,'tif','Compression','none');  %CFP
        
  

    
  
     
        aa1=uint16(double(registCrop2));
        aa2=uint16(double(registCrop));
        if size(aa1)~=size(aa2)
            error('Image sizes don''t match.')
        end
        SS=size(aa1);
        aa1=double(aa1);
        aa2=double(aa2);
        picc1=reshape(aa1,1,(SS(1)*SS(2)));
        picc2=reshape(aa2,1,(SS(1)*SS(2)));

        
        
        picc1(picc1>0)=255;
        %picc1=double(picc1);
        
        picc2(picc2>0)=255;
        %picc2=double(picc2);
        
        picc1=reshape(picc1, SS(1),SS(2));
        picc2=reshape(picc2, SS(1),SS(2));
        

        
     
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % registration based on cross correlation
        im1a_flag=0;
        im2a_flag=0;
        
        clear pic1 pic2 post*;
        correlation=normxcorr2(picc1, picc2);
        %offset by correlation

        [xoffsetsub,yoffsetsub]=subpixShift(correlation)

        offsetval(1,1)= xoffsetsub;
        offsetval(1,2)= yoffsetsub;
 
        
%Shift to test
        
        
  xOffsetval = offsetval(1,1);
    yOffsetval = offsetval(1,2);
    
   

        aaX=uint16(double(registCrop));
           
        xoffset=floor(xOffsetval);
        yoffset=floor(yOffsetval);
        % whole pixel shift first:
        se = translate(strel(1), [yoffset xoffset]);
        aaX = imdilate(uint16(aaX),se);
        % then subpixel shift:
        aaX = subalign(aaX,xOffsetval-xoffset,yOffsetval-yoffset);
        aaX=uint16(aaX);
        Shift(2,1)= xOffsetval;
        Shift(2,2)= yOffsetval;
        clear xOffsetval; 
        clear yOffsetval
        
        
        
        ffname=sprintf('shiftm%s.tif',fnameFRET);
        imwrite(aaX,ffname,'tif','Compression','none');
        

        
   xlswrite('Shift.xls',Shift);
    
 
    
    

    
    
    
        
        

