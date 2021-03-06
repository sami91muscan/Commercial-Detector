
%% Initialization
SamplesPerFrame = 2048;
FReader = dsp.AudioFileReader('clips/cb2/ad-s3e7.wav','SamplesPerFrame',SamplesPerFrame, ...
    'PlayCount',1);
Fs = FReader.SampleRate;

TimeScope = dsp.TimeScope('SampleRate',Fs,'BufferLength',4*Fs,...
	 'TimeSpan',60,'YLimits',[-0.5 0.5],'ShowGrid',true);

%TimeScopeOut = dsp.TimeScope('SampleRate',Fs,'BufferLength',4*Fs,...
%	 'TimeSpan',300,'YLimits',[-0.5 0.5],'ShowGrid',true, 'Name', 'Output Time Scope');

Player = dsp.AudioPlayer('SampleRate',Fs);
 
Meaner = dsp.Mean();

%% Variables to be tuned
max_comm_length = 30; % Maximum length of a single commercial
max_comm_block_length = 180; % Maximum length of a block of commercials
threshold = 1; % Ignore detected silences if it's been < threshold
               % time since last silence

%% Initialize features for figuring stuff out
in_commercial = false;
last_toggle = 0;
last_silence = 0;
time_since_start = 0; % Should we have this or just use toc?

%% Stream
tic;
i=0;

while ~isDone(FReader)
	 % Read frame from file
	 audioIn = step(FReader);
     
     % Trivial algorithm, scale input audio
	 audioOut = 0.8*audioIn;

	 % View audio waveform
	 step(TimeScope,audioIn);

	 % Play resulting audio, if we're not in a commercial
     if (in_commercial==true)
        audioOut = zeros(size(audioOut)); 
     end
     step(Player,audioOut);

    % View waveform of output sound
    % step(TimeScopeOut, audioOut);
     
     % Calculate mean
     m = step(Meaner, audioIn);
     m = sum(m,2);
     
     % If we're sure we're not in a commercial, fix it!
     % Basically, if there hasn't been a silence in a long time,
     % we must be in the show.
     if (in_commercial)
         if ((toc - last_silence) > max_comm_length)
             t = toc - last_silence
            in_commercial = false
         end
     end
     
     % check for silence
     if (m==0)
         
         % If we just saw a silence, this one is meaningless
         if ((toc - last_silence) < threshold)
             % Set time since last silence to now
            last_silence = toc; 
            % Ignore this silence
            'ignoring silence'
            continue;
         end
         
         % if we've found a silence, see if it's been enough time
         if (toc - last_toggle > max_comm_block_length)
            in_commercial = true
            last_toggle = toc;
            % last_silence = toc;   
         end
         
         % Set current time to be the last silence found
         last_silence = toc;
     end

end

%% Terminate
release(FReader)
s = [];
release(TimeScope)
s.TimeScope = TimeScope;
release(Player)
