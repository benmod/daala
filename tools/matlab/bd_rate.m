#!/usr/bin/octave -qf

warning("off","Octave:nested-functions-coerced");
warning("on","Octave:missing-semicolon");

args=argv();

if size(args,1)!=2
  printf("usage: ./bd_rate.sh <RD-1.out> <RD-2.out>\n");
  printf("influential environment variables:\n");
  printf("TYPE: piecewise-linear or cubic-polyfit\n");
  printf("MIN_BPP, MAX_BPP: Bounds, in bits per pixel, for curve integration.\n");
  printf("              Ignore rate %% if this range is small.\n");
  return
end

TYPE=getenv("TYPE");
if strcmp(TYPE,"")
  TYPE="piecewise-linear";
end

MIN_BPP=getenv("MIN_BPP");
if strcmp(MIN_BPP,"")
  min_bpp = 0;
else
  min_bpp = str2double(MIN_BPP);
  if isnan(min_bpp)
    printf("MIN_BPP must be a floating-point number.");
    return;
  end
end

MAX_BPP=getenv("MAX_BPP");
if strcmp(MAX_BPP,"")
  max_bpp = Inf;
else
  max_bpp = str2double(MAX_BPP);
  if isnan(max_bpp)
    printf("MAX_BPP must be a floating-point number.");
    return;
  end
end

if min_bpp >= max_bpp
  printf("MAX_BPP must be greater than MIN_BPP.");
  return;
end

switch (TYPE)
  case "piecewise-linear"
    t=1;
  case "cubic-polyfit"
    t=2;
%  case "two-point-monotone-cubic-spline"
%    t=3;
%  case "three-point-monotone-cubic-spline"
%    t=4;
%  case "cubic-spline-interp"
%    t=5;
%  case "shape-preserving-cubic-hermite-interp"
%    t=6;
  otherwise
    printf("Invalid type: %s\n",TYPE);
    return
endswitch

rd1=load("-ascii",args{1});
rd2=load("-ascii",args{2});

rd1=flipud(sortrows(rd1,1));
rd2=flipud(sortrows(rd2,1));

rate1=rd1(:,3)*8./rd1(:,2);
rate2=rd2(:,3)*8./rd2(:,2);

pin = program_invocation_name;
chdir(pin(1:(length(pin)-length(program_name))));

[psnr_rate,psnr_dsnr]=bjontegaard([rate1,rd1(:,4)],[rate2,rd2(:,4)],t,min_bpp,max_bpp);
[psnrhvs_rate,psnrhvs_dsnr]=bjontegaard([rate1,rd1(:,5)],[rate2,rd2(:,5)],t,min_bpp,max_bpp);
[ssim_rate,ssim_dsnr]=bjontegaard([rate1,rd1(:,6)],[rate2,rd2(:,6)],t,min_bpp,max_bpp);
[fastssim_rate,fastssim_dsnr]=bjontegaard([rate1,rd1(:,7)],[rate2,rd2(:,7)],t,min_bpp,max_bpp);

if ((min_bpp != 0) || (max_bpp != Inf))
  printf("          DSNR (dB)\n");
  printf("    PSNR %0.5f\n",psnr_dsnr);
  printf(" PSNRHVS %0.5f\n",psnrhvs_dsnr);
  printf("    SSIM %0.5f\n",ssim_dsnr);
  printf("FASTSSIM %0.5f\n",fastssim_dsnr);
else 
  printf("           RATE (%%)  DSNR (dB)\n");
  printf("    PSNR %0.5f  %0.5f\n",psnr_rate,psnr_dsnr);
  printf(" PSNRHVS %0.5f  %0.5f\n",psnrhvs_rate,psnrhvs_dsnr);
  printf("    SSIM %0.5f  %0.5f\n",ssim_rate,ssim_dsnr);
  printf("FASTSSIM %0.5f  %0.5f\n",fastssim_rate,fastssim_dsnr);
endif
