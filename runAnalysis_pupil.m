%% Example script for pupil analysis
restoredefaultpath; clear; % this clears the path
addpath('/Users/kloosterman/Documents/MATLAB/fieldtrip-20240603') % add fieldtrip to path, download from https://download.fieldtriptoolbox.org/
ft_defaults % this sets up fieldtrip toolbox for use, see https://www.fieldtriptoolbox.org/faq/installation/
addpath('/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/23-24SS/FoPra_pupil/FoPra_pupilanalysis') % the read_tobii_txt should be in this path

datapath = '/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/23-24SS/FoPra_pupil/data'; % replace this path with your data path
cd(datapath)

%% preprocessing eye tracking data: reading txt file into memory 
% this section loads in the data and does some basic preprocessing. See% https://www.fieldtriptoolbox.org/tutorial/continuous/ for more info

% data = read_tobii_txt(fullfile(datapath, 'G643402_Arousing_Eyecatchers_Session2_2024-06-10_14h47.06.152.txt')); % replace txt with your own data file
% data = read_tobii_txt(fullfile(datapath, 'F567226_Arousing_Eyecatchers_Session2_2024-06-10_14h05.43.046-1.txt')); % replace txt with your own data file
data = read_tobii_txt(fullfile(datapath, 'E304683_Arousing_Eyecatchers_Session2_2024-06-10_13h18.36.786-1.txt')); % replace txt with your own data file

% Now you should have a structure called "data" in your workspace

%% save the data to file
save( fullfile(datapath, 'Proband1.mat'), 'data')  % this saves variable "data" into file Proband1.mat 

%% in the datafile the RIGHT pupil channel contains plausible pupil data. To visualize this, do the following:
% see https://www.fieldtriptoolbox.org/faq/how_can_i_use_the_databrowser/ for more info
cfg=[];
cfg.channel =  'right_pupil_measure1';
cfg.demean = 'yes'; % this makes the data zero-centered 
cfg = ft_databrowser(cfg, data); % click through the trials

%% plot average pupil, to see if we have a pupil dilation/constriction
% average over trials
cfg=[];
cfg.channel = 'right_pupil_measure1';
timelock = ft_timelockanalysis(cfg, data);

% plot the trial average
cfg=[];
cfg.xlim = [0 1.5];
ft_singleplotER(cfg, timelock) 
xlabel('Time (s)')
ylabel('Pupil size')
saveas(gcf, 'PupilResponse.png') % save to a figure

%% get single trial pupil response prestim (assuming the first 0.5 s are prestim)
% select pupil and put single trials in matrix
cfg=[];
cfg.keeptrials = 'yes';
cfg.channel = 'right_pupil_measure1';
timelock = ft_timelockanalysis(cfg, data); 

% select 0-0.5 s interval and average within that interval
cfg=[];
cfg.latency = [0. 0.5];
cfg.avgovertime = 'yes';
prestimpupil = ft_selectdata(cfg, timelock); 

% plot the single trial values in a histogram to see distribution
figure; histogram(prestimpupil.trial)
title('Histogram of single-trial pupil size between 0 and 0.5 s')
xlabel('Pupil size (arbitrary units)')
ylabel('Frequency of occurrence')
saveas(gcf, 'SingleTrialPupil.png') % save to a figure
