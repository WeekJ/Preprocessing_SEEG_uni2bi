clear all;clc;
Path='E:\ECCEN\';
Subjects={'08_WuFang','16_Zhang_Cong'};
Files={'Eccen'};
for ordsub=1%2:length(Subjects)
    Working_Path=[Path,Subjects{ordsub}];
    data=[];
    for ordfile=1%1:length(Files)
    %% raw data preprocessing in eeglab
    % ��.m00���ݵ���eeglab
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    [EEG, com] = pop_importNihonKodenM00(fullfile(Working_Path,'\RAW_m00\',[Files{ordfile},'.m00']));
    EEG = eeg_checkset( EEG );
    
    %�ú���get_nkheader.m ��ȡraw data�еĵ缫��Ϣ
    [ntpoints,nchannels,bsweep,sampintms,binsuV,start_time,ch_names]=get_nkheader(fullfile(Working_Path,'\RAW_m00\',[Files{ordfile},'.m00']));
    
    %���缫����ch_names����eeglab���ļ��ṹ��
    for i=1:size(ch_names,1)
        EEG.chanlocs(i).labels=ch_names(i,:);
    end
    
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = eeg_checkset( EEG );
    
    % ���е�50hz����
    % �еĲ����е�Ӱ��ܴ󣬿����Կ�һ�㣬���£�47-53hz
    %     EEG = pop_eegfiltnew(EEG, 47, 53, [], 1, [], 1);
    %     [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'overwrite', 'on', 'gui', 'off');
    %     EEG = eeg_checkset( EEG );
    
    %  ���� DC09 DC10 DC11 DC12 ��ʾ�Ķ������ź�ת����ʮ����mark
    % �ú���transf_mark.m����ת��
    cd 'E:\MOTION\';
    EventTmp = transf_mark(EEG);
    EEG.event = EventTmp; %��ת����mark�浽EEGLAB�ṹ��
    EEG = eeg_checkset(EEG);
    [ALLEEG, EEG, CURRENTSET] = eeg_store (ALLEEG, EEG, 0);
    
    % ��󱣴���µ�dataset ��filename_ori.set��
    mkdir(Working_Path,'\Raw_Set_File\');
    cd(fullfile(Working_Path,'\Raw_Set_File\'));
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'savenew', [Files{ordfile},'_Ori.set'], 'gui', 'off');
    EEG = eeg_checkset( EEG );
    %% load eeglab data and transfer to fieldtrip
    cd(fullfile(Working_Path,'Raw_Set_File\'));
    % path='C:\Users\Lu Shen\Documents\SEEG����Ԥ����';
    datapath=pwd;
    clear data;
    data = eeglab2fieldtrip (EEG, 'preprocessing', 'none');
    data.label=strtrim(data.label);
    %%
    event=[];
    for i=1:size(EEG.event,2)
        event(i).value=str2num(EEG.event(i).type);
        event(i).type='MIB';
        event(i).latency=EEG.event(i).latency;
        event(i).sample=EEG.event(i).latency;
        event(i).offset = 0;
        event(i).duration = 0;
    end;
    data.event=event;
    %% read header info
    clear hdr;
    hdr.nChans              = size(EEG.chanlocs,2);
    hdr.nSamples            = size(EEG.times,2);
    hdr.nSamplesPre         = 0;
    hdr.nTrials             = 1;
    hdr.Fs                  = EEG.srate;
    for i=1:numel(EEG.chanlocs)
        hdr.label{i} =strtrim( EEG.chanlocs(i).labels);
    end;
    data.hdr=hdr;
    mkdir(Working_Path,'\FT_File\');
    save([Working_Path,'\FT_File\','FT_Data_',Files{ordfile},'.mat'],'data');
    %% bipolar montage
    % define bipolar labels
    k = [];
    for ii=1:size(data.label,2)-1
        newlabel{ii} = [char(data.label(ii)),'-',char(data.label(ii+1))];
        if ~strncmp(data.label(ii),data.label(ii+1),1) ...
                || strncmp(data.label{ii},'DC',2)...
                || strncmp(data.label{ii},'EK',2)...
                || strncmp(data.label{ii},'LE',2)...
                || strncmp(data.label{ii},'RE',2)...
                || strncmp(data.label{ii},'Trigger',7)...
                k = [k ii];
        end
    end
    
    tramat = zeros(size(newlabel,2),size(data.label,2))...
        +eye(size(newlabel,2),size(data.label,2))...
        -[zeros(size(newlabel,2),1),eye(size(newlabel,2),size(data.label,2)-1)];
    tramat(k,:) = [];
    newlabel(k)=[];
    bipolar=[];
    bipolar.labelorg  = data.label;
    bipolar.labelnew  = newlabel;
    bipolar.tra       = tramat;
    clear databi;
    [databi]    = ft_apply_montage(data, bipolar);
    mkdir(Working_Path,'\BI_MAT\');
    save([Working_Path,'\BI_MAT\FT_DataBi_',Files{ordfile},'.mat'],'databi');
end;
end;




