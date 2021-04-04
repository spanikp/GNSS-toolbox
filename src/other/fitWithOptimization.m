function funfit = fitWithOptimization(f,x,y,showPlot)
validateattributes(f,{'function_handle'},{'size',[1,1]},1);
validateattributes(x,{'double'},{},2);
validateattributes(y,{'double'},{},3);
assert(isequal(size(x),size(y)),'Mismatch of input sizes x<->y!');
if nargin < 4, showPlot = false; end
validateattributes(showPlot,{'logical'},{'size',[1,1]},4);

% Get fits of SNR differences
fString = func2str(f);
[matchStart,matchEnd] = regexp(fString,'p\((\d+)\)');
params = cell(1,length(matchStart));
for iMatch = 1:length(matchStart)
    params{iMatch} = fString(matchStart(iMatch):matchEnd(iMatch));
end
params = unique(params); % Will sort and make unique
nParams = length(params);
paramIdx = cellfun(@(x) str2double(x(3:end-1)),params);
if ~isequal(paramIdx,1:nParams)
    error('Invalid function definition! Some indices were omitted.');
end

% Get symbolic Jacobian variables
P = cellfun(@(x) replace(upper(x),{'(',')'},''),params,'UniformOutput',false);
FString = ['F = ',fString(7:end)];
%FString = replace(FString,'.','');
FString = replace(FString,'x','X');
for i = 1:nParams, FString = replace(FString,params{i},P{i}); end
eval(['syms X ',strjoin(P,' ')]);
eval(sprintf('%s;',FString));

JP = cell(1,nParams);
JX = cell(1,nParams);
symbolsToDerivate = {'X','P'};
for i = 1:nParams
    for iSymbol = 1:length(symbolsToDerivate)
        if iSymbol == 'X'
            s = char(diff(F,X));
        else
            s = char(diff(F,sprintf('%s%d',symbolsToDerivate{iSymbol},i)));
        end
        s = replace(s,'X','x');
        s = replace(s,'*','.*');
        s = replace(s,'/','./');
        s = replace(s,'^','.^');
        for j = 1:nParams, s = replace(s,P{j},params{j}); end
        
        if iSymbol == 'X'
            JX{i} = str2func(['@(x,p) ',s]);
        else
            JP{i} = str2func(['@(x,p) ',s]);
        end
    end
end


% Optimize given function "f" for given data pairs "(x,y)"
options = optimset('MaxIter',1000,'TolFun',1e-6,'TolX',1e-6);%,'Display','iter');

sse = @(p) sum((y - f(x,p)).^2);
p0 = zeros(1,nParams);
%p0 = 0.001*randn(1,nParams); % Often converge to wrong minimum

% Use more specialized function from Optimization toolbox if available
%if license('test','Optimization_Toolbox')
%    p = fminunc(sse,p0,options);
%else
    [p,min_sse,exitflag,output] = fminsearch(sse,p0,options);
%end

funfit = @(x) f(x,p);

% Get covariance matrix of fit parameters
MSE = min_sse/(length(x) - nParams);
J = nan(length(x),nParams);
for i = 1:length(params)
    J(:,i) = JP{i}(x);
end
pCov = inv(J'*J)*MSE;
pStd = sqrt(diag(pCov));
fBound = @(x,t) funfit(x) + t*sqrt(p*pCov*p');


fprintf('%s\nOptimized parameters of fitted function:\n  %s\n\n',repmat('=',[1,49]),func2str(f));
fprintf('+---------------+---------------+---------------+\n')
fprintf('|   Parameter   |     Value     |     Sigma     |\n');
fprintf('+---------------+---------------+---------------+\n')
for i = 1:nParams
    fprintf('| %s|%13.8f  |%13.8f  |\n',pad(params{i},14),p(i),pStd(i));
end
fprintf('+---------------+---------------+---------------+\n\n')



% Development figure
if showPlot
    figure;
    tBound = 2;
    xPlot = 0:90;
    plot(x,y,'k.','DisplayName','data'); hold on;
    polyFit = polyfit(x,y,3);
    plot(xPlot,polyval(polyFit,xPlot),'-','LineWidth',5,'Color',[.5,.5,.5],'DisplayName','polyfit');
    plot(xPlot,f(xPlot,p0),'--','LineWidth',5,'DisplayName','initial');
    plot(xPlot,funfit(xPlot),'r-','LineWidth',3,'DisplayName','optimized SSE');
    plot(xPlot,f(xPlot,p+pStd'),'r--','DisplayName','fit bounds');
    plot(xPlot,f(xPlot,p-pStd'),'r--','HandleVisibility','off');
    %patchObj = patch('XData',[xPlot,fliplr(xPlot),xPlot(1)],'YData',[fBound(xPlot,-tBound),fliplr(fBound(xPlot,tBound)),fBound(xPlot(1),-tBound)]);
    %set(patchObj,'FaceColor','r','EdgeColor','none','FaceAlpha',0.05);
    yr = max(y) - min(y);
    ylim([min(y)-0.05*yr,max(y)+0.05*yr])
    legend('Location','NorthEast');
    title(sprintf('Optimization fitted function "%s"\newlineexitFlag=%d, SSE=%.3f, iterations=%d',...
        func2str(f),exitflag,min_sse,output.iterations));
end



