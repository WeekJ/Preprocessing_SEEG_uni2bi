clear all;clc;
Path='E:\ECCEN\';
Subjects={'08_WuFang','16_Zhang_Cong'};
Files={'Eccen'};
for ordsub=1%:numel(Subjects)
    for ordcon=1:4
    Working_Path=[Path,Subjects{ordsub}]; 
    %% Lowpass Filter &Baseline Correction
    clear data;
    load([Working_Path,'\CLEAN_DATABI\DataBi_Eccen.mat']);
    channelsel1=ft_channelselection(['F*'],data.label);
    channelsel2=ft_channelselection(['C*'],data.label);
    channelsel3=ft_channelselection(['L*'],data.label);
    channelsel4=ft_channelselection(['V*'],data.label);
    channelsel=[channelsel1;channelsel2;channelsel3;channelsel4];
    cfg=[];
    cfg.channel=channelsel;
    cfg.trials = find(data.trialinfo==ordcon);
    cfg.dftfilter     ='yes'; % line noise removal using discrete fourier transform (default = 'no')
    data=ft_preprocessing(cfg,data);
    %% ERP
    mkdir([Working_Path,'\ERP\']);
    cfg = [];
    cfg.lpfilter = 'yes';
    cfg.lpfreq = 25; % smooth ERP with low-pass filter
    cfg.demean          = 'yes';
    cfg.baselinewindow  =[-0.2 0];%'[-0.3 -0.1]'
    %cfg.toi=[-0.3,1];
    Filt_bl = ft_preprocessing(cfg,data);
    cfg = [];
    cfg.trials          = 'all';  %a selection given as a 1xN vector
    ERP_bl = ft_timelockanalysis(cfg,Filt_bl);
    eval(['ERP_bl_',num2str(ordcon),'=ERP_bl;']);
    %% POWER
    cfg = [];
    cfg.channel    = 'all';%channels;
    cfg.method    = 'wavelet';  %'wavelet'
    cfg.keeptrials = 'yes';
    cfg.output      = 'pow';   %'fourier';  %'pow';'powandcsd'
    cfg.foi            = 1:2:150;  %2:2:80
    cfg.toi            = -0.2:0.02:1.5;
    cfg.width        = linspace(1,30,numel(cfg.foi)); %linspace(1,25,numel(cfg.foi))
    TFR = ft_freqanalysis(cfg, data);  %
    % plot TFRs
    cfg = [];
    cfg.parameter = 'powspctrm';
    cfg.colorbar = 'yes';
    % baseline correction
    cfg = [];
    cfg.baseline = [-0.2 0];
    cfg.baselinetype ='db';
    POW_bl = ft_freqbaseline(cfg, TFR);
    clear TFR*;
    eval(['POW_bl_',num2str(ordcon),'=POW_bl;']);

%     %% ITPC
%     cfg = [];
%     cfg.channel    =  'all';%channels;
%     cfg.method     = 'wavelet';  %'wavelet'
%     cfg.keeptrials = 'yes';
%     cfg.output     = 'fourier';   %'fourier';  %'pow';'powandcsd'
%     cfg.foi           = 1:2:150;  %2:2:80
%     cfg.toi          = -0.2:0.02:1.5;
%     cfg.width      = linspace(1,30,numel(cfg.foi)); %linspace(1,25,numel(cfg.foi))
%     TFR = ft_freqanalysis(cfg, data);  %
%     itc = [];
%     itc.label     = TFR.label;
%     itc.freq      = TFR.freq;
%     itc.time      = TFR.time;
%     itc.dimord    = 'chan_freq_time';  %'rpttap_chan_freq_time''chan_freq_time'   'rpt_chan_freq_time'
% %     itc.itpc=squeeze(abs(mean(exp(1i*angle(TFR.fourierspctrm)),1)));
    end;
end;

%% plot the traces
label=POW_bl.label;
cfg = [];
cfg.xlim=[-0.2 1.5];
cfg.parameter = 'avg';
cfg.ylim          = 'maxabs';
cfg.linewidth     =0.5;
figure(1)
for ichan =1:length(label)
    clf;clear A;
    A = label{ichan};
    A(find(isspace(A))) = [];
    cfg.channel = A;
    set(1, 'position', [0 0 1200 2000]);
    subplot(3,2,1);F=ft_singleplotER(cfg,ERP_bl_1,ERP_bl_2,ERP_bl_3,ERP_bl_4);
    legend(A);
    subplot(3,2,3);
    contourf(POW_bl_1.time,POW_bl_1.freq,squeeze(mean(squeeze(POW_bl_1.powspctrm(:,ichan,:,:)),1)),100,'linecolor','none');
    colorbar;
    title(A);
    caxis([-3 3]);
    subplot(3,2,4);
    contourf(POW_bl_2.time,POW_bl_2.freq,squeeze(mean(squeeze(POW_bl_2.powspctrm(:,ichan,:,:)),1)),100,'linecolor','none');
    colorbar;
    title(A);
    caxis([-3 3]);
    subplot(3,2,5);
    contourf(POW_bl_3.time,POW_bl_3.freq,squeeze(mean(squeeze(POW_bl_3.powspctrm(:,ichan,:,:)),1)),100,'linecolor','none');
    colorbar;
    title(A);
    caxis([-3 3]);
    subplot(3,2,6);
    contourf(POW_bl_4.time,POW_bl_4.freq,squeeze(mean(squeeze(POW_bl_4.powspctrm(:,ichan,:,:)),1)),100,'linecolor','none');
    colorbar;
    title(A);
    caxis([-3 3]);
    colormap('jet');
    B=getframe(1);
    mkdir([Working_Path,'\Figure\']);
    imwrite(B.cdata,[Working_Path,'\Figure\',A,'.png']);
    %saveas(1,[Working_Path,'\Figure\',Subjects{ordsub},'_',A,'_Diff_V-A'],'jpg');
    %print(1,'-dpng',[Working_Path,'\Figure\',Subjects{ordsub},'_',A,'.png']); %
    %close all;
end;
