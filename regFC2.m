%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% regFC.m
% 
% Program to do registration of FRET and CFP ONLY.
% Must have FRETmk.tif and CFPmk.tif with running numbers.
% These input files must be shade corrected, background subtracted and
% MASKED images.
% Outputs registered FRET images only (FRETreg.tif).
%
% Based on Feimo Shen's kr_fret routine
%
% Louis Hodgson Jan 2007
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



clear all;

        

D=input('Enter duration:	');
lead0=ceil(log10(D+1));


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
        fname1=sprintf('CFPmk%s.tif',fname);
    	fname2=sprintf('FRETmk%s.tif',fname);
        
        aa1=imread(fname1,'tif');
        aa2=imread(fname2,'tif');
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

        offsetval(x,1)= xoffsetsub;
        offsetval(x,2)= yoffsetsub;
        

        
                      
        clear correlation p* a* b* fv*;     % fixing matlab memory problem
    end
    savefile=sprintf('offsets.csv');
    csvwrite(savefile, offsetval);
    
    xOffsets = offsetval(:,1);
    yOffsets = offsetval(:,2);
    xOffsetval = median(xOffsets);
    yOffsetval = median(yOffsets);
    
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
        fprintf(1,'Writing file, time index %d.\n', x);
        fname1=sprintf('CFPmk%s.tif',fname);
    	fname2=sprintf('FRETmk%s.tif',fname);
        
        aa1=imread(fname1,'tif');
        aa2=imread(fname2,'tif');    
        xoffset=floor(xOffsetval);
        yoffset=floor(yOffsetval);
        % whole pixel shift first:
        se = translate(strel(1), [yoffset xoffset]);
        aa2 = imdilate(uint16(aa2),se);
        % then subpixel shift:
        aa2 = subalign(aa2,xOffsetval-xoffset,yOffsetval-yoffset);
        aa2=uint16(aa2);
        ffname=sprintf('FRETreg%s.tif',fname);
        imwrite(aa2,ffname,'tif','Compression','none');
    
    end
    
          fprintf(1,'FRET X-offset:%5.3f\n', xOffsetval);  
          fprintf(1,'FRET Y-offset:%5.3f\n', yOffsetval);    
