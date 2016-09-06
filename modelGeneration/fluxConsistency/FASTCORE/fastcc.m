function [A,V] = fastcc(model,epsilon,printLevel)
% [A,V] = fastcc(model,epsilon,printLevel)
%
% The FASTCC algorithm for testing the consistency of a stoichiometric model
% Output A is the consistent part of the model
%
% INPUT
% model         cobra model structure containing the fields
%   S           m x n stoichiometric matrix    
%   lb          n x 1 flux lower bound
%   ub          n x 1 flux uppper bound
%   rxns        n x 1 cell array of reaction abbreviations
% 
% epsilon       
% printLevel    0 = silent, 1 = summary, 2 = debug
%
% OPTIONAL INPUT
% modeFlag      {(0),1}; 1=return matrix of modes V
%
% OUTPUT
% A             n x 1 boolean vector indicating the flux consistent
%               reactions
% V             n x k matrix such that S(:,A)*V(:,A)=0 and |V(:,A)|'*1>0
 
% (c) Nikos Vlassis, Maria Pires Pacheco, Thomas Sauter, 2013
%     LCSB / LSRU, University of Luxembourg
%
% Ronan Fleming      17/10/14 Commenting of inputs/outputs/code
% Oveis Jamialahmadi 17/08/16 Modifying the fastcc to reduce cpu time.

if ~exist('printLevel','var')
    printLevel = 2;
end
% ///// Commented only for comparison with original fastcc withouth modeFlag
% if ~exist('modeFlag','var')
%     modeFlag=0;
% end
%//////////////////////////////////////////////////////////////////////////

tic

% origModel=model; % Commented only for comparison with original fastcc

%number of reactions
N = (1:size(model.S,2));

%reactions assumed to be irreversible in forward direction
I = find(model.lb==0);

A = [];

% J is the set of irreversible reactions
J = intersect( N, I );
if printLevel>1
    fprintf('|J|=%d  ', numel(J));
end

%V is the n x k matrix of maximum cardinality vectors
% V=[]; Commented only for comparison with original fastcc withouth modeFlag

%v is the flux vector that approximately maximizes the cardinality 
%of the set of irreversible reactions v(J)
V = LP7( J, model, epsilon);

% ======================= EDITED on original LP7 of FASTCORE | Oveis Jamialahmadi =============
% NOTE: The following lines are not documented; however, the overall ideas are:
% 1- After identifying the inconsistent irreversible rxns by original LP7, similar to original
%    fastcc, the reversible reactions which their consistency have not been established yet are 
%    set as objectives to form a new LP problem. On the other hand, the lb of irreversible consistent 
%    reactions are set to epsilon (clearly they can carry flux). This new LP is run two times:one
%    for 'max' and the other for 'min'. Reversible rxns which can carry a flux in either of these 
%    two optimization states are moved to consistent rxns (Threshold is the same as that of LP-7). Also,
%    similar to original fastcc, by flipping the S matrix sign, the flux rates in reverse directions are
%    also checked similar to the above-mentioned procedure. These steps are run in a loop (just
%     like the fastcc, but without iterative use of LP-7). 
% 2- Comparing these results with those of fastcc revealed that some rxns cannot be checked merely 
%    with this method. These rxns have special characteristics as mentioned in lines 168-169.
% 3- This approach takea much less cpu time comparing with fastcc, simply by using Lp-7 only for one time.
N = (1:size(model.S,2));
ThrowME = 1; loopME = 1;
while ThrowME
    Supp = find( abs(V) >= 0.99*epsilon );
    A = Supp;
    A_original = A;
    
    inconsistent_irrevs = setdiff( J, A );
    consistent_revs = setdiff( A, J );
    zero_revs = setdiff( setdiff( N, A ), inconsistent_irrevs);
    zero_revs_rxns = model.rxns(zero_revs);
%     consistent_revs_rxns = model.rxns(consistent_revs);
%     inconsistent_irrevs = model.rxns(setdiff( J, A ));
    
    model.lb(setdiff(A,consistent_revs)) = epsilon;
    model.c(find(model.c)) = 0;
    model.c(zero_revs) = 1;

    New_V1 = optimizeCbModel(model,'min');
    New_Vm1 = optimizeCbModel(model,'max');

    Flg_revs = zeros(numel(V),1);
    for i = 1:numel(zero_revs_rxns)
        if abs(New_V1.x(zero_revs(i))) >= 0.99*epsilon || abs(New_Vm1.x(zero_revs(i))) >= 0.99*epsilon

            V(zero_revs(i)) = epsilon;
            Flg_revs(zero_revs(i)) = 1;
        end
    end

    JiRev = find(model.rev);
    model.S(:,JiRev) = -model.S(:,JiRev);
    tmp = model.ub(JiRev);
    model.ub(JiRev) = -model.lb(JiRev);
    model.lb(JiRev) = -tmp;
    New_V1 = optimizeCbModel(model,'min');
    New_Vm1 = optimizeCbModel(model,'max');

    for i = 1:numel(zero_revs_rxns)
        if abs(New_V1.x(zero_revs(i))) >= 0.99*epsilon || abs(New_Vm1.x(zero_revs(i))) >= 0.99*epsilon
              if ~Flg_revs(zero_revs(i))
                  V(zero_revs(i)) = epsilon;
              end
        end
    end
    
    model.S(:,JiRev) = -model.S(:,JiRev);
    tmp = model.ub(JiRev);
    model.ub(JiRev) = -model.lb(JiRev);
    model.lb(JiRev) = -tmp;
    
    Supp = find( abs(V) >= 0.99*epsilon );
    A = Supp;
    if numel(A) == numel(A_original)
        ThrowME = 0;
    end
    loopME = loopME + 1;
end

% Check for remaining reversible rxns with one single metabolite in common:
% For example: Rxns 1515 and 3145 in Recon2 and Rxns 881 and 1327 in Recon1
[MetIndx,~] = find(model.S(:,zero_revs));
[unique_ids,~,Idx] = unique(MetIndx);
% Repeated_ids = unique_ids(histc(Idx,1:numel(Idx))==2);

candidate_revs = (0); ct1 = 1;
for ct = 1:numel(zero_revs)
    if numel(find(model.S(:,zero_revs(ct)))) == 1
       Temp_mets = find(model.S(:,zero_revs(ct)));
       Temp_rxns = find(model.S(Temp_mets,:));
       if numel(Temp_rxns) == 2 && isempty(setdiff(Temp_rxns,zero_revs))
        candidate_revs(ct1) = zero_revs(ct);
        ct1 = ct1 + 1;
       end
    end
end

% Set new objectives
model.c(find(model.c)) = 0;
model.c(candidate_revs) = 1;
Min_res = optimizeCbModel(model,'min');
Min_res = Min_res.x(candidate_revs);
Min_res(Min_res<0.99*epsilon) = 0;
Max_res = optimizeCbModel(model,'max');
Max_res = Max_res.x(candidate_revs);
Max_res(Max_res<0.99*epsilon) = 0;
[~,candInd] = setdiff(abs(Min_res),abs(Max_res));
[candInd,~] = find(model.S(:,candidate_revs(candInd)));
[~,candInd] = find(model.S(candInd,:));
Cons_revs = intersect(zero_revs,candInd);
A = union(A,Cons_revs);
