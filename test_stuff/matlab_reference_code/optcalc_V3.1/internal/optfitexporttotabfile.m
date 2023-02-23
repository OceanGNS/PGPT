function optfitexporttotabfile(w)
% function optfitexporttotabfile(w)
%
% export calibration data to tab file and add coefficients for Uchida et
% al. 2008 (pO2) abd adapted uchidasq (pO2) model
%
% input:
%   w       - structure from flw.OWwinklerfromtime
%   w.goodi   - logical index to good observations
%   w.OW      - Winkler oxygen
%   w.OWstd   - Winkler oxygen std
%
%
% output: file in current directory 'MODEL_SN.TAB'
%
% Henry Bittig, GEOMAR
% 31.07.2012

% number of elements
nol=length(find(w.goodi));
% collect calibration data and prepare string
if islogical(w.goodi)
    info=[datestr(w.date(w.goodi,:)) ones(nol,1)*'\t' num2str(w.t(w.goodi),'%4.2f') ones(nol,1)*'\t' num2str(w.bp(w.goodi),'%5.3f') ones(nol,1)*'\t' num2str(w.OW(w.goodi),'%4.1f') ones(nol,1)*'\t' num2str(w.OWstd(w.goodi),'%2.1f') ones(nol,1)*'\t' num2str(w.generatorflag(w.goodi),'%2.1f') ones(nol,1)*'\n'];
else
    info=[datestr(w.date(sort(w.goodi),:)) ones(nol,1)*'\t' num2str(w.t(sort(w.goodi)),'%4.2f') ones(nol,1)*'\t' num2str(w.bp(sort(w.goodi)),'%5.3f') ones(nol,1)*'\t' num2str(w.OW(sort(w.goodi)),'%4.1f') ones(nol,1)*'\t' num2str(w.OWstd(sort(w.goodi)),'%2.1f') ones(nol,1)*'\t' num2str(w.generatorflag(sort(w.goodi)),'%2.1f') ones(nol,1)*'\n'];
end
% calculate fit parameters
fuchida=optfitfoilcoeffromstruct(w,'uchida');
close(gcf)
fuchidasq=optfitfoilcoeffromstruct(w,'uchidasq');
close(gcf)
% write tab file
try
    eval(['fid=fopen(''' num2str(w.model) '_' num2str(str2num(w.sn),'%.4u') '.TAB'',''w'');'])
catch
    eval(['fid=fopen(''' num2str(w.model) '_' num2str(w.sn,'%.4u') '.TAB'',''w'');'])
end
fwrite(fid,sprintf('date\ttime\ttemperature\tTCPhase\tWinkler O2\tWinkler O2 std\n'));
fwrite(fid,reshape(sprintf(info')',[],nol));
fwrite(fid,sprintf('\nUchida et al. 2008 coefficients (pO2 / mbar)\n'));
fwrite(fid,sprintf([num2str(fuchida.foilcoef(:,1),'%.8e') ones(7,1)*'\n']')');
fwrite(fid,sprintf('\nafter Uchida et al. 2008 (uchidasq) coefficients (pO2 / mbar)\n'));
fwrite(fid,sprintf([num2str(fuchidasq.foilcoef(:,1),'%.8e') ones(21,1)*'\n']')');
fclose(fid);