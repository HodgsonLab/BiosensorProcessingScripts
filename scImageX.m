%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   shading software scImageY.m
% 
%   uses Median shading intensity for scaling
%   puts median filter on XXXsc images for output
%   This version takes bright set of shading images (make as bright as
%   possible without saturation, using the same ND filter setting as the
%   actual acquisition), scales up to 65535 and then uses those for shading
%   correction. Plastic fluorescence standards should be usable for this.
%
%
%   Louis Hodgson 05/23
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



clear all;


D=input('Enter duration:	');
lead0=ceil(log10(D+1));
%fname1In=input('Enter file name for reference (Donor-CFP etc.):  ','s');  % This is the name of the ratio file to be corrected
%fname2In=input('Enter file name for numerator (FRET):  ','s');  % This is the name of the ratio file to be corrected
fname3In=input('Enter file name for reference shade (Donor-CFPshade etc.):  ','s');  % This is the name of the ratio file to be corrected
fname4In=input('Enter file name for numerator shade (FRETshade):  ','s');  % This is the name of the ratio file to be corrected
% fname5In=input('Enter file name for DC image reference (CFP or Atto):  ','s');  % This is the name of the ratio file to be corrected
% fname6In=input('Enter file name for DC image numerator (FRET or ISO):  ','s');  % This is the name of the ratio file to be corrected
%fname7In=input('Enter file name for bad pixels:  ','s');  % This is the name of the ratio file to be corrected

fname3=sprintf('%s.tif',fname3In); %CFPshade
fname4=sprintf('%s.tif',fname4In); %FRETshade
% fname5=sprintf('%s.tif',fname5In); %DC CFP
% fname6=sprintf('%s.tif',fname6In); %DC FRET
% fname7=sprintf('%s.tif',fname7In); %bad pixels

shade1=double(imread(fname3,'tif')); %shade for reference
shade2=double(imread(fname4,'tif')); %shade for numerator
% DCref=double(imread(fname5,'tif'));
% DCnum=double(imread(fname6,'tif'));
%badPix=double(imread(fname7,'tif'));
        if size(shade1)~=size(shade2)
            error('Image sizes don''t match.')
        end
    
SS=size(shade1);

% aveRef=sum(sum(shade1))/(SS(1)*SS(2));
% aveNum=sum(sum(shade2))/(SS(1)*SS(2));
medRef=median(shade1(:)); 
medNum=median(shade2(:));
Shade1Max=max(shade1(:));
Shade2Max=max(shade2(:));


%aveDCref=sum(sum(DCref))/(SS(1)*SS(2));
%aveDCnum=sum(sum(DCnum))/(SS(1)*SS(2));

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
        %fname1=sprintf('%s%s.tif',fname1In,fname);
    	%fname2=sprintf('%s%s.tif',fname2In,fname);
        fname1=sprintf('CFP%s.tif',fname);
    	fname2=sprintf('FRET%s.tif',fname);
        refImage=double(imread(fname1,'tif'));
        numImage=double(imread(fname2,'tif'));
        
       % refImage2=(refImage-DCref)+ aveDCref;
       % shade1p=(shade1-DCref) + aveDCref;
        
       % numImage2=(numImage-DCnum) + aveDCnum;
       % shade2p=(shade2-DCnum) + aveDCnum;
        
        
        
        refOut=uint16(medRef *((refImage)./(shade1)));
        numOut=uint16(medNum *((numImage)./(shade2)));
        refOut=medfilt2(refOut, [3 3]);
        numOut=medfilt2(numOut, [3 3]);
        
        
        
        
        
        
     %   ffname1=sprintf('%ssc%s.tif',fname1In,fname);  %CFPsc output
     %   ffname2=sprintf('%ssc%s.tif',fname2In,fname);  %FRETsc output
        ffname1=sprintf('CFPsc%s.tif',fname);  %CFPsc output
        ffname2=sprintf('FRETsc%s.tif',fname);  %FRETsc output
        imwrite(refOut,ffname1,'tif','Compression','none');
        imwrite(numOut,ffname2,'tif','Compression','none');
    
    end