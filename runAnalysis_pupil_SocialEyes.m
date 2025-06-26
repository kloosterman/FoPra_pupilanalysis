%% Example script for pupil analysis
restoredefaultpath; clear; % this clears the path
addpath('/Users/kloosterman/Documents/MATLAB/fieldtrip-20240603') % add fieldtrip to path, download from https://download.fieldtriptoolbox.org/
ft_defaults % this sets up fieldtrip toolbox for use, see https://www.fieldtriptoolbox.org/faq/installation/
addpath('/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/23-24SS/FoPra_pupil/FoPra_pupilanalysis') % the read_tobii_txt should be in this path

% datapath = '/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/24-25SS/Fopra/2Pupil/StressEye/data/pilot'; % replace this path with your data path
datapath = '/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/24-25SS/Fopra/2Pupil/SocialEyes/data';
cd(datapath)

B = readtable("Tabelle_Beobachtung.xlsx");
B.Vpcode = string(B.Vpcode);
B = sortrows(B, 'Vpcode');

%% test data
conds = ["UnBeob" "Beob"];
out_t = table();

timelock_all = cell(2,2);
subjlist = B.Vpcode;
for isub = 1:length(subjlist) % remove CH1173
  % t=table();
  % t.group = conds(icond);
  file = dir(subjlist(isub) + "*" );
  disp(file.name)
  data = read_tobii_txt(file.name);
  length(data.trial)
  % % 1:45  easy  45 trials
  % % 46:57 hard  12 trials
  % % 58:102 easy
  % % 103:114 hard
  % % etc
  % % easy: 4 to 18 s
  % % hard: 4 to 28 AND 4 to 18 s
  diff_trials = ones(235,1)+1;
  diff_trials([1:45 58:102 115:159 176:220]) = 1; %figure; plot(diff_trials)
  BU_trials = ones(235,1);
  BU_trials(1:45) = B{B.Vpcode == subjlist(isub), "easy1"};
  BU_trials(46:57) = B{B.Vpcode == subjlist(isub), "hard1"};
  BU_trials(58:102) = B{B.Vpcode == subjlist(isub), "easy2"};
  BU_trials(103:114) = B{B.Vpcode == subjlist(isub), "hard2"};

  BU_trials(115:159) = B{B.Vpcode == subjlist(isub), "easy3"};
  BU_trials(160:171) = B{B.Vpcode == subjlist(isub), "hard3"};
  BU_trials(176:220) = B{B.Vpcode == subjlist(isub), "easy4"};
  BU_trials(221:235) = B{B.Vpcode == subjlist(isub), "hard4"}; %figure; plot(BU_trials)
  BU_trials = BU_trials+1;

  for icond = 1:2 % "UnBeob" "Beob"
    for idiff = 1:2
      cfg = [];
      cfg.trials = ismember(data.trialinfo.Trialno, find(diff_trials == idiff)) & ...
        ismember(data.trialinfo.Trialno, find(BU_trials == icond));
      cfg.channel = 'pupil';
      timelock_all{idiff, icond}{end+1} = ft_timelockanalysis(cfg, data);
    end
  end

end

%% append
for icond = 1:2 % "UnBeob" "Beob"
  for idiff = 1:2
    cfg = [];
    cfg.appenddim = 'rpt';
    timelock_all{idiff, icond} = ft_appendtimelock(cfg, timelock_all{idiff, icond}{:})
  end
end
%%
condleg = ['U easy'; 'U hard'; 'B easy'; 'B hard'; ];

figure
ft_singleplotER([], timelock_all{:})
legend(condleg)
saveas(gcf, 'allconds.png')

%% get prestim and poststim data
timelock_all_post = {};
out_t = table();
out_t.VPcode = B.Vpcode;
for icond = 1:2 % "UnBeob" "Beob"
  for idiff = 1:2
    cfg = [];
    cfg.avgovertime = 'yes';
    cfg.latency = [2 3];
    timelock_all_pre{idiff, icond} = ft_selectdata(cfg, timelock_all{idiff, icond});
    cfg.latency = [5 7];
    timelock_all_post{idiff, icond} = ft_selectdata(cfg, timelock_all{idiff, icond});
  end
end
out_t.Ueasy_pre = timelock_all_pre{1, 1}.trial;
out_t.Uhard_pre = timelock_all_pre{2, 1}.trial;
out_t.Beasy_pre = timelock_all_pre{1, 2}.trial;
out_t.Bhard_pre = timelock_all_pre{2, 2}.trial;

out_t.Ueasy_post = timelock_all_post{1, 1}.trial;
out_t.Uhard_post = timelock_all_post{2, 1}.trial;
out_t.Beasy_post = timelock_all_post{1, 2}.trial;
out_t.Bhard_post = timelock_all_post{2, 2}.trial;

cd ..
mkdir preproc
cd preproc
writetable(out_t, 'SocialEyes_prepostdata.csv')

% % t.VPcode = subjlist(isub).name(1:6);
% [maxtriallength, ind] = max(cellfun(@length, data.trial)); % where is the arousal manipulation trial
% ntrials = length(data.trial);
% if icond == 1 % physio
%   % select trials for pre post
%   cfg = [];
%   cfg.trials = 1:ind-1;
%   cfg.channel = 'pupil';
%   data_pre = ft_selectdata(cfg, data);
%   cfg.trials = ind;
%   data_manipulation = ft_selectdata(cfg, data);
%   cfg.trials = ind+1:ntrials;
%   data_post = ft_selectdata(cfg, data);
%   data_U_easy{end+1} = ft_timelockanalysis([], data_pre);
%   data_B_easy{end+1} = ft_timelockanalysis([], data_post);
% else % kognitiv
%   % select trials for pre post
%   cfg = [];
%   cfg.trials = 1:204;
%   cfg.channel = 'pupil';
%   data_pre = ft_selectdata(cfg, data);
%   midtrial = round(ntrials/2);
%   cfg.trials = midtrial-50:midtrial+50; % which trials?
%   data_manipulation = ft_selectdata(cfg, data);
%   cfg.trials = ntrials-204:ntrials;
%   data_post = ft_selectdata(cfg, data);
%   data_U_hard{end+1} = ft_timelockanalysis([], data_pre);
%   data_B_hard{end+1} = ft_timelockanalysis([], data_post);
% end

%     % avg over trials PRE manipulation TOTAL pupil
%     cfg=[];
%     timelock = ft_timelockanalysis(cfg, data_pre);
%     cfg.latency = 'all';  % e.g., [0.1 0.3] to average from 100 to 300 ms
%     cfg.avgovertime = 'yes';
%     avg_data = ft_selectdata(cfg, timelock);
%     % t.(conds(icond) + "_pupil_pre_total") = avg_data.avg;
%     t.pupil_pre_total = avg_data.avg;
%
%     % avg over trials POST manipulation TOTAL pupil
%     cfg=[];
%     timelock = ft_timelockanalysis(cfg, data_post);
%     cfg.latency = 'all';  % e.g., [0.1 0.3] to average from 100 to 300 ms
%     cfg.avgovertime = 'yes';
%     avg_data = ft_selectdata(cfg, timelock);
%     t.pupil_post_total = avg_data.avg;
%
%     % avg over trials POST manipulation TOTAL pupil
%     cfg=[];
%     timelock = ft_timelockanalysis(cfg, data_manipulation);
%     cfg.latency = 'all';  % e.g., [0.1 0.3] to average from 100 to 300 ms
%     cfg.avgovertime = 'yes';
%     avg_data = ft_selectdata(cfg, timelock);
%     t.pupil_manipulation_total = avg_data.avg;
%
%     % avg over trials PRE manipulation prestimulus pupil
%     cfg=[];
%     timelock = ft_timelockanalysis(cfg, data_pre);
%     cfg.latency = [0 1];  % e.g., [0.1 0.3] to average from 100 to 300 ms
%     cfg.avgovertime = 'yes';
%     avg_data = ft_selectdata(cfg, timelock);
%     % t.(conds(icond) + "_pupil_pre_total") = avg_data.avg;
%     t.pupil_pre_prestim = avg_data.avg;
%
%     % avg over trials POST manipulation poststimulus pupil
%     cfg=[];
%     timelock = ft_timelockanalysis(cfg, data_post);
%     cfg.latency = [1 2];  % e.g., [0.1 0.3] to average from 100 to 300 ms
%     cfg.avgovertime = 'yes';
%     avg_data = ft_selectdata(cfg, timelock);
%     t.pupil_post_poststim = avg_data.avg;
%
%     out_t(end+1,:) = t;
%   end
%
% end
%
% out_t = sortrows(out_t, 'VPcode');
% disp(out_t)
%
% cd ../
% mkdir preproc
% cd preproc
% writetable(out_t, "Stresseye_preproc_data.csv")
%
% data_U_hard = ft_timelockgrandaverage([], data_U_hard{:});
% data_U_easy = ft_timelockgrandaverage([], data_U_easy{:});
% data_B_hard = ft_timelockgrandaverage([], data_B_hard{:});
% data_B_easy = ft_timelockgrandaverage([], data_B_easy{:});
%
% figure;
% ft_singleplotER([], data_U_hard, data_U_easy, data_B_hard, data_B_easy)
% legend({'data_U_hard', 'data_U_easy', 'data_B_hard', 'data_B_easy'})
% saveas(gcf, "pupil_timecourses.png")
% % cfg = [];
% % cfg.channel = 'pupil';
% % cfg.preproc.demean = 'yes';
% % cfg.method = 'channel';
% % ft_databrowser(cfg, data)
% % % ft_rejectvisual(cfg, data)
% %
% % timelock = ft_timelockanalysis([], data);
% % cfg = [];
% % cfg.channel = 'pupil';
% % cfg.parameter = 'avg';
% % ft_singleplotER(cfg, timelock)
% % xlabel('Time (s)')
% % ylabel('Pupil size (mm)')
% % f=gcf;  f.Position = [  744   792   250   150 ];
% %
% % saveas(gcf, 'KOG-Test.png', 'png')
%
%
