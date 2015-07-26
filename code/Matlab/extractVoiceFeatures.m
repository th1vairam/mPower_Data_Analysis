% Wrapper function to call Max Little's voice extraction feature
clear
close all
clc

% Add Max code's to search path 
addpath('/mnt/Github/PDScores/bridge_ufb (original)')

% Search all wav files in mPower directory
[success,message,messageid] = fileattrib('/mPower/*');
File_Names = arrayfun(@(x){x.Name},message); 

%% Extract features from audio_audio.m4a files (converted to wav form)
ALL_FEATURES = zeros(length(File_Names),13);
ind_audio = zeros(length(File_Names),1);
ind_audio_failed = zeros(length(File_Names),1);
ind_countdown = zeros(length(File_Names),1);
ind_countdown_failed = zeros(length(File_Names),1);
parfor i = 1:length(File_Names)
    if ~isempty(strfind(File_Names{i},'audio_audio')) && ~isempty(strfind(File_Names{i},'.wav'))
        try
            [Y,FS] = audioread(File_Names{i});
            ind_audio(i) = 1;
            ALL_FEATURES(i,:) = features_bvav2(Y,FS);
        catch
            ind_audio_failed(i) = 1;
        end
    elseif ~isempty(strfind(File_Names{i},'audio_countdown')) && ~isempty(strfind(File_Names{i},'.wav'))
        try
            [Y,FS] = audioread(File_Names{i});
            ind_countdown(i) = 1;
            ALL_FEATURES(i,:) = features_bvav2(Y,FS);
        catch
            ind_countdown_failed(i) = 1;
        end
    end
    display(strcat('Finished iteration ',num2str(i)));
end
save Audio_Features ALL_FEATURES File_Names ind_audio ind_countdown ind_audio_failed ind_countdown_failed
%% Write features to table
Audio_Features = ALL_FEATURES(~~(ind_audio),:);
Countdown_Features = ALL_FEATURES(~~(ind_countdown),:);

Audio_Features = array2table(Audio_Features,'RowNames',File_Names(~~(ind_audio)),...
    'VariableNames',{'Median_F0','Mean_Jitter','Median_Jitter','Mean_Shimmer','Median_Shimmer',...
    'MFCC_Band_1','MFCC_band_2','MFCC_band_3','MFCC_band_4','MFCC_Jitter_band_1_Positive',...
    'MFCC_Jitter_band_2_Positive','MFCC_Jitter_band_3_Positive','MFCC_Jitter_band_4_Positive'});
writetable(Audio_Features, 'Audio_Features.csv', 'Delimiter', '\t', 'WriteRownames',true);

Countdown_Features = array2table(Countdown_Features,'RowNames',File_Names(~~(ind_countdown)),...
    'VariableNames',{'Median_F0','Mean_Jitter','Median_Jitter','Mean_Shimmer','Median_Shimmer',...
    'MFCC_Band_1','MFCC_band_2','MFCC_band_3','MFCC_band_4','MFCC_Jitter_band_1_Positive',...
    'MFCC_Jitter_band_2_Positive','MFCC_Jitter_band_3_Positive','MFCC_Jitter_band_4_Positive'});
writetable(Countdown_Features, 'Countdown_Features.csv', 'Delimiter', '\t', 'WriteRownames',true);