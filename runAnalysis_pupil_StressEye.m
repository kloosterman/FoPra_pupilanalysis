%% Example script for pupil analysis
restoredefaultpath; clear; % this clears the path
addpath('/Users/kloosterman/Documents/MATLAB/fieldtrip-20240603') % add fieldtrip to path, download from https://download.fieldtriptoolbox.org/
ft_defaults % this sets up fieldtrip toolbox for use, see https://www.fieldtriptoolbox.org/faq/installation/
addpath('/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/23-24SS/FoPra_pupil/FoPra_pupilanalysis') % the read_tobii_txt should be in this path

% datapath = '/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/24-25SS/Fopra/2Pupil/StressEye/data/pilot'; % replace this path with your data path
datapath = '/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/24-25SS/Fopra/2Pupil/StressEye/Pupillendaten/'
cd(datapath)

%% test data
% data = read_tobii_txt('KOG-Test.txt'); % CH1173_PhysiologischesArousal_2025-06-03_09h53.41.792.txt
% data = read_tobii_txt('AT1579_KognitivesArousal_2025-06-03_08h59.27.927.txt'); % CH1173_PhysiologischesArousal_2025-06-03_09h53.41.792.txt
% data = read_tobii_txt('WN1836_Physiologisches Arousal_2025-06-04_16h52.26.290.txt'); % CH1173_PhysiologischesArousal_2025-06-03_09h53.41.792.txt
data = read_tobii_txt('BS2569_Physiologisches Arousal_2025-06-11_10h53.43.151.txt'); % CH1173_PhysiologischesArousal_2025-06-03_09h53.41.792.txt
cfg = [];
cfg.trials = [1:204 206:409];
data = ft_selectdata(cfg, data);

cfg = [];
cfg.channel = 'pupil';
cfg.preproc.demean = 'yes';
cfg.method = 'channel';
ft_databrowser(cfg, data)
% ft_rejectvisual(cfg, data)

timelock = ft_timelockanalysis([], data);
cfg = [];
cfg.channel = 'pupil';
cfg.parameter = 'avg';
ft_singleplotER(cfg, timelock)
xlabel('Time (s)')
ylabel('Pupil size (mm)')
f=gcf;  f.Position = [  744   792   250   150 ];

saveas(gcf, 'KOG-Test.png', 'png')

