%% Example script for pupil analysis
restoredefaultpath; clear; % this clears the path
addpath('/Users/kloosterman/Documents/MATLAB/fieldtrip-20240603') % add fieldtrip to path, download from https://download.fieldtriptoolbox.org/
ft_defaults % this sets up fieldtrip toolbox for use, see https://www.fieldtriptoolbox.org/faq/installation/
addpath('/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/23-24SS/FoPra_pupil/FoPra_pupilanalysis') % the read_tobii_txt should be in this path

% datapath = '/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/24-25SS/Fopra/2Pupil/StressEye/data/pilot'; % replace this path with your data path
datapath = '/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/24-25SS/Fopra/2Pupil/StressEye/Pupillendaten/'
cd(datapath)

%% test data

groups = ["Physiologisch" "Kognitiv"];
out_t = table();
data_pre_phys = {};
data_pre_kog = {};
data_post_phys = {};
data_post_kog = {};
for igroup = 1:2
  subjlist = dir("*" + groups(igroup) + "*");
  for isub = 1:length(subjlist) % remove CH1173
    t=table();
    t.group = groups(igroup);
    disp(subjlist(isub).name)
    if contains(subjlist(isub).name, 'CH1173')
      continue
    end
    data = read_tobii_txt(subjlist(isub).name);
    t.VPcode = subjlist(isub).name(1:6);
    [maxtriallength, ind] = max(cellfun(@length, data.trial)); % where is the arousal manipulation trial
    ntrials = length(data.trial);
    if igroup == 1 % physio
      % select trials for pre post
      cfg = [];
      cfg.trials = 1:ind-1;
      cfg.channel = 'pupil';
      data_pre = ft_selectdata(cfg, data);
      cfg.trials = ind;
      data_manipulation = ft_selectdata(cfg, data);
      cfg.trials = ind+1:ntrials;
      data_post = ft_selectdata(cfg, data);
      data_pre_phys{end+1} = ft_timelockanalysis([], data_pre);
      data_post_phys{end+1} = ft_timelockanalysis([], data_post);
    else % kognitiv
      % select trials for pre post
      cfg = [];
      cfg.trials = 1:204;
      cfg.channel = 'pupil';
      data_pre = ft_selectdata(cfg, data);
      midtrial = round(ntrials/2);
      cfg.trials = midtrial-50:midtrial+50; % which trials?
      data_manipulation = ft_selectdata(cfg, data);
      cfg.trials = ntrials-204:ntrials;
      data_post = ft_selectdata(cfg, data);
      data_pre_kog{end+1} = ft_timelockanalysis([], data_pre);
      data_post_kog{end+1} = ft_timelockanalysis([], data_post);
    end

    % avg over trials PRE manipulation TOTAL pupil
    cfg=[];
    timelock = ft_timelockanalysis(cfg, data_pre);
    cfg.latency = 'all';  % e.g., [0.1 0.3] to average from 100 to 300 ms
    cfg.avgovertime = 'yes';
    avg_data = ft_selectdata(cfg, timelock);
    % t.(groups(igroup) + "_pupil_pre_total") = avg_data.avg;
    t.pupil_pre_total = avg_data.avg;

    % avg over trials POST manipulation TOTAL pupil
    cfg=[];
    timelock = ft_timelockanalysis(cfg, data_post);
    cfg.latency = 'all';  % e.g., [0.1 0.3] to average from 100 to 300 ms
    cfg.avgovertime = 'yes';
    avg_data = ft_selectdata(cfg, timelock);
    t.pupil_post_total = avg_data.avg;

    % avg over trials POST manipulation TOTAL pupil
    cfg=[];
    timelock = ft_timelockanalysis(cfg, data_manipulation);
    cfg.latency = 'all';  % e.g., [0.1 0.3] to average from 100 to 300 ms
    cfg.avgovertime = 'yes';
    avg_data = ft_selectdata(cfg, timelock);
    t.pupil_manipulation_total = avg_data.avg;

    % avg over trials PRE manipulation prestimulus pupil
    cfg=[];
    timelock = ft_timelockanalysis(cfg, data_pre);
    cfg.latency = [0 1];  % e.g., [0.1 0.3] to average from 100 to 300 ms
    cfg.avgovertime = 'yes';
    avg_data = ft_selectdata(cfg, timelock);
    % t.(groups(igroup) + "_pupil_pre_total") = avg_data.avg;
    t.pupil_pre_prestim = avg_data.avg;

    % avg over trials POST manipulation poststimulus pupil
    cfg=[];
    timelock = ft_timelockanalysis(cfg, data_post);
    cfg.latency = [1 2];  % e.g., [0.1 0.3] to average from 100 to 300 ms
    cfg.avgovertime = 'yes';
    avg_data = ft_selectdata(cfg, timelock);
    t.pupil_post_poststim = avg_data.avg;

    out_t(end+1,:) = t;
  end

end

out_t = sortrows(out_t, 'VPcode');
disp(out_t)

cd ../
mkdir preproc
cd preproc
writetable(out_t, "Stresseye_preproc_data.csv")

data_pre_kog = ft_timelockgrandaverage([], data_pre_kog{:});
data_pre_phys = ft_timelockgrandaverage([], data_pre_phys{:});
data_post_kog = ft_timelockgrandaverage([], data_post_kog{:});
data_post_phys = ft_timelockgrandaverage([], data_post_phys{:});

figure;
ft_singleplotER([], data_pre_kog, data_pre_phys, data_post_kog, data_post_phys)
legend({'data_pre_kog', 'data_pre_phys', 'data_post_kog', 'data_post_phys'})
saveas(gcf, "pupil_timecourses.png")
% cfg = [];
% cfg.channel = 'pupil';
% cfg.preproc.demean = 'yes';
% cfg.method = 'channel';
% ft_databrowser(cfg, data)
% % ft_rejectvisual(cfg, data)
% 
% timelock = ft_timelockanalysis([], data);
% cfg = [];
% cfg.channel = 'pupil';
% cfg.parameter = 'avg';
% ft_singleplotER(cfg, timelock)
% xlabel('Time (s)')
% ylabel('Pupil size (mm)')
% f=gcf;  f.Position = [  744   792   250   150 ];
% 
% saveas(gcf, 'KOG-Test.png', 'png')

