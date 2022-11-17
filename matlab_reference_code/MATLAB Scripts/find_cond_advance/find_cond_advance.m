function [bestAdv,bestSal,advances,goodness,binIndex,varargout] = find_cond_advance(t,c,p,minAdv,maxAdv,varargin)
%
% find_cond_advance.m--Finds the best advance (in scans) of conductivity
% relative to temperature to minimize salinity spiking.
%
% Required input arguments are temperature, conductivity, pressure and the
% minimum and maximum values of advance (in scans) to be tried. 
%
% In determining the best conductivity advance, find_cond_advance.m bins
% the calculated salinity by pressure. If the optional input argument
% binIndex is specified, find_cond_advance.m skips the time-consuming
% binning procedure and uses the supplied binning instead. This can greatly
% speed processing if subsequent calls to find_cond_advance.m use the same
% binning, as when finding the best conductivity advance for both primary
% and secondary temperature/conductivity channels from the same CTD cast.
%
% Other input arguments in the form of parameter/value pairs may be
% appended to the above-mentioned input arguments. Supported parameters
% are:
%    'showprogress'--'yes' or 'no' (the default): prints messages to
%       command line showing progress of program.
%
% The "bestAdv" output argument gives the best advance value found. The
% "bestSal" output argument gives the salinity calculated from conductivity
% advanced by bestAdv scans. The "advances" output argument gives the
% values of advances that were tried in finding the best advance. The next
% output argument gives the "goodness" value associated with each value of
% advance (the best advance is the one with the largest "goodness"). The
% goodness value is an arbitrary measure, and is not comparable between
% different CTD casts. The final, standard output argument is binIndex, the
% index used for binning the conductivity and temperature by depth; this
% can be used as the input for subsequent runs of find_cond_advance.m on
% the same data.
%
% If the optional output argument, "salinities", is specified, then the
% salinity vector for each conductivity advance is returned. This can be
% useful for debugging, but makes large demands on computer memory.
%
% Syntax: [bestAdv,bestSal,advances,goodness,binIndex,<salinities>] = find_cond_advance(t,c,p,minAdv,maxAdv,<binIndex>)
%
% e.g.,   load('fca_demodata.mat');
%         [bestAdv,bestSal,advances,goodness,binIndex,salinities] = find_cond_advance(t,c,p,-4,4,'showprogress','yes');
%
%         figure; subplot(2,1,1);
%         plot(advances,goodness,'o-',bestAdv,goodness(find(advances==bestAdv)),'ro');
%         xlabel('advance [scans]'); ylabel('''goodness''');
%         title(sprintf('Best Advance is %.2f scans',bestAdv));
%         subplot(2,1,2);
%         numAdvs = length(advances); 
%
%         for iAdv = 1:numAdvs
%            thisAdv = advances(iAdv);
%            thisSal = salinities{iAdv} + (0.03*iAdv-1);
%            if thisAdv == bestAdv, lineColour='r'; else lineColour='b';end
%            line(thisSal,p,'color',lineColour); 
%         end % for
%
%         set(gca,'ydir','r','xtick',[]); axis('tight'); box on;
%         xlabel('salinity'); ylabel('pressure');

% Developed in Matlab 7.0.1.24704 (R14) Service Pack 1 on GLNX86.
% Kevin Bartlett(kpb@uvic.ca), 2006/01/12, 11:45
%-------------------------------------------------------------------------

% Handle output arguments.
if nargout == 6
    doReturnSals = true;
else
    doReturnSals = false;    
end % if

% Handle input arguments.
t = t(:);
c = c(:);
p = p(:);

if rem(nargin,2) == 0
    
    % If an even number of arguments, then binIndex is the first of the
    % varargins.
    binIndex = varargin{1};
    
    % The rest of the arguments (if any) are parameter/value pairs.
    if nargin>1
        inArgs = varargin(2:end);
    else
        inArgs = {};
    end % if
else
    
    % An odd number of arguments means that no binIndex has been supplied.
    binIndex = [];
    inArgs = varargin;
    
end % if

defaultVals.showprogress = 'no';
parValStruct = parse_args(defaultVals,inArgs{:});
doShowProgress = strcmpi(parValStruct.showprogress,'yes');

% Get an index for binning by pressure. Bins will be used in an overlapping
% way, with values for a particular bin being gleaned from that depth bin
% plus the two adjacent bins as well. This will help to avoid problems with
% spikes on the cusp of two bins that sometimes appear in one bin and
% sometimes in the adjacent bin, depending on the advance value used.
if isempty(binIndex)

    BINWIDTH = 0.33; % [m]
    firstBinCentre = roundto(min(p),BINWIDTH,'up') + BINWIDTH/2;
    lastBinCentre = roundto(max(p),BINWIDTH,'down') - BINWIDTH/2;
    binCentres = firstBinCentre:BINWIDTH:lastBinCentre;
    
    if length(binCentres)<2
        bestAdv = NaN;
        advances = NaN;
        goodness = 0;
        
        if doReturnSals
            salinities = {NaN};
            varargout{1} = salinities;
        end % if
        
        return;
    end % if
    
    binIndex = getbinindex(p,binCentres);
    
end % if

numBins = length(binIndex);

% Advance conductivity by a pair of values well outside the expected range
% and calculate corresponding salinity profiles. Because we are using
% extreme values for conductivity advance, the resulting salinity profiles
% should have a lot of spiking in them. Salinity spikes caused by incorrect
% advance values tend to be of opposite sign for opposite extremes of
% misalignment, so the range of salinities at each depth we find here should be
% very large. We will use the salinity ranges found using these extreme
% advance values as a standard of badness for comparison with the results
% from using more realistic advance values later in the program.
if doShowProgress
    disp('   Calculating profiles using extreme advance values');
end % if

%scans = [1:length(c)]';
notNanIndex = find(~isnan(c));
% advRange = range([minAdv maxAdv]);
advRange = abs(maxAdv-minAdv);
bracketMultiplier = 2;
lowerBracketAdv = minAdv - bracketMultiplier*advRange;
upperBracketAdv = maxAdv + bracketMultiplier*advRange;

% ...Lower bracket advance value.
advancedCond = advance_conductivity(c(notNanIndex),lowerBracketAdv);
lowerBracketSal = cond2sal(advancedCond(:),t(:),p(:));

% ...Upper bracket advance value.
advancedCond = advance_conductivity(c(notNanIndex),upperBracketAdv);
upperBracketSal = cond2sal(advancedCond(:),t(:),p(:));

% Find the range between the salinity profiles calculated from the two
% extreme, bracketed advances at each depth bin.
bracketRange = NaN * ones(1,numBins);

for binCount = 2:numBins-1
    
    % Take information from two neighbouring bins as well.
    thisBinIndex = [binIndex{binCount-1}; binIndex{binCount}; binIndex{binCount+1}];

    if isempty(thisBinIndex)
        bracketRange(binCount) = NaN;
    else        
        thisLowerBracketSal = lowerBracketSal(thisBinIndex);
        thisUpperBracketSal = upperBracketSal(thisBinIndex);
        thisBinMin = min(min(thisLowerBracketSal),min(thisUpperBracketSal));
        thisBinMax = max(max(thisLowerBracketSal),max(thisUpperBracketSal));
        bracketRange(binCount) = thisBinMax - thisBinMin;
    end % if

end % for

% Advance the conductivity by values within the requested range and
% calculate the salinity profiles. Determine the "goodness" of each advance
% value. The "goodness" is a measure of how different the profiles are from
% the deliberately bad extreme profiles (i.e., how small the salinity range
% in each depth bin is relative to the ranges found for the two extreme
% advance values). The best advance value will be the one associated with
% the largest value of "goodness".

% ...Search for the best advance value 5 values at a time. At each
% iteration, will find the best advance value so far and examine 5 more
% advance values centred around this best value. Iteration will stop when
% resolution reaches a desired size.
NUM_ADVS_PER_ITERATION = 5;

% Want resolution of 1/10 of a scan, so iterations will stop when advance
% values are 1/20 of a scan apart.
TOL = 1/20; 

advances = [];
goodness = [];
res = +Inf;
itNum = 0;

if doReturnSals
    salinities = {};
end % if

if doShowProgress
    fprintf(1,'   %s','Calculating goodness   ');
end % if

currMinAdv = minAdv;
currMaxAdv = maxAdv;

while res > TOL

    itNum = itNum + 1;
    
    if doShowProgress
        fprintf(1,'%c','.');
    end % if
    
    thisItAdvs = linspace(currMinAdv,currMaxAdv,NUM_ADVS_PER_ITERATION);

    % Don't calculate twice: remove any previously-done advance from this
    % iteration's list of advances.
    thisItAdvs = thisItAdvs(~ismember(thisItAdvs,advances));
    thisItGoodness = NaN * thisItAdvs;
    thisItSals = cell(size(thisItAdvs));

    % For each advance value in this iteration, shift the conductivity and
    % calculate the goodness.
    for advCount = 1:length(thisItAdvs)

        thisAdv = thisItAdvs(advCount);
        advancedCond = advance_conductivity(c(notNanIndex),thisAdv);
        advancedSal = cond2sal(advancedCond(:),t(:),p(:));
        
        if doReturnSals
            thisItSals{advCount} = advancedSal;
        end % if
        
        thisAdvSalRanges = NaN * ones(numBins,1);

        for binCount = 2:numBins-1

            % Take information from two neighbouring bins as well.
            thisBinIndex = [binIndex{binCount-1}; binIndex{binCount}; binIndex{binCount+1}];

            if isempty(thisBinIndex)
                thisAdvSalRanges(binCount) = NaN;
            else
                thisBinMin = min(advancedSal(thisBinIndex));
                thisBinMax = max(advancedSal(thisBinIndex));
                thisBinRange = thisBinMax - thisBinMin;
                thisAdvSalRanges(binCount) = thisBinRange;
            end % if

        end % for

        % Square the difference between the range of the binned salinity
        % profile and the range of the two bracketed profiles. This will give
        % more weight to spikes.
        thisItGoodness(advCount) = nansum((thisAdvSalRanges(:) - bracketRange(:)).^2);

    end % for each advance value

    % Combine this iteration's advance and goodness (and optionally
    % salinities) values to the overall advance and goodness variables.
    if doReturnSals
        [salinities{length(salinities)+1:length(salinities)+length(thisItSals)}] = deal(thisItSals{:});
    end % if
    
    advances = [advances thisItAdvs];
    goodness = [goodness thisItGoodness];
    [dummy,sortIndex] = sort(advances);
    advances = advances(sortIndex);
    goodness = goodness(sortIndex);
    
    if doReturnSals
        salinities = salinities(sortIndex);
    end % if

    % ...Remove any duplicate values of advance.
    [dummy,unique_i,unique_j] = unique(advances);
    advances = advances(unique_i);
    goodness = goodness(unique_i);

    if doReturnSals
        salinities = salinities(unique_i);
    end % if

    % Find the advance value that has the best goodness value so far.
    [dummy,maxIndex] = max(goodness);

    if maxIndex == 1
        minAdvIndex = 1;
    else
        minAdvIndex = maxIndex - 1;
    end % if

    if maxIndex == length(advances)
        maxAdvIndex = length(advances);
    else
        maxAdvIndex = maxIndex + 1;
    end % if

    currMinAdv = advances(minAdvIndex);
    currMaxAdv = advances(maxAdvIndex);

    % See how far apart advance values are. Will exit while loop if
    % resolution smaller than desired tolerance. Otherwise, will continue
    % on to next iteration with new currMinAdv and currMaxAdv values.
    res = max(diff(thisItAdvs));
    
    % Safety bail-out:
    if itNum>25
        break;
    end % if

end % while

if doShowProgress
    fprintf(1,'\n');
end % if

% Find the advance value that has the best goodness value.
[dummy,maxIndex] = max(goodness);

if maxIndex == 1 || maxIndex == length(goodness)
    
    if doShowProgress
        disp([mfilename '.m--No maximum exists in ''goodness'' curve for range of advances from ' num2str(minAdv) ' to ' num2str(maxAdv) ' scans. Returning a value of NaN.']);
    end % if
    
    bestAdv = NaN;
else
    bestAdv = advances(maxIndex);
end % if

% Re-calculate the salinity that results from the best advance (the
% alternative to re-calculating here would be to keep all the salinities
% calculated at all the advances and then choose the best one for output,
% and this would put a lot of demands on computer memory).
advancedCond = advance_conductivity(c(notNanIndex),bestAdv);
bestSal = cond2sal(advancedCond(:),t(:),p(:));

% Output all the salinities, if requested.
if doReturnSals
    varargout{1} = salinities;
end % if

%-------------------------------------------------------------------------

function [binIndex,varargout] = getbinindex(data,binCentres,varargin)
%
% getbinindex.m--Bins data into bins specified by the user. Unlike Matlab's
% hist.m function, Getbinindex.m returns an index to the binned data, allowing
% the user to bin one quantity by another. You can, for example, bin salinity
% data by depth. Getbinindex.m can be used like Matlab's interp1.m function
% to thin data, but does not require the independent variable to be monotonic.
%
% Getbinindex.m takes as input arguments the vector "data", and the vector
% "binCentres". binCentres specifies the bin locations using their
% central values.
%
% Getbinindex.m returns three indices to the data: binIndex, infraBinIndex,
% and ultraBinIndex (the last two are optional).
%
% infraBinIndex and ultraBinIndex are indices to the data that lie outside 
% of the specified bins. data(infraBinIndex) consists of all the data that
% lie below the lowest data bin, while data(ultraBinIndex) consists of all
% the data that lie above the highest data bin.
%
% binIndex is in the form of a cell array, with each cell corresponding to
% a data bin. Thus, data(binIndex{3}) consists of the data that lie within
% the bin limits of data bin 3.
%
% Syntax: [binIndex,<infraBinIndex>,<ultraBinIndex>] = ...
%             getbinindex(data,binCentres);
%
% e.g., depth   =[0 101 202 302 400 492 423 360 352 400 494 605 701 793 900 973];
%       density =[5 10 14 17 24 40 47 44 36 32 32 40 50 62 76 97]; 
%       [binIndex,infraBinIndex,ultraBinIndex] = getbinindex(depth,[150 400 700]);
%       figure(1);clf;plot(depth,density,'k-');hold on;
%       plot(depth(infraBinIndex),density(infraBinIndex),'k*');
%       plot(depth(ultraBinIndex),density(ultraBinIndex),'k*');
%       ColourOrder=get(gca,'ColorOrder');
%       for count=1:length(binIndex),h=plot(depth(binIndex{count}),density(binIndex{count}));
%       set(h,'Marker','o','Color',ColourOrder(count,:));end
%       xlabel('Depth');ylabel('Density');title(['Density Values Binned by Depth']);

% Kevin Bartlett, IOS, 5/1999.
%------------------------------------------------------------------------------

% Note: implemented this syntax to try to vectorize and thus make more
% efficient the binning process, but ran into two problems:
% (1) Found that I couldn't figure out how to vectorize the algorithm
%    completely, so there was little if any difference in speed.
% (2) Ran out of memory when I tried to use it on real data.
%
% e.g., binIndex = getbinindex(depth,[150 400 700],'method','loop');
% e.g., binIndex = getbinindex(depth,[150 400 700],'method','matrix');
%
%    ==> Just stick to default "loop" method.
%
% Kevin Bartlett, 2005-12-19.

% Additional note: Eleanor Williams had a vectorised bin-averaging program
% that looked promising, but it looks like the process is lossy. There is a
% step in her algorithm where she extracts one of each unique pressure
% value in the time series (necessary for her interpolation scheme) and
% only keeps the corresponding elements of the time series being binned:
%   [punik,I,J] = unique(pressN);
%   seriesunik = seriesN(I);
% This means (I think) that any time a pressure value is encountered more
% than once, only one value of temperature would be contributed to the
% bin's sum. This would work for a lot of data, but not where there are
% wild values.

if nargin == 4
    
    parStr = varargin{1};
    
    if strcmp(parStr,'method') == 0
        error([mfilename '.m--Unrecognised parameter name used as input argument.']);
    end % if
    
    methodStr = varargin{2};

    if ~ismember(methodStr,{'loop' 'matrix'})
        error([mfilename '.m--Unrecognised methodStr value: ' methodStr]);
    end % if
    
elseif nargin == 2
    methodStr = 'loop';
else
    error([mfilename '.m--Incorrect number of input arguments.']);
end % if

numBins = length(binCentres);

if numBins < 2,
   error([mfilename '.m--Number of bins must be greater than 1.']);
end % if

if any(diff(binCentres)<=0)
   error([mfilename '.m--Bin values must be monotonically increasing.']);
end % if

% 1) Determine limits of each bin. The halfway point between adjacent bin
% centres is taken to be the dividing line between bins.
%binBorders = [];
binBorders = NaN * ones(1,numBins-1);

for count = 1:(numBins-1),
   binBorders(count) = (binCentres(count) + binCentres(count+1))/2;
end % for

% The lowest bin does not yet have a lower limit, and the highest bin
% has no upper limit. Define these bins to be symmetric and calculate
% their limits accordingly.
BinDifference = diff(binCentres);

LowestBinLimit  = binCentres(1) - BinDifference(1)/2;
HighestBinLimit = binCentres(numBins) + BinDifference(length(BinDifference))/2;

binBorders = [LowestBinLimit binBorders HighestBinLimit];

% 2) Find the indices to the data for each data bin.

% 2.1) Find the indices to the data that lie below the lower limit of the
% lowest data bin.
infraBinIndex = find(data <= LowestBinLimit);

% 2.2) Find the indices to the data that lie above the upper limit of the
% highest data bin.
ultraBinIndex = find(data > HighestBinLimit);

% 2.3) For each data bin specified by the user, find the indices to the
% data that lie within each bin.

if strcmp(methodStr,'loop')
   binIndex = binwithloop(data,binBorders);
else
    binIndex = binwithmatrices(data,binBorders);
end % if

if nargout == 2
    varargout{1} = infraBinIndex;
elseif nargout == 3
    varargout{1} = infraBinIndex;
    varargout{2} = ultraBinIndex;
elseif nargout ~= 1
    error([mfilename '.m--Incorrect number of output arguments.']);
end % if
    
%-------------------------------------------------------------------------
function [binIndex] = binwithloop(data,binBorders)
%
% binwithloop.m--Slow, but non-memory intensive method of binning data.
%
% Syntax: binIndex = binwithloop(data,binBorders)

% Developed in Matlab 7.0.1.24704 (R14) Service Pack 1 on GLNX86.
% Kevin Bartlett(kpb@uvic.ca), 2005/12/19, 09:08
%-------------------------------------------------------------------------

numBins = length(binBorders) - 1;
binIndex = cell(1,numBins);

% Try to improve efficiency by not considering bins outside the range of
% the data.
%startBin = max(find(binBorders < min(data)));
startBin = find(binBorders < min(data),1,'last');

if isempty(startBin) || startBin < 1
    startBin = 1;
end % if

%endBin = min(find(binBorders > max(data))) - 1;
endBin = find(binBorders > max(data),1,'first') - 1;

if isempty(endBin) || endBin > numBins
    endBin = numBins;
end % if

% Loop through each bin and find the index to the data for each one.
for count = startBin:endBin
    
   CurrLowerLim = binBorders(count);
   CurrUpperLim = binBorders(count+1);
   
   binIndex{count} = find( (data > CurrLowerLim) & (data <= CurrUpperLim) );
   
end % for

%-------------------------------------------------------------------------
function [binIndex] = binwithmatrices(data,binBorders)
%
% binwithmatrices.m--Fast, but memory-intensive method of binning data.
%
% Syntax: binIndex = binwithmatrices(data,binBorders)

% Developed in Matlab 7.0.1.24704 (R14) Service Pack 1 on GLNX86.
% Kevin Bartlett(kpb@uvic.ca), 2005/12/19, 09:08
%-------------------------------------------------------------------------

error([mfilename '.m--This method no faster, and causes memory exhaustion.']);

% Convert data to row vector, if necessary.
dataLength = length(data);
isCol = size(data,2) == 1;

if isCol == 1
    data = data(:)';
end % if

% Tile the data to have the same number of rows as there are bins.
numBins = length(binBorders) - 1;
data = repmat(data,numBins,1);

% Determine the lower and upper limits of the bins.
lowBorders = binBorders(1:end-1);
upperBorders = binBorders(2:end);

% Tile the bin borders to have as many columns as there are columns of
% data to be binned.
lowBorders = lowBorders(:);
lowBorders = repmat(lowBorders,1,dataLength);
upperBorders = upperBorders(:);
upperBorders = repmat(upperBorders,1,dataLength);

% Find the elements of data that lie within the bin limits.
findMat = (data>lowBorders & data<=upperBorders)';
%[r,c] = find(findMat);
rowMat = repmat((1:dataLength)',1,numBins);
rowMat(findMat==0) = 0;

% Couldn't figure out how to do this entirely without a loop. Will it still
% be faster?
% rowCell = num2cell(rowMat)
% [rowCell{find(findMat==0)}] = deal([]);
%
% rowCell = num2cell(rowMat,1)

binIndex = cell(1,numBins);

for binCount = 1:numBins
    binIndex{binCount} = rowMat(rowMat(:,binCount)>0,binCount);  
end % for

%-------------------------------------------------------------------------

function [RoundedNumber] = roundto(number,increment,varargin)
%
% roundto.m--Rounds a number to the nearest specified increment.
%
% For example, specifying an increment of .01 will cause the input
% number to be rounded to the nearest one-hundredth while an increment
% of 25 will cause the input number to be rounded to the nearest
% multiple of 25. An increment of 1 causes the input number to be
% rounded to the nearest integer, just as Matlab's round.m does.
%
% Optional input argument RoundDirection can be 'up', in which case
% the number is rounded up, or 'down', in which case the
% number is rounded down. A RoundDirection of 'auto' will result
% in normal rounding, with no preferred direction.
%
% Roundto.m works for scalars and matrices.
%
% Syntax: RoundedNumber = roundto(number,increment,<RoundDirection>);
%
% e.g., RoundedNumber = roundto(123.456789,.01)
% e.g., RoundedNumber = roundto(123.456789,5)
% e.g., RoundedNumber = roundto(123.456789,.01,'down')

% Developed in Matlab 6.1.0.450 (R12.1) on Linux.
% Kevin Bartlett(kpb@hawaii.edu), 2003/03/25, 15:47
%------------------------------------------------------------------------------

UP = 1;
AUTO = 0;
DOWN = -1;

if nargin == 2
   RoundDirection = AUTO;
elseif nargin == 3
    
    if strcmpi(varargin{1},'down')
        RoundDirection = DOWN;
    elseif strcmpi(varargin{1},'up')
        RoundDirection = UP;
    elseif strcmpi(varargin{1},'auto')
        RoundDirection = AUTO;
    else
        error([mfilename '.m--Unrecognized rounding-direction string.']);
    end % if
    
else
    error([mfilename '.m--Incorrect number of input arguments.']);
end % if
    
if increment == 0,
   error([mfilename '.m--Cannot round to the nearest zero.'])
end % if

if increment < 0,
   error([mfilename '.m--Rounding increment must be positive.'])
end % if

multiplier = 1/increment;

if RoundDirection == AUTO
   RoundedNumber = (round(multiplier*number))/multiplier;
elseif RoundDirection == UP
   RoundedNumber = ceil((multiplier*number))/multiplier;
elseif RoundDirection == DOWN
   RoundedNumber = floor((multiplier*number))/multiplier;
end % if
%-------------------------------------------------------------------------

function sal = cond2sal(cond,temp,varargin)
%
% cond2sal.m--Converts conductivity and temperature to salinity.
%
% If pressure is not passed to the program, a pressure of zero is used in
% calculating salinity.
%
% Input units are: conductivity [S/m]; temperature [C]; pressure [db].
% Output is PSU.
%
% This program is really just a user-friendly wrapper for functions from 
% the seawater package; these functions are included as part of the code 
% of cond2sal.m.
%
% Syntax: sal = cond2sal(cond,temp,<press>)
%
% e.g.,   sal = cond2sal(4.4,16,200)

% Developed in Matlab 6.5.0.180913a (R13) on SUN OS 5.8.
% Kevin Bartlett(kpb@hawaii.edu), 2003/01/15, 14:04
%------------------------------------------------------------------------------

% Parse input arguments.
if nargin == 3
   press = varargin{1};
elseif nargin ~= 2 && nargin ~= 1
   error([mfilename '.m--Incorrect number of input arguments.']);
end % if

if isempty(cond)
    sal = [];
    %keyboard
    return;
end % if

% Output salinity in same orientation as conductivity.
isRowVec = size(cond,1)==1;

% Convert conductivity to salinity.
CondRatio = cond./(sw_c3515./10); % (See help for sw_cndr.m) (/10 to convert from mS/cm to S/m)

% If pressure is not available, calculate salinity with a pressure of zero.
if exist('press','var') ~= 1
   press = zeros(size(CondRatio));
end % if

if isempty(press)
   press = zeros(size(CondRatio));
end % if

if ~isequal(size(press),size(temp),size(cond))
    error([mfilename '.m--Input variables must be of same size.']);
end % if

% Possible bug: sw_salt returns small imaginary component. Get rid of it.
sal = real(sw_salt(CondRatio(:),temp(:),press(:)));

if isRowVec
   sal = sal(:)';
else
   sal = sal(:);   
end % if

%-------------------------------------------------------------------------
function [advancedCond] = advance_conductivity(cond,advance)
%
% advance_conductivity.m--Shifts CTD conductivity data by the specifed
% advance. Advance value is in "scans".
%
% Syntax: advancedCond = advance_conductivity(cond,advance)
%
% e.g.,   load('cca_demo.mat'); 
%         advancedCond = advance_conductivity(c,-1.4);
%         spikySal = cond2sal(c,t,p); lessSpikySal = cond2sal(advancedCond,t,p);
%         figure; plot(spikySal,p); hold on; plot(lessSpikySal,p,'r');
%         set(gca,'ydir','reverse');

% Developed in Matlab 7.6.0.324 (R2008a) on GLNX86.
% Kevin Bartlett (kpb@uvic.ca), 2008-09-16 09:39
%-------------------------------------------------------------------------

% "Scans" are just the integer indices of the temperature and conductivity
% samples.
scans = ones(size(cond));
scans(1:length(scans)) = (1:length(scans));

% Definition of a positive advance of conductivity relative to temperature:
% in a SeaBird instrument, temperature is read before conductivity (T leads
% C), so a transition to a new water type during a CTD cast will be
% registered in the temperature record before it appears in the
% conductivity record. To make T and C simultaneous, the conductivity is
% "advanced" by a positive amount. This is equivalent to subtracting a
% positive amount from the time values associated with C. For example,
% let's say a transition to a new water layer appears in the temperature
% record at scan #8, but doesn't appear in the conductivity record until
% scan #10. Subtracting 2 from the vector of scans associated with C causes
% the transition to appear in the conductivity record at scan #8,
% simultaneous with the transition in the temperature record.

% Shift the conductivity records by the specified advance
shiftedScans = scans - advance;

% If conductivity were advanced an integer number of scans, it would be
% possible just to pad the conductivity and temperature vectors by suitable
% amounts to make them line up again (so that scan #8 is the eighth element
% of both conductivity and temperature, for example). If a NON-integer
% advance was used, however, no amount of shifting and padding will let
% conductivity and temperature line up again. Instead of simply shifting
% conductivity, then, we will line it up with temperature using
% interpolation.
advancedCond = interp1(shiftedScans,cond,scans,'linear','extrap');
%-------------------------------------------------------------------------


function c3515 = sw_c3515()

% SW_C3515   Conductivity at (35,15,0)
%=========================================================================
% SW_c3515  $Revision: 1.4 $   $Date: 1994/10/10 04:35:22 $
%       %   Copyright (C) CSIRO, Phil Morgan 1993.
%
% USAGE:  c3515 = sw_c3515
%
% DESCRIPTION:
%   Returns conductivity at S=35 psu , T=15 C [ITPS 68] and P=0 db).
%
% INPUT: (none)
%
% OUTPUT:
%   c3515  = Conductivity   [mmho/cm == mS/cm] 
% 
% AUTHOR:  Phil Morgan 93-04-17  (morgan@ml.csiro.au)
%
% DISCLAIMER:
%   This software is provided "as is" without warranty of any kind.  
%   See the file sw_copy.m for conditions of use and licence.
%
% REFERENCES:
%    R.C. Millard and K. Yang 1992.
%    "CTD Calibration and Processing Methods used by Woods Hole 
%     Oceanographic Institution"  Draft April 14, 1992
%    (Personal communication)
%=========================================================================

% CALLER: none
% CALLEE: none
%

c3515 = 42.914;

return

%-------------------------------------------------------------------------
function Rp = sw_salrp(R,T,P)

% SW_SALRP   Conductivity ratio   Rp(S,T,P) = C(S,T,P)/C(S,T,0)
%=========================================================================
% SW_SALRP   $Revision: 1.3 $  $Date: 1994/10/10 05:47:27 $
%            Copyright (C) CSIRO, Phil Morgan 1993.
%
% USAGE:  Rp = sw_salrp(R,T,P)
%
% DESCRIPTION:
%    Equation Rp(S,T,P) = C(S,T,P)/C(S,T,0) used in calculating salinity.
%    UNESCO 1983 polynomial.
%
% INPUT: (All must have same shape)
%   R = Conductivity ratio  R =  C(S,T,P)/C(35,15,0) [no units]
%   T = temperature [degree C (IPTS-68)]
%   P = pressure    [db]
%
% OUTPUT:
%   Rp = conductivity ratio  Rp(S,T,P) = C(S,T,P)/C(S,T,0)  [no units] 
% 
% AUTHOR:  Phil Morgan 93-04-17  (morgan@ml.csiro.au)
%
% DISCLAIMER:
%   This software is provided "as is" without warranty of any kind.  
%   See the file sw_copy.m for conditions of use and licence.
%
% REFERENCES:
%    Fofonoff, P. and Millard, R.C. Jr
%    Unesco 1983. Algorithms for computation of fundamental properties of 
%    seawater, 1983. _Unesco Tech. Pap. in Mar. Sci._, No. 44, 53 pp.
%=========================================================================

% CALLER: sw_salt
% CALLEE: none

%-------------------
% CHECK INPUTS
%-------------------
if nargin~=3
  error('sw_salrp.m: requires 3 input arguments')
end %if

[mr,nr] = size(R);
[mp,np] = size(P);
[mt,nt] = size(T);
if ~(mr==mp | mr==mt | nr==np | nr==nt)
   error('sw_salrp.m: R,T,P must all have the same shape')
end %if   

%-------------------
% eqn (4) p.8 unesco.
%-------------------
d1 =  3.426e-2;
d2 =  4.464e-4;
d3 =  4.215e-1;
d4 = -3.107e-3;

e1 =  2.070e-5;
e2 = -6.370e-10;
e3 =  3.989e-15;

Rp = 1 + ( P.*(e1 + e2.*P + e3.*P.^2) ) ...
     ./ (1 + d1.*T + d2.*T.^2 +(d3 + d4.*T).*R);
 
return
%-----------------------------------------------------------------------

%-------------------------------------------------------------------------


function rt = sw_salrt(T)

% SW_SALRT   Conductivity ratio   rt(T)     = C(35,T,0)/C(35,15,0)
%=========================================================================
% SW_SALRT  $Revision: 1.3 $  $Date: 1994/10/10 05:48:34 $
%           Copyright (C) CSIRO, Phil Morgan 1993.
%
% USAGE:  rt = sw_salrt(T)
%
% DESCRIPTION:
%    Equation rt(T) = C(35,T,0)/C(35,15,0) used in calculating salinity.
%    UNESCO 1983 polynomial.
%
% INPUT: 
%   T = temperature [degree C (IPTS-68)]
%
% OUTPUT:
%   rt = conductivity ratio  [no units] 
% 
% AUTHOR:  Phil Morgan 93-04-17  (morgan@ml.csiro.au)
%
% DISCLAIMER:
%   This software is provided "as is" without warranty of any kind.  
%   See the file sw_copy.m for conditions of use and licence.
%
% REFERENCES:
%    Fofonoff, P. and Millard, R.C. Jr
%    Unesco 1983. Algorithms for computation of fundamental properties of 
%    seawater, 1983. _Unesco Tech. Pap. in Mar. Sci._, No. 44, 53 pp.
%=========================================================================

% CALLER: sw_salt
% CALLEE: none

% rt = rt(T) = C(35,T,0)/C(35,15,0)
% Eqn (3) p.7 Unesco.

c0 =  0.6766097;
c1 =  2.00564e-2;
c2 =  1.104259e-4;
c3 = -6.9698e-7;
c4 =  1.0031e-9;

rt = c0 + (c1 + (c2 + (c3 + c4.*T).*T).*T).*T;

return
%--------------------------------------------------------------------
%-------------------------------------------------------------------------


function S = sw_sals(Rt,T)

% SW_SALS    Salinity of sea water
%=========================================================================
% SW_SALS  $Revision: 1.3 $  $Date: 1994/10/10 05:49:13 $
%          Copyright (C) CSIRO, Phil Morgan 1993.
%
% USAGE:  S = sw_sals(Rt,T)
%
% DESCRIPTION:
%    Salinity of sea water as a function of Rt and T.  
%    UNESCO 1983 polynomial.
%
% INPUT:
%   Rt = Rt(S,T) = C(S,T,0)/C(35,T,0)
%   T  = temperature [degree C (IPTS-68)]
%
% OUTPUT:
%   S  = salinity    [psu      (PSS-78)]
% 
% AUTHOR:  Phil Morgan 93-04-17  (morgan@ml.csiro.au)
%
% DISCLAIMER:
%   This software is provided "as is" without warranty of any kind.  
%   See the file sw_copy.m for conditions of use and licence.
%
% REFERENCES:
%    Fofonoff, P. and Millard, R.C. Jr
%    Unesco 1983. Algorithms for computation of fundamental properties of 
%    seawater, 1983. _Unesco Tech. Pap. in Mar. Sci._, No. 44, 53 pp.
%=========================================================================

% CALLER: sw_salt
% CALLEE: none

%--------------------------
% CHECK INPUTS
%--------------------------
if nargin~=2
  error('sw_sals.m: requires 2 input arguments')
end %if

[mrt,nrt] = size(Rt);
[mT,nT]   = size(T);
if ~(mrt==mT | nrt==nT)
   error('sw_sals.m: Rt and T must have the same shape')
end %if

%--------------------------
% eqn (1) & (2) p6,7 unesco
%--------------------------
a0 =  0.0080;
a1 = -0.1692;
a2 = 25.3851;
a3 = 14.0941;
a4 = -7.0261;
a5 =  2.7081;

b0 =  0.0005;
b1 = -0.0056;
b2 = -0.0066;
b3 = -0.0375;
b4 =  0.0636;
b5 = -0.0144;

k  =  0.0162;

Rtx   = sqrt(Rt);
del_T = T - 15;
del_S = (del_T ./ (1+k*del_T) ) .* ...
        ( b0 + (b1 + (b2+ (b3 + (b4 + b5.*Rtx).*Rtx).*Rtx).*Rtx).*Rtx);
	
S = a0 + (a1 + (a2 + (a3 + (a4 + a5.*Rtx).*Rtx).*Rtx).*Rtx).*Rtx;

S = S + del_S;

return
%----------------------------------------------------------------------
%-------------------------------------------------------------------------


function S = sw_salt(cndr,T,P)

% SW_SALT    Salinity from cndr, T, P
%=========================================================================
% SW_SALT  $Revision: 1.3 $  $Date: 1994/10/10 05:49:53 $
%          Copyright (C) CSIRO, Phil Morgan 1993.
%
% USAGE: S = sw_salt(cndr,T,P)
%
% DESCRIPTION:
%   Calculates Salinity from conductivity ratio. UNESCO 1983 polynomial.
%
% INPUT:
%   cndr = Conductivity ratio     R =  C(S,T,P)/C(35,15,0) [no units]
%   T    = temperature [degree C (IPTS-68)]
%   P    = pressure    [db]
%
% OUTPUT:
%   S    = salinity    [psu      (PSS-78)]
% 
% AUTHOR:  Phil Morgan 93-04-17  (morgan@ml.csiro.au)
%
% DISCLAIMER:
%   This software is provided "as is" without warranty of any kind.  
%   See the file sw_copy.m for conditions of use and licence.
%
% REFERENCES:
%    Fofonoff, P. and Millard, R.C. Jr
%    Unesco 1983. Algorithms for computation of fundamental properties of 
%    seawater, 1983. _Unesco Tech. Pap. in Mar. Sci._, No. 44, 53 pp.
%=========================================================================

% CALLER: general purpose
% CALLEE: sw_sals.m sw_salrt.m sw_salrp.m

  
%----------------------------------
% CHECK INPUTS ARE SAME DIMENSIONS
%----------------------------------
[mc,nc] = size(cndr);
[mt,nt] = size(T);
[mp,np] = size(P);

if ~(mc==mt | mc==mp | nc==nt | nc==np)
  error('sw_salt.m: cndr,T,P must all have the same dimensions')
end %if

%-------
% BEGIN
%-------
R  = cndr;
rt = sw_salrt(T);
Rp = sw_salrp(R,T,P);
Rt = R./(Rp.*rt);
S  = sw_sals(Rt,T);

return
%--------------------------------------------------------------------

%-------------------------------------------------------------------------

function [argStruct,varargout] = parse_args(varargin)
%
% parse_args.m--Parses input arguments for a client function. Arguments are
% assumed to be in parameter/value pair form. 
%
% The following example shows the steps involved in using parse_args.m:
%
% (1) Create m-file "myfunc.m" with the following function declaration:
%        function [] = myfunc(varargin)
%
% (2) Inside myfunc.m, include the following lines:
%        defaultVals.figureWidth = 0.8; 
%        defaultVals.figureHeight = 0.5;
%        argStruct = parse_args(defaultVals,varargin{:});
%
% (3) Call your function with the following syntax:
%        myfunc('figureHeight',0.99)
%
% Inside myfunc.m, the structured variable argStruct will contain fields
% named 'figureWidth' and 'figureHeight'. The 'figureWidth' field will
% contain the default value of 0.8, since no non-default value was passed
% to myfunc.m, but the 'figureHeight' field will contain the value 0.99,
% over-riding the default value of 0.5.
%
% There are variations on this pattern:
%
% (a) Your "myfunc.m" program may take arguments in addition to varargin,
%     but they must precede varargin. For example, your function
%     declaration could look like this:
%         function [] = myfunc(numFiles,pathName,varargin)
%
% (b) It is not necessary to declare any default values. Your "myfunc.m"
%     program can call parse_args.m like this:
%         argStruct = parse_args(varargin{:});
%
% (c) You can call myfunc.m with all parameter/value pairs specified, none
%     of them specified, or anything in between. In the example above,
%     myfunc.m could be called like this:
%         myfunc('figureHeight',0.99,'figureWidth',0.2);
%     or like this:
%         myfunc;
%
% (d) Your "myfunc.m" program  can call parse_args.m with two additional
%     input arguments:
%         argStruct = parse_args(...,allowNewFields,isCaseSensitive);
%     where allowNewFields and isCaseSensitive are both Boolean values. By
%     default, isCaseSensitive is true, so parse_args.m will treat the
%     parameters 'lineColour' and 'linecolour' (for example) as different
%     parameters. The allowNewFields parameter is also true by default,
%     meaning that parse_args.m will accept parameters whose names are NOT
%     included as fields in the default values structured variable. You can
%     over-ride the default behaviour by specifying a different value for
%     allowNewFields or isCaseSensitive, but in this case, BOTH of these
%     arguments must be specified in the call to parse_args.m as shown
%     above.
%
% (e) Your program may call parse_args.m with a second output argument:
%         [argStruct,overRidden] = parse_args(...
%     The "overRidden" output argument contains a list of those variables
%     (if any) whose default values were overridden by varargin elements.
%
% N.B., program originally named parvalpairs.m. Program is based on the
% (University of Hawaii) Firing Group's fillstruct.m.
%
% Syntax: [argStruct,<overRidden>] = parse_args(<defaultStruct>,...
%                                    par1,val1,par2,val2,...,
%                                    <allowNewFields,isCaseSensitive>)
%
% e.g.,   argStruct = parse_args('Position',[256 308 512 384],'Units','pixels','Color',[1 0 1])
%
% e.g.,   defaultStruct.a = pi; 
%         defaultStruct.b = 'hello'; 
%         defaultStruct.c = [1;2;3];
%         allowNewFields = 1; 
%         isCaseSensitive = 0; 
%         [argStruct,overRidden] = parse_args(defaultStruct,varargin{:},allowNewFields,isCaseSensitive);
%         % N.B., for demonstration on command line (where you won't have a
%         varargin variable), use this syntax: 
%         [argStruct,overRidden] = parse_args(defaultStruct,'A',pi/2,'b','bye','z','new field',allowNewFields,isCaseSensitive)

% Developed in Matlab 6.1.0.450 (R12.1) on Linux. Kevin
% Bartlett(kpb@hawaii.edu), 2003/04/08, 11:49
%--------------------------------------------------------------------------

% Handle input arguments.
args = varargin;

if nargin == 0
    argStruct = struct([]);
    overRidden = {};
    
    if nargout > 1
        varargout{1} = overRidden;
    end % if

    return;
end % if

% If a structured variable containing default field values has been
% supplied, separate it from the other input arguments.
defaultStruct = struct([]);

if isstruct(args{1})

    defaultStruct = args{1};

    if length(args) > 1
        args = args(2:end);
    else
        args = {};
    end % if

end % if

argStruct = defaultStruct;

% Determine if values of the variables "allowNewFields" and
% "isCaseSensitive" have been specified.

% ...Default values:
allowNewFields = 1;
isCaseSensitive = 1;

if length(args) > 1
    
    % If no values of allowNewFields and isCaseSensitive have been
    % specified, then all the remaining arguments will be parameter/value
    % pairs. The second-to-last argument should then be a string.
    if ~ischar(args{end-1})
    
        % The second-to-last argument is NOT a string, so it must be the
        % Boolean variable allowNewFields.
        allowNewFields = args{end-1};
        
        % ...and the last input argument is the Boolean variable
        % isCaseSensitive.
        isCaseSensitive = args{end};
        
        if length(args) > 1
           args = args(1:end-2);
        else
            args = {};
        end % if
        
    end % if
        
end % if

% If no arguments remain after extracting the default field values and the
% Boolean variables "allowNewFields" and "isCaseSensitive", then exit now.
% The value of argStruct returned will contain the same values as
% defaultStruct.
if isempty(args)
    overRidden = {};
    
    if nargout > 1
        varargout{1} = overRidden;
    end % if

    return;
end % if

if ~ismember(allowNewFields,[1 0])
    error([mfilename '.m--Value for "allowNewFields" must be 1 or 0.']);
end % if

if ~ismember(isCaseSensitive,[1 0])
    error([mfilename '.m--Value for "isCaseSensitive" must be 1 or 0.']);
end % if

% Remaining input arguments should be parameter/value pairs.
existingFieldNames = fieldnames(defaultStruct);
lowerExistingFieldNames = lower(existingFieldNames);
overRidden = cell(1,length(args)/2);

for iArg = 1:2:length(args)

    thisFieldName = args{iArg};
    overRidden{1+(iArg-1)/2} = thisFieldName;

    if ~ischar(thisFieldName)
        error([mfilename '.m--Parameter names must be strings.']);
    end % if

    thisField = args{iArg+1};

    % Find out if field already exists.
    if isCaseSensitive == 1

        if ismember(thisFieldName,existingFieldNames)
            fieldExists = 1;
            fieldNameToInsert = thisFieldName;
        else
            fieldExists = 0;
            fieldNameToInsert = thisFieldName;
        end % if

    else

        if ismember(lower(thisFieldName),lowerExistingFieldNames)
            fieldExists = 1;
            matchIndex = strmatch(lower(thisFieldName),lowerExistingFieldNames,'exact');
            fieldNameToInsert = existingFieldNames{matchIndex};
        else
            fieldExists = 0;
            fieldNameToInsert = thisFieldName;
        end % if

    end % if

    % If new fields are not permitted to be added, test that field already exists.
    if allowNewFields == 0 && fieldExists == 0
        
        % If the default structure is empty, and the user is not permitting
        % the addition of new fields, there is no point in running this
        % program; probably the user doesn't intend this.
        if isempty(defaultStruct)
            error([mfilename '.m--Need to permit the addition of new fields if no default structure specified.']);
        end % if

        if isCaseSensitive == 1
            %error([mfilename '.m--Attempt to add new parameter to existing set (case-sensitive). Use allowNewFields=1 to allow this.']);
            error([mfilename '.m--Unrecognised input argument ''' thisFieldName '''. (arguments are case-sensitive).']);
        else
            %error([mfilename '.m--Attempt to add new parameter to existing set. Use allowNewFields=1 to allow this.']);
            error([mfilename '.m--Unrecognised input argument ''' thisFieldName '''.']);
        end % if

    end % if

    if isempty(argStruct)
        argStruct = struct(fieldNameToInsert,thisField);
    else
        argStruct.(fieldNameToInsert) = thisField;
    end % if
            
end % for

if nargout > 1
    varargout{1} = overRidden;
end % if
