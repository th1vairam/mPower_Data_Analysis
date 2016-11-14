% Wrapper function to download a m4a file from synapse and call Max
% Little's feature extraction code for phonation
clear
close all
clc

% Add Max code's to search path 
addpath('/mnt/Github/PDScores/bridge_ufb (original)')
%% Input parameters
WORKING_DIR = '/mnt/Github/mPower_Data_Analysis/code/';
SOURCE_TBL = 'syn4590865';
FEATURE_TBL = 'syn5555323';%'syn5557868';%'syn5555323';
COLUMN_NAME = 'audio_countdown.m4a';

%% Extract all unfinished rowIDs, rowVersions and recordIDs from synapse table "syn4590865"
[a,b] = system(['Rscript ',...
    WORKING_DIR,'R/extractRecordIds.R ',...
    SOURCE_TBL,' ',...
    FEATURE_TBL,' ',...
    'AllRecordIds.txt ',...
    WORKING_DIR]);
All_recordIds = readtable([WORKING_DIR,...
    'Matlab/AllRecordIds.txt'], 'Delimiter','\t');

%% Extract features from audio_*.m4a files (converted to wav form)
nbatch = ceil(size(All_recordIds, 1)/100);
for batch = 1:nbatch
    % Get first 100 records
    ind_start = (batch-1)*100+1;
    ind_end = min(batch*100,size(All_recordIds,1));
    records = All_recordIds(ind_start:ind_end,:);
    
    writetable(records, [WORKING_DIR, ...
        'R/records.csv'])
    
    display(['Extracting batch ',num2str(batch)])
    % Use R to extract and convert m4a files to wav
    [~,b] = system(['Rscript ',...
        WORKING_DIR, 'R/getVoiceDataAndConvert2WAV.R ',...
        SOURCE_TBL,' ',...
        'records.csv ',...
        COLUMN_NAME, ' ',...
        WORKING_DIR]);
    
    % Get all converted wav file names
    wavFileNames = readtable([WORKING_DIR,...
        'R/wavfileNames.txt'],...
        'Delimiter','\t');
    
    ALL_FEATURES = zeros(size(wavFileNames,1),13);
    rowId_finished = zeros(size(wavFileNames,1),1);
    parfor i = 1:size(wavFileNames,1)
        try
            [Y,FS] = audioread(char(wavFileNames{i,'wavFileName'}));
            ALL_FEATURES(i,:) = features_bvav2(Y,FS);
            rowId_finished(i,1) = (wavFileNames{i,'SOURCE_ROW_ID'});
        catch
            ALL_FEATURES(i,:) = NaN(1, 13);
            rowId_finished(i,1) = NaN;
        end
        display(strcat('Finished iteration_',num2str(i),' in batch_', num2str(batch)));
    end
    
    ind = ~isnan(rowId_finished);
    % Convert results to table files
    Audio_Features = array2table(ALL_FEATURES(ind,:),...
        'VariableNames',{'Median_F0','Mean_Jitter','Median_Jitter','Mean_Shimmer','Median_Shimmer',...
        'MFCC_Band_1','MFCC_Band_2','MFCC_Band_3','MFCC_Band_4','MFCC_Jitter_Band_1_Positive',...
        'MFCC_Jitter_Band_2_Positive','MFCC_Jitter_Band_3_Positive','MFCC_Jitter_Band_4_Positive'});
    Audio_Features = [wavFileNames(ind,:), Audio_Features];
    writetable(Audio_Features, ['/mPower/CountdownFeatures_WO_Trimming/Countdown_Features_Batch_',num2str(batch),'.csv'],...
        'Delimiter', ',', 'WriteRownames',false);

    % Clean synapseCache
    a = system('rm -rf /home/rstudio/.synapseCache/*');
    a = system(['rm ',...
        WORKING_DIR,'R/records.csv']);
    a = system(['rm ',...
        WORKING_DIR, 'R/wavfileNames.txt']);
    a = system(['rm ',...
        WORKING_DIR, 'Matlab/AllRecordIds.txt']);
    
    % Upload results to table
    [a,b] = system(['Rscript ',...
        WORKING_DIR,'R/uploadFeatures2Table.R ',...
        SOURCE_TBL,' ',...
        FEATURE_TBL,' ',...
        ['/mPower/CountdownFeatures_WO_Trimming/Countdown_Features_Batch_',num2str(batch),'.csv'],' ',...
        WORKING_DIR]);

    display(strcat('Completed batch ',num2str(batch)));
end