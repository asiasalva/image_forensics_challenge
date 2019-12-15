%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Course :  Multimedia Data Security                             %
% Project:  Second competition - get_map function                %
% Refereence paper: Fast, automatic and fine-grained tampered    %
%                   JPEG img detection via DCT coeff analysis    %
% Group name: beermark                                           %
% Group members: Stefano Branchi; Federico Brugiolo;             %
%                Matteo Malacarne; Asia Salvaterra               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function get_map(imgPath)
    addpath('./SUPPORT/support_functions/');
    addpath('./SUPPORT/jpegtbx_1.4/');
    
    %% Read img
    imgName = split(imgPath, '/');
    imgName = imgName{end};
    imgNames = split(imgName, '.');
    imgName = imgNames{1};
    
    format = imgNames{2};
    
    if contains(format,'jpg')
        im = jpeg_read(imgPath);
    else
        im = imread(imgPath);
        imwrite(im, 'tmp.jpg', 'Quality', 100);
        im = jpeg_read('tmp.jpg');
        delete('tmp.jpg');
    end
    
    %% From paper description
    MaxCoeffs = 15;
    coeff = [1 9 2 3 10 17 25 18 11 4 5 12 19 26 33 41 34 27 20 13 6 7 14 21 28 35 42 49 57 50 43 36 29 22 15 8 16 23 30 37 44 51 58 59 52 45 38 31 24 32 39 46 53 60 61 54 47 40 48 55 62 63 56 64];

    for channel=1
        coeff_array = im.coef_arrays{channel};
        coeff_array=coeff_array(1:end,:);

        for coeffIndex=1:MaxCoeffs

            coe = coeff(coeffIndex);
            startY = mod(coe,8);
            if startY == 0
                startY = 8;
            end
            startX=ceil(coe/8);
            sel_coeffs=coeff_array(startX:8:end, startY:8:end);
            coeff_list=reshape(sel_coeffs,1,numel(sel_coeffs));


            minHistValue=min(coeff_list)-1;
            maxHistValue=max(coeff_list)+1;

            coeff_hist=hist(coeff_list,minHistValue:maxHistValue);

            AllHists{coeffIndex}=coeff_hist;

            if numel(coeff_hist>0)
                [MaxHVal,s_0]=max(coeff_hist);
                s_0_Out(coeffIndex)=s_0;
                dims(coeffIndex)=length(coeff_hist);
                H=zeros(floor(length(coeff_hist)/4),1);
                for coeffInd=1:(length(coeff_hist)-1)
                    vals=[coeff_hist(s_0:coeffInd:end) coeff_hist(s_0-coeffInd:-coeffInd:1)];
                    H(coeffInd)=mean(vals);
                end
                H_Out{coeffIndex}=H;
                [a,p_h_avg(coeffIndex)]=max(H);
            else
                s_0_Out(coeffIndex)=0;
                dims(coeffIndex)=0;
                H_Out{coeffIndex}=[];
                p_h_avg(coeffIndex)=1;
            end

            FFT=abs(fft(coeff_hist));
            FFT_Out{coeffIndex}=FFT;

            if length(FFT)>0
                DC=FFT(1);

                %Find first local minimum, to remove DC peak
                FreqValley=1;
                while (FreqValley<length(FFT)-1) && (FFT(FreqValley)>= FFT(FreqValley+1))
                    FreqValley=FreqValley+1;
                end

                FFT=FFT(FreqValley:floor(length(FFT)/2));
                FFT_smoothed{coeffIndex}=FFT;
                [maxPeak,FFTPeak]=max(FFT);
                FFTPeak=FFTPeak+FreqValley-1-1; %-1 bc FreqValley appears twice, and -1 for the 0-freq DC term
                if length(FFTPeak)==0 | maxPeak<DC/5 | min(FFT)/maxPeak>0.9 %threshold at 1/5 the DC and 90% the remaining lowest to only retain significant peaks
                    p_h_fft(coeffIndex)=1;
                else
                    p_h_fft(coeffIndex)=round(length(coeff_hist)/FFTPeak);
                end
            else
                FFT_Out{coeffIndex}=[];
                FFT_smoothed{coeffIndex}=[];
                p_h_fft(coeffIndex)=1;
            end

            p_final(coeffIndex)=p_h_fft(coeffIndex);

            if p_final(coeffIndex)~=1
                adjustedCoeffs=sel_coeffs-minHistValue+1;
                period_start=adjustedCoeffs-(rem(adjustedCoeffs-s_0_Out(coeffIndex),p_final(coeffIndex)));
                for kk=1:size(period_start,1)
                    for ll=1:size(period_start,2)
                        if period_start(kk,ll)>=s_0_Out(coeffIndex)
                            period=period_start(kk,ll):period_start(kk,ll)+p_final(coeffIndex)-1;

                            if period_start(kk,ll)+p_final(coeffIndex)-1>length(coeff_hist)
                                period(period>length(coeff_hist))=period(period>length(coeff_hist))-p_final(coeffIndex);
                            end

                            num(kk,ll)=coeff_hist(adjustedCoeffs(kk,ll));
                            denom(kk,ll)=sum(coeff_hist(period));
                        else
                            period=period_start(kk,ll):-1:period_start(kk,ll)-p_final(coeffIndex)+1;

                            if period_start(kk,ll)-p_final(coeffIndex)+1<= 0
                                period(period<=0)=period(period<=0)+p_final(coeffIndex);
                            end
                            num(kk,ll)=coeff_hist(adjustedCoeffs(kk,ll));
                            denom(kk,ll)=sum(coeff_hist(period));

                        end
                    end
                end
                P_u=num./denom;
                P_t=1./p_final(coeffIndex);

                P_tampered(:,:,coeffIndex)=P_t./(P_u+P_t);
                P_untampered(:,:,coeffIndex)=P_u./(P_u+P_t);

            else
                P_tampered(:,:,coeffIndex)=ones(ceil(size(coeff_array,1)/8),ceil(size(coeff_array,2)/8))*0.5;
                P_untampered(:,:,coeffIndex)=1-P_tampered(:,:,coeffIndex);
            end
        end
    end

    P_tampered_Overall=prod(P_tampered,3)./(prod(P_tampered,3)+prod(P_untampered,3));
    P_tampered_Overall(isnan(P_tampered_Overall))=0;

    OutputMap=P_tampered_Overall;

    %% Select the best thresold and retrieve the estimated map
    t = mean(mean(OutputMap)) + var(var(OutputMap));
    n_cc = 0;
    minvalue = 100000;
    maxvalue = 3000000;
    while n_cc < 1
        map_est = imbinarize(OutputMap, t);
        map_est = repelem(map_est, 8, 8);

        map_est = medfilt2(map_est,[40 40],'symmetric'); 

        map_est = map_est(1:1500, :);
        map_est = bwareafilt(map_est,[minvalue maxvalue]);
        CC = bwconncomp(map_est);
        if CC.NumObjects == 0
            t = t/10;
            minvalue = minvalue - 1000;
        elseif CC.NumObjects > 1
            minvalue = minvalue + 10000;
        else
            n_cc = 1;
        end    
    end
    
    imwrite(map_est, strcat('DEMO-RESULTS/',imgName, '.bmp'));
    
end