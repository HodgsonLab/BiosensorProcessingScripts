%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% affine transformation fit based morphing
% 
% Program to do morphing of channels based on a priori calibration.
% Binary mask the bead field data for optimal results
% Flatten field prior to threasholding for masking for optimal results
% Must have a priori calibration of the FOV using the morphPrep.m.
% needs Shift.xls with x-y shift values, subpixel. This takes pre-morph
% shift and post-morph shift.  If pre-morph shift set to 0,0, then same as
% morph4.m
%
% Requires shiftImage.m subroutine
%
% Louis Hodgson Dec 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



clear all;

warning off;
fprintf(1,'Morphs and shifts in relation to reference; need input_points base_points and Shift Excel files \n');
D=input('Enter duration:	');
lead0=ceil(log10(D+1));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Control point determination
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%fname2In=input('Enter file name you want to morph and shift in relation to the reference:  ','s');  % FRET input file name
%fname3In=input('Enter file name reference (typically CFP stays put):  ','s');  % CFP reference file name
           BNAMEIN=sprintf('base_points.xls');
           base_points = double(xlsread(BNAMEIN));  %this is CFP channel as master
           INAMEIN=sprintf('input_points.xls');
           input_points = double(xlsread(INAMEIN));  % this is FRET channel as slave
           
           SNAMEIN=sprintf('Shift.xls'); % this is shift parameters
           Shift = double (xlsread(SNAMEIN));
           
           
           
           
    %  tform = cp2tform(input_points, base_points, 'polynomial',2); 
           
     tform = cp2tform(input_points, base_points, 'affine');

   % tform = cp2tform(input_points, base_points, 'polynomial',3);

   % tform = cp2tform(input_points, base_points, 'polynomial',4);
        
    %     tform = cp2tform(input_points, base_points, 'lwm');


    for x=1:D
        switch lead0
            case {0}
                fname=sprintf('%i',x);
            case {1}
                fname=sprintf('%i',x);
            case {2}
                fname=sprintf('%.2i',x);
            case {3}
                fname=sprintf('%.3i',x);
            case {4}
                fname=sprintf('%.4i',x);
            otherwise
                fname=sprintf('%i',x);
        end

        fprintf(1,'Current time index is %d.\n', x);
    	%fname2=sprintf('%s%s.tif',fname2In,fname);
        %fname3=sprintf('%s%s.tif',fname3In,fname);
        fname2=sprintf('FRETscbs%s.tif',fname);
        fname3=sprintf('CFPscbs%s.tif',fname);
        aa2=imread(fname2,'tif');  %FRET image
        aa3=imread(fname3,'tif');  %reference CFP image
        [H,W] = size(aa2);
       
        
        
        
        
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% First shift by specific amount


       aa2 = shiftImage(aa2,Shift(1,1),Shift(1,2));    

        
        
%%%%%%%%%%%%%%%%%%%% morph here
       
        registered = imtransform(aa2,tform);
        [HH, WW] = size(registered);
        
        if (HH == H)&&(WW == W);
            registCrop =registered;
        elseif (HH == H)&&(WW > W);
            registCrop = imcrop(registered, [0 0 W H]);
        elseif (HH == H)&&(WW < W);
            registCrop = padarray(registered, [0 (W - WW)],0, 'post'); 
        elseif (HH>H)&&(WW==W);
            registCrop = imcrop(registered, [0 0 W H]);
        elseif (HH<H)&&(WW==W);
            registCrop = padarray(registered, [(H-HH) 0],0, 'post'); 
        elseif (HH>H)&&(WW>W);
            registCrop = imcrop(registered, [0 0 W H]);
        elseif (HH>H)&&(WW<W);
            registCrop = padarray(registered, [0 (W - WW)],0, 'post'); 
            registCrop=imcrop(registCrop, [0 0 W H]);
        elseif (HH<H)&&(WW>W);
            registCrop = padarray(registered, [(H-HH) 0],0, 'post'); 
            registCrop=imcrop(registCrop, [0 0 W H]);
        elseif (HH<H)&&(WW<W);
            registCrop = padarray(registered, [(H-HH) (W-WW)],0, 'post'); 
        end
        
        
        
        
    %    if (SS1(1)>=SS(1))
     %       H=SS(1);
         %   registCrop = imcrop(registered, [0 0 0 H]);
      %  else
          %  registCrop = padarray(registered, [0 (SS(1)-SS1(1))],0, 'post');
%           H=SS1(1);
       % end
       %  if (SS1(2)>=SS(2));
        %  W=SS(2);
          %registCrop = imcrop(registCrop, [0 0 W 0]);
        % else
          %registCrop = padarray(registCrop, [(SS(2)-SS1(2)) 0],0, 'post');   
         % W=SS1(2);
         % end        
        
       % W=SS(2);
       % H=SS(1);
        
       
    %   registCrop = imcrop(registered, [0 0 W H]);
       % registCrop2= imcrop(aa3,[0 0 W H]);
       
 %%%%%%%%%%%%%%%%%%%%%%%%%% post morph shift      
       
       registCrop = shiftImage(registCrop,Shift(2,1),Shift(2,2));     
        

        %ffname=sprintf('m%s%s.tif',fname2In, fname);
        %ff2name=sprintf('m%s%s.tif',fname3In, fname);            
       

        ffname=sprintf('mFRETscbs%s.tif', fname);
        ff2name=sprintf('mCFPscbs%s.tif', fname);
        imwrite(aa3,ff2name,'tif','Compression','none');
        imwrite(registCrop,ffname,'tif','Compression','none');
       
    end
    